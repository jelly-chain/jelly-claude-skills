# Binance Skills Hub

AI agent skill for Binance market data, spot trading, token security audits, and on-chain analysis.

## Source (official)
```bash
npx skills add binance/binance-skills-hub
```

## Setup: Part 1 — Public data (no API key needed)
The Binance public API requires no authentication for market data queries.

## Setup: Part 2 — Trading (API key required)
1. Log in to [binance.com](https://binance.com)
2. Go to Profile → API Management → Create API
3. **Security**: Enable IP restrictions before enabling trading
4. Never enable withdrawals for agent API keys
5. Store keys in `~/.claude/skills/binance-skills-hub/.keys`

## Example prompts — public data
- "Find the top 3 USDT pairs with highest 24h gains on Binance"
- "Show today's top trending tokens"
- "Run a token security audit for [contract] on BSC"
- "Fetch BTC real-time market data and K-line summary"

## Example prompts — authenticated
- "Check my Binance spot wallet balance"
- "Buy 0.1 BNB at market price"
- "Show my order history for the last 24 hours"
- "Place an OCO order for BNB with 20% take-profit and 20% stop-loss"

## Security reminder
- API keys are stored locally only — never in any repo
- Mask keys: show only first 5 and last 4 characters when displaying
- Always require "CONFIRM" before executing any mainnet trade
- Use a sub-account with limited funds for agent trading
