import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test NFT minting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'mint-nft', [
                types.ascii("Test NFT"),
                types.ascii("Test Description"),
                types.uint(1000),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectUint(1);
        
        const metadata = chain.callReadOnlyFn(
            'craft-loop',
            'get-token-metadata',
            [types.uint(1)],
            deployer.address
        );
        metadata.result.expectSome();
    }
});

Clarinet.test({
    name: "Test NFT listing and purchase flow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // Mint NFT
        let block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'mint-nft', [
                types.ascii("Test NFT"),
                types.ascii("Test Description"),
                types.uint(1000),
                types.principal(seller.address)
            ], deployer.address)
        ]);
        
        // List NFT
        block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'list-nft', [
                types.uint(1),
                types.uint(500)
            ], seller.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Purchase NFT
        block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'purchase-nft', [
                types.uint(1)
            ], buyer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify ownership transfer
        const owner = chain.callReadOnlyFn(
            'craft-loop',
            'get-owner',
            [types.uint(1)],
            deployer.address
        );
        owner.result.expectSome().expectPrincipal(buyer.address);
    }
});

Clarinet.test({
    name: "Test listing management",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const seller = accounts.get('wallet_1')!;
        
        // Mint and list NFT
        let block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'mint-nft', [
                types.ascii("Test NFT"),
                types.ascii("Test Description"),
                types.uint(1000),
                types.principal(seller.address)
            ], deployer.address),
            Tx.contractCall('craft-loop', 'list-nft', [
                types.uint(1),
                types.uint(500)
            ], seller.address)
        ]);
        
        // Update price
        block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'update-price', [
                types.uint(1),
                types.uint(600)
            ], seller.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Remove listing
        block = chain.mineBlock([
            Tx.contractCall('craft-loop', 'remove-listing', [
                types.uint(1)
            ], seller.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify listing removed
        const listing = chain.callReadOnlyFn(
            'craft-loop',
            'get-listing',
            [types.uint(1)],
            deployer.address
        );
        listing.result.expectNone();
    }
});
