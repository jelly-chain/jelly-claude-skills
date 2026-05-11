# predict-fun-skill v2 — BNB Chain CLOB Prediction Market

## Overview
predict.fun is a Central Limit Order Book (CLOB) prediction market running natively on **BNB Chain**, settled in **USDT**. Markets are binary YES/NO contracts that resolve via the UMA Optimistic Oracle. This v2 skill covers the complete API surface: authentication (TS + Python), orderbook analysis, full order lifecycle, OAuth connections, market data, positions, and WebSocket streaming.

### Platform snapshot
| Item | Value |
|------|-------|
| Chain | BNB Mainnet (Chain ID 56) / Testnet (Chain ID 97) |
| Collateral | USDT (6 decimals) |
| Market type | Binary YES/NO, CLOB |
| Price range | 0.01 – 0.99 (implied probability) |
| Resolution oracle | UMA Optimistic Oracle |
| REST API (mainnet) | `https://api.predict.fun/` |
| REST API (testnet) | `https://api-testnet.predict.fun/` |
| WebSocket | `wss://ws.predict.fun/ws` |
| TypeScript SDK | `@predictdotfun/sdk` (npm) |
| Python SDK | `predictdotfun` (PyPI) |
| Rate limit | 240 req/min |
| API key | Required on mainnet; not required on testnet |
| LLMs.txt | `https://dev.predict.fun/llms.txt` |

---

## 1. Authentication — TypeScript

```typescript
import { Wallet } from "ethers";
import { OrderBuilder, ChainId } from "@predictdotfun/sdk";

const BASE = "https://api.predict.fun";
const signer = new Wallet(process.env.EVM_PRIVATE_KEY!);

// GET /v1/auth/message — get auth challenge message
const msgRes = await fetch(`${BASE}/v1/auth/message`, {
  headers: { "x-api-key": process.env.PREDICT_API_KEY! },
});
const { data: { message } } = await msgRes.json();

// Sign with EOA wallet
const signature = await signer.signMessage(message);

// POST /v1/auth — get JWT with valid signature
const authRes = await fetch(`${BASE}/v1/auth`, {
  method: "POST",
  headers: {
    "x-api-key": process.env.PREDICT_API_KEY!,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ signer: signer.address, message, signature }),
});
const { data: { token: JWT } } = await authRes.json();

const headers = {
  "x-api-key": process.env.PREDICT_API_KEY!,
  "Authorization": `Bearer ${JWT}`,
  "Content-Type": "application/json",
};
```

## 1b. Authentication — Python

```python
import os, requests
from eth_account import Account
from eth_account.messages import encode_defunct

BASE = "https://api.predict.fun"
API_HEADERS = {"x-api-key": os.environ["PREDICT_API_KEY"]}

# Get auth message
msg_data = requests.get(f"{BASE}/v1/auth/message", headers=API_HEADERS).json()
message = msg_data["data"]["message"]

# Sign with EOA
account = Account.from_key(os.environ["EVM_PRIVATE_KEY"])
msg = encode_defunct(text=message)
signature = account.sign_message(msg).signature.hex()

# Get JWT
auth_resp = requests.post(
    f"{BASE}/v1/auth",
    headers={**API_HEADERS, "Content-Type": "application/json"},
    json={"signer": account.address, "message": message, "signature": signature}
)
JWT = auth_resp.json()["data"]["token"]

auth_headers = {**API_HEADERS, "Authorization": f"Bearer {JWT}", "Content-Type": "application/json"}
```

---

## 2. Understanding the Orderbook

The orderbook stores prices for the **YES** outcome only. NO prices are derived via the complement formula. This is the foundation of all pricing logic on predict.fun.

