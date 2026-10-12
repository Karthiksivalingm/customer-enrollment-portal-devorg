@isTest
public class ShopifyAssociationSyncSchedulableTest {
    private static Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();

    // ── NEW: mock so the enqueued ShopifyAssociationSyncQueueable's callout ──
    // ── doesn't fail when Test.stopTest() executes the scheduled job        ──
    private class ShopifyMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyAssignCustomerAsContact":{"companyContact":{"id":"gid://shopify/CompanyContact/1"},"userErrors":[]}}}');
            return res;
        }
    }

    @isTest
    static void testExecuteWithValidData() {
        // ── CHANGED: added BillingCountryCode so the country-based config lookup ──
        // ── (ShopifyConfigService.getConfigByCountry) resolves correctly         ──
        Account testAccount = new Account(
            Name = 'Test Account',
            Shopify_Company_Id__c = 'shopify_company_123',
            Tax_Id__c = '123456789',
            RecordTypeId = companyRtId,
            Sales_Channel__c = 'Specialty',
            BillingCountryCode = 'US'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com',
            Shopify_Customer_Id__c = 'shopify_customer_123'
        );
        insert testContact;

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();

        ShopifyAssociationSyncSchedulable schedulable = new ShopifyAssociationSyncSchedulable(
            new List<Id>{ testContact.Id }
        );

        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test Job', cronExp, schedulable);

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    // ── NEW: same scenario but with a Canadian Account, to confirm the      ──
    // ── country-resolution fix routes correctly and doesn't default to US   ──
    @isTest
    static void testExecuteWithValidData_Canada() {
        Account testAccount = new Account(
            Name = 'Test Account CA',
            Shopify_Company_Id__c = 'shopify_company_456',
            Tax_Id__c = '987654321',
            RecordTypeId = companyRtId,
            Sales_Channel__c = 'Specialty',
            BillingCountryCode = 'CA'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'ContactCA',
            AccountId = testAccount.Id,
            Email = 'testca@example.com',
            Shopify_Customer_Id__c = 'shopify_customer_456'
        );
        insert testContact;

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();

        ShopifyAssociationSyncSchedulable schedulable = new ShopifyAssociationSyncSchedulable(
            new List<Id>{ testContact.Id }
        );

        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test Job CA', cronExp, schedulable);

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @isTest
    static void testExecuteWithEmptyList() {
        Test.startTest();

        ShopifyAssociationSyncSchedulable schedulable = new ShopifyAssociationSyncSchedulable(
            new List<Id>()
        );

        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test Empty Job', cronExp, schedulable);

        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @isTest
    static void testExecuteWithoutShopifyIds() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Tax_Id__c = '123456789',
            RecordTypeId = companyRtId,
            Sales_Channel__c = 'Specialty',
            BillingCountryCode = 'US'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com'
        );
        insert testContact;

        Test.startTest();

        ShopifyAssociationSyncSchedulable schedulable = new ShopifyAssociationSyncSchedulable(
            new List<Id>{ testContact.Id }
        );

        String cronExp = '0 0 0 * * ?';
        System.schedule('Test No Shopify Job', cronExp, schedulable);

        Test.stopTest();

        // ── NEW: confirm the "still not ready" Api_Log__c entry was created  ──
        // ── instead of silently dropping this Contact, since it never had a  ──
        // ── Shopify_Customer_Id__c populated.                               ──
        Integer logCount = [
            SELECT COUNT() FROM Api_Log__c
            WHERE Context__c = 'ShopifyAssociationSyncSchedulable - Still Not Ready After Delay'
            AND Related_Record_Id__c = :testContact.Id
        ];
        System.assertEquals(1, logCount, 'Expected an Api_Log__c entry for the Contact that was never ready');
    }
}