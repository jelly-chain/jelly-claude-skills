# BNB Chain MCP Skill

AI agent skill for the BNB Chain MCP (Model Context Protocol) server. Covers blocks, transactions, contracts, tokens, NFTs, wallet operations, ERC-8004 agent registration, and Greenfield storage.

## Source (official)
```bash
npx skills add bnb-chain/bnbchain-skills
```
GitHub: https://github.com/bnb-chain/bnbchain-skills

## Setup: Install the BNB Chain MCP server
```bash
npx @bnb-chain/mcp@latest
```

Add to your Claude Code MCP config (`~/.claude/mcp.json`):
```json
{
  "mcpServers": {
    "bnbchain": {
      "command": "npx",
      "args": ["@bnb-chain/mcp@latest"],
      "env": {
        "BNBCHAIN_API_KEY": "your-key-here"
      }
    }
  }
}
```

## Available MCP tools (once installed)
- `get_block` — fetch block data by number or hash
- `get_transaction` — fetch transaction details and receipt
- `get_balance` — native BNB balance for any address
- `get_token_balance` — ERC-20/BEP-20 balance
- `get_contract_abi` — fetch verified contract ABI from BscScan
- `call_contract` — read-only contract function call
- `send_transaction` — sign and broadcast a transaction (requires private key in env)
- `get_nft_metadata` — fetch NFT metadata for BEP-721/1155 tokens
- `register_erc8004_agent` — register an AI agent on-chain via ERC-8004 identity registry
- `greenfield_list_buckets` — list Greenfield storage buckets
- `greenfield_get_object` — retrieve an object from Greenfield

## Example prompts (once MCP is configured)
- "Get the latest BNB Chain block"
- "Check the USDT balance of 0x..."
- "Fetch the ABI for PancakeSwap router"
- "What is the transaction status of 0x...?"
- "Register this MCP as an ERC-8004 agent"