```typescript
// GET /v1/markets/:id/orderbook — get the orderbook for a market
const obRes = await fetch(`${BASE}/v1/markets/${marketId}/orderbook`, {
  headers: { "x-api-key": apiKey },
});
const { data: { asks, bids, updateTimestampMs } } = await obRes.json();
// asks = [[price, qty], ...] sorted ASC  — asks[0] = best ask (cheapest YES to buy)
// bids = [[price, qty], ...] sorted DESC — bids[0] = best bid (highest YES bid)

// Complement formula — derive NO prices from YES orderbook
const complement = (price: number, decimals = 2): number => {
  const f = 10 ** decimals;
  return (f - Math.round(price * f)) / f;
};

const yesBestAsk = asks[0][0];                   // cheapest YES to buy
const yesBestBid = bids[0][0];                   // highest YES bid
const noBestBid  = complement(yesBestAsk);       // cheapest NO to buy (from complement)
const noBestAsk  = complement(yesBestBid);       // best NO bid (from complement)

// Full NO-side depth reconstruction (swap sides, complement each price)
const noAsks = bids.map(([p, q]) => [complement(p), q]);
const noBids = asks.map(([p, q]) => [complement(p), q]);

// Spread and mid-price analysis
const yesMid    = (yesBestBid + yesBestAsk) / 2;
const yesSpread = yesBestAsk - yesBestBid;
const noMid     = (noBestBid + noBestAsk) / 2;

// Total depth within a price band around mid
const depthWithin = (side: number[][], center: number, band: number) =>
  side.filter(([p]) => Math.abs(p - center) <= band).reduce((acc, [, q]) => acc + q, 0);

const yesLiquidity = depthWithin(asks, yesMid, 0.05); // depth within 5¢ of mid

// Pricing intuition:
// price 0.72 → market implies 72% chance YES wins
// BUY YES at 0.72: risk 72¢, gain 28¢ profit if YES wins
// BUY NO  at 0.28: risk 28¢, gain 72¢ profit if NO  wins
```

### Orderbook depth visualization

```typescript
function printBook(asks: number[][], bids: number[][], levels = 5) {
  console.log("  PRICE   | QUANTITY");
  console.log("  ─────────────────── ASK (YES to buy)");
  [...asks].slice(0, levels).reverse().forEach(([p, q]) =>
    console.log(`  ${p.toFixed(2)}    |  ${q.toFixed(0)} shares`));
  console.log("  ─── MID ───────────");
  bids.slice(0, levels).forEach(([p, q]) =>
    console.log(`  ${p.toFixed(2)}    |  ${q.toFixed(0)} shares`));
  console.log("  ─────────────────── BID (YES holders selling)");
}
```

---

## 3. Categories

```typescript
// GET /v1/categories — get all categories
const catsRes = await fetch(`${BASE}/v1/categories`, {
  headers: { "x-api-key": apiKey },
});
const { data: { categories } } = await catsRes.json();
categories.forEach(c => console.log(c.slug, c.name, c.marketCount));

// GET /v1/categories/:slug — get category by slug
const catRes = await fetch(`${BASE}/v1/categories/crypto`, {
  headers: { "x-api-key": apiKey },
});
const { data: category } = await catRes.json();
// category.markets contains the markets in this category

// GET /v1/tags — get all tags (only tags with at least one active market)
const tagsRes = await fetch(`${BASE}/v1/tags`, {
  headers: { "x-api-key": apiKey },
});
const { data: { tags } } = await tagsRes.json();
```

---

## 4. Markets

```typescript
// GET /v1/markets — list markets (paginated)
const marketsRes = await fetch(
  `${BASE}/v1/markets?status=open&limit=20&sort=volume&order=desc`,
  { headers: { "x-api-key": apiKey } }
);
const { data: { markets, total } } = await marketsRes.json();
markets.forEach(m => {
  console.log(`[${m.id}] ${m.question}`);
  console.log(`  YES tokenId: ${m.outcomes[0].onChainId}`);
  console.log(`  NO  tokenId: ${m.outcomes[1].onChainId}`);
  console.log(`  Fee: ${m.feeRateBps} bps | Status: ${m.status} | Trading: ${m.tradingStatus}`);
});

// GET /v1/markets/:id — get market by ID
const mktRes = await fetch(`${BASE}/v1/markets/${marketId}`, {
  headers: { "x-api-key": apiKey },
});
const { data: market } = await mktRes.json();
const feeRateBps = market.feeRateBps; // always fetch fresh before ordering

// GET /v1/markets/:id/stats — get market statistics
const statsRes = await fetch(`${BASE}/v1/markets/${marketId}/stats`, {
  headers: { "x-api-key": apiKey },
});
const { data: stats } = await statsRes.json();
// stats.volume24h, stats.openInterest, stats.totalVolume

// GET /v1/markets/:id/last-sale — get market last sale information
const lastSaleRes = await fetch(`${BASE}/v1/markets/${marketId}/last-sale`, {
  headers: { "x-api-key": apiKey },
});
const { data: { price, size, timestamp } } = await lastSaleRes.json();

// GET /v1/markets/:id/timeseries — get market timeseries
const tsRes = await fetch(
  `${BASE}/v1/markets/${marketId}/timeseries?interval=1h&start=${startTs}&end=${endTs}`,
  { headers: { "x-api-key": apiKey } }
);
const { data: { points } } = await tsRes.json();
// points = [{ timestamp, price, volume }, ...]

// GET /v1/markets/:id/timeseries/latest — get latest market timeseries value
const latestRes = await fetch(`${BASE}/v1/markets/${marketId}/timeseries/latest`, {
  headers: { "x-api-key": apiKey },
});

// GET /v1/search — search categories and markets
const searchRes = await fetch(
  `${BASE}/v1/search?query=bitcoin+price+2025`,
  { headers: { "x-api-key": apiKey } }
);
const { data: { markets: results, categories: catResults } } = await searchRes.json();
```

