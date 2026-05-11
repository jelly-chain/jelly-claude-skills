# OpenSea Skill

NFT collections, listings, offers, sales, and order execution via the OpenSea API v2.

## API Base
```
https://api.opensea.io/api/v2
```

## Authentication
```typescript
const headers = {
  "x-api-key": process.env.OPENSEA_API_KEY!,
  "accept": "application/json",
};
```
Get API key: https://docs.opensea.io/reference/api-keys

Keys stored at `~/.jelly-claude/.keys`:
```
OPENSEA_API_KEY=...
```

Supported chains: `ethereum`, `polygon`, `base`, `arbitrum`, `optimism`, `solana`, `zora`

## Browse Collections

```typescript
const BASE = "https://api.opensea.io/api/v2";

// Get a collection by slug
const col = await fetch(`${BASE}/collections/boredapeyachtclub`, { headers }).then(r => r.json());
console.log(col.name, "| Floor:", col.stats?.floor_price, "ETH");
console.log("Total volume:", col.stats?.total_volume, "ETH");
console.log("Owners:", col.stats?.num_owners, "| Supply:", col.stats?.total_supply);
console.log("7d volume:", col.stats?.seven_day_volume);

// Search collections
const search = await fetch(
  `${BASE}/collections?chain=ethereum&limit=20`,
  { headers }
).then(r => r.json());
search.collections.forEach(c => console.log(c.name, c.collection, c.stats?.floor_price));
```

## Collection Stats

```typescript
// Detailed stats for a collection
const stats = await fetch(`${BASE}/collections/azuki/stats`, { headers }).then(r => r.json());
console.log("Floor:", stats.total.floor_price, "ETH");
console.log("24h vol:", stats.intervals.find(i => i.interval === "one_day")?.volume);
console.log("7d vol:", stats.intervals.find(i => i.interval === "seven_day")?.volume);
console.log("30d vol:", stats.intervals.find(i => i.interval === "thirty_day")?.volume);
```

## NFT Data

```typescript
// Get a specific NFT
const nft = await fetch(
  `${BASE}/chain/ethereum/contract/0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D/nfts/1`,
  { headers }
).then(r => r.json());
console.log(nft.nft.name, "| Owner:", nft.nft.owners[0]?.address);
console.log("Traits:", nft.nft.traits.map(t => `${t.trait_type}: ${t.value}`).join(", "));

// Get NFTs in a collection (paginated)
const nfts = await fetch(
  `${BASE}/collection/boredapeyachtclub/nfts?limit=20`,
  { headers }
).then(r => r.json());

// Get NFTs owned by a wallet
const owned = await fetch(
  `${BASE}/chain/ethereum/account/0xYOUR_WALLET/nfts?limit=50`,
  { headers }
).then(r => r.json());
owned.nfts.forEach(n => console.log(n.collection, "#" + n.identifier));
```

## Listings (Active Sell Orders)

```typescript
// Get active listings for a collection
const listings = await fetch(
  `${BASE}/listings/collection/boredapeyachtclub/best?limit=20`,
  { headers }
).then(r => r.json());
listings.listings.forEach(l => {
  const price = Number(l.price.current.value) / 1e18;
  console.log(`#${l.token_id}: ${price.toFixed(4)} ETH`);
});

// Get listing for a specific NFT
const nftListing = await fetch(
  `${BASE}/listings/collection/boredapeyachtclub/nfts/1/best`,
  { headers }
).then(r => r.json());
```

## Offers (Active Buy Orders)

```typescript
// Get best offers for a collection
const offers = await fetch(
  `${BASE}/offers/collection/boredapeyachtclub/best?limit=10`,
  { headers }
).then(r => r.json());
offers.offers.forEach(o => {
  const price = Number(o.price.value) / 1e18;
  console.log("Offer:", price.toFixed(4), "ETH | Expires:", new Date(o.expiration_time * 1000).toISOString());
});
```

## Recent Sales

```typescript
// Recent sales events for a collection
const events = await fetch(
  `${BASE}/events/collection/pudgypenguins?event_type=sale&limit=20`,
  { headers }
).then(r => r.json());
events.asset_events.forEach(e => {
  const price = Number(e.payment.quantity) / 10 ** e.payment.decimals;
  console.log(`#${e.nft.identifier}: ${price.toFixed(4)} ${e.payment.symbol} | ${new Date(e.event_timestamp * 1000).toLocaleString()}`);
});

// Events for a specific NFT (sale history)
const nftEvents = await fetch(
  `${BASE}/events/chain/ethereum/contract/0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D/nfts/1?event_type=sale&limit=10`,
  { headers }
).then(r => r.json());
```

## Fulfill a Listing (Buy an NFT)

```typescript
import { ethers } from "ethers";

// 1. Get the fulfillment data from OpenSea
const fulfillRes = await fetch(`${BASE}/listings/fulfillment_data`, {
  method: "POST",
  headers: { ...headers, "Content-Type": "application/json" },
  body: JSON.stringify({
    listing: {
      hash:   listingOrderHash,
      chain:  "ethereum",
      protocol_address: "0x0000000000000068F116a894984e2DB1123eB395",
    },
    fulfiller: { address: "0xYOUR_WALLET" },
  }),
}).then(r => r.json());

// 2. Execute the transaction
const wallet = new ethers.Wallet(process.env.EVM_PRIVATE_KEY!, provider);
const { transaction } = fulfillRes.fulfillment_data;
const tx = await wallet.sendTransaction({
  to:    transaction.to,
  data:  transaction.input_data.parameters ? undefined : transaction.input_data,
  value: BigInt(transaction.value),
});
await tx.wait();
console.log("NFT purchased:", tx.hash);
```

## Create an Offer

```typescript
// Create a collection offer (Seaport EIP-712 signature)
// Use the SDK for simplicity: npm install @opensea/seaport-js
import { Seaport } from "@opensea/seaport-js";

const seaport = new Seaport(wallet);
const { actions } = await seaport.createOrder({
  offer: [{ itemType: 1, token: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", amount: ethers.parseEther("0.1").toString() }],
  consideration: [{ itemType: 2, token: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D", identifier: "1", recipient: wallet.address }],
});
```

## Common Use Cases
- "What's the floor price of BAYC?" → collection stats
- "Show recent BAYC sales" → events with event_type=sale
- "Find the cheapest listing in Azuki collection" → listings/best
- "What NFTs does wallet 0x... own?" → account nfts
- "Show me traits for Pudgy Penguin #100" → nft detail
- "What's the best offer on this NFT?" → offers/best

## Rarity and Trait Filtering
```typescript
// Filter by trait when browsing collection NFTs
const rare = await fetch(
  `${BASE}/collection/boredapeyachtclub/nfts?trait_type=Fur&trait_value=Solid+Gold&limit=10`,
  { headers }
).then(r => r.json());
```

## Links
- App: https://opensea.io
- Docs: https://docs.opensea.io
- API key: https://docs.opensea.io/reference/api-keys
- Seaport SDK: https://github.com/ProjectOpenSea/seaport-js
