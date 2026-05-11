# Jelly-Claude Skills

> 27 skills for the Jelly-Claude multi-chain AI agent — Solana, BNB, Base, Hyperliquid, Polymarket, Kalshi, Birdeye, DexScreener, jellychain.fun, and more.

**GitHub:** [github.com/jelly-chain/jelly-claude-skills](https://github.com/jelly-chain/jelly-claude-skills)

Skills teach [Claude Code](https://github.com/anthropics/claude-code) how to interact with specific blockchain protocols, DEXs, and market APIs. Install them and the agent gains instant expertise.

---

## Install everything at once

```bash
bash install-all.sh       # Mac / Linux
.\install-all.ps1         # Windows PowerShell
```

Or via the `npx skills` CLI:
```bash
npx skills add jelly-chain/jelly-claude-skills
```

## Install a single skill

```bash
bash skills/jupiter-skill/install.sh
```

---

## Skill list (27 skills)

### Original Jelly-Claude skills
| Skill | Description |
|-------|-------------|
| `prediction-skill` | Jelly Score heuristics, trend confirmation, market prediction patterns |
| `solana-wallet-skill` | Keypair generation, devnet airdrop, balance checks, SOL transfers |
| `bnb-wallet-skill` | EVM wallet creation (BNB + Polygon), BEP-20 transfers |
| `solana-trading-skill` | Jupiter swaps, Raydium CLMM/AMM, slippage and safety checks |
| `bnb-trading-skill` | PancakeSwap/Venus flows, token approvals, DEX safety checks |

### Prediction market skills
| Skill | Description |
|-------|-------------|
| `polymarket-skill` | Polymarket CLOB API — browse markets, place orders, manage positions on Polygon |
| `kalshi-skill` | Kalshi REST API — US regulated binary markets, yes/no contracts, portfolio P&L |

### Solana Foundation official skills
| Skill | Description |
|-------|-------------|
| `solana-common-errors` | Diagnose and fix common Solana build/RPC errors |
| `solana-compatibility-matrix` | Anchor/CLI/Rust/Node version matching table |
| `solana-confidential-transfers` | Token-2022 private/encrypted balance transfers |
| `solana-frontend-kit` | React/Next.js Wallet Standard patterns with @solana/kit |
| `solana-idl-codegen` | Codama type-safe client generation from IDLs |
| `solana-security-checklist` | Program security audit — account validation, signer checks |
| `solana-testing-strategy` | LiteSVM + Mollusk + Surfpool testing pyramid |

### Community Solana skills
| Skill | Description |
|-------|-------------|
| `jupiter-skill` | Jupiter Ultra swaps, DCA, limit orders, perpetuals |
| `pumpfun-skill` | pump.fun token launches, bonding curves, PumpSwap |
| `raydium-skill` | Raydium CLMM, CPMM, AMM, farming, Trade API |
| `meteora-skill` | Meteora liquidity pools, AMMs, bonding curves |
| `helius-skill` | Helius DAS API, enhanced transactions, webhooks |
| `metaplex-skill` | Core NFTs, Token Metadata, Candy Machine |

### BNB Chain skills
| Skill | Description |
|-------|-------------|
| `bnbchain-mcp-skill` | BNB Chain MCP — blocks, contracts, tokens, NFTs, ERC-8004, Greenfield |
| `binance-skills-hub` | Binance market data, spot trading, token security audit |

### New chain & analytics skills
| Skill | Description |
|-------|-------------|
| `hyperliquid-skill` | Hyperliquid L1 perps — open/close orders, set leverage, funding rates, EIP-712 signing |
| `base-skill` | Base chain (Coinbase L2) — Aerodrome swaps, Uniswap V3, bridging, viem code snippets |
| `birdeye-skill` | Birdeye token analytics — price history, holders, top traders, trending tokens, wallet P&L |
| `dexscreener-skill` | DexScreener public API — new pairs, pair search, liquidity filters, boosted tokens |
| `jelly-skill` | jellychain.fun API — chain TVL, 24h DEX volume, protocol leaderboard (no key required) |

---

## Skill structure

Each skill follows this layout:
```
skills/<skill-name>/
  SKILL.md        ← knowledge base Claude Code reads
  install.sh      ← Mac/Linux installer
  install.ps1     ← Windows installer
  README.md       ← docs, example prompts, required keys
  .keys.example   ← key template (actual .keys file is gitignored)
```

---

## Adding new skills

1. Create a folder under `skills/your-skill-name/`
2. Add `SKILL.md`, `install.sh`, `install.ps1`, `README.md`, `.keys.example`
3. The installer pattern is the same for all skills — copy from any existing one
4. Send a PR to [github.com/jelly-chain/jelly-claude-skills](https://github.com/jelly-chain/jelly-claude-skills)

---

## License

MIT
