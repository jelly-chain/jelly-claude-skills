# Jelly Skill

Live DeFi data from jellychain.fun — chain TVL, DEX trading volume, protocol leaderboards, and trending movers. No API key required.

## API Base
```
https://jellychain.fun/api
```

## Authentication
None — all endpoints are fully public.

## Endpoints

### Chain List with TVL
```
GET /chains
```
Full URL: `https://jellychain.fun/api/chains`

Returns all tracked chains with TVL, 24h change, protocol count, and chain metadata.

**Response shape:**
```json
[
  {
    "name": "Ethereum",
    "tvl": 54320000000,
    "change_1d": -0.8,
    "change_7d": 2.1,
    "protocols": 892,
    "mcap": null,
    "gecko_id": "ethereum"
  }
]
```

### 24h DEX Volume per Chain
```
GET /chains/dex-volume
```
Full URL: `https://jellychain.fun/api/chains/dex-volume`

Returns a map of chain name (lowercase) to 24h DEX trading volume in USD.

**Response shape:**
```json
{
  "ethereum": 698276018,
  "solana": 1014794681,
  "bsc": 626710775,
  "base": 312445000,
  "arbitrum": 289000000
}
```

### Protocol List
```
GET /protocols?limit=50&chain=Ethereum
```
Full URL: `https://jellychain.fun/api/protocols`

Returns DeFi protocols with TVL, fees, revenue, category, and chain info.

**Query params:**
- `limit` — max results (default 50)
- `chain` — filter by chain name (e.g. `Ethereum`, `Solana`, `BSC`)

**Response shape (array):**
```json
[
  {
    "id": "1234",
    "name": "Aave V3",
    "slug": "aave-v3",
    "logo": "https://...",
    "chain": "Multi-Chain",
    "chains": ["Ethereum", "Polygon", "Arbitrum"],
    "category": "Lending",
    "tvl": 24960000000,
    "change_1d": -0.61,
    "change_7d": 6.04,
    "mcap": null,
    "fees_24h": 1525719,
    "revenue_24h": null
  }
]
```

### Fundamentals Leaderboard
```
GET /fundamentals?metric=tvl&timeframe=1d&limit=10
```
Full URL: `https://jellychain.fun/api/fundamentals`

Returns top protocols sorted by the chosen metric.

**Query params:**
- `metric` — `tvl` | `fees` | `revenue` | `marketCap`
- `timeframe` — `1d` | `7d` | `30d` (only applies for fees/revenue)
- `limit` — number of results (default 10)

### Protocol DEX Volume (by slug)
```
GET /protocols/dex-volume
```
Full URL: `https://jellychain.fun/api/protocols/dex-volume`

Returns a map of protocol slug to 24h DEX trading volume. Covers 842 DEX protocols.

**Response shape:**
```json
{
  "uniswap-v3": 304405998,
  "curve-dex": 64446444,
  "pancakeswap-amm": 42385392
}
```

## Usage Examples

```javascript
const BASE = "https://jellychain.fun/api";

// Get chain TVL rankings
async function getChains() {
  const res = await fetch(`${BASE}/chains`);
  return res.json();
}

// Get 24h DEX volume per chain
async function getDexVolume() {
  const res = await fetch(`${BASE}/chains/dex-volume`);
  return res.json(); // { ethereum: 698276018, solana: 1014794681, ... }
}

// Get top protocols by TVL
async function getTopProtocols(limit = 10) {
  const res = await fetch(`${BASE}/protocols?limit=${limit}`);
  return res.json();
}

// Get fundamentals leaderboard
async function getLeaderboard(metric = "tvl", limit = 10) {
  const res = await fetch(`${BASE}/fundamentals?metric=${metric}&limit=${limit}`);
  return res.json();
}

// Get DEX volume per protocol slug
async function getProtocolDexVolumes() {
  const res = await fetch(`${BASE}/protocols/dex-volume`);
  return res.json(); // { "uniswap-v3": 304405998, ... }
}

// Find chains gaining TVL fastest
async function getTrendingChains() {
  const chains = await getChains();
  return chains
    .filter(c => c.change_1d != null)
    .sort((a, b) => b.change_1d - a.change_1d)
    .slice(0, 5);
}
```

## Use Cases for Prediction Markets
- Compare Ethereum vs Solana DEX volume to find markets on chain dominance
- Track TVL changes week-over-week to form thesis on lending/staking markets
- Use protocol fee data to find markets on DeFi protocol revenue
- Identify chains gaining TVL for "will X flip Y" type markets

## Docs / Site
https://jellychain.fun
