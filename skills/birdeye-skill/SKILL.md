# Birdeye Skill

Token analytics, trending tokens, holder analysis, wallet P&L, and new listings via the Birdeye API.

## API Base
```
https://public-api.birdeye.so
```

## Authentication
All requests require:
```
X-API-KEY: <your_key>
```

Key stored at `~/.jelly-claude/.keys`:
```
BIRDEYE_API_KEY=your_key_here
```

Get a free key at https://birdeye.so (Starter: 100 req/min, covers most use cases).

## Supported Chains
`solana`, `ethereum`, `arbitrum`, `avalanche`, `bsc`, `optimism`, `polygon`, `base`, `zksync`, `sui`

Pass as `chain` query param or `x-chain` header.

## Key Endpoints

### Token Overview
```
GET /defi/token_overview?address={token_address}
Headers: X-API-KEY, x-chain: solana
```
Returns: price, volume_24h, liquidity, market_cap, holder_count, price_change_24h, trade_24h

### Price History
```
GET /defi/history_price?address={token_address}&address_type=token&type={interval}&time_from={unix}&time_to={unix}
```
Intervals: `1m`, `3m`, `5m`, `15m`, `30m`, `1H`, `2H`, `4H`, `6H`, `8H`, `12H`, `1D`, `3D`, `1W`, `1M`

### Top Holders
```
GET /defi/v3/token/holder?address={token_address}&offset=0&limit=20
Headers: X-API-KEY, x-chain: solana
```

### Top Traders
```
GET /defi/v2/tokens/{token_address}/top_traders?time_frame=24h&sort_by=volume&sort_type=desc&offset=0&limit=10
Headers: X-API-KEY, x-chain: solana
```
time_frame options: `30m`, `1h`, `2h`, `4h`, `8h`, `24h`

### Trending Tokens
```
GET /defi/token_trending?sort_by=rank&sort_type=asc&offset=0&limit=20
Headers: X-API-KEY, x-chain: solana
```

### New Listings
```
GET /defi/v2/tokens/new_listing?time_to={unix}&limit=20&meme_platform_enabled=true
Headers: X-API-KEY, x-chain: solana
```

### Wallet P&L
```
GET /v1/wallet/token_list?wallet={wallet_address}
Headers: X-API-KEY, x-chain: solana
```

### Token Security Check
```
GET /defi/token_security?address={token_address}
Headers: X-API-KEY, x-chain: solana
```
Returns: is_token_meta_ok, top_10_holder_percent, creator_percentage, mutable_metadata, freeze_authority, mint_authority

## Usage Example
```javascript
const BIRDEYE_KEY = process.env.BIRDEYE_API_KEY;
const BASE_URL = "https://public-api.birdeye.so";

async function getTokenOverview(address, chain = "solana") {
  const res = await fetch(`${BASE_URL}/defi/token_overview?address=${address}`, {
    headers: {
      "X-API-KEY": BIRDEYE_KEY,
      "x-chain": chain
    }
  });
  const data = await res.json();
  return data.data;
}

async function getTrendingTokens(chain = "solana", limit = 20) {
  const res = await fetch(`${BASE_URL}/defi/token_trending?sort_by=rank&sort_type=asc&limit=${limit}`, {
    headers: {
      "X-API-KEY": BIRDEYE_KEY,
      "x-chain": chain
    }
  });
  const data = await res.json();
  return data.data?.tokens ?? [];
}

async function getWalletPnl(wallet, chain = "solana") {
  const res = await fetch(`${BASE_URL}/v1/wallet/token_list?wallet=${wallet}`, {
    headers: {
      "X-API-KEY": BIRDEYE_KEY,
      "x-chain": chain
    }
  });
  const data = await res.json();
  return data.data;
}
```

## Rate Limits
| Tier | Requests/min |
|------|-------------|
| Free / Starter | 100 |
| Growth | 500 |
| Business | 1000+ |

## Docs
https://docs.birdeye.so/reference/get_defi-token-overview
