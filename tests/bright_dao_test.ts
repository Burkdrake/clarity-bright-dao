[Previous test content plus:]

Clarinet.test({
    name: "Test duplicate application prevention",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const applicant = accounts.get('wallet_1')!;
        
        // Create scholarship
        let block1 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Test Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // First application should succeed
        let block2 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'apply-for-scholarship', [
                types.uint(1),
                types.ascii("Test documents")
            ], applicant.address)
        ]);
        
        // Second application should fail
        let block3 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'apply-for-scholarship', [
                types.uint(1),
                types.ascii("Test documents")
            ], applicant.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectUint(1);
        block3.receipts[0].result.expectErr(types.uint(107)); // err-duplicate-application
    }
});
