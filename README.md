# CraftLoop: Artisanal NFT Marketplace

A decentralized marketplace for unique artisanal NFT products built on the Stacks blockchain.

## Features
- Create and mint artisanal NFTs with detailed metadata
- List NFTs for sale at a specified price
- Purchase listed NFTs
- Update listing prices 
- Remove listings
- View all active listings
- Get NFT details and ownership history

## Setup and Installation
1. Clone the repository
2. Install Clarinet 
3. Run `clarinet check` to verify the contracts
4. Run `clarinet test` to execute the test suite

## Usage Examples
```clarity
;; Create a new artisanal NFT
(contract-call? .craft-loop mint-nft "Handcrafted Vase" "A unique ceramic vase" u100000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; List an NFT for sale
(contract-call? .craft-loop list-nft u1 u50000)

;; Purchase a listed NFT
(contract-call? .craft-loop purchase-nft u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
- SIP-009 NFT standard compliance
