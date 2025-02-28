[Previous test content plus:]

Clarinet.test({
    name: "Test scholarship deadline validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test deadline too close to current block
        let block1 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Test Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(10)  // Too close to current block
            ], deployer.address)
        ]);
        
        // Test valid deadline
        let block2 = chain.mineBlock([
            Tx.contractCall('bright-dao', 'create-scholarship', [
                types.ascii("Valid Scholarship"),
                types.uint(1000),
                types.ascii("Test criteria"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block1.receipts[0].result.expectErr(types.uint(106)); // err-invalid-deadline
        block2.receipts[0].result.expectOk().expectUint(1);
    }
});
