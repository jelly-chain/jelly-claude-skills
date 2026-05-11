# Aave Skill

Lending, borrowing, flash loans, and yield on Aave V3 across Ethereum, Base, Arbitrum, Polygon, Avalanche, and Optimism.

## Overview
Aave V3 is the leading decentralized lending protocol. You deposit collateral and borrow against it (up to the Loan-to-Value ratio). Interest rates adjust dynamically based on utilization. Flash loans let you borrow with no collateral as long as you repay in the same transaction.

## Key Contract Addresses — Ethereum Mainnet V3

| Contract | Address |
|----------|---------|
| Pool (supply/borrow/repay) | `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |
| PoolAddressesProvider | `0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e` |
| UIPoolDataProviderV3 | `0x91c0eA31b49B69Ea18607702c5d9aC360bf3dE7d` |
| WrappedTokenGateway (ETH) | `0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C` |
| Aave Protocol Data Provider | `0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3` |

All chain deployments: https://docs.aave.com/developers/deployed-contracts/v3-mainnet

## SDK Setup
```bash
npm install @aave/core-v3 @aave/contract-helpers @aave/math-utils ethers
```

## Read Pool Data (no wallet needed)

```typescript
import { UiPoolDataProvider, ChainId } from "@aave/contract-helpers";
import { providers } from "ethers";

const provider = new providers.JsonRpcProvider(process.env.ETH_RPC_URL);

const poolDataProvider = new UiPoolDataProvider({
  uiPoolDataProviderAddress: "0x91c0eA31b49B69Ea18607702c5d9aC360bf3dE7d",
  provider,
  chainId: ChainId.mainnet,
});

// Get all reserve (market) data
const { reservesData, baseCurrencyData } = await poolDataProvider.getReservesHumanized({
  lendingPoolAddressProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
});
reservesData.forEach(r => {
  console.log(`${r.symbol}: supply APY ${(Number(r.supplyAPY) * 100).toFixed(2)}% | borrow APY ${(Number(r.variableBorrowAPY) * 100).toFixed(2)}%`);
  console.log(`  LTV: ${Number(r.baseLTVasCollateral) / 100}% | Liquidation threshold: ${Number(r.reserveLiquidationThreshold) / 100}%`);
  console.log(`  Total supplied: $${Number(r.totalLiquidityUSD).toFixed(0)} | Utilization: ${(Number(r.utilizationRate) * 100).toFixed(1)}%`);
});

// Get user account data
const userReserves = await poolDataProvider.getUserReservesHumanized({
  lendingPoolAddressProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
  user: "0xYOUR_WALLET_ADDRESS",
});
```

## Supply (Deposit)

```typescript
import { ethers } from "ethers";

const POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);

const poolAbi = [
  "function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)",
];
const pool = new ethers.Contract(POOL, poolAbi, wallet);

// Approve first
const erc20Abi = ["function approve(address spender, uint256 amount) returns (bool)"];
const usdc = new ethers.Contract(USDC, erc20Abi, wallet);
const amount = ethers.parseUnits("1000", 6); // $1000 USDC
await usdc.approve(POOL, amount);

// Supply
await pool.supply(USDC, amount, wallet.address, 0);
console.log("Supplied 1000 USDC to Aave");
```

## Supply ETH (native token via gateway)

```typescript
const GATEWAY = "0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C";
const gatewayAbi = [
  "function depositETH(address pool, address onBehalfOf, uint16 referralCode) payable"
];
const gateway = new ethers.Contract(GATEWAY, gatewayAbi, wallet);
await gateway.depositETH(POOL, wallet.address, 0, { value: ethers.parseEther("1") });
```

## Borrow

```typescript
const poolBorrowAbi = [
  "function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)"
];
const poolBorrow = new ethers.Contract(POOL, poolBorrowAbi, wallet);

// interestRateMode: 1 = stable, 2 = variable (use 2)
const borrowAmount = ethers.parseUnits("500", 6); // borrow $500 USDC
await poolBorrow.borrow(USDC, borrowAmount, 2, 0, wallet.address);
console.log("Borrowed 500 USDC at variable rate");
```

## Repay

```typescript
const repayAbi = ["function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) returns (uint256)"];
const poolRepay = new ethers.Contract(POOL, repayAbi, wallet);

// Approve first
await usdc.approve(POOL, ethers.MaxUint256); // approve max to cover interest

// type(uint256).max = repay all
await poolRepay.repay(USDC, ethers.MaxUint256, 2, wallet.address);
console.log("Repaid all USDC debt");
```

## Withdraw

```typescript
const withdrawAbi = ["function withdraw(address asset, uint256 amount, address to) returns (uint256)"];
const poolWithdraw = new ethers.Contract(POOL, withdrawAbi, wallet);

// type(uint256).max = withdraw all
await poolWithdraw.withdraw(USDC, ethers.MaxUint256, wallet.address);
```

## Check Health Factor

```typescript
const accountAbi = [
  "function getUserAccountData(address user) view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor)"
];
const poolAccount = new ethers.Contract(POOL, accountAbi, provider);
const data = await poolAccount.getUserAccountData("0x...");

const healthFactor = Number(ethers.formatUnits(data.healthFactor, 18));
const totalCollateral = Number(ethers.formatUnits(data.totalCollateralBase, 8));
const totalDebt = Number(ethers.formatUnits(data.totalDebtBase, 8));
const availableToBorrow = Number(ethers.formatUnits(data.availableBorrowsBase, 8));

console.log(`Health Factor: ${healthFactor.toFixed(2)} (>1.0 is safe; <1.0 = liquidation risk)`);
console.log(`Total Collateral: $${totalCollateral.toFixed(2)}`);
console.log(`Total Debt: $${totalDebt.toFixed(2)}`);
console.log(`Available to Borrow: $${availableToBorrow.toFixed(2)}`);
```

## Flash Loans

```typescript
// Flash loans let you borrow any amount with 0 collateral, repay in same tx
// Use case: arbitrage, liquidations, collateral swaps

const flashLoanAbi = [
  "function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode)"
];
// Your receiver contract must implement IFlashLoanSimpleReceiver
// Flash loan fee: 0.05% (5 bps) on Aave V3
```

## Risk Parameters Guide
| Metric | Safe Zone | Danger Zone |
|--------|-----------|-------------|
| Health Factor | > 2.0 | < 1.5 (getting close to liquidation) |
| LTV Utilization | < 60% of max | > 80% of max |
| Liquidation | Health Factor < 1.0 | Liquidators can repay your debt |

## Common Use Cases
- "What are current Aave supply APYs?" → read reserves data
- "Supply 1000 USDC to Aave" → supply()
- "Borrow 500 USDC against my ETH" → borrow()
- "What's my health factor?" → getUserAccountData()
- "Repay all my USDC debt" → repay() with MaxUint256
- "Withdraw my USDC from Aave" → withdraw()

## Links
- App: https://app.aave.com
- Docs: https://docs.aave.com
- Deployed contracts: https://docs.aave.com/developers/deployed-contracts/v3-mainnet
