# CoinGecko Skill

Token prices, market data, trending coins, and historical OHLCV via the CoinGecko API.

## API Base
```
https://api.coingecko.com/api/v3          # Free (rate-limited)
https://pro-api.coingecko.com/api/v3      # Pro (API key required)
```

## Authentication
```typescript
const headers = process.env.COINGECKO_API_KEY
  ? { "x-cg-pro-api-key": process.env.COINGECKO_API_KEY }
  : {};
```

Free tier: 30 calls/min. Pro: 500 calls/min.

Keys stored at `~/.jelly-claude/.keys`:
```
COINGECKO_API_KEY=CG-...   # optional — free endpoints work without it
```

## Key Endpoints

### Token price (simple)
```typescript
const BASE = "https://api.coingecko.com/api/v3";

// Price + market cap + 24h change for multiple tokens
const res = await fetch(
  `${BASE}/simple/price?ids=bitcoin,ethereum,binancecoin&vs_currencies=usd&include_market_cap=true&include_24hr_change=true`,
  { headers }
);
const prices = await res.json();
// { bitcoin: { usd: 65000, usd_market_cap: 1.28e12, usd_24h_change: -1.4 }, ... }

// Price by contract address (any EVM chain)
const contractRes = await fetch(
  `${BASE}/simple/token_price/ethereum?contract_addresses=0xdac17f958d2ee523a2206206994597c13d831ec7&vs_currencies=usd`,
  { headers }
);
```

### Search and coin list
```typescript
// Search by name or symbol
const search = await fetch(`${BASE}/search?query=pepe`, { headers }).then(r => r.json());
search.coins.slice(0, 5).forEach(c => console.log(c.id, c.symbol, c.market_cap_rank));

// Full coin list (id → name mapping)
const coinList = await fetch(`${BASE}/coins/list`, { headers }).then(r => r.json());
```

### Market overview
```typescript
// Top N coins by market cap
const markets = await fetch(
  `${BASE}/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false`,
  { headers }
).then(r => r.json());
markets.forEach(c => console.log(c.id, c.current_price, c.market_cap_rank, c.price_change_percentage_24h));
```

### Coin detail
```typescript
// Full data for one coin
const coin = await fetch(
  `${BASE}/coins/bitcoin?localization=false&tickers=false&market_data=true&community_data=false`,
  { headers }
).then(r => r.json());
console.log(coin.market_data.current_price.usd);
console.log(coin.market_data.ath.usd, coin.market_data.ath_date.usd);
```

### OHLCV history
```typescript
// Daily OHLCV (up to 90 days auto-granularity)
const ohlcv = await fetch(
  `${BASE}/coins/bitcoin/ohlc?vs_currency=usd&days=30`,
  { headers }
).then(r => r.json());
// [[timestamp, open, high, low, close], ...]

// Market chart (price + volume + market cap)
const chart = await fetch(
  `${BASE}/coins/ethereum/market_chart?vs_currency=usd&days=7`,
  { headers }
).then(r => r.json());
// { prices: [[ts, price], ...], market_caps: [...], total_volumes: [...] }
```

### Trending
```typescript
// Top 7 trending searches in last 24h
const trending = await fetch(`${BASE}/search/trending`, { headers }).then(r => r.json());
trending.coins.forEach(({ item: c }) => console.log(c.name, c.symbol, c.market_cap_rank));
```

### Global market
```typescript
const global = await fetch(`${BASE}/global`, { headers }).then(r => r.json());
console.log("Total market cap:", global.data.total_market_cap.usd);
console.log("BTC dominance:", global.data.market_cap_percentage.btc.toFixed(1), "%");
console.log("24h volume:", global.data.total_volume.usd);
```

### Exchange rates and DEX
```typescript
// Exchange tickers for a coin (where it's listed)
const tickers = await fetch(`${BASE}/coins/bitcoin/tickers?page=1`, { headers }).then(r => r.json());

// Token price from DEX (via on-chain)
const dex = await fetch(
  `${BASE}/onchain/simple/networks/eth/token_price/0xdac17f958d2ee523a2206206994597c13d831ec7`,
  { headers }
).then(r => r.json());
```

## Common Use Cases
- "What's the current price of [token]?" → `/simple/price`
- "Show me the top 20 coins by market cap" → `/coins/markets`
- "What's trending in crypto right now?" → `/search/trending`
- "Show me Bitcoin's price chart for the last 30 days" → `/coins/bitcoin/ohlc`
- "What is the total crypto market cap?" → `/global`
- "Find the CoinGecko ID for [token name]" → `/search`

## Links
- Docs: https://docs.coingecko.com
- API key: https://www.coingecko.com/en/api/pricing
