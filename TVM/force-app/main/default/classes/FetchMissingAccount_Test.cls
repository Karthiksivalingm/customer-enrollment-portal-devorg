@isTest
public class FetchMissingAccount_Test {
    private static String uniqueSuffix() {        
        //Long ts = Datetime.now().getTime();
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        //return ts + '_' + String.valueOf(rnd);
        return String.valueOf(rnd);
    }

    public static void setupData() {
        String suf = uniqueSuffix();

        Account acc = new Account(
            Name = 'testfd_' + suf,
            Active__c = true,
            Type = 'Dealer Group',
            BillingCity = 'indore',
            BillingStreet = 'test',
            BillingCountry = 'india',
            BillingState = 'mp',
            BillingPostalCode = '480221',
            ShippingCity = 'indore',
            ShippingCountry = 'India',
            ShippingState = 'mp',
            ShippingStreet = 'test',
            ShippingPostalCode = '480221',
            Quickbase_Record_ID__c = suf +1
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'testLast_' + suf,
            Email = 'test' + suf + '@example.com',
            AccountId = acc.Id
        );
        insert con;

        Account accRecord2 = new Account(
            Name = 'Test Acc2 ' + suf,
            BillingCity = 'Indore' + suf,
            BillingStreet = 'test4234',
            BillingCountry = 'India',
            BillingState = 'mp',
            BillingPostalCode = '480221',
            ShippingCity = 'ABCD',
            ShippingCountry = 'India',
            ShippingState = 'mp',
            ShippingStreet = 'test',
            ShippingPostalCode = '455874',
            Quickbase_Record_ID__c = suf
        );
        insert accRecord2;

        AccountContactRelation accCon = new AccountContactRelation(
            AccountId = accRecord2.Id,
            ContactId = con.Id,
            Roles = 'All'
        );
        insert accCon;
    }

    static testMethod void testFetchAccount() {       
        setupData();

        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

        Test.startTest();
            FetchMissingAccount.fetchAccount();
            FetchMissingAccount.fetchAccountNoPrimary();
            FetchMissingAccount.fetchAccountNoSecondary();
        Test.stopTest();
    }
}