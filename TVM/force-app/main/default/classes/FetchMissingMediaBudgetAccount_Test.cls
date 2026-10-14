//Apex from FND
@isTest
public class FetchMissingMediaBudgetAccount_Test {
    
    // 🔹 helper method for suffix
    private static String uniqueSuffix() {        
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    public static void testMthd(){
        String suf = uniqueSuffix();
        
        Account acc = new Account();
        acc.Name = 'test_' + suf;
        acc.Active__c = true;
        acc.Type = 'Dealer Group';
        acc.BillingCity ='indore';
        acc.BillingStreet = 'test';
        acc.BillingCountry = 'india';
        acc.BillingState = 'mp';
        acc.BillingPostalCode ='480221';
        acc.ShippingCity = 'indore';
        acc.ShippingCountry = 'india';
        acc.ShippingState = 'mp';
        acc.ShippingStreet = 'test';
        acc.ShippingPostalCode = '480221';
        acc.Quickbase_Record_ID__c = suf; // if field exists
        insert acc;

        Contact con = new Contact();
        con.LastName = 'test1_' + suf;
        con.Email ='test' + suf + '@gmail.com';
        con.AccountId = acc.id;
        insert con;

        Account accRecord2 = new Account();
        accRecord2.Name = 'Test Acc2_' + suf;
        accRecord2.BillingCity ='indorewer';
        accRecord2.BillingStreet = 'teststreey';
        accRecord2.BillingCountry = 'Countryindia';
        accRecord2.BillingState = 'mpState';
        accRecord2.BillingPostalCode ='4802211';
        accRecord2.ShippingCity = 'indores';
        accRecord2.ShippingCountry = 'india';
        accRecord2.ShippingState = 'mp';
        accRecord2.ShippingStreet = 'testshipping';
        accRecord2.ShippingPostalCode = '480221';
        accRecord2.Quickbase_Record_ID__c = suf + '1'; // if field exists
        insert accRecord2;

        AccountContactRelation accCon = new AccountContactRelation();
        accCon.AccountId = accRecord2.id;
        accCon.ContactId = con.Id;
        accCon.Roles = 'All';
        insert accCon;

        // FetchMissingMediaBudgetAccount.fetchAccount();
    }

    static testMethod void testFetchAccount(){
        testMthd();
        
        Test.startTest();
        FetchMissingMediaBudgetAccount.fetchAccount();
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        Test.stopTest();
        
        // Assertions (example – update based on actual logic in fetchAccount())
        List<Account> accList = [SELECT Id, Name FROM Account WHERE Name LIKE 'test_%' OR Name LIKE 'Test Acc2_%'];
        System.assertEquals(2, accList.size(), 'Two test Accounts should exist');
    }
}