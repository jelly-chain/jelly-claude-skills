# coingecko-skill

Token prices, market data, trending coins, OHLCV history, and global market stats via the free CoinGecko API.

## Install
```bash
bash install.sh       # Mac / Linux
.\install.ps1         # Windows PowerShell
```

## Keys required (optional — free tier works without key)
Add to `~/.jelly-claude/.keys`:
```
COINGECKO_API_KEY=CG-...   # optional — unlocks 500 req/min (vs 30 free)
```
Get key: https://www.coingecko.com/en/api/pricing

## Used by agents
- `birdeye-analyst`, `defi-yield-optimizer`, `token-launch-monitor`

## Docs
https://docs.coingecko.com
