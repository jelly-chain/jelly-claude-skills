# Solana Wallet Skill

## Overview
Covers Solana keypair generation, balance checking, devnet airdrops, SOL transfers, and token account management using `@solana/kit` and the Solana CLI.

## Key concepts
- **Keypair**: Ed25519 key pair. The public key is the wallet address (base58 encoded).
- **Lamports**: 1 SOL = 1,000,000,000 lamports (10^9).
- **Associated Token Account (ATA)**: A deterministic account address that holds a specific SPL token for a wallet.
- **Rent**: Small SOL deposit required to keep accounts open.

## Generate a keypair

### CLI
```bash
solana-keygen new --outfile ~/.config/solana/id.json
solana-keygen pubkey ~/.config/solana/id.json
```

### @solana/kit
```typescript
import { generateKeyPairSigner } from '@solana/kit';
const signer = await generateKeyPairSigner();
console.log('Address:', signer.address);
```

## Check balance

```typescript
import { createSolanaRpc } from '@solana/kit';
const rpc = createSolanaRpc('https://api.mainnet-beta.solana.com');
const balance = await rpc.getBalance(address).send();
console.log('Balance:', Number(balance.value) / 1e9, 'SOL');
```

## Airdrop (devnet only)

```bash
solana airdrop 2 <ADDRESS> --url devnet
```

```typescript
const rpc = createSolanaRpc('https://api.devnet.solana.com');
await rpc.requestAirdrop(address, 2_000_000_000n).send();
```

## SOL transfer

```typescript
import { createSolanaRpc, createSolanaRpcSubscriptions, sendAndConfirmTransactionFactory, pipe, createTransactionMessage, setTransactionMessageFeePayerSigner, setTransactionMessageLifetimeUsingBlockhash, appendTransactionMessageInstructions, signTransactionMessageWithSigners } from '@solana/kit';
import { getTransferSolInstruction } from '@solana-program/system';

const rpc = createSolanaRpc('https://api.mainnet-beta.solana.com');
const { value: latestBlockhash } = await rpc.getLatestBlockhash().send();

const tx = pipe(
  createTransactionMessage({ version: 0 }),
  msg => setTransactionMessageFeePayerSigner(signer, msg),
  msg => setTransactionMessageLifetimeUsingBlockhash(latestBlockhash, msg),
  msg => appendTransactionMessageInstructions([
    getTransferSolInstruction({ source: signer, destination: recipientAddress, amount: lamports(0.01) })
  ], msg)
);
const signed = await signTransactionMessageWithSigners(tx);
// send with sendAndConfirmTransactionFactory(...)
```

## RPC endpoints
| Network | URL |
|---------|-----|
| Mainnet | `https://api.mainnet-beta.solana.com` |
| Devnet | `https://api.devnet.solana.com` |
| Helius Mainnet | `https://mainnet.helius-rpc.com/?api-key=YOUR_KEY` |

## Common errors
- `AccountNotFound` — wallet has never received SOL; send a small amount first
- `InsufficientFundsForRent` — not enough SOL to pay rent; top up wallet
- `BlockhashNotFound` — blockhash expired; retry with a fresh blockhash
