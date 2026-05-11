# DeFiLlama Skill

Protocol TVL, chain analytics, yields, stablecoins, DEX volumes, and bridge flows via the free DeFiLlama API.

## API Base
```
https://api.llama.fi        # TVL and protocol data
https://yields.llama.fi     # Yield pools (DeFi earn)
https://stablecoins.llama.fi # Stablecoin data
https://bridges.llama.fi    # Bridge volume
https://coins.llama.fi      # Token prices (cross-chain)
https://fe-cache.llama.fi   # Fee and revenue data
```

No API key required. All endpoints are free and public.

## Protocol TVL

```typescript
const BASE = "https://api.llama.fi";

// All protocols with TVL (5000+ protocols)
const all = await fetch(`${BASE}/protocols`).then(r => r.json());
const top10 = all.sort((a, b) => b.tvl - a.tvl).slice(0, 10);
top10.forEach(p => console.log(`${p.name}: $${(p.tvl / 1e9).toFixed(2)}B | ${p.category} | ${p.chain}`));

// Single protocol TVL history
const aave = await fetch(`${BASE}/protocol/aave`).then(r => r.json());
console.log("Aave TVL:", aave.currentChainTvls);
// Historical: aave.tvl = [{ date, totalLiquidityUSD }, ...]

// TVL change in 24h
console.log("24h change:", aave.change_1d, "%");
console.log("7d change:", aave.change_7d, "%");
```

## Chain TVL

```typescript
// All chains ranked by TVL
const chains = await fetch(`${BASE}/chains`).then(r => r.json());
chains.sort((a, b) => b.tvl - a.tvl).slice(0, 15).forEach(c =>
  console.log(`${c.name}: $${(c.tvl / 1e9).toFixed(2)}B`)
);

// Historical TVL for a chain
const ethTvl = await fetch(`${BASE}/v2/historicalChainTvl/Ethereum`).then(r => r.json());
ethTvl.slice(-7).forEach(d =>
  console.log(new Date(d.date * 1000).toLocaleDateString(), `$${(d.tvl / 1e9).toFixed(2)}B`)
);
```

## DeFi Yields

```typescript
const YIELDS = "https://yields.llama.fi";

// All yield pools across DeFi
const pools = await fetch(`${YIELDS}/pools`).then(r => r.json());
const top = pools.data
  .filter(p => p.tvlUsd > 1_000_000 && p.apy > 0)
  .sort((a, b) => b.apy - a.apy)
  .slice(0, 20);

top.forEach(p => {
  console.log(`${p.project} | ${p.symbol} | APY: ${p.apy.toFixed(2)}% | TVL: $${(p.tvlUsd / 1e6).toFixed(1)}M | ${p.chain}`);
});

// Filter by chain and token
const ethPools = pools.data.filter(p =>
  p.chain === "Ethereum" && p.symbol.includes("USDC") && p.apy > 3
);

// Historical APY for a specific pool
const poolHistory = await fetch(`${YIELDS}/chart/${poolId}`).then(r => r.json());
poolHistory.data.slice(-30).forEach(d =>
  console.log(d.timestamp, `APY: ${d.apy.toFixed(2)}%`, `TVL: $${(d.tvlUsd / 1e6).toFixed(1)}M`)
);
```

## Token Prices (Cross-Chain)

```typescript
const COINS = "https://coins.llama.fi";

// Price by contract address (prefix with chain)
const priceRes = await fetch(
  `${COINS}/prices/current/ethereum:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,bsc:0x55d398326f99059fF775485246999027B3197955`
).then(r => r.json());
// coins["ethereum:0x..."]: { price, symbol, timestamp, decimals }

// Historical price
const histPrice = await fetch(
  `${COINS}/prices/historical/1710000000/ethereum:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
).then(r => r.json());

// Price chart (OHLC-like)
const chart = await fetch(
  `${COINS}/chart/ethereum:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2?start=${startTs}&span=200&period=1d&searchWidth=600`
).then(r => r.json());
chart.coins["ethereum:0x..."].prices.forEach(([ts, price]) =>
  console.log(new Date(ts * 1000).toLocaleDateString(), `$${price.toFixed(2)}`)
);
```

## Stablecoins

```typescript
const STABLE = "https://stablecoins.llama.fi";

// All stablecoins
const stables = await fetch(`${STABLE}/stablecoins?includePrices=true`).then(r => r.json());
stables.peggedAssets.sort((a, b) => b.circulating.peggedUSD - a.circulating.peggedUSD)
  .slice(0, 10)
  .forEach(s => console.log(`${s.symbol}: $${(s.circulating.peggedUSD / 1e9).toFixed(2)}B | peg: ${s.pegType}`));

// Stablecoin circulating supply history
const usdtHistory = await fetch(`${STABLE}/stablecoin/${stablecoinId}`).then(r => r.json());
```

## DEX Volume

```typescript
// Daily volume across all DEXes
const dexVol = await fetch(`${BASE}/overview/dexs?excludeTotalDataChart=false`).then(r => r.json());
console.log("24h DEX volume:", dexVol.total24h);
dexVol.protocols.sort((a, b) => b.total24h - a.total24h).slice(0, 10)
  .forEach(p => console.log(`${p.name}: $${(p.total24h / 1e6).toFixed(1)}M/day`));

// Volume for a specific DEX
const uniVol = await fetch(`${BASE}/summary/dexs/uniswap`).then(r => r.json());
console.log("Uniswap 24h:", uniVol.total24h);
```

## Protocol Revenue and Fees

```typescript
// Protocol fees and revenue
const fees = await fetch(`${BASE}/overview/fees`).then(r => r.json());
fees.protocols.sort((a, b) => b.total24h - a.total24h).slice(0, 10)
  .forEach(p => console.log(`${p.name}: $${(p.total24h / 1e3).toFixed(0)}K fees/day`));
```

## Bridge Flows

```typescript
const BRIDGES = "https://bridges.llama.fi";

// All bridges with 24h volume
const bridgeList = await fetch(`${BRIDGES}/bridges?includeChains=true`).then(r => r.json());
bridgeList.bridges.sort((a, b) => b.lastDailyVolume - a.lastDailyVolume).slice(0, 10)
  .forEach(b => console.log(`${b.displayName}: $${(b.lastDailyVolume / 1e6).toFixed(1)}M/day`));
```

## Common Use Cases
- "What's the TVL of Aave?" → `/protocol/aave`
- "Which chains have the most TVL?" → `/chains`
- "Find the best yield for USDC" → yields pool filter
- "What's the current price of USDT on BNB Chain?" → coins API
- "What's the 24h DEX trading volume?" → overview/dexs
- "Which stablecoins are losing their peg?" → stablecoins API
- "Show me ETH price history for the last 30 days" → coins chart

## Links
- App: https://defillama.com
- API docs: https://defillama.com/docs/api
- Yields: https://defillama.com/yields