---

## 5. Orders — How to Create or Cancel Orders

### Create a LIMIT order

```typescript
import { Wallet, parseUnits } from "ethers";
import { OrderBuilder, ChainId, Side } from "@predictdotfun/sdk";

const signer  = new Wallet(process.env.EVM_PRIVATE_KEY!);
const builder = await OrderBuilder.make(ChainId.BnbMainnet, signer);

// Fetch feeRateBps fresh before each order
const { data: market } = await (await fetch(`${BASE}/v1/markets/${marketId}`, { headers })).json();
const feeRateBps = market.feeRateBps;
const yesTokenId = market.outcomes[0].onChainId;

const { makerAmount, takerAmount } = builder.getLimitOrderAmounts({
  side:       Side.BUY,
  price:      0.65,
  tokenId:    yesTokenId,
  usdtAmount: parseUnits("10", 6),  // $10 USDT
});

const order = builder.buildOrder("LIMIT", {
  side: Side.BUY, tokenId: yesTokenId, makerAmount, takerAmount, nonce: 0n, feeRateBps,
});
const typedData   = builder.buildTypedData(order);
const signedOrder = await builder.signTypedDataOrder(typedData);
const orderHash   = builder.buildTypedDataHash(typedData);

// POST /v1/orders — create an order
const submitRes = await fetch(`${BASE}/v1/orders`, {
  method: "POST",
  headers,
  body: JSON.stringify({ order: signedOrder, orderHash }),
});
const result = await submitRes.json();
console.log("Status:", result.data.status);   // "OPEN" | "MATCHED" | "ERROR"
console.log("Hash:",   orderHash);
```

### Create a MARKET order

```typescript
const { data: orderbook } = await (await fetch(`${BASE}/v1/markets/${marketId}/orderbook`, { headers })).json();

const { makerAmount, takerAmount } = builder.getMarketOrderAmounts({
  side:       Side.BUY,
  tokenId:    yesTokenId,
  usdtAmount: parseUnits("10", 6),
  orderbook,
  slippage:   0.02,   // 2% max slippage
});
const order = builder.buildOrder("MARKET", {
  side: Side.BUY, tokenId: yesTokenId, makerAmount, takerAmount, nonce: 0n, feeRateBps,
});
const typedData   = builder.buildTypedData(order);
const signedOrder = await builder.signTypedDataOrder(typedData);
const orderHash   = builder.buildTypedDataHash(typedData);
await fetch(`${BASE}/v1/orders`, { method: "POST", headers, body: JSON.stringify({ order: signedOrder, orderHash }) });
```

### Read and cancel orders

```typescript
// GET /v1/orders/:hash — get order by hash
const orderRes = await fetch(`${BASE}/v1/orders/${orderHash}`, { headers });

// GET /v1/orders — get orders (filter by status)
const listRes = await fetch(`${BASE}/v1/orders?status=open&limit=50`, { headers });
const { data: { orders } } = await listRes.json();
orders.forEach(o => console.log(o.hash, o.price, o.side, o.status));

// GET /v1/orders/matches — get order match events
const matchRes = await fetch(`${BASE}/v1/orders/matches?limit=20`, { headers });
const { data: { events } } = await matchRes.json();

// POST /v1/orders/remove — remove orders from the orderbook
const cancelRes = await fetch(`${BASE}/v1/orders/remove`, {
  method: "POST",
  headers,
  body: JSON.stringify({ orderHashes: [orderHash1, orderHash2] }),
});
const { data } = await cancelRes.json();
console.log("Cancelled:", data.cancelledHashes);
```

---

## 6. Account

```typescript
// GET /v1/account — get connected account
const acctRes = await fetch(`${BASE}/v1/account`, { headers });
const { data: account } = await acctRes.json();
console.log("Address:", account.address, "| Balance:", account.balance, "USDT");

// GET /v1/account/activity — get account activity
const actRes = await fetch(`${BASE}/v1/account/activity?limit=50`, { headers });
const { data: { events } } = await actRes.json();
events.forEach(e => console.log(e.eventName, e.marketId, e.amount, e.timestamp));

// POST /v1/account/referral — set a referral
await fetch(`${BASE}/v1/account/referral`, {
  method: "POST",
  headers,
  body: JSON.stringify({ referralCode: "JELLY" }),
});
```

