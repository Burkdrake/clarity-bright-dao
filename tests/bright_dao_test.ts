import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test scholarship creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Test successful creation by owner
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Test Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], deployer.address),
            
            // Test failed creation by non-owner
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Invalid Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        block.receipts[1].result.expectErr(types.uint(100)); // err-owner-only
    }
});

Clarinet.test({
    name: "Test scholarship application",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const applicant = accounts.get('wallet_1')!;
        
        // First create a scholarship
        let block1 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Test Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Then test application
        let block2 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'apply-for-scholarship', [
                types.uint(1),
                types.ascii("Test documents")
            ], applicant.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Test donation functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const donor = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('bright-dao', 'donate-to-fund', [
                types.uint(1000)
            ], donor.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify donor info
        let donorInfoBlock = chain.mineBlock([
            Tx.contractCall('bright-dao', 'get-donor-info', [
                types.principal(donor.address)
            ], donor.address)
        ]);
        
        const donorInfo = donorInfoBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(donorInfo['total-donated'], types.uint(1000));
    }
});

Clarinet.test({
    name: "Test fund distribution",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const applicant = accounts.get('wallet_1')!;
        const donor = accounts.get('wallet_2')!;
        
        // Setup: Create scholarship and fund it
        let setup = chain.mineBlock([
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Test Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('bright-dao', 'donate-to-fund', [
                types.uint(1000)
            ], donor.address)
        ]);
        
        // Apply for scholarship
        let application = chain.mineBlock([
            Tx.contractCall('bright-dao', 'apply-for-scholarship', [
                types.uint(1),
                types.ascii("Test documents")
            ], applicant.address)
        ]);
        
        // Approve application
        let approval = chain.mineBlock([
            Tx.contractCall('bright-dao', 'approve-application', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        // Distribute funds
        let distribution = chain.mineBlock([
            Tx.contractCall('bright-dao', 'distribute-funds', [
                types.uint(1),
                types.ascii("0x1234567890abcdef")
            ], deployer.address)
        ]);
        
        distribution.receipts[0].result.expectOk().expectUint(1);
        
        // Verify distribution
        let distributionInfo = chain.mineBlock([
            Tx.contractCall('bright-dao', 'get-distribution', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        const distInfo = distributionInfo.receipts[0].result.expectOk().expectSome();
        assertEquals(distInfo['status'], types.ascii("completed"));
    }
});
