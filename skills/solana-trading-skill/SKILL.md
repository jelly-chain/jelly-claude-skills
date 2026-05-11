# Solana Trading Skill — Jupiter, Raydium, Safety Checks

## Overview
Covers swapping tokens on Solana using Jupiter aggregator, managing Raydium CLMM/AMM liquidity positions, and applying safety checks before executing trades.

## Pre-trade safety checklist
Before any trade:
1. Check token mint authority — if still enabled, creator can mint unlimited supply
2. Check freeze authority — if enabled, your tokens can be frozen
3. Check top 10 holder concentration — >50% = high rug risk
4. Check liquidity depth — slippage > 3% on your intended size = thin liquidity
5. Verify the token address matches the official source (not a copycat)

## Jupiter — Swap aggregator

### Get a quote
```typescript
const params = new URLSearchParams({
  inputMint:  'So11111111111111111111111111111111111111112', // SOL
  outputMint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', // USDC
  amount:     '1000000000', // 1 SOL in lamports
  slippageBps:'50',        // 0.5% slippage
});
const quote = await fetch(`https://quote-api.jup.ag/v6/quote?${params}`).then(r => r.json());
```

### Execute a swap
```typescript
const { swapTransaction } = await fetch('https://quote-api.jup.ag/v6/swap', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    quoteResponse: quote,
    userPublicKey: walletAddress,
    wrapAndUnwrapSol: true,
    dynamicComputeUnitLimit: true,
    prioritizationFeeLamports: 'auto',
  }),
}).then(r => r.json());

// Deserialize, sign and send with your @solana/kit signer
```

### Jupiter DCA (recurring buys)
Use Jupiter's DCA API to set up recurring purchases:
```typescript
// POST https://dca-api.jup.ag/dca
// Params: inputMint, outputMint, inAmount, numberOfCycles, cycleFrequency (seconds)
```

### Jupiter Limit Orders
```typescript
// POST https://jup.ag/api/limit-order/v2/openOrders
// Params: inputMint, outputMint, inAmount, outAmount (target price), expiredAt
```

## Raydium

### Swap via Trade API
```typescript
const { data } = await fetch(`https://transaction-v1.raydium.io/compute/swap-base-in?inputMint=${inputMint}&outputMint=${outputMint}&amount=${amount}&slippageBps=50&txVersion=V0`).then(r => r.json());
```

### CLMM — Create liquidity position
```typescript
import { Raydium, TxVersion } from '@raydium-io/raydium-sdk-v2';

const raydium = await Raydium.load({ owner: wallet, connection });
const { execute } = await raydium.clmm.openPositionFromBase({
  poolId,
  base: { mint: inputMint, amount },
  otherAmountMax: slippageAdjustedAmount,
  tickLower, tickUpper,
  txVersion: TxVersion.V0,
});
const { txIds } = await execute();
```

## Slippage guidelines

| Market condition | Recommended slippage |
|-----------------|---------------------|
| Blue chip (SOL, USDC) | 0.1–0.5% |
| Mid-cap DeFi token | 0.5–1.5% |
| Low-cap / new token | 2–5% |
| Meme / launchpad token | 5–15% |

## Priority fees
Always use dynamic priority fees for time-sensitive trades:
```typescript
prioritizationFeeLamports: 'auto'  // Jupiter handles this
// OR manually:
// prioritizationFeeLamports: 100000  // ~0.0001 SOL
```

## Useful token addresses
| Token | Mint |
|-------|------|
| SOL (wrapped) | `So11111111111111111111111111111111111111112` |
| USDC | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` |
| USDT | `Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB` |
| BONK | `DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263` |