---

## 7. Positions

```typescript
// GET /v1/positions — get positions (your account)
const posRes = await fetch(`${BASE}/v1/positions`, { headers });
const { data: { positions } } = await posRes.json();
positions.forEach(p => {
  const pnl = ((currentPrice - p.avgPrice) * p.size).toFixed(2);
  console.log(`Market ${p.marketId} | ${p.side} | Size: ${p.size} | Avg: ${p.avgPrice} | P&L: $${pnl}`);
});

// GET /v1/positions/:address — get positions by address (any public wallet)
const pubRes = await fetch(`${BASE}/v1/positions/${walletAddress}`, {
  headers: { "x-api-key": apiKey },
});

// Redeem winning positions after market resolves
const redeemResult = await builder.redeemPositions({ marketId });
console.log("Redeemed:", redeemResult);
```

---

## 8. OAuth Connection Endpoints

```typescript
// POST — finalize a OAuth connection
const finalizeRes = await fetch(`${BASE}/v1/oauth/finalize`, {
  method: "POST",
  headers,
  body: JSON.stringify({ code: oauthCode, state: oauthState }),
});

// POST — get the orders for a OAuth connection
const oauthOrdersRes = await fetch(`${BASE}/v1/oauth/orders`, {
  method: "POST",
  headers,
  body: JSON.stringify({ connectionId: myConnectionId, status: "open" }),
});

// POST — create an order for a OAuth connection
const oauthCreateRes = await fetch(`${BASE}/v1/oauth/orders/create`, {
  method: "POST",
  headers,
  body: JSON.stringify({ connectionId: myConnectionId, order: signedOrder, orderHash }),
});

// POST — cancel the orders for a OAuth connection
const oauthCancelRes = await fetch(`${BASE}/v1/oauth/orders/cancel`, {
  method: "POST",
  headers,
  body: JSON.stringify({ connectionId: myConnectionId, orderHashes: [hash1, hash2] }),
});

// POST — get the positions for a OAuth connection
const oauthPosRes = await fetch(`${BASE}/v1/oauth/positions`, {
  method: "POST",
  headers,
  body: JSON.stringify({ connectionId: myConnectionId }),
});
```

---

## 9. Complete API Reference

| Method | Path | Needs JWT | Description |
|--------|------|-----------|-------------|
| GET | `/v1/auth/message` | No | Get auth message |
| POST | `/v1/auth` | No | Get JWT with valid signature |
| GET | `/v1/categories` | No | Get categories |
| GET | `/v1/categories/:slug` | No | Get category by slug |
| GET | `/v1/tags` | No | Get all tags |
| GET | `/v1/markets` | No | Get markets |
| GET | `/v1/markets/:id` | No | Get market by ID |
| GET | `/v1/markets/:id/stats` | No | Get market statistics |
| GET | `/v1/markets/:id/last-sale` | No | Get market last sale information |
| GET | `/v1/markets/:id/orderbook` | No | Get the orderbook for a market |
| GET | `/v1/markets/:id/timeseries` | No | Get market timeseries |
| GET | `/v1/markets/:id/timeseries/latest` | No | Get latest market timeseries value |
| GET | `/v1/orders/:hash` | Yes | Get order by hash |
| GET | `/v1/orders` | Yes | Get orders |
| GET | `/v1/orders/matches` | Yes | Get order match events |
| POST | `/v1/orders/remove` | Yes | Remove orders from the orderbook |
| POST | `/v1/orders` | Yes | Create an order |
| GET | `/v1/account` | Yes | Get connected account |
| GET | `/v1/account/activity` | Yes | Get account activity |
| POST | `/v1/account/referral` | Yes | Set a referral |
| GET | `/v1/positions` | Yes | Get positions |
| GET | `/v1/positions/:address` | No | Get positions by address |
| GET | `/v1/search` | No | Search categories and markets |
| POST | `/v1/oauth/finalize` | Yes | Finalize a OAuth connection |
| POST | `/v1/oauth/orders` | Yes | Get the orders for a OAuth connection |
| POST | `/v1/oauth/orders/create` | Yes | Create an order for a OAuth connection |
| POST | `/v1/oauth/orders/cancel` | Yes | Cancel the orders for a OAuth connection |
| POST | `/v1/oauth/positions` | Yes | Get the positions for a OAuth connection |

---

## 10. WebSocket — Live Data

```typescript
import WebSocket from "ws";

const ws = new WebSocket(`wss://ws.predict.fun/ws?apiKey=${process.env.PREDICT_API_KEY}`);

