@isTest
public class AccountHandlerTriggerTest {

    @testSetup
    static void setupTestData() {
        // Create some Accounts for testing
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accList.add(new Account(
                Name = 'Test Account ' + i,
                NPN_Number__c = 'NPN-' + i
            ));
        }
        insert accList;
    }

    @isTest
    static void testAfterInsert() {
        // Insert new account to fire AFTER INSERT
        Account acc = new Account(
            Name = 'Insert Account',
            NPN_Number__c = '12345'
        );
        Test.startTest();
        insert acc;
        Test.stopTest();

        // Assertions
        Account insertedAcc = [SELECT Id, Name, NPN_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('12345', insertedAcc.NPN_Number__c, 'NPN number should match');
    }

    @isTest
    static void testBeforeDelete() {
        // Query one of the accounts created in @testSetup
        Account acc = [SELECT Id, NPN_Number__c FROM Account LIMIT 1];

        Test.startTest();
        delete acc; // This will fire BEFORE DELETE
        Test.stopTest();

        // Verify that record is deleted
        Integer countAcc = [SELECT count() FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, countAcc, 'Account should be deleted');
    }
}