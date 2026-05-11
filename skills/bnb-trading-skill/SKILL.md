# BNB Trading Skill — PancakeSwap, Venus, Safety Checks

## Overview
Covers token swapping on BNB Smart Chain using PancakeSwap v3, lending on Venus Protocol, token approval patterns, and pre-trade safety checks.

## Pre-trade safety checklist
1. Check if contract is verified on BscScan
2. Check if ownership is renounced (`owner()` returns zero address)
3. Check liquidity lock — LP tokens should be locked (check via Mudra/Team.Finance)
4. Honeypot check — can you actually sell the token? Use honeypot.is API
5. Check tax: buy tax + sell tax > 10% = warning; > 25% = do not trade

## PancakeSwap v3 — Swap

### Get a quote via PancakeSwap Smart Router API
```typescript
const params = new URLSearchParams({
  chainId: '56',
  currency0: inputTokenAddress,
  currency1: outputTokenAddress,
  amount:     '1000000000000000000', // 1 token in wei
  tradeType: 'EXACT_INPUT',
});
const { trade } = await fetch(`https://api.pancakeswap.info/cachedPoolsV3?${params}`).then(r => r.json());
```

### Swap via Smart Router contract
```typescript
const ROUTER_ABI = [
  'function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96)) external payable returns (uint256 amountOut)',
];
const router = new ethers.Contract('0x1b81D678ffb9C0263b24A97847620C99d213eB14', ROUTER_ABI, wallet);
const tx = await router.exactInputSingle({
  tokenIn: inputToken,
  tokenOut: outputToken,
  fee: 2500, // 0.25%
  recipient: wallet.address,
  amountIn: ethers.parseEther('1'),
  amountOutMinimum: minAmountOut,
  sqrtPriceLimitX96: 0n,
}, { value: isNativeBNB ? ethers.parseEther('1') : 0n });
```

## Token approval pattern
```typescript
const ERC20 = new ethers.Contract(tokenAddress, [
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
], wallet);

const allowance = await ERC20.allowance(wallet.address, routerAddress);
if (allowance < amountNeeded) {
  const tx = await ERC20.approve(routerAddress, ethers.MaxUint256);
  await tx.wait();
}
```

## Venus Protocol (lending/borrowing)

```typescript
// Supply BNB to earn interest
const vBNB = new ethers.Contract('0xA07c5b74C9B40447a954e1466938b865b6BBea36', [
  'function mint() external payable',
  'function redeem(uint256 redeemTokens) external returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
], wallet);
await (await vBNB.mint({ value: ethers.parseEther('1') })).wait();

// Borrow USDT against BNB collateral
const vUSDT = new ethers.Contract('0xfD5840Cd36d94D7229439859C0112a4185BC0255', [
  'function borrow(uint256 borrowAmount) external returns (uint256)',
], wallet);
await (await vUSDT.borrow(ethers.parseUnits('100', 18))).wait();
```

## Key contract addresses (BSC Mainnet)

| Contract | Address |
|----------|---------|
| PancakeSwap v3 Router | `0x1b81D678ffb9C0263b24A97847620C99d213eB14` |
| PancakeSwap v2 Router | `0x10ED43C718714eb63d5aA57B78B54704E256024E` |
| WBNB | `0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c` |
| USDT (BSC) | `0x55d398326f99059fF775485246999027B3197955` |
| BUSD | `0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56` |
| Venus Unitroller | `0xfD36E2c2a6789Db23113685031d7F16329158384` |

## Slippage guidelines (BSC)
| Token type | Slippage |
|-----------|---------|
| WBNB/USDT | 0.1–0.3% |
| Established DeFi | 0.5–1% |
| Low-cap token | 2–5% |
| Meme / new launch | 10–20% |
