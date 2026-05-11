# OKX Skill

Spot trading, perpetuals, market data, wallet operations, and DEX aggregation via the OKX API and OKX DEX API.

## API Base
```
https://www.okx.com/api/v5      # CEX REST API
https://www.okx.com/priapi/v1   # DEX Aggregator (Web3)
```

## Authentication (CEX API)
All private endpoints require HMAC-SHA256 signature.

```typescript
import crypto from "crypto";

const API_KEY    = process.env.OKX_API_KEY!;
const SECRET_KEY = process.env.OKX_SECRET_KEY!;
const PASSPHRASE = process.env.OKX_PASSPHRASE!;

function sign(timestamp: string, method: string, path: string, body = ""): string {
  const msg = timestamp + method.toUpperCase() + path + body;
  return crypto.createHmac("sha256", SECRET_KEY).update(msg).digest("base64");
}

function authHeaders(method: string, path: string, body = "") {
  const timestamp = new Date().toISOString();
  return {
    "OK-ACCESS-KEY":        API_KEY,
    "OK-ACCESS-SIGN":       sign(timestamp, method, path, body),
    "OK-ACCESS-TIMESTAMP":  timestamp,
    "OK-ACCESS-PASSPHRASE": PASSPHRASE,
    "Content-Type":         "application/json",
  };
}

const BASE = "https://www.okx.com";

// Example: GET account balance
const balRes = await fetch(`${BASE}/api/v5/account/balance`, {
  headers: authHeaders("GET", "/api/v5/account/balance"),
}).then(r => r.json());
```

Keys stored at `~/.jelly-claude/.keys`:
```
OKX_API_KEY=...
OKX_SECRET_KEY=...
OKX_PASSPHRASE=...
```

## Market Data (Public — No Auth)

```typescript
// All trading instruments
const instruments = await fetch(`${BASE}/api/v5/public/instruments?instType=SPOT`).then(r => r.json());

// Ticker (price, volume, 24h change)
const ticker = await fetch(`${BASE}/api/v5/market/ticker?instId=BTC-USDT`).then(r => r.json());
const t = ticker.data[0];
console.log(`BTC/USDT: $${t.last} | 24h: ${t.change24h}% | Vol: ${t.vol24h} BTC`);

// Multiple tickers
const tickers = await fetch(`${BASE}/api/v5/market/tickers?instType=SPOT`).then(r => r.json());
const top10 = tickers.data.sort((a, b) => Number(b.volCcy24h) - Number(a.volCcy24h)).slice(0, 10);
top10.forEach(t => console.log(`${t.instId}: $${t.last} | Vol: $${(Number(t.volCcy24h) / 1e6).toFixed(1)}M`));

// Order book
const book = await fetch(`${BASE}/api/v5/market/books?instId=ETH-USDT&sz=10`).then(r => r.json());
const { asks, bids } = book.data[0];
console.log("Best ask:", asks[0], "| Best bid:", bids[0]);

// Candlesticks (OHLCV)
// bar: 1m, 5m, 15m, 1H, 4H, 1D, 1W
const candles = await fetch(`${BASE}/api/v5/market/candles?instId=BTC-USDT&bar=1H&limit=24`).then(r => r.json());
candles.data.forEach(([ts, o, h, l, c, vol]) =>
  console.log(new Date(Number(ts)).toISOString(), `O:${o} H:${h} L:${l} C:${c} V:${vol}`)
);

// Funding rate (perps)
const funding = await fetch(`${BASE}/api/v5/public/funding-rate?instId=BTC-USD-SWAP`).then(r => r.json());
console.log("Funding rate:", funding.data[0].fundingRate, "| Next:", funding.data[0].nextFundingTime);
```

## Account & Portfolio

```typescript
// Portfolio balance (unified account)
const balance = await fetch(`${BASE}/api/v5/account/balance`, {
  headers: authHeaders("GET", "/api/v5/account/balance"),
}).then(r => r.json());
balance.data[0].details.filter(d => Number(d.eq) > 0).forEach(d =>
  console.log(`${d.ccy}: ${d.availBal} (total: ${d.eq})`)
);

// Positions
const positions = await fetch(`${BASE}/api/v5/account/positions`, {
  headers: authHeaders("GET", "/api/v5/account/positions"),
}).then(r => r.json());
positions.data.forEach(p =>
  console.log(`${p.instId} | ${p.posSide} | Size: ${p.pos} | UPnL: ${p.upl} USDT | Liq: ${p.liqPx}`)
);
```

## Spot Trading

```typescript
// Place a spot limit order
const body = JSON.stringify({
  instId:  "ETH-USDT",
  tdMode:  "cash",        // "cash" = spot
  side:    "buy",         // "buy" | "sell"
  ordType: "limit",       // "limit" | "market" | "post_only"
  sz:      "0.1",         // quantity in base currency (0.1 ETH)
  px:      "3200",        // limit price
});
const path = "/api/v5/trade/order";
const order = await fetch(`${BASE}${path}`, {
  method: "POST",
  headers: authHeaders("POST", path, body),
  body,
}).then(r => r.json());
console.log("Order ID:", order.data[0].ordId, "| Status:", order.data[0].sCode);

// Market order (no price)
const mktBody = JSON.stringify({ instId: "ETH-USDT", tdMode: "cash", side: "buy", ordType: "market", sz: "100", tgtCcy: "quote_ccy" });

// Cancel order
const cancelBody = JSON.stringify({ instId: "ETH-USDT", ordId: "ORDER_ID" });
const cancelPath = "/api/v5/trade/cancel-order";
await fetch(`${BASE}${cancelPath}`, { method: "POST", headers: authHeaders("POST", cancelPath, cancelBody), body: cancelBody });
```

## Perpetuals Trading

```typescript
// Open a perpetual futures position
const perpBody = JSON.stringify({
  instId:  "ETH-USDT-SWAP",
  tdMode:  "cross",       // "cross" | "isolated"
  side:    "buy",
  posSide: "long",        // "long" | "short" | "net"
  ordType: "market",
  sz:      "1",           // 1 contract = 0.1 ETH on OKX
});
```

## OKX DEX (on-chain swap)

```typescript
// Best swap quote across on-chain DEXes
const dexQuote = await fetch(
  `${BASE}/api/v5/dex/aggregator/quote?chainId=1&fromTokenAddress=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2&toTokenAddress=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&amount=1000000000000000000&slippage=0.01`,
  { headers: { "OK-ACCESS-KEY": API_KEY } }
).then(r => r.json());
console.log("You receive:", dexQuote.data?.toTokenAmount, "USDC");
```

## Common Use Cases
- "What's the current BTC price on OKX?" → market/ticker
- "Show my OKX portfolio balance" → account/balance
- "Buy 0.1 ETH at $3200 limit on OKX spot" → trade/order limit
- "What's the funding rate for BTC perps?" → public/funding-rate
- "Show me my open positions" → account/positions
- "Cancel order [id]" → trade/cancel-order
- "What are the top 10 highest volume pairs on OKX?" → market/tickers sorted by vol

## Links
- App: https://www.okx.com
- API docs: https://www.okx.com/docs-v5/en/
- API key: https://www.okx.com/account/my-api
