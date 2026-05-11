# Base Skill

Interact with Base chain (Coinbase L2) — swaps on Aerodrome and Uniswap V3, LP positions, bridging from Ethereum, and contract reads.

## Chain Info
- **Chain ID:** 8453
- **RPC:** `https://mainnet.base.org` (public, no key needed)
- **Block explorer:** https://basescan.org
- **Native token:** ETH

## Key Contracts on Base
| Contract | Address |
|----------|---------|
| Aerodrome Router | `0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43` |
| Aerodrome Factory | `0x420DD381b31aEf6683db6B902084cB0FFECe40Da` |
| Uniswap V3 Router | `0x2626664c2603336E57B271c5C0b26F421741e481` |
| Uniswap V3 Factory | `0x33128a8fC17869897dcE68Ed026d694621f6FDfD` |
| WETH (Base) | `0x4200000000000000000000000000000000000006` |
| USDC (Base) | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| cbBTC | `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` |
| Base Bridge (L1) | `0x3154Cf16ccdb4C6d922629664174b904d80F2C35` |

## Swapping on Aerodrome
Aerodrome uses stable and volatile pool types. Most pairs use volatile pools.

```javascript
import { createPublicClient, createWalletClient, http, parseEther, parseUnits } from "viem";
import { base } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const account = privateKeyToAccount(process.env.EVM_PRIVATE_KEY);
const walletClient = createWalletClient({ account, chain: base, transport: http("https://mainnet.base.org") });
const publicClient = createPublicClient({ chain: base, transport: http("https://mainnet.base.org") });

const AERODROME_ROUTER = "0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43";

// Swap ETH -> USDC (volatile pool)
const routes = [{
  from: "0x4200000000000000000000000000000000000006", // WETH
  to: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",   // USDC
  stable: false,
  factory: "0x420DD381b31aEf6683db6B902084cB0FFECe40Da"
}];

const deadline = BigInt(Math.floor(Date.now() / 1000) + 1200);
const amountIn = parseEther("0.1");
const minOut = 0n; // Always calculate real minOut in production

const hash = await walletClient.writeContract({
  address: AERODROME_ROUTER,
  abi: aerodromeRouterAbi,
  functionName: "swapExactETHForTokens",
  args: [minOut, routes, account.address, deadline],
  value: amountIn
});
```

## Swapping on Uniswap V3 (Base)
```javascript
const UNISWAP_V3_ROUTER = "0x2626664c2603336E57B271c5C0b26F421741e481";

// exactInputSingle
const hash = await walletClient.writeContract({
  address: UNISWAP_V3_ROUTER,
  abi: uniswapV3RouterAbi,
  functionName: "exactInputSingle",
  args: [{
    tokenIn: "0x4200000000000000000000000000000000000006",  // WETH
    tokenOut: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
    fee: 500,  // 0.05% pool (500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
    recipient: account.address,
    amountIn: parseEther("0.1"),
    amountOutMinimum: 0n,
    sqrtPriceLimitX96: 0n
  }],
  value: parseEther("0.1")
});
```

## Reading Token Balances
```javascript
const balance = await publicClient.readContract({
  address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  abi: erc20Abi,
  functionName: "balanceOf",
  args: [account.address]
});
```

## Checking Gas Price
```javascript
const gasPrice = await publicClient.getGasPrice();
console.log("Base gas:", formatGwei(gasPrice), "gwei");
```

## Bridging from Ethereum to Base
Use the official [Base Bridge](https://bridge.base.org) UI or call the L1 bridge contract:
- L1 Bridge: `0x3154Cf16ccdb4C6d922629664174b904d80F2C35`
- Estimated time: ~1 minute (Base is an OP Stack chain)
- ETH bridges automatically; ERC-20 tokens need approval first

## EVM Wallet
The EVM wallet is at `~/.jelly-claude/wallets/evm.json`. Load it:
```javascript
import { readFileSync } from "fs";
import { homedir } from "os";

const wallet = JSON.parse(readFileSync(`${homedir()}/.jelly-claude/wallets/evm.json`, "utf8"));
const privateKey = wallet.privateKey;
const address = wallet.address;
```

## Useful Links
- Aerodrome docs: https://aerodrome.finance/docs
- Base docs: https://docs.base.org
- BaseScan: https://basescan.org
- Base Bridge: https://bridge.base.org