ws.on("open", () => {
  ws.send(JSON.stringify({ method: "subscribe", topic: `predictOrderbook/${marketId}`, requestId: 1 }));
  ws.send(JSON.stringify({ method: "subscribe", topic: `assetPriceUpdate/${priceFeedId}`, requestId: 2 }));
  ws.send(JSON.stringify({ method: "subscribe", topic: `predictWalletEvents/${JWT}`, requestId: 3 }));
});

ws.on("message", (raw) => {
  const msg = JSON.parse(raw.toString());
  // REQUIRED: respond to server heartbeats every 15s or connection drops
  if (msg.type === "M" && msg.topic === "heartbeat") {
    ws.send(JSON.stringify({ method: "heartbeat", timestamp: msg.timestamp }));
    return;
  }
  if (msg.topic?.startsWith("predictOrderbook/")) {
    const { asks, bids } = msg.data;
    console.log("Book update — best ask:", asks[0], "best bid:", bids[0]);
  }
  if (msg.topic?.startsWith("predictWalletEvents/")) {
    // eventType: orderAccepted | orderNotAccepted | orderExpired | orderCancelled
    //            orderTransactionSubmitted | orderTransactionSuccess | orderTransactionFailed
    console.log("Wallet event:", msg.data.eventType, msg.data.orderHash);
  }
});
```

---

## 11. One-Time Approvals

Run once per wallet before first trade (needs ~0.01 BNB gas):

```typescript
const builder = await OrderBuilder.make(ChainId.BnbMainnet, signer);
const result = await builder.setApprovals();
if (!result.success) throw new Error("Approval failed — check BNB balance");
console.log("Approvals set. Only needs to be done once per wallet.");
```

---

## 12. Smart Wallet Mode (Privy / Predict Account)

```typescript
// Export PRIVY_WALLET_PRIVATE_KEY and PREDICT_ACCOUNT_ADDRESS from predict.fun/account/settings
const privyWallet = new Wallet(process.env.PRIVY_WALLET_PRIVATE_KEY!);
const builder = await OrderBuilder.make(ChainId.BnbMainnet, privyWallet, {
  predictAccount: process.env.PREDICT_ACCOUNT_ADDRESS!,
});
// Use builder.signPredictAccountMessage() — not signer.signMessage()
const signature = await builder.signPredictAccountMessage(message);
// Use PREDICT_ACCOUNT_ADDRESS as signer in auth body
```

---

## 13. Contract Addresses — BNB Mainnet

| Contract | Address |
|----------|---------|
| CTFExchange (Yield Bearing) | `0x6bEb5a40C032AFc305961162d8204CDA16DECFa5` |
| NegRiskCtfExchange (Yield Bearing) | `0x8A289d458f5a134bA40015085A8F50Ffb681B41d` |
| YieldBearingConditionalTokens | `0x9400F8Ad57e9e0F352345935d6D3175975eb1d9F` |
| UmaCompatibleCtfAdapter | `0x947cc06D38d3cB0a2BB5AdFB668b99B4FF53d7B4` |
| NegRisk Adapter | `0x41dCe1A4B8FB5e6327701750aF6231B7CD0B2A40` |
| Vault | `0x09F683d8a144c4ac296D770F839098c3377410c5` |
| USDT on BNB Chain | `0x55d398326f99059fF775485246999027B3197955` |

---

## 14. Risk Rules — Always Follow

- **5% rule:** Never risk more than 5% of USDT balance on a single market.
- **Use LIMIT orders** on thin books — MARKET orders suffer slippage.
- **Check depth:** If total ask depth < your order size, split the order.
- **Check `tradingStatus === "active"`** before placing any order.
- **Test on testnet first** (`api-testnet.predict.fun`, no API key needed).
- **Never log private keys.** Always load from environment variables.
- **Cancel stale LIMIT orders** when market moves away from your price.
- **Call `redeemPositions()`** after resolution to claim winnings.

---

## 15. Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Invalid API key` | Wrong or missing `x-api-key` | Check env var; testnet needs no key |
| `401 Unauthorized` | JWT expired or missing | Re-authenticate |
| `Insufficient allowance` | Approvals not set | Run `builder.setApprovals()` |
| `Self trade prevention` | Opposing resting order | Cancel opposing orders first |
| `Order too small` | Below minimum size | Check `market.minOrderSize` |
| `429 Too Many Requests` | >240 req/min | Add backoff; use WebSocket for streaming |
| `Invalid signature` | Wrong signing method | Use `signPredictAccountMessage()` for Smart Wallet |
| `Nonce already used` | Reused nonce | Increment nonce per order |
| `Market not active` | Closed or suspended | Check `market.tradingStatus` |
