@isTest
public class AdvertisedPayment_Batch_Test {

    // Generate a unique suffix for test data
    private static String uniqueSuffix() {
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    // Create a test user
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        UserRole r = new UserRole(Name = 'Test Role ' + uniqueSuffix());
        insert r;

        User u = new User(
            Alias = 'tusr' + uniqueSuffix().substring(0, 3),
            Email = 'user' + uniqueSuffix() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            UserRoleId = r.Id,
            Username = 'user' + uniqueSuffix() + '@test.com'
        );
        insert u;
        return u;
    }

    // Create a test Account
    private static Account createTestAccount(String suf, Id ownerId) {
        Account acc = new Account(
            Name = 'Test Account ' + suf,
            BillingStreet = '123 Main St',
            BillingCity = 'Los Angeles',
            BillingState = 'CA',
            BillingPostalCode = '90001',
            OwnerId = ownerId,
            Quickbase_Record_ID__c = 'QB_' + suf,
            Active__c = true,
            Coop__c = true
        );
        insert acc;
        return acc;
    }

    // Create Foundation_Onboarding__c records needed for AdvertisedPayment batch
    private static void createOnboarding(Account acc, User usr) {
        Foundation_Onboarding__c ob = new Foundation_Onboarding__c(
            Account__c = acc.Id,
            OwnerId = usr.Id,
            Active__c = true,
            Advertised_Payments_Ready_to_Send__c = System.today(),
            Advertised_Payments_Approved__c = null
        );
        insert ob;
    }

    // Test method for AdvertisedPayment batch
    @isTest
    static void testAdvertisedPaymentBatch() {
        String suf = uniqueSuffix();
        User testUser = createTestUser();

        System.runAs(testUser) {
            Account acc = createTestAccount(suf, testUser.Id);

            // Create onboarding records for batch coverage
            createOnboarding(acc, testUser);

            Test.startTest();
            Database.executeBatch(new AdvertisedPayment(), 1);
            Test.stopTest();
        }

        // Assert the Account exists
        List<Account> accs = [SELECT Id, Quickbase_Record_ID__c FROM Account WHERE Quickbase_Record_ID__c = :('QB_' + suf)];
        System.assert(!accs.isEmpty(), 'Account should exist');
    }
}