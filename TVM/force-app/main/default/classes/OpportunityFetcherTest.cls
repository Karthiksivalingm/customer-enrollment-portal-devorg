@isTest
public class OpportunityFetcherTest {

    // Helper method to generate unique suffix
    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    @testSetup
    static void setupTestData() {
        String suf1 = uniqueSuffix();
        String suf2 = uniqueSuffix();

        // Create Accounts with unique names and Quickbase_Record_ID__c to prevent duplicates
        Account acc1 = new Account(
            Name = 'Test Account 1 ' + suf1,
            Quickbase_Record_ID__c = 'QB_' + suf1
        );

        Account acc2 = new Account(
            Name = 'Test Account 2 ' + suf2,
            Quickbase_Record_ID__c = 'QB_' + suf2
        );

        insert new List<Account>{acc1, acc2};

        // Create Opportunities with the same name as Account (required by validation rule)
        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = acc1.Name, 
                StageName = 'New', 
                Amount = 10000, 
                CloseDate = Date.today().addDays(30), 
                AccountId = acc1.Id
            ),
            new Opportunity(
                Name = acc2.Name, 
                StageName = 'New', 
                Amount = 20000, 
                CloseDate = Date.today().addDays(45), 
                AccountId = acc2.Id
            ),
            new Opportunity(
                Name = acc1.Name, 
                StageName = 'New', 
                Amount = 15000, 
                CloseDate = Date.today().addDays(60), 
                AccountId = acc1.Id
            )
        };
        insert opportunities;
    }

    @isTest
    static void testGetOpportunitiesForAccounts() {
        // Only get the accounts created in test setup
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 2];

        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        // Call the Apex method
        Test.startTest();
        List<Opportunity> resultOpportunities = OpportunityFetcher.getOpportunitiesForAccounts(accountIds);
        Test.stopTest();

        // Simple assertion
        System.assert(resultOpportunities.size() > 0, 'Opportunities should be returned');

        // Ensure Opportunity names match Account names using a for-loop
        for (Opportunity opp : resultOpportunities) {
            Boolean matchFound = false;
            for (Account acc : testAccounts) {
                if (acc.Id == opp.AccountId) {
                    System.assertEquals(acc.Name, opp.Name, 'Opportunity Name should match Account Name');
                    matchFound = true;
                    break;
                }
            }
            System.assert(matchFound, 'Matching Account not found for Opportunity');
        }
    }

    @isTest
    static void testGetOpportunitiesForAccountsWithNoAccounts() {
        // Call the method with an empty list
        Test.startTest();
        List<Opportunity> resultOpportunities = OpportunityFetcher.getOpportunitiesForAccounts(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, resultOpportunities.size(), 'No opportunities should be returned');
    }
}