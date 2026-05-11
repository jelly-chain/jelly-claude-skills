# Hyperliquid Skill

Trade perpetuals and spot on Hyperliquid L1 — the highest-volume onchain perps exchange.

## API Base
```
https://api.hyperliquid.xyz
```

## Authentication
Hyperliquid uses EIP-712 signed actions. No API key — all requests are signed with your EVM private key.

Keys stored at `~/.jelly-claude/.keys`:
```
HYPERLIQUID_WALLET_ADDRESS=0x...
HYPERLIQUID_PRIVATE_KEY=...
```

## Key Endpoints

### Info (read-only, no auth)
```
POST https://api.hyperliquid.xyz/info
```

Get account state (balances, positions, margin):
```json
{ "type": "clearinghouseState", "user": "0x..." }
```

Get all open orders:
```json
{ "type": "openOrders", "user": "0x..." }
```

Get funding rates for all markets:
```json
{ "type": "metaAndAssetCtxs" }
```

Get market metadata:
```json
{ "type": "meta" }
```

Get leaderboard (top traders by PnL):
```json
{ "type": "leaderboard" }
```

### Exchange (authenticated — signed actions)
```
POST https://api.hyperliquid.xyz/exchange
```

All exchange requests have the shape:
```json
{
  "action": { ... },
  "nonce": <unix_ms>,
  "signature": { "r": "...", "s": "...", "v": 28 }
}
```

#### Place order
```json
{
  "action": {
    "type": "order",
    "orders": [{
      "a": 3,
      "b": true,
      "p": "3500",
      "s": "0.1",
      "r": false,
      "t": { "limit": { "tif": "Gtc" } }
    }],
    "grouping": "na"
  }
}
```
- `"a"`: asset index (0 = BTC, 1 = ETH, 3 = SOL — use `/info` meta to get indices)
- `"b"`: true = buy/long, false = sell/short
- `"p"`: price as string
- `"s"`: size as string
- `"r"`: reduce-only flag
- `tif`: "Gtc" (good-till-cancel), "Ioc", "Alo"

For **market orders**, use `"p": "0"` and `tif: "Ioc"`.

#### Cancel order
```json
{
  "action": {
    "type": "cancel",
    "cancels": [{ "a": 3, "o": <oid> }]
  }
}
```

#### Set leverage
```json
{
  "action": {
    "type": "updateLeverage",
    "asset": 3,
    "isCross": true,
    "leverage": 5
  }
}
```

#### Close position (market)
Place a reduce-only market order in the opposite direction for the full position size.

## Signing Requests (Node.js)
```javascript
import { ethers } from "ethers";

const wallet = new ethers.Wallet(process.env.HYPERLIQUID_PRIVATE_KEY);

async function signAction(action, nonce) {
  const domain = {
    name: "Exchange",
    version: "1",
    chainId: 1337,
    verifyingContract: "0x0000000000000000000000000000000000000000"
  };
  const types = {
    Agent: [
      { name: "source", type: "string" },
      { name: "connectionId", type: "bytes32" }
    ]
  };
  // Full signing implementation: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/signing
  const sig = await wallet.signTypedData(domain, types, {
    source: "a",
    connectionId: ethers.id(JSON.stringify(action) + nonce)
  });
  const { r, s, v } = ethers.Signature.from(sig);
  return { r, s, v };
}
```

## Asset Indices (common)
| Asset | Index |
|-------|-------|
| BTC   | 0     |
| ETH   | 1     |
| ARB   | 2     |
| SOL   | 3     |
| AVAX  | 4     |
| BNB   | 5     |
| MATIC | 6     |
| DOGE  | 11    |
| SUI   | 14    |

Fetch full list: `POST /info` with `{ "type": "meta" }`.

## Important Notes
- All sizes and prices are strings, not numbers
- Leverage range: 1x–50x (market dependent)
- USDC is the only margin/settlement asset
- Withdrawals go to Arbitrum — bridge back via [app.hyperliquid.xyz](https://app.hyperliquid.xyz)
- Docs: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api
