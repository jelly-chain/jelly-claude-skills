# Etherscan Skill

On-chain data for Ethereum and all major EVM chains via Etherscan-compatible APIs.

## Supported Chains

| Chain | Base URL | Env Key |
|-------|----------|---------|
| Ethereum | `https://api.etherscan.io/api` | `ETHERSCAN_API_KEY` |
| BNB Chain | `https://api.bscscan.com/api` | `BSCSCAN_API_KEY` |
| Polygon | `https://api.polygonscan.com/api` | `POLYGONSCAN_API_KEY` |
| Base | `https://api.basescan.org/api` | `BASESCAN_API_KEY` |
| Arbitrum | `https://api.arbiscan.io/api` | `ARBISCAN_API_KEY` |
| Optimism | `https://api-optimistic.etherscan.io/api` | `OPTIMISM_ETHERSCAN_KEY` |
| Avalanche | `https://api.snowtrace.io/api` | `SNOWTRACE_API_KEY` |

Keys stored at `~/.jelly-claude/.keys`

## Authentication
All requests append `&apikey=YOUR_KEY`. Free tier: 5 calls/sec, 100k calls/day.

```typescript
const ETHERSCAN = "https://api.etherscan.io/api";
const KEY = process.env.ETHERSCAN_API_KEY!;
const get = (params: string) => fetch(`${ETHERSCAN}?${params}&apikey=${KEY}`).then(r => r.json());
```

## Key Endpoints

### Account balances
```typescript
// ETH balance
const bal = await get(`module=account&action=balance&address=0x...&tag=latest`);
const ethBalance = Number(bal.result) / 1e18;

// Multi-address ETH balance (up to 20)
const multi = await get(`module=account&action=balancemulti&address=0x...,0x...&tag=latest`);

// ERC-20 token balance
const tokenBal = await get(`module=account&action=tokenbalance&contractaddress=0x...&address=0x...&tag=latest`);
```

### Transaction history
```typescript
// Normal transactions
const txList = await get(`module=account&action=txlist&address=0x...&startblock=0&endblock=99999999&sort=desc&page=1&offset=20`);
txList.result.forEach(tx => console.log(tx.hash, tx.value, tx.from, tx.to, tx.isError));

// Internal transactions
const internal = await get(`module=account&action=txlistinternal&address=0x...&sort=desc`);

// ERC-20 token transfers
const erc20 = await get(`module=account&action=tokentx&address=0x...&sort=desc&page=1&offset=50`);
erc20.result.forEach(t => console.log(t.tokenSymbol, t.value, t.from, t.to));

// ERC-721 NFT transfers
const nft = await get(`module=account&action=tokennfttx&address=0x...&sort=desc`);
```

### Contract
```typescript
// ABI of a verified contract
const abi = await get(`module=contract&action=getabi&address=0x...`);
const parsedAbi = JSON.parse(abi.result);

// Source code of a verified contract
const src = await get(`module=contract&action=getsourcecode&address=0x...`);
console.log(src.result[0].ContractName, src.result[0].SourceCode);

// Check if address is a contract
const code = await get(`module=proxy&action=eth_getCode&address=0x...&tag=latest`);
const isContract = code.result !== "0x";
```

### Transaction info
```typescript
// Transaction receipt and status
const receipt = await get(`module=transaction&action=gettxreceiptstatus&txhash=0x...`);
// result.status: "1" = success, "0" = failed

// Get transaction by hash
const tx = await get(`module=proxy&action=eth_getTransactionByHash&txhash=0x...`);
```

### Token info
```typescript
// Token supply
const supply = await get(`module=stats&action=tokensupply&contractaddress=0x...`);

// Token holders count
const holders = await get(`module=token&action=tokenholdercount&contractaddress=0x...`);
```

### Gas tracker
```typescript
// Current gas price
const gas = await get(`module=gastracker&action=gasoracle`);
console.log("Safe:", gas.result.SafeGasPrice, "gwei");
console.log("Propose:", gas.result.ProposeGasPrice, "gwei");
console.log("Fast:", gas.result.FastGasPrice, "gwei");
```

### Block data
```typescript
// Get block number by timestamp
const blockNum = await get(`module=block&action=getblocknobytime&timestamp=${Math.floor(Date.now()/1000)}&closest=before`);

// Get block reward (mining info)
const blockReward = await get(`module=block&action=getblockreward&blockno=18000000`);
```

### Logs (events)
```typescript
// Query smart contract events by topic
const logs = await get(
  `module=logs&action=getLogs&address=0x...&fromBlock=18000000&toBlock=latest&topic0=0x...`
);
logs.result.forEach(l => console.log(l.transactionHash, l.data, l.topics));
```

## Common Use Cases
- "Check ETH balance of address 0x..." → `account/balance`
- "Show recent transactions for wallet" → `account/txlist`
- "Get ABI for contract 0x..." → `contract/getabi`
- "What was the gas price for tx 0x...?" → `proxy/eth_getTransactionByHash`
- "Show me all USDT transfers from this wallet" → `account/tokentx`
- "Is this address a contract or wallet?" → `proxy/eth_getCode`
- "What's the current gas price?" → `gastracker/gasoracle`

## Links
- Etherscan: https://etherscan.io
- API docs: https://docs.etherscan.io
- API key: https://etherscan.io/apis
