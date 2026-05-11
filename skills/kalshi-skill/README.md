# kalshi-skill

Kalshi REST API — regulated US binary prediction markets, yes/no contracts, portfolio and P&L management.

## Install
```bash
bash install.sh
```

## Setup required
1. Create account at [kalshi.com](https://kalshi.com) (US-eligible only)
2. Deposit USD in the app
3. Get API key at Account → API Access
4. Add keys to `~/.claude/skills/kalshi-skill/.keys`

**Start with Demo mode** — set `KALSHI_BASE_URL=https://demo-api.kalshi.co/trade-api/v2`

## Example prompts
- "Show me the top Kalshi markets by volume today"
- "What are the current odds on the 2026 election markets?"
- "Buy 10 YES contracts on [ticker] at 65 cents"
- "Show me my Kalshi portfolio balance and open positions"
- "Cancel all my resting Kalshi orders"
