# Kalshi Skill — Regulated US Prediction Markets

## Overview
Kalshi is a CFTC-regulated prediction market exchange. Markets are binary (YES/NO) contracts denominated in USD cents. No cryptocurrency or wallet needed — it's a fully off-chain, fiat-based platform.

## What you need
1. **Kalshi account** — sign up at [kalshi.com](https://kalshi.com) (US-eligible users only)
2. **USD balance** — deposit via bank transfer or debit card inside the app
3. **API key + secret** — from [kalshi.com](https://kalshi.com) → Account → API Access

## API base URLs
| Environment | URL |
|-------------|-----|
| Production | `https://trading-api.kalshi.com/trade-api/v2` |
| Demo (paper trading) | `https://demo-api.kalshi.co/trade-api/v2` |

**Always start with Demo to test your strategy.**

## Authentication
```typescript
import axios from 'axios';
import crypto from 'crypto';

function kalshiSign(method: string, path: string, body: string, timestamp: string): string {
  const message = timestamp + method.toUpperCase() + '/trade-api/v2' + path + (body || '');
  return crypto.createHmac('sha256', process.env.KALSHI_API_SECRET!)
               .update(message)
               .digest('base64');
}

const timestamp = Date.now().toString();
const signature = kalshiSign('GET', '/markets', '', timestamp);

const response = await axios.get(`${process.env.KALSHI_BASE_URL}/markets`, {
  headers: {
    'KALSHI-ACCESS-KEY':       process.env.KALSHI_API_KEY!,
    'KALSHI-ACCESS-TIMESTAMP': timestamp,
    'KALSHI-ACCESS-SIGNATURE': signature,
  }
});
```

## Browse markets

```typescript
// List active markets
const { markets } = await kalshiGet('/markets', { status: 'open', limit: 100 });

// Get a specific market
const { market } = await kalshiGet(`/markets/${ticker}`);
console.log(market.title, 'YES:', market.yes_ask, 'NO:', market.no_ask);
```

## Get orderbook

```typescript
const { orderbook } = await kalshiGet(`/markets/${ticker}/orderbook`);
console.log('YES bids:', orderbook.yes.map(([price, size]) => `${price}¢ x ${size}`));
```

## Place an order

```typescript
// Buy YES
const order = {
  action:       'buy',
  type:         'limit',    // or 'market'
  ticker:       'KXBTC-25DEC31-T100000',
  side:         'yes',
  count:        10,         // number of contracts ($10 max payout at $1/contract)
  yes_price:    65,         // price in cents (1–99)
  time_in_force: 'gtc',    // good-till-cancelled
};

const result = await kalshiPost('/portfolio/orders', order);
console.log('Order ID:', result.order.order_id);
```

## Check portfolio & positions

```typescript
// Account balance
const { balance } = await kalshiGet('/portfolio/balance');
console.log('Available:', balance.available_balance / 100, 'USD');

// Open positions
const { positions } = await kalshiGet('/portfolio/positions');
positions.forEach(p => {
  console.log(p.ticker, 'YES:', p.position, 'value:', p.market_value / 100, 'USD');
});

// Order history
const { orders } = await kalshiGet('/portfolio/orders', { status: 'resting' });
```

## Cancel an order

```typescript
await kalshiDelete(`/portfolio/orders/${orderId}`);
```

## Market structure
- Each market has a **ticker** like `KXBTC-25DEC31-T100000`
- Contracts pay **$1** if YES, **$0** if NO at resolution
- Prices are in **cents** (1–99); YES price + NO price ≈ 100¢ (spread in between)
- Example: YES at 65¢ means market implies 65% probability of YES
- Minimum order: 1 contract ($1 max payout)

## Pricing intuition
- Buy YES at 65¢: risk 65¢ to win 35¢ if market resolves YES
- Buy NO at 35¢: risk 35¢ to win 65¢ if market resolves NO
- Your breakeven: you need to be right more often than your price implies

## Risk guidelines
- Kalshi is real-money, CFTC-regulated — treat it like any financial account
- Use the Demo environment (paper trading) before going live
- Never risk more than you can afford to lose
- Check the resolution source and exact criteria — wording matters a lot
- Watch for liquidity: thin books = wide spreads = poor fills
