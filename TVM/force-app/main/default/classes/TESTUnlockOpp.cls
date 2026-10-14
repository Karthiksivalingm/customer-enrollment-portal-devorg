@isTest
private class TESTUnlockOpp {
    //https://salesforce.stackexchange.com/questions/329335/how-do-i-write-a-test-class-invoked-from-a-flow
    // Recommended practice is to use a @testSetup annotated method to create
    // the common data required for each test.
    // It can help test execution speed.
    // The 'testMethod' keyword has been deprecated for a while
    // The preferred approach is to use the @isTest annotation
    @isTest
    private static void validateUnlockOpportunity() {
        Account testAcc1 = new Account(Name = 'Test T3');
		insert testAcc1;
        List<Account> acc = [SELECT Id FROM Account WHERE Name = 'Test T3'];
        system.debug('***************Debug STARTED***************');
        system.debug(acc);
        Opportunity testOpp1 = new Opportunity(Name = 'Test T3');
        testOpp1.AccountId=acc[0].Id;
        testOpp1.StageName='Negotiation';
        testOpp1.CloseDate=date.parse('02/6/2014');
        insert testOpp1;
        List<Opportunity> opp = [SELECT Id FROM Opportunity WHERE Name = 'Test T3'];
        system.debug(testOpp1);
		system.debug(testOpp1.Id);

		Approval.LockResult locked = Approval.lock(opp[0].Id);
            
        Test.startTest();
      	Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        UnlockOpportunity.getOpportunity(opp);
        Test.stopTest();
    }
}