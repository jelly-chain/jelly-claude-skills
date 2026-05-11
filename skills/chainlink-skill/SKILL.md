# Chainlink Skill

Price feeds, VRF (verifiable randomness), Automation (keepers), CCIP (cross-chain), and Functions via Chainlink on any EVM chain.

## Overview
Chainlink provides the most widely used decentralized oracle network. Price feeds are the most common use — they deliver reliable, tamper-resistant price data on-chain updated every heartbeat interval or when price deviates beyond a threshold.

## Price Feed Addresses — Ethereum Mainnet
| Pair | Address |
|------|---------|
| ETH/USD | `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` |
| BTC/USD | `0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c` |
| LINK/USD | `0x2c1d072e956AFFC0D435Cb7AC308d97936Ed4773` |
| USDC/USD | `0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6` |
| MATIC/USD | `0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c895a1e3` |
| SOL/USD | `0x4ffC43a60e009B551865A93d232E33Fce9f01507` |
| BNB/USD | `0x14e613AC84a31f709eadbEF3bf98bEFf77D9D081` |

Full list: https://data.chain.link

## Read a Price Feed

```typescript
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.ETH_RPC_URL);

const aggregatorAbi = [
  "function latestRoundData() view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)",
  "function decimals() view returns (uint8)",
  "function description() view returns (string)",
];

const ETH_USD_FEED = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
const feed = new ethers.Contract(ETH_USD_FEED, aggregatorAbi, provider);

const [, answer, , updatedAt] = await feed.latestRoundData();
const decimals = await feed.decimals();
const price = Number(answer) / 10 ** decimals;
const ageSeconds = Math.floor(Date.now() / 1000) - Number(updatedAt);

console.log(`ETH/USD: $${price.toFixed(2)}`);
console.log(`Last updated: ${ageSeconds}s ago`);

// Safety check: reject stale data (heartbeat is typically 3600s for most feeds)
if (ageSeconds > 3600) throw new Error("Stale price feed — do not use");
```

## Read Multiple Feeds

```typescript
const feeds = {
  "ETH/USD": "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
  "BTC/USD": "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c",
  "LINK/USD": "0x2c1d072e956AFFC0D435Cb7AC308d97936Ed4773",
};

const prices: Record<string, number> = {};
await Promise.all(
  Object.entries(feeds).map(async ([pair, address]) => {
    const f = new ethers.Contract(address, aggregatorAbi, provider);
    const [, answer] = await f.latestRoundData();
    const dec = await f.decimals();
    prices[pair] = Number(answer) / 10 ** dec;
  })
);
console.log(prices);
```

## Historical Round Data

```typescript
// Get historical price data by round
const [roundId] = await feed.latestRoundData();
const PHASES = 2n ** 64n;  // round ID is phaseId << 64 | aggregatorRound

// Go back N rounds
const history: { price: number; timestamp: number }[] = [];
for (let i = 0n; i < 10n; i++) {
  const [, answer, , updatedAt] = await feed.getRoundData(roundId - i);
  history.push({
    price: Number(answer) / 10 ** 8,
    timestamp: Number(updatedAt),
  });
}
history.forEach(h => console.log(new Date(h.timestamp * 1000).toISOString(), `$${h.price.toFixed(2)}`));
```

## BNB Chain Price Feeds

```typescript
const bscProvider = new ethers.JsonRpcProvider("https://bsc-dataseed.binance.org");

const BNB_FEEDS: Record<string, string> = {
  "BNB/USD":  "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE",
  "ETH/USD":  "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e",
  "BTC/USD":  "0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf",
  "USDT/USD": "0xB97Ad0E74fa7d920791E90258A6E2085088b4320",
};
```

## Chainlink Data Streams (low-latency)

```typescript
// Data Streams provide sub-second price updates via pull model
// Used for perpetuals and high-frequency applications
// Report fetched off-chain, verified on-chain

// Streams API: https://api.testnet-dataengine.chain.link
const streamReport = await fetch(
  `https://api.testnet-dataengine.chain.link/api/v1/reports/single?feedID=${feedId}&timestamp=${timestamp}`,
  { headers: { "Authorization": `Bearer ${process.env.CHAINLINK_STREAMS_KEY}` } }
).then(r => r.json());
```

## VRF v2 — Verifiable Randomness

```typescript
// VRF gives provably fair random numbers on-chain
// Your contract must: inherit VRFConsumerBaseV2, subscribe to VRF, fund with LINK

// Subscription coordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909 (ETH)
// Key hash (200 gwei): 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
```

## Chainlink Automation (Keepers)

```typescript
// Automate contract function calls based on time or custom logic
// Your contract implements:
//   checkUpkeep(bytes calldata) returns (bool upkeepNeeded, bytes memory performData)
//   performUpkeep(bytes calldata performData)
// Register at: https://automation.chain.link
```

## CCIP — Cross-Chain Interoperability

```typescript
// Send tokens or messages cross-chain with security guarantees
// CCIP Router Ethereum: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D

const ccipRouterAbi = [
  "function getFee(uint64 destinationChainSelector, tuple(bytes receiver, bytes data, tuple(address token, uint256 amount)[] tokenAmounts, address feeToken, bytes extraArgs) message) view returns (uint256 fee)"
];
// Chain selectors: ETH=5009297550715157269, Arbitrum=4949039107694359620, Base=15971525489660198786
```

## Common Use Cases
- "What's the current ETH price on-chain?" → latestRoundData()
- "Show me BTC price history for last 10 rounds" → getRoundData() loop
- "Is this price feed fresh?" → check updatedAt vs block.timestamp
- "Show me all major asset prices" → read multiple feeds in parallel
- "How old is the ETH/USD feed?" → Date.now()/1000 - updatedAt

## Price Feed Staleness Thresholds
| Feed Type | Heartbeat | Max Acceptable Age |
|-----------|-----------|-------------------|
| Crypto (high vol) | 1 hour | 3600s |
| Crypto (low vol) | 24 hours | 86400s |
| Forex | 1 hour | 3600s |

## Links
- Price feeds: https://data.chain.link
- Docs: https://docs.chain.link
- VRF: https://docs.chain.link/vrf
- Automation: https://automation.chain.link
- CCIP: https://docs.chain.link/ccip
