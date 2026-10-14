@isTest(seeAllData = true)
public class OpportunityLineItemController_Test {

    // Helper method to create test data
    public static Account createTestData() {
        // Fetch a profile to use for the test user
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Adjust if needed

        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'uniqueoppuser@example.com'
        );
        insert testUser;

        Account testAcc;
        System.runAs(testUser) {
            // Create Account
            testAcc = new Account(Name = 'Testing Account');
            insert testAcc;

            // Create Pricebook
            Pricebook2 pb = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
            insert pb;

            // Create Product
            Product2 prod = new Product2(Name = 'FEEFUEL', IsActive = true);
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
                Name = 'Testing Opportunity',
                AccountId = testAcc.Id,
                StageName = 'Live',
                CloseDate = Date.today()
            );
            insert opp;

            // Create Opportunity Line Item
            OpportunityLineItem oppLine = new OpportunityLineItem(
                Quantity = 1,
                OpportunityId = opp.Id,
                UnitPrice = 0.01,
                PriceBookEntryId = stdPbe.Id
            );
            insert oppLine;

            // Create Foundation Onboarding
            Foundation_Onboarding__c onboarding = new Foundation_Onboarding__c(
                Opportunity__c = opp.Id
            );
            insert onboarding;

            // Call methods to cover
            OpportunityLineItemController.getProduct(testAcc.Id);
            OpportunityLineItemController.getProduct(onboarding.Id);
        }

        return testAcc;
    }

    @isTest static void testControllerMethods() {
        Account acct = createTestData();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
    }
}