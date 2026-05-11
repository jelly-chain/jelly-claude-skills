# GMX Skill

Perpetual trading, liquidity provision, and market data on GMX v2 (Arbitrum and Avalanche).

## Overview
GMX V2 is a decentralized perpetuals exchange using isolated markets with synthetic and real assets. It uses a two-token model: GM tokens (market liquidity) and GLV tokens (vaulted liquidity). Trades are executed via Keepers against Chainlink oracles.

## Key Addresses — Arbitrum

| Contract | Address |
|----------|---------|
| ExchangeRouter | `0x900173A20b5B4Af7807B0B9F554abb95b0BF4a84` |
| OrderVault | `0x31eF83a530Fde1B38ee9A18093A333D8Bbbc40D5` |
| DataStore | `0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8` |
| Reader | `0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE4E6B88E` |
| EventEmitter | `0xC8ee91A54287DB53897056e12D9819156D3822Fb` |

GMX v2 Markets (example):
- ETH/USD: `0x70d95587d40A2caf56bd97485aB3Eec10Bee6336`
- BTC/USD: `0x47c031236e19d024b42f8AE6780E44A573170703`
- SOL/USD: `0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9`

## SDK Setup
```bash
npm install ethers
# GMX SDK: https://github.com/gmx-io/gmx-sdk (TypeScript)
```

## Read Market Data via Subgraph

```typescript
const GMX_SUBGRAPH = "https://subgraph.satsuma-prod.com/3b2ced13c8d9/gmx/gmx-arbitrum-stats/api";

const query = `{
  tradingStats(first: 1, orderBy: timestamp, orderDirection: desc, where: { period: "daily" }) {
    timestamp
    volume
    fees
    trades
    longOpenInterest
    shortOpenInterest
  }
  glpStats(first: 1, orderBy: timestamp, orderDirection: desc, where: { period: "daily" }) {
    glpPrice
    aumInUsdg
    aum
  }
}`;

const res = await fetch(GMX_SUBGRAPH, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ query }),
}).then(r => r.json());

const stats = res.data.tradingStats[0];
console.log(`24h Volume: $${(Number(stats.volume) / 1e30).toFixed(2)}M`);
console.log(`24h Fees: $${(Number(stats.fees) / 1e30).toFixed(2)}M`);
console.log(`Long OI: $${(Number(stats.longOpenInterest) / 1e30).toFixed(2)}M`);
console.log(`Short OI: $${(Number(stats.shortOpenInterest) / 1e30).toFixed(2)}M`);
```

## GMX v2 REST API (via GMX Stats)

```typescript
const GMX_API = "https://arbitrum-api.gmxinfra.io";

// Markets overview
const markets = await fetch(`${GMX_API}/markets`).then(r => r.json());
markets.forEach(m => {
  console.log(`${m.indexToken.symbol}: Long OI $${(Number(m.longInterestInTokensUsd) / 1e30).toFixed(2)}M | Short OI $${(Number(m.shortInterestInTokensUsd) / 1e30).toFixed(2)}M`);
  console.log(`  Borrow rate long: ${(Number(m.borrowingFactorPerSecondForLongs) * 86400 * 365 * 100).toFixed(2)}%/yr`);
});

// Funding rates
const funding = await fetch(`${GMX_API}/funding-rates`).then(r => r.json());

// Positions for a wallet
const positions = await fetch(`${GMX_API}/positions?account=0x...`).then(r => r.json());
positions.forEach(p => {
  const pnl = Number(p.unrealizedPnl) / 1e30;
  console.log(`${p.market} | ${p.isLong ? "LONG" : "SHORT"} | Size: $${(Number(p.sizeInUsd) / 1e30).toFixed(2)} | PnL: $${pnl.toFixed(2)}`);
  console.log(`  Entry: $${(Number(p.entryPrice) / 1e30).toFixed(2)} | Liq: $${(Number(p.liquidationPrice) / 1e30).toFixed(2)}`);
});
```

## Create a Market Order (Long/Short)

