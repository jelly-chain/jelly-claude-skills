# DexScreener Skill

Discover new token pairs, monitor prices, and surface trending tokens across all chains via the DexScreener public API. No API key required.

## API Base
```
https://api.dexscreener.com
```

## Authentication
None — fully public API. No key required.

## Rate Limits
300 requests/minute (unauthenticated). Add `User-Agent: jelly-claude/1.0` header as courtesy.

## Key Endpoints

### Search Pairs by Token/Name/Address
```
GET /latest/dex/search?q={query}
```
Returns up to 30 matching pairs. Query can be token name, symbol, or contract address.

### Get Pairs by Token Address
```
GET /latest/dex/tokens/{tokenAddress}
```
Returns all trading pairs for a given token across all DEXs and chains.

### Get Specific Pair by Address
```
GET /latest/dex/pairs/{chainId}/{pairAddress}
```
Chain IDs: `solana`, `bsc`, `ethereum`, `base`, `arbitrum`, `polygon`, `avalanche`, `optimism`

### New Pairs (latest listings)
```
GET /token-profiles/latest/v1
```
Returns recently added token profiles. Combine with pair data for full picture.

### Boosted Tokens
```
GET /token-boosts/active/v1
```
Returns currently promoted/boosted tokens.

### Token Orders (paid promotions check)
```
GET /orders/v1/{chainId}/{tokenAddress}
```

## Pair Object Fields
Key fields in every pair response:
```json
{
  "chainId": "solana",
  "dexId": "raydium",
  "pairAddress": "...",
  "baseToken": { "address": "...", "name": "...", "symbol": "..." },
  "quoteToken": { "address": "...", "name": "...", "symbol": "..." },
  "priceNative": "0.00001234",
  "priceUsd": "0.00182",
  "txns": {
    "m5":  { "buys": 12, "sells": 8 },
    "h1":  { "buys": 89, "sells": 54 },
    "h6":  { "buys": 340, "sells": 210 },
    "h24": { "buys": 1200, "sells": 890 }
  },
  "volume": { "h24": 52000, "h6": 18000, "h1": 4200, "m5": 310 },
  "priceChange": { "m5": 1.2, "h1": -3.4, "h6": 12.1, "h24": 45.2 },
  "liquidity": { "usd": 87000, "base": 45000000, "quote": 43500 },
  "fdv": 1820000,
  "marketCap": 1100000,
  "pairCreatedAt": 1713000000000,
  "info": {
    "imageUrl": "...",
    "websites": [{ "url": "..." }],
    "socials": [{ "type": "twitter", "url": "..." }]
  }
}
```

## Usage Examples

```javascript
const BASE = "https://api.dexscreener.com";
const HEADERS = { "User-Agent": "jelly-claude/1.0" };

// Search for a token
async function searchToken(query) {
  const res = await fetch(`${BASE}/latest/dex/search?q=${encodeURIComponent(query)}`, { headers: HEADERS });
  const data = await res.json();
  return data.pairs ?? [];
}

// Get all pairs for a token address
async function getTokenPairs(address) {
  const res = await fetch(`${BASE}/latest/dex/tokens/${address}`, { headers: HEADERS });
  const data = await res.json();
  return data.pairs ?? [];
}

// Get specific pair
async function getPair(chain, pairAddress) {
  const res = await fetch(`${BASE}/latest/dex/pairs/${chain}/${pairAddress}`, { headers: HEADERS });
  const data = await res.json();
  return data.pairs?.[0] ?? null;
}

// Filter new/trending pairs with minimum liquidity
function filterPairs(pairs, { minLiquidityUsd = 20000, minMakers = 10, maxAgeMs = 3600000 } = {}) {
  const now = Date.now();
  return pairs.filter(p =>
    (p.liquidity?.usd ?? 0) >= minLiquidityUsd &&
    (p.txns?.h1?.buys ?? 0) + (p.txns?.h1?.sells ?? 0) >= minMakers &&
    (!p.pairCreatedAt || (now - p.pairCreatedAt) <= maxAgeMs)
  );
}
```

## Supported Chain IDs
`ethereum`, `bsc`, `polygon`, `avalanche`, `arbitrum`, `optimism`, `base`, `solana`, `fantom`, `cronos`, `dogechain`, `celo`, `moonbeam`, `osmosis`, `sui`, `ton`, `aptos`

## Docs
https://docs.dexscreener.com/api/reference
