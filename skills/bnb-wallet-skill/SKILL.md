# BNB Wallet Skill (EVM — BNB Chain + Polygon)

## Overview
Covers EVM wallet generation, BNB/MATIC balance checks, BEP-20/ERC-20 token transfers, and network configuration for BNB Smart Chain and Polygon. The same private key works on both networks.

## Key concepts
- **EVM address**: 20-byte hex, format `0x...` — same address on all EVM chains
- **Gas**: BNB on BSC, MATIC/POL on Polygon — required for every transaction
- **BEP-20**: BNB Chain's token standard (identical to ERC-20)
- **Nonce**: Auto-increments; always fetch from RPC, never hardcode

## Generate a wallet (ethers.js v6)

```typescript
import { ethers } from 'ethers';

const wallet = ethers.Wallet.createRandom();
console.log('Address:     ', wallet.address);
console.log('Private key: ', wallet.privateKey);
console.log('Mnemonic:    ', wallet.mnemonic?.phrase);
```

## Load wallet from private key

```typescript
const provider = new ethers.JsonRpcProvider('https://bsc-dataseed.binance.org');
const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);
```

## Check BNB balance

```typescript
const balance = await provider.getBalance(wallet.address);
console.log('BNB:', ethers.formatEther(balance));
```

## Send BNB (native gas token)

```typescript
const tx = await wallet.sendTransaction({
  to: recipientAddress,
  value: ethers.parseEther('0.01'),
  gasLimit: 21000n,
});
const receipt = await tx.wait();
console.log('TxHash:', receipt?.hash);
```

## BEP-20 / ERC-20 token transfer

```typescript
const ERC20_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function decimals() view returns (uint8)',
];
const token = new ethers.Contract(tokenAddress, ERC20_ABI, wallet);
const decimals = await token.decimals();
const tx = await token.transfer(recipientAddress, ethers.parseUnits('10', decimals));
await tx.wait();
```

## Network configs

| Network | RPC | Chain ID | Explorer |
|---------|-----|----------|----------|
| BSC Mainnet | `https://bsc-dataseed.binance.org` | 56 | bscscan.com |
| BSC Testnet | `https://data-seed-prebsc-1-s1.bnbchain.org:8545` | 97 | testnet.bscscan.com |
| Polygon Mainnet | `https://polygon-rpc.com` | 137 | polygonscan.com |
| Polygon Amoy Testnet | `https://rpc-amoy.polygon.technology` | 80002 | amoy.polygonscan.com |

## Common errors
- `INSUFFICIENT_FUNDS` — not enough gas token; top up BNB (BSC) or MATIC (Polygon)
- `nonce too low` — transaction already mined or pending; fetch fresh nonce
- `gas too low` — increase gasLimit; use `provider.estimateGas()` first
- `execution reverted` — token transfer failed; check allowance or balance
