# Polymarket Skill — Prediction Market Trading on Polygon

## Overview
Polymarket is the world's largest prediction market, running on Polygon (formerly Matic). It uses a Central Limit Order Book (CLOB) API backed by conditional tokens (ERC-1155) and USDC collateral.

## What you need (setup checklist)
1. **Polygon wallet private key** — same EVM address as your BNB wallet, on Polygon network
2. **USDC on Polygon** — minimum ~$5 to start; bridge from Ethereum or buy on a CEX and withdraw to Polygon
3. **Polymarket API key, secret, and passphrase** — from [app.polymarket.com](https://app.polymarket.com) → Settings → API
4. **Proxy wallet approval** — one-time EIP-712 signature to approve the Polymarket conditional token framework contract

## API base URLs
| Environment | URL |
|-------------|-----|
| CLOB (orders/markets) | `https://clob.polymarket.com` |
| Gamma (market metadata) | `https://gamma-api.polymarket.com` |

## Authentication
Polymarket uses L1 authentication (signed EIP-712 message) for order operations.

```typescript
import { ClobClient } from '@polymarket/clob-client';
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider('https://polygon-rpc.com');
const wallet   = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);

const client = new ClobClient(
  'https://clob.polymarket.com',
  137, // Polygon chain ID
  wallet,
  {
    key:        process.env.POLYMARKET_API_KEY!,
    secret:     process.env.POLYMARKET_SECRET!,
    passphrase: process.env.POLYMARKET_PASSPHRASE!,
  }
);
```

## Browse markets

```typescript
// List all active markets
const markets = await client.getMarkets();

// Get a specific market by condition ID
const market = await client.getMarket({ conditionId: '0x...' });
console.log(market.question, market.outcomes);
```

## Get orderbook

```typescript
const book = await client.getOrderBook({ tokenId: market.tokens[0].token_id });
console.log('Best bid:', book.bids[0]?.price, 'Best ask:', book.asks[0]?.price);
```

## Place an order (buy YES)

```typescript
import { Side, OrderType } from '@polymarket/clob-client';

const order = await client.createOrder({
  tokenId: market.tokens[0].token_id, // YES token
  price:   0.65, // 65 cents = 65% implied probability
  size:    10,   // $10 worth
  side:    Side.BUY,
  orderType: OrderType.GTC, // Good-till-cancelled
});
const result = await client.postOrder(order);
console.log('Order ID:', result.orderID);
```

## Place a market order (immediate fill)

```typescript
const order = await client.createMarketOrder({
  tokenId: market.tokens[0].token_id,
  amount:  10, // $10 USDC
  side:    Side.BUY,
});
await client.postOrder(order);
```

## Check positions

```typescript
const positions = await client.getPositions();
positions.forEach(p => {
  console.log(p.market, 'YES:', p.size, 'Avg price:', p.avgPrice);
});
```

## Cancel an order

```typescript
await client.cancelOrder({ orderId: '...' });
// Cancel all open orders:
await client.cancelAll();
```

## One-time proxy wallet approval
Run this once before your first trade:
```typescript
const approval = await client.createApiKey();
// The client SDK handles the EIP-712 proxy approval automatically
// on the first order if not already set up
```

## USDC approval for trading
```typescript
// USDC on Polygon: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
const USDC = new ethers.Contract('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', [
  'function approve(address,uint256) returns (bool)',
], wallet);
// Polymarket CTF exchange address
await USDC.approve('0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982e', ethers.MaxUint256);
```

## Pricing intuition
- Price = implied probability (0.01–0.99)
- Example: price 0.72 = market implies 72% chance of YES
- To bet YES at 72¢: your max loss is 72¢, max gain is 28¢ (pays $1 if YES wins)
- To bet NO at 28¢: your max loss is 28¢, max gain is 72¢

## Risk guidelines
- Never risk more than 5% of bankroll on a single market
- Check market liquidity before placing large orders (slippage in thin books is severe)
- Use GTC limit orders near mid-price to avoid large fills against stale quotes
- Always check the resolution source and criteria before entering a position