```typescript
import { ethers } from "ethers";

const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);

const exchangeRouterAbi = [
  "function createOrder(tuple(address receiver, address cancellationReceiver, address callbackContract, address uiFeeReceiver, address market, address initialCollateralToken, address[] swapPath, uint256 sizeDeltaUsd, uint256 initialCollateralDeltaAmount, uint256 triggerPrice, uint256 acceptablePrice, uint256 executionFee, uint256 callbackGasLimit, uint256 minOutputAmount, bool isLong, bool shouldUnwrapNativeToken, bool autoCancel, bytes32 referralCode) params) payable external returns (bytes32)"
];

const router = new ethers.Contract(
  "0x900173A20b5B4Af7807B0B9F554abb95b0BF4a84",
  exchangeRouterAbi,
  wallet
);

const EXECUTION_FEE = ethers.parseEther("0.0003"); // Keeper fee ~0.0003 ETH on Arbitrum
const ETH_MARKET    = "0x70d95587d40A2caf56bd97485aB3Eec10Bee6336";
const USDC          = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"; // USDC on Arbitrum

const tx = await router.createOrder({
  receiver:                   wallet.address,
  cancellationReceiver:       wallet.address,
  callbackContract:           ethers.ZeroAddress,
  uiFeeReceiver:              ethers.ZeroAddress,
  market:                     ETH_MARKET,
  initialCollateralToken:     USDC,
  swapPath:                   [],
  sizeDeltaUsd:               ethers.parseUnits("1000", 30),  // $1000 position size
  initialCollateralDeltaAmount: ethers.parseUnits("100", 6),  // $100 USDC collateral (10x)
  triggerPrice:               0n,
  acceptablePrice:            ethers.parseUnits("3500", 30),  // max acceptable price
  executionFee:               EXECUTION_FEE,
  callbackGasLimit:           0n,
  minOutputAmount:            0n,
  isLong:                     true,   // true = long, false = short
  shouldUnwrapNativeToken:    false,
  autoCancel:                 false,
  referralCode:               ethers.ZeroHash,
}, { value: EXECUTION_FEE });

const receipt = await tx.wait();
console.log("Order created:", receipt?.hash);
// A Keeper will execute the order within ~1-2 blocks
```

## Close / Decrease Position

```typescript
// To close: sizeDeltaUsd = full position size, initialCollateralDeltaAmount = 0
// To partially close: sizeDeltaUsd = amount to reduce
await router.createOrder({
  ...params,
  sizeDeltaUsd:               positionSizeUsd,  // full size to close
  initialCollateralDeltaAmount: 0n,
  acceptablePrice:            isLong
    ? ethers.parseUnits("3000", 30)  // min price for longs
    : ethers.parseUnits("4000", 30), // max price for shorts
  isLong: currentPositionIsLong,
}, { value: EXECUTION_FEE });
```

## GM Token Liquidity Provision

```typescript
// GM tokens = provide liquidity to a specific market
// Deposit: provide long+short collateral, receive GM tokens
// Withdraw: redeem GM tokens for underlying collateral

// Check GM token APY (from stats API)
const gmApy = await fetch(`${GMX_API}/gm-markets`).then(r => r.json());
gmApy.forEach(m => console.log(`${m.name} GM APY: ${m.apr?.toFixed(2)}%`));
```

## Risk Rules for GMX
- **Always set a stop-loss**: Liquidation is permanent. Set trigger orders.
- **Monitor liquidation price**: Health factor < 1.0 = instant liquidation.
- **Pay execution fee**: Underfunded orders will fail — use at least 0.0003 ETH on Arbitrum.
- **Check max leverage**: GMX V2 allows up to 100x but use ≤10x for safety.
- **Funding rate risk**: High OI imbalance can produce large funding payments.

## Common Use Cases
- "What's the current ETH open interest on GMX?" → markets API
- "Open a $1000 ETH long with $100 USDC collateral" → createOrder isLong=true
- "What's my current PnL on GMX?" → positions API
- "Close my ETH long position" → createOrder with full sizeDeltaUsd
- "What's the 24h trading volume on GMX?" → subgraph tradingStats
- "Show me current funding rates" → funding-rates API

## Links
- App: https://app.gmx.io
- Docs: https://docs.gmx.io
- Stats: https://stats.gmx.io
- API: https://arbitrum-api.gmxinfra.io
