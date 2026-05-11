# Prediction Skill — Jelly Score & Market Prediction Patterns

## Overview
This skill gives the agent heuristics for market prediction, trend confirmation, and the "Jelly Score" pattern used across Jelly-Chain tooling.

## Jelly Score
The Jelly Score is a 0–100 composite conviction signal:

| Score | Label | Meaning |
|-------|-------|---------|
| 80–100 | Strong Bull | Multiple confirming signals, high conviction long |
| 60–79 | Bull | More bullish signals than bearish, moderate conviction |
| 40–59 | Neutral | Mixed signals, no clear edge |
| 20–39 | Bear | More bearish signals, moderate conviction short |
| 0–19 | Strong Bear | Multiple confirming signals, high conviction short |

### Inputs to the score (weight each equally unless you have better data)
1. **Price trend** — 24h and 7d price direction relative to market
2. **Volume trend** — Rising volume on up moves = bullish; rising volume on down moves = bearish
3. **Holder concentration** — Top 10 holders > 50% = risk flag (−10 to score)
4. **Smart money flow** — Net buys/sells by wallets with strong historical returns
5. **Social momentum** — Twitter/X volume, Telegram activity (qualitative)
6. **On-chain activity** — Transaction count, new wallet growth

### Calculation
```
score = (price_trend * 20) + (volume_trend * 20) + (holder_score * 15)
      + (smart_money * 25) + (social_score * 10) + (onchain_score * 10)
```
All inputs normalized to 0–1 before weighting.

## Trend Confirmation Patterns

### Bull confirmation (all three needed for high conviction)
- Price above 50-period MA
- Volume on up candles > volume on down candles (last 14 periods)
- At least two of: RSI > 50, MACD crossover positive, new highs on above-average volume

### Bear confirmation
- Price below 50-period MA
- Volume on down candles > volume on up candles
- At least two of: RSI < 50, MACD crossover negative, lower highs forming

### Reversal signals (use for entry timing)
- Bullish: hammer or engulfing candle at support + volume spike
- Bearish: shooting star or evening star at resistance + volume spike

## Market Context Rules
- In a macro bear market: reduce all bull scores by 15 points
- In a macro bull market: reduce all bear scores by 10 points
- For meme/launchpad tokens: ignore slow MA signals, focus on volume and holder data only

## Risk Management Templates

### Position sizing (Kelly-inspired, conservative)
```
size = (edge * bankroll) / odds
edge = (win_rate * avg_win) - ((1 - win_rate) * avg_loss)
```
Default: never allocate more than 5% of portfolio to a single prediction.

### Stop-loss defaults
- High volatility (meme tokens): 20–30%
- Mid volatility (DeFi blue chips): 10–15%
- Low volatility (stables, BTC/ETH correlated): 5–8%

## Example Agent Prompts
- "Calculate the Jelly Score for SOL right now using on-chain data and price action"
- "Confirm whether BONK is in a bull trend using the trend confirmation pattern"
- "What is the current risk-adjusted position size I should take on this trade?"
