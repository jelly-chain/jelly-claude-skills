# Uniswap Skill

Swap tokens, manage liquidity positions, and query pool data on Uniswap v3/v4 across Ethereum, Base, Arbitrum, Polygon, and more.

## Overview
Uniswap V3 uses concentrated liquidity ranges (ticks). V4 introduces hooks. Both use off-chain quoter contracts for price estimation and on-chain router contracts for execution.

## Key Addresses — Ethereum Mainnet

| Contract | V3 Address |
|----------|-----------|
| SwapRouter02 | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| QuoterV2 | `0x61fFE014bA17989E743c5F6cB21bF9697530B21e` |
| PositionManager (NFT) | `0xC36442b4a4522E871399CD717aBDD847Ab11FE88` |
| Factory | `0x1F98431c8aD98523631AE4a59f267346ea31F984` |

Chain deployments: https://docs.uniswap.org/contracts/v3/reference/deployments

## Common Fee Tiers
| Tier | Basis Points | Use For |
|------|-------------|---------|
| 0.01% | 100 | Stablecoins (USDC/USDT/DAI) |
| 0.05% | 500 | Correlated pairs (ETH/WBTC) |
| 0.30% | 3000 | Most pairs |
| 1.00% | 10000 | Exotic pairs |

## SDK Setup
```bash
npm install @uniswap/v3-sdk @uniswap/sdk-core ethers viem
```

## Get Token Price via Quoter

```typescript
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.ETH_RPC_URL);
const QUOTER_V2 = "0x61fFE014bA17989E743c5F6cB21bF9697530B21e";

const quoterAbi = [
  "function quoteExactInputSingle((address tokenIn, address tokenOut, uint256 amountIn, uint24 fee, uint160 sqrtPriceLimitX96)) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)"
];
const quoter = new ethers.Contract(QUOTER_V2, quoterAbi, provider);

// Quote swapping 1 ETH → USDC (0.05% pool)
const WETH  = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC  = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const amountIn = ethers.parseEther("1");

const [amountOut] = await quoter.quoteExactInputSingle.staticCall({
  tokenIn:  WETH,
  tokenOut: USDC,
  amountIn,
  fee: 500,   // 0.05%
  sqrtPriceLimitX96: 0n,
});
console.log("1 ETH →", ethers.formatUnits(amountOut, 6), "USDC");
```

## Execute a Swap

```typescript
import { ethers } from "ethers";

const ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
const routerAbi = [
  "function exactInputSingle((address tokenIn, address tokenOut, uint24 fee, address recipient, uint256 amountIn, uint256 amountMinOut, uint160 sqrtPriceLimitX96)) payable returns (uint256 amountOut)"
];
const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);
const router = new ethers.Contract(ROUTER, routerAbi, wallet);

// Approve token first (if not native ETH)
const erc20Abi = ["function approve(address spender, uint256 amount) returns (bool)"];
const token = new ethers.Contract(WETH, erc20Abi, wallet);
await token.approve(ROUTER, amountIn);

// Swap with 0.5% slippage
const minOut = amountOut * 995n / 1000n;
const deadline = Math.floor(Date.now() / 1000) + 60 * 20;

const tx = await router.exactInputSingle({
  tokenIn:  WETH,
  tokenOut: USDC,
  fee:      500,
  recipient: wallet.address,
  amountIn,
  amountMinOut: minOut,
  sqrtPriceLimitX96: 0n,
}, { value: amountIn });  // send ETH as value for WETH wrapping
await tx.wait();
console.log("Swap complete:", tx.hash);
```

## Query Pool Data via Subgraph

```typescript
const SUBGRAPH = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3";

const query = `{
  pools(first: 10, orderBy: volumeUSD, orderDirection: desc) {
    id
    token0 { symbol }
    token1 { symbol }
    feeTier
    volumeUSD
    tvlUSD: totalValueLockedUSD
    token0Price
    token1Price
  }
}`;

const res = await fetch(SUBGRAPH, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ query }),
}).then(r => r.json());
res.data.pools.forEach(p =>
  console.log(`${p.token0.symbol}/${p.token1.symbol} | TVL: $${Number(p.tvlUSD).toFixed(0)} | Vol: $${Number(p.volumeUSD).toFixed(0)}`)
);
```

## Get Pool Price and Tick Data

```typescript
const poolAbi = [
  "function slot0() view returns (uint160 sqrtPriceX96, int24 tick, uint16 obs, uint16 obsCard, uint16 obsCardNext, uint8 feeProtocol, bool unlocked)",
  "function liquidity() view returns (uint128)",
  "function fee() view returns (uint24)",
];
const poolAddress = "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640"; // ETH/USDC 0.05%
const pool = new ethers.Contract(poolAddress, poolAbi, provider);

const [sqrtPriceX96, tick] = await pool.slot0();
const price = (Number(sqrtPriceX96) / 2**96) ** 2 * (10**12); // adjust for decimals
console.log("Current price:", price.toFixed(2), "USDC per ETH");
console.log("Current tick:", tick);
```

## Manage Liquidity Position

```typescript
// Add liquidity (mint new position)
const posManagerAbi = [
  "function mint((address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min, address recipient, uint256 deadline)) returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)"
];
const posManager = new ethers.Contract(
  "0xC36442b4a4522E871399CD717aBDD847Ab11FE88", posManagerAbi, wallet
);
// tickLower/tickUpper define your price range — calculate from price range target
```

## Common Use Cases
- "What's the current ETH/USDC price on Uniswap?" → QuoterV2 staticCall
- "Swap 1 ETH for USDC on Uniswap V3" → exactInputSingle
- "Show the top pools by TVL" → Subgraph query
- "What fee tier should I use for this pair?" → See fee tier table
- "What's the current tick for the ETH/USDC 0.05% pool?" → slot0()

## Links
- App: https://app.uniswap.org
- Docs: https://docs.uniswap.org
- Subgraph: https://thegraph.com/explorer/subgraphs/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV
