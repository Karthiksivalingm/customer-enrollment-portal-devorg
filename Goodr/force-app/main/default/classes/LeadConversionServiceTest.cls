@isTest
public class LeadConversionServiceTest {

    @testSetup
    static void setup() {
        Shopify_Configuration__c config = new Shopify_Configuration__c(
            Name = 'Specialty',
            Shopify_Access_Token__c = 'test_access_token_12345',
            Shopify_Endpoint__c = 'https://test.com'
        );
        insert config;
        
        Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
        Id storeRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();
        
        Account company = new Account(
            Name = 'Test Company',
            RecordTypeId = companyRtId,
            Tax_ID__c = '123456789',
            BillingStreet = '123 Main St',
            BillingCity = 'New York',
            BillingState = 'NY',
            BillingPostalCode = '10001',
            BillingCountry = 'US'
        );
        insert company;
        
        Account store = new Account(
            Name = 'Test Store',
            RecordTypeId = storeRtId,
            ParentId = company.Id,
            Tax_ID__c = '123456789',
            ShippingStreet = '456 Store St',
            ShippingCity = 'Brooklyn',
            ShippingState = 'NY',
            ShippingPostalCode = '11201',
            ShippingCountry = 'US'
        );
        insert store;
    }
    
    @isTest
    static void testCanConvert_QualifiedLeadWithVertical() {
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Tax_ID__c = '987654321',
            Status = 'New',
            Parent_Vertical__c = 'Active',
            Email = 'john.doe@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test',
            Country = 'US',
            // Required by validation rule Require_Sales_Channel_Sector_To_Qualify
            Sales_Channel__c = 'Specialty',
            Sector__c = 'Self Service'
        );
        insert testLead;
        testLead.Status = 'Qualified';
        update testLead;

        Test.startTest();
        Boolean result = LeadConversionService.canConvert(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testCanConvert_NotQualifiedLead() {
        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Company',
            Status = 'New',
            Parent_Vertical__c = 'Active',
            Email = 'jane.smith@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test',
            Country = 'US'
        );
        insert testLead;
        
        Test.startTest();
        Boolean result = LeadConversionService.canConvert(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(false, result);
    }
    
    @isTest
    static void testCanConvert_NoVertical() {
        Lead testLead = new Lead(
            FirstName = 'Bob',
            LastName = 'Johnson',
            Tax_ID__c = '987654321',
            Company = 'Test Company',
            Status = 'Qualified',
            Email = 'bob.johnson@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test',
            Country = 'US'
        );
        insert testLead;
        
        Test.startTest();
        Boolean result = LeadConversionService.canConvert(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(false, result);
    }
    
    @isTest
    static void testCanConvert_WithStoresWithVertical() {
        Lead testLead = new Lead(
            FirstName = 'Charlie',
            LastName = 'Brown',
            Company = 'Test Company',
            Tax_ID__c = '987654321',
            Status = 'Qualified',
            Parent_Vertical__c = 'Active',
            Email = 'charlie.brown@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test',
            Country = 'US'
        );
        insert testLead;
        testLead.Status = 'Qualified';
        update testLead;
        
        Store__c store = new Store__c(
            Lead__c = testLead.Id,
            Address__c = '789 Store Ave, Chicago, IL, 60601, US',
            Parent_Vertical__c = 'Active'
        );
        insert store;
        
        Test.startTest();
        Boolean result = LeadConversionService.canConvert(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testConvertLead_NewCompanyScenario() {
        Lead testLead = new Lead(
            FirstName = 'David',
            LastName = 'Miller',
            Company = 'New Company LLC',
            Email = 'david.miller@newcompany.com',
            Phone = '5551234567',
            Status = 'Qualified',
            Tax_ID__c = '987654321',
            Parent_Vertical__c = 'Fashion',
            Vertical__c = 'Fashion',
            Sales_Channel__c = 'Specialty',
            Street = '100 New St',
            City = 'Boston',
            State = 'MA',
            PostalCode = '02101',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        
        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();
        
        List<Account> companies = [SELECT Id, Name, Tax_ID__c FROM Account WHERE RecordType.DeveloperName = 'Company'];
        System.assertEquals(2, companies.size());
        
        List<Account> stores = [SELECT Id, Name, ParentId FROM Account WHERE RecordType.DeveloperName = 'Store_Location'];
        System.assertEquals(2, stores.size());
        
        List<Contact> contacts = [SELECT Id, Email, AccountId FROM Contact WHERE Email = 'david.miller@newcompany.com'];
        System.assertEquals(1, contacts.size());
    }
    
    @isTest
    static void testConvertLead_ExistingCompanyScenario() {
        Lead testLead = new Lead(
            FirstName = 'Sarah',
            LastName = 'Davis',
            Company = 'Test Company',
            Email = 'sarah.davis@testcompany.com',
            Phone = '5559876543',
            Status = 'Qualified',
            Tax_ID__c = '123456789',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '200 Second St',
            City = 'Austin',
            State = 'TX',
            PostalCode = '73301',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        
        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();
        
        List<Account> companies = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Company'];
        System.assertEquals(1, companies.size());
        
        List<Account> stores = [SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName = 'Store_Location'];
        System.assertEquals(2, stores.size());
        
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email = 'sarah.davis@testcompany.com'];
        System.assertEquals(1, contacts.size());
    }
    
    @isTest
    static void testConvertLead_WithStoreRecords() {
        Lead testLead = new Lead(
            FirstName = 'Emma',
            LastName = 'Thompson',
            Company = 'Multi Store Co',
            Email = 'emma.thompson@multistore.com',
            Phone = '5554445555',
            Status = 'Qualified',
            Tax_ID__c = '555666777',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '300 Main Ave',
            City = 'Seattle',
            State = 'WA',
            PostalCode = '98101',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        List<Store__c> stores = new List<Store__c>();
        stores.add(new Store__c(
            Lead__c = testLead.Id,
            Address__c = '100 First St, Seattle, WA, 98102, US',
            Parent_Vertical__c = 'Active',
            Store_Square_Footage__c = 1000
        ));
        stores.add(new Store__c(
            Lead__c = testLead.Id,
            Address__c = '200 Second St, Seattle, WA, 98103, US',
            Parent_Vertical__c = 'Active',
            Store_Square_Footage__c = 2000
        ));
        insert stores;
        
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        
        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();
        
        List<Account> storeAccounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Store_Location'];
        System.assert(storeAccounts.size() >= 2);
    }
    
    @isTest
    static void testConvertLead_WithBillingAddress() {
        Lead testLead = new Lead(
            FirstName = 'Robert',
            LastName = 'Anderson',
            Company = 'Billing Test Co',
            Email = 'robert.anderson@billing.com',
            Phone = '5556667777',
            Status = 'Qualified',
            Tax_ID__c = '333444555',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '400 Fourth St',
            City = 'Denver',
            State = 'CO',
            PostalCode = '80201',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        
        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();
        
        List<Account> companies = [SELECT Id, BillingStreet, BillingCity FROM Account WHERE RecordType.DeveloperName = 'Company' AND Tax_ID__c = '333444555'];
        System.assertEquals(1, companies.size());
    }
    
    @isTest
    static void testConvertLead_WithAllFields() {
        Lead testLead = new Lead(
            FirstName = 'Jessica',
            LastName = 'Martinez',
            Company = 'Full Fields Company',
            Email = 'jessica.martinez@fullfields.com',
            Phone = '5557778888',
            Status = 'Qualified',
            Tax_ID__c = '444555666',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Website = 'www.fullfields.com',
            Facebook__c = 'facebook.com/fullfields',
            Instagram__c = 'instagram.com/fullfields',
            Twitter__c = 'twitter.com/fullfields',
            Is_Tax_Exempt__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Is_Franchise__c = true,
            Franchise_Name__c = 'Full Fields Franchise',
            Street = '500 Fifth Ave',
            City = 'Miami',
            State = 'FL',
            PostalCode = '33101',
            Country = 'US',
            Has_Physical_Store__c = true,
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        
        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();
        
        List<Account> companies = [
            SELECT Id, Website, Facebook__c, Is_Tax_Exempt__c, Is_Franchise__c 
            FROM Account 
            WHERE RecordType.DeveloperName = 'Company' AND Tax_ID__c = '444555666'
        ];
        System.assertEquals(1, companies.size());
        System.assertEquals('www.fullfields.com', companies[0].Website);
        System.assertEquals(true, companies[0].Is_Tax_Exempt__c);
    }

    @isTest
    static void testConvertLead_EmailDuplicateInSalesforce() {
        Account existingCompany = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Company' LIMIT 1];
        insert new Contact(
            FirstName = 'Existing',
            LastName = 'User',
            Email = 'duplicate@test.com',
            AccountId = existingCompany.Id
        );

        Lead testLead = new Lead(
            FirstName = 'Dupe',
            LastName = 'User',
            Company = 'Dupe Company',
            Email = 'duplicate@test.com',
            Status = 'Qualified',
            Tax_ID__c = '111222999',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '1 Dupe St',
            City = 'Chicago',
            State = 'IL',
            PostalCode = '60601',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            LeadConversionService.convertLead(testLead.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException for duplicate email in Salesforce');
    }

    @isTest
    static void testConvertLead_EmailDuplicateInShopify() {
        Lead testLead = new Lead(
            FirstName = 'Shopify',
            LastName = 'Dupe',
            Company = 'Shopify Dupe Co',
            Email = 'shopify.dupe@test.com',
            Status = 'Qualified',
            Tax_ID__c = '777888999',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '2 Shopify St',
            City = 'Los Angeles',
            State = 'CA',
            PostalCode = '90001',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ShopifyMockDuplicateCustomer());

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            LeadConversionService.convertLead(testLead.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException for duplicate email in Shopify');
    }

    @isTest
    static void testCanConvert_StoreVerticalStaysInSyncWithLead() {
        // NOTE: A record-triggered Flow keeps Store__c.Parent_Vertical__c in
        // permanent sync with its related Lead's Parent_Vertical__c — it
        // copies the value down whenever either record is created or
        // updated, unconditionally (not just when blank). Because of this,
        // a Store__c can never actually end up with a null vertical while
        // its Lead has one set, so that negative scenario can't be produced
        // through ordinary DML and isn't tested here.
        //
        // To directly test the isStoresReady == false branch in
        // canConvert(), this Flow needs a bypass hook (e.g. a Custom
        // Permission checked in an early Decision element) that a test can
        // activate via System.runAs(). None exists yet in this org.
        //
        // In the meantime, this test documents and verifies the invariant
        // the Flow actually enforces: once the Lead has a vertical, its
        // Store__c records pick it up automatically, and canConvert()
        // correctly returns true for that fully-synced state.
        Lead testLead = new Lead(
            FirstName = 'Vert',
            LastName = 'Synced',
            Company = 'Vert Co',
            Tax_ID__c = '112233000',
            Status = 'Qualified',
            Email = 'vert.synced@test.com',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test',
            Country = 'US'
        );
        insert testLead;

        Store__c store = new Store__c(
            Lead__c = testLead.Id,
            Address__c = '10 Blank Ave, Denver, CO, 80201, US'
        );
        insert store;

        testLead.Parent_Vertical__c = 'Active';
        update testLead;

        Store__c refreshedStore = [
            SELECT Parent_Vertical__c FROM Store__c WHERE Id = :store.Id
        ];
        System.assertNotEquals(
            null,
            refreshedStore.Parent_Vertical__c,
            'Flow automation should sync the Store vertical from the Lead'
        );

        Test.startTest();
        Boolean result = LeadConversionService.canConvert(testLead.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'canConvert should return true once Lead and Store verticals are in sync');
    }

    @isTest
    static void testConvertLead_WithStoreRecords_CacheHit() {
        Lead testLead = new Lead(
            FirstName = 'Cache',
            LastName = 'Test',
            Company = 'Cache Co',
            Email = 'cache.test@test.com',
            Phone = '5550000001',
            Status = 'Qualified',
            Tax_ID__c = '998877665',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '50 Cache St',
            City = 'Phoenix',
            State = 'AZ',
            PostalCode = '85001',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        insert new List<Store__c>{
            new Store__c(
                Lead__c = testLead.Id,
                Address__c = '60 New St, Phoenix, AZ, 85002, US',
                Parent_Vertical__c = 'Active',
                Store_Square_Footage__c = 500
            ),
            new Store__c(
                Lead__c = testLead.Id,
                Address__c = '70 Another St, Phoenix, AZ, 85003, US',
                Parent_Vertical__c = 'Active',
                Store_Square_Footage__c = 800
            )
        };

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());

        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();

        List<Account> storeAccounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Store_Location' AND Tax_ID__c = '998877665'];
        System.assert(storeAccounts.size() >= 3, 'Should create store accounts for each unique Store__c address');
    }

    @isTest
    static void testConvertLead_SixPartAddress() {
        Lead testLead = new Lead(
            FirstName = 'Six',
            LastName = 'Parts',
            Company = 'Six Part Co',
            Email = 'six.parts@test.com',
            Phone = '5550000002',
            Status = 'Qualified',
            Tax_ID__c = '112233445',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '10 Main St',
            City = 'Portland',
            State = 'OR',
            PostalCode = '97201',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        insert new Store__c(
            Lead__c = testLead.Id,
            Address__c = '10 Main St, Suite 200, Portland, OR, 97201, US',
            Parent_Vertical__c = 'Active'
        );

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());

        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();

        List<Account> storeAccounts = [
            SELECT Id, ShippingStreet
            FROM Account
            WHERE RecordType.DeveloperName = 'Store_Location' AND Tax_ID__c = '112233445'
        ];
        System.assert(storeAccounts.size() >= 1, 'Store account should be created from 6-part address');
    }

    @isTest
    static void testConvertLead_FallbackAddress() {
        Lead testLead = new Lead(
            FirstName = 'Fall',
            LastName = 'Back',
            Company = 'Fallback Co',
            Email = 'fall.back@test.com',
            Phone = '5550000003',
            Status = 'Qualified',
            Tax_ID__c = '998800112',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '99 Plain St',
            City = 'Austin',
            State = 'TX',
            PostalCode = '73301',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        insert new Store__c(
            Lead__c = testLead.Id,
            Address__c = '99 Plain Street Austin',
            Parent_Vertical__c = 'Active'
        );

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());

        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();

        List<Account> storeAccounts = [
            SELECT Id FROM Account
            WHERE RecordType.DeveloperName = 'Store_Location' AND Tax_ID__c = '998800112'
        ];
        System.assert(storeAccounts.size() >= 1, 'Store account should be created even with fallback address parsing');
    }

    @isTest
    static void testConvertLead_ExistingStoreScenario() {
        // Covers handleExistingStoreScenario(): a Lead whose Tax_ID__c matches
        // an existing Company AND whose Street/City/State/PostalCode/Country
        // matches an existing Store_Location Account's billing address.
        Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
        Id storeRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();

        Account company = new Account(
            Name = 'Existing Store Match Co',
            RecordTypeId = companyRtId,
            Tax_ID__c = '222333444'
        );
        insert company;

        // Use a known-good, correctly matched US address (same city/state/zip
        // combo already used successfully elsewhere in this test class) and
        // populate both Billing AND Shipping fields — an org validation rule
        // requires a valid/complete Shipping Address on Account, while the
        // service's matching logic (findMatchingStore) compares against
        // BillingAddress.
        Account existingStore = new Account(
            Name = 'Existing Store Match Store',
            RecordTypeId = storeRtId,
            ParentId = company.Id,
            Tax_ID__c = '222333444',
            BillingStreet = '789 Store Ave',
            BillingCity = 'Chicago',
            BillingState = 'IL',
            BillingPostalCode = '60601',
            BillingCountry = 'US',
            ShippingStreet = '789 Store Ave',
            ShippingCity = 'Chicago',
            ShippingState = 'IL',
            ShippingPostalCode = '60601',
            ShippingCountry = 'US'
        );
        insert existingStore;

        Lead testLead = new Lead(
            FirstName = 'Match',
            LastName = 'Store',
            Company = 'Existing Store Match Co',
            Email = 'match.store@test.com',
            Phone = '5559990000',
            Status = 'Qualified',
            Tax_ID__c = '222333444',
            Parent_Vertical__c = 'Active',
            Sales_Channel__c = 'Specialty',
            Street = '789 Store Ave',
            City = 'Chicago',
            State = 'IL',
            PostalCode = '60601',
            Country = 'US',
            Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.',
            Terms_of_Service_Agreement__c = 'Test'
        );
        insert testLead;

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());

        Test.startTest();
        LeadConversionService.convertLead(testLead.Id);
        Test.stopTest();

        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = 'match.store@test.com'];
        System.assertEquals(1, contacts.size());
        System.assertEquals(company.Id, contacts[0].AccountId, 'Contact should be linked to the matched existing Company');

        List<Lead> updatedLeads = [SELECT Related_Account__c, Related_Contact__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(company.Id, updatedLeads[0].Related_Account__c);
        System.assertEquals(contacts[0].Id, updatedLeads[0].Related_Contact__c);

        // No new Store_Location Account should have been created for this address
        List<Account> storeAccounts = [
            SELECT Id FROM Account
            WHERE ParentId = :company.Id AND RecordType.DeveloperName = 'Store_Location'
        ];
        System.assertEquals(1, storeAccounts.size(), 'Should reuse the existing matched store, not create a new one');
    }

    public class ShopifyMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"customers": []}');
            return res;
        }
    }

    public class ShopifyMockDuplicateCustomer implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"customers": [{"id": 1, "email": "shopify.dupe@test.com"}]}');
            return res;
        }
    }
}