@isTest(seeAllData = false)
public class agency_Fees_UpdateBatch_Test {

    // 🔹 Helper method to create test data
    public static Account createTestData() {
        // Fetch a profile to assign to the test user
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Adjust if needed

        User testUser = new User(
            Alias = 'afuser',
            Email = 'afuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'BatchTester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'unique.afuser@example.com'
        );
        insert testUser;

        Account testAcc;
        System.runAs(testUser) {
            Date closeDt = Date.Today();
            DateTime dt = Datetime.now();
            String Month = dt.format('MMM');
            String Year = dt.format('yyyy');

            // Create Account
            testAcc = new Account(Name = 'Testing Acc');
            insert testAcc;

            // Create Monthly Budget
            Monthly_Budget__c mb = new Monthly_Budget__c(
                Account__c = testAcc.Id,
                Budget_Month__c = Month,
                Budget_Year__c = Year
            );
            insert mb;

            // Create Pricebook
            Pricebook2 pb = new Pricebook2(Name = 'Test PB', IsActive = true);
            insert pb;

            // Create Product (Agency Fee)
            Product2 prod = new Product2(
                Name = System.Label.AgencyFee_ProductName,
                IsActive = true,
                Percentage__c = 5
            );
            insert prod;

            // Standard Pricebook Entry
            PricebookEntry stdPbe = new PricebookEntry(
                UnitPrice = 0.01,
                Product2Id = prod.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                IsActive = true,
                UseStandardPrice = false
            );
            insert stdPbe;

            // Custom Pricebook Entry
            PricebookEntry customPbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = prod.Id,
                UnitPrice = 12000,
                IsActive = true
            );
            insert customPbe;

            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Testing Opp',
                AccountId = testAcc.Id,
                StageName = 'Live',
                CloseDate = closeDt
            );
            insert opp;

            // Create Opportunity Line Item
            OpportunityLineItem oppLine = new OpportunityLineItem(
                Quantity = 1,
                OpportunityId = opp.Id,
                UnitPrice = 0.01,
                PriceBookEntryId = stdPbe.Id,
                Percentage__c = 10
            );
            insert oppLine;
        }

        return testAcc;
    }

    // 🔹 Actual test method
    @isTest static void testBatch() {
        Account acct = createTestData();

        Test.startTest();
        agency_Fees_UpdateBatch batchJob = new agency_Fees_UpdateBatch();
        String sch = '20 30 8 10 2 ?';
        String jobId = System.schedule('AgencyFee Job', sch, batchJob);
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
    }
}