# polymarket-skill

Polymarket CLOB API — browse prediction markets, place/cancel orders, manage positions on Polygon.

## Install
```bash
bash install.sh
```

## Setup required
1. Get API keys at [app.polymarket.com](https://app.polymarket.com) → Settings → API
2. Get USDC on Polygon (bridge or CEX withdrawal)
3. Add keys to `~/.claude/skills/polymarket-skill/.keys`

## Example prompts
- "Show me the top 10 most active Polymarket markets right now"
- "What is the current price on the 'Will X happen by Y date' market?"
- "Buy $20 of YES on the [market question]"
- "Show me my open Polymarket positions and P&L"
- "Cancel all my open Polymarket orders"
