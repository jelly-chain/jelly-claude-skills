# 1inch Skill

Best-rate DEX aggregation across 300+ sources on Ethereum, BNB Chain, Polygon, Arbitrum, Base, Avalanche, and more.

## API Base
```
https://api.1inch.dev/swap/v6.0/{chainId}     # Swap API
https://api.1inch.dev/price/v1.1/{chainId}    # Token prices
https://api.1inch.dev/balance/v1.2/{chainId}  # Balances
https://api.1inch.dev/token/v1.2/{chainId}    # Token info
```

## Chain IDs
| Chain | ID |
|-------|----|
| Ethereum | 1 |
| BNB Chain | 56 |
| Polygon | 137 |
| Arbitrum | 42161 |
| Base | 8453 |
| Avalanche | 43114 |
| Optimism | 10 |

## Authentication
```typescript
const headers = {
  "Authorization": `Bearer ${process.env.ONEINCH_API_KEY}`,
  "accept": "application/json",
};
```
Get API key: https://portal.1inch.dev

Keys stored at `~/.jelly-claude/.keys`:
```
ONEINCH_API_KEY=...
```

## Get Best Swap Quote

```typescript
const chainId = 1; // Ethereum
const WETH   = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC   = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const amount = "1000000000000000000"; // 1 ETH in wei

const quoteRes = await fetch(
  `https://api.1inch.dev/swap/v6.0/${chainId}/quote?` +
  `src=${WETH}&dst=${USDC}&amount=${amount}`,
  { headers }
).then(r => r.json());

console.log("You get:", quoteRes.dstAmount / 1e6, "USDC");
console.log("Estimated gas:", quoteRes.gas);
console.log("Route protocols:", quoteRes.protocols.map(p => p[0][0].name).join(" → "));
```

## Build Swap Transaction

```typescript
const swapParams = new URLSearchParams({
  src:              WETH,
  dst:              USDC,
  amount:           amount,
  from:             "0xYOUR_WALLET_ADDRESS",
  slippage:         "0.5",      // 0.5%
  disableEstimate:  "false",
  allowPartialFill: "false",
});

const swapRes = await fetch(
  `https://api.1inch.dev/swap/v6.0/${chainId}/swap?${swapParams}`,
  { headers }
).then(r => r.json());

// swapRes.tx contains the ready-to-broadcast transaction
const { to, data, value, gas } = swapRes.tx;

// Execute with ethers
import { ethers } from "ethers";
const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);
const tx = await wallet.sendTransaction({ to, data, value: BigInt(value), gasLimit: BigInt(gas) });
await tx.wait();
console.log("Swap complete:", tx.hash);
```

## Check Token Approval

```typescript
// Check if router is already approved (saves gas if already approved)
const approveRes = await fetch(
  `https://api.1inch.dev/swap/v6.0/${chainId}/approve/allowance?` +
  `tokenAddress=${USDC}&walletAddress=0x...`,
  { headers }
).then(r => r.json());

if (BigInt(approveRes.allowance) < BigInt(amount)) {
  // Build approval transaction
  const approvalTx = await fetch(
    `https://api.1inch.dev/swap/v6.0/${chainId}/approve/transaction?tokenAddress=${USDC}`,
    { headers }
  ).then(r => r.json());
  await wallet.sendTransaction(approvalTx);
}
```

## Token Prices

```typescript
// Price of multiple tokens in USD
const priceRes = await fetch(
  `https://api.1inch.dev/price/v1.1/${chainId}`,
  {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ tokens: [WETH, USDC, "0xdAC17F958D2ee523a2206206994597C13D831ec7"] }),
  }
).then(r => r.json());
// { "0x...": "65000.00", ... }
```

## Token Balances

```typescript
// All non-zero token balances for a wallet
const balRes = await fetch(
  `https://api.1inch.dev/balance/v1.2/${chainId}/balances/0xYOUR_WALLET`,
  { headers }
).then(r => r.json());
// { "0x...": "1000000000", ... } — raw amounts, divide by decimals
```

## Token Info & Search

```typescript
// Search tokens by name or symbol
const tokenSearch = await fetch(
  `https://api.1inch.dev/token/v1.2/${chainId}/search?query=USDC&limit=5`,
  { headers }
).then(r => r.json());
tokenSearch.tokens.forEach(t => console.log(t.symbol, t.address, t.decimals));

// Token info by address
const tokenInfo = await fetch(
  `https://api.1inch.dev/token/v1.2/${chainId}/custom/${USDC}`,
  { headers }
).then(r => r.json());
```

## Limit Orders

```typescript
// Get active limit orders for a wallet
const orders = await fetch(
  `https://api.1inch.dev/orderbook/v4.0/${chainId}/address/0x...?page=1&limit=10`,
  { headers }
).then(r => r.json());
orders.forEach(o => console.log(o.id, o.makerAsset, o.takerAsset, o.makingAmount));
```

## Common Use Cases
- "Swap X ETH for USDC at best rate" → quote + swap
- "What's the current price of [token]?" → price API
- "Show my token balances on Ethereum" → balance API
- "Find the best swap route for this trade" → quote with protocol breakdown
- "What slippage should I set?" → check spread in quote, use 0.5–1% for most pairs

## Slippage Guide
| Market Condition | Recommended Slippage |
|-----------------|---------------------|
| Stablecoin pairs | 0.1% |
| Large-cap (ETH, BTC) | 0.3–0.5% |
| Mid-cap tokens | 0.5–1% |
| Low-cap / new tokens | 1–3% |

## Links
- App: https://app.1inch.io
- Docs: https://portal.1inch.dev
- API key: https://portal.1inch.dev
