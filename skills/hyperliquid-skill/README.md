# hyperliquid-skill

Trade perpetual futures on Hyperliquid L1 — open/close positions, set leverage, monitor funding rates, and track PnL.

## Install
```bash
bash install.sh       # Mac / Linux
.\install.ps1         # Windows PowerShell
```

## Keys required
Add to `~/.jelly-claude/.keys`:
```
HYPERLIQUID_WALLET_ADDRESS=0x...
HYPERLIQUID_PRIVATE_KEY=...
```

## Used by agents
- `hyperliquid-trader`

## API
https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api
