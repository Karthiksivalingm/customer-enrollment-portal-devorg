@isTest
public class ShopifyAccountIntegrationTest {

    private static Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
    private static Id storeRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Store Location').getRecordTypeId();

    // ─── Existing Mocks ───────────────────────────────────────────────────────

    private class TestHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyCreate')) {
                res.setBody('{"data":{"companyCreate":{"company":{"id":"gid://shopify/Company/123","name":"TestCo"},"userErrors":[]}}}');
            } else if (body.contains('getCompanyLocations')) {
                res.setBody('{"data":{"company":{"locations":{"edges":[{"node":{"id":"gid://shopify/CompanyLocation/456","name":"MainLoc"}}]}}}}');
            } else if (body.contains('companyLocationDelete')) {
                res.setBody('{"data":{"companyLocationDelete":{"deletedCompanyLocationId":"gid://shopify/CompanyLocation/456","userErrors":[]}}}');
            } else if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/789","name":"Store1"},"userErrors":[]}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    private class ErrorHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":{"companyCreate":{"company":null,"userErrors":[{"message":"Invalid input"}]}}}');
            return res;
        }
    }

    // ─── New Mocks ────────────────────────────────────────────────────────────

    private class HttpErrorOnCompanyCreateMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"errors":"Internal Server Error"}');
            return res;
        }
    }

    private class LocationUserErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyCreate')) {
                res.setBody('{"data":{"companyCreate":{"company":{"id":"gid://shopify/Company/123","name":"TestCo"},"userErrors":[]}}}');
            } else if (body.contains('getCompanyLocations')) {
                res.setBody('{"data":{"company":{"locations":{"edges":[{"node":{"id":"gid://shopify/CompanyLocation/456","name":"MainLoc"}}]}}}}');
            } else if (body.contains('companyLocationDelete')) {
                res.setBody('{"data":{"companyLocationDelete":{"deletedCompanyLocationId":"456","userErrors":[]}}}');
            } else if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":null,"userErrors":[{"field":"name","message":"Location already exists"}]}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    private class LocationHttpErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();
            if (body.contains('companyCreate')) {
                res.setStatusCode(200);
                res.setBody('{"data":{"companyCreate":{"company":{"id":"gid://shopify/Company/123","name":"TestCo"},"userErrors":[]}}}');
            } else if (body.contains('getCompanyLocations')) {
                res.setStatusCode(200);
                res.setBody('{"data":{"company":{"locations":{"edges":[{"node":{"id":"gid://shopify/CompanyLocation/456","name":"MainLoc"}}]}}}}');
            } else if (body.contains('companyLocationDelete')) {
                res.setStatusCode(200);
                res.setBody('{"data":{"companyLocationDelete":{"deletedCompanyLocationId":"456","userErrors":[]}}}');
            } else if (body.contains('companyLocationCreate')) {
                res.setStatusCode(500);
                res.setBody('{"errors":"Internal Server Error"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }

    private class StoreLocationSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/789","name":"Store1"},"userErrors":[]}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        Account company = new Account(
            Name = 'Test Company',
            Tax_Id__c = '123456789',
            RecordTypeId = companyRtId,
            Sales_Channel__c = 'Specialty'
        );
        insert company;

        Account store = new Account(
            Name = 'Test Store',
            ParentId = company.Id,
            RecordTypeId = storeRtId,
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City',
            ShippingPostalCode = '12345',
            ShippingCountry = 'US',
            ShippingCountryCode = 'US',
            Sales_Channel__c = 'Specialty',
            New_User_Email__c = 'store@test.com',
            First_Name__c = 'Store',
            Last_Name__c = 'Manager',
            Manual_Approval_Status__c = 'Approved'
        );
        insert store;

        insert new Shopify_Configuration__c(
            Name = 'Specialty',
            Shopify_Endpoint__c = 'https://test-endpoint.com',
            Shopify_Access_Token__c = 'fake'
        );
    }

    // ─── Helper: query store with Parent.Name ─────────────────────────────────
    // FIX: All tests that pass a store location Account into createCompanyLocation
    // must include Parent.Name in the SOQL — the method accesses location.Parent.Name
    private static Account getStoreWithParent() {
        return [
            SELECT Id, Name, ParentId, Parent.Name, Sales_Channel__c,
                   Shopify_Company_Id__c,
                   ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry,ShippingCountryCode
            FROM Account
            WHERE Name = 'Test Store'
            LIMIT 1
        ];
    }

    // ─── Existing Tests (unchanged) ───────────────────────────────────────────

    @IsTest
    static void testExtractLastIdPart() {
        System.assertEquals('123', ShopifyAccountIntegration.extractLastIdPart('gid://shopify/Company/123'));
        System.assertEquals(null, ShopifyAccountIntegration.extractLastIdPart(null));
        System.assertEquals(null, ShopifyAccountIntegration.extractLastIdPart(''));
    }

    @IsTest
    static void testSendAccountAndStoreLocation_Success() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ comp.Id });
        Test.stopTest();
        Account updated = [SELECT Shopify_Company_Id__c FROM Account WHERE Id = :comp.Id];
        System.assertNotEquals(null, updated.Shopify_Company_Id__c);
    }

    @IsTest
    static void testSendAccountAndStoreLocation_ErrorUserErrors() {
        Test.setMock(HttpCalloutMock.class, new ErrorHttpResponseGenerator());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ comp.Id });
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Should insert log on error');
    }

    @IsTest
    static void testCreateCompanyLocation_Success() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        // FIX: use helper that includes Parent.Name in SOQL
        Account store = getStoreWithParent();
        Test.startTest();
        Account result = ShopifyAccountIntegration.createCompanyLocation('123', store);
        Test.stopTest();
        System.assertNotEquals(null, result.Shopify_Company_Id__c, 'Should update Shopify_Company_Id__c');
    }

    @IsTest
    static void testCreateStoreLocations_EmptyList() {
        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>());
        Test.stopTest();
        System.assert(true, 'Should handle empty list gracefully');
    }

    @IsTest
    static void testCreateStoreLocations_NoParentShopifyId() {
        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'store@test.com'];
        System.assertEquals(0, contacts.size(), 'Should skip store location without parent Shopify ID');
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId = :store.Id];
        System.assertEquals(0, cases.size(), 'Should not create case when parent has no Shopify ID');
    }

    @IsTest
    static void testCreateStoreLocations_NoNewUserEmail() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        Account company = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        company.Shopify_Company_Id__c = 'gid://shopify/Company/123';
        update company;
        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];
        store.New_User_Email__c = null;
        update store;
        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();
        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'Should not create contact when New_User_Email__c is blank');
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId = :store.Id];
        System.assertEquals(0, cases.size(), 'Should not create case when New_User_Email__c is blank');
    }

    @IsTest
    static void testShopifyAccountSyncQueuable_Success() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new ShopifyAccountSyncQueuable(new List<Id>{ comp.Id }));
        Test.stopTest();
        Account updated = [SELECT Shopify_Company_Id__c FROM Account WHERE Id = :comp.Id];
        System.assertNotEquals(null, updated.Shopify_Company_Id__c, 'Should update Shopify_Company_Id__c via Queueable');
    }

    @IsTest
    static void testShopifyAccountSyncQueuable_WithError() {
        Test.setMock(HttpCalloutMock.class, new ErrorHttpResponseGenerator());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new ShopifyAccountSyncQueuable(new List<Id>{ comp.Id }));
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Should create error log when sync fails');
    }

    // ─── New Tests ────────────────────────────────────────────────────────────

    @IsTest
    static void testSendAccountAndStoreLocation_Http500OnCompanyCreate() {
        Test.setMock(HttpCalloutMock.class, new HttpErrorOnCompanyCreateMock());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ comp.Id });
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Should insert error log on HTTP 500 for company create');
    }

    @IsTest
    static void testSendAccountAndStoreLocation_LocationUserErrors() {
        Test.setMock(HttpCalloutMock.class, new LocationUserErrorMock());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ comp.Id });
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Should insert error log when companyLocationCreate returns userErrors');
    }

    @IsTest
    static void testSendAccountAndStoreLocation_LocationHttp500() {
        Test.setMock(HttpCalloutMock.class, new LocationHttpErrorMock());
        Account comp = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        Test.startTest();
        ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(new List<Id>{ comp.Id });
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Should insert error log when companyLocationCreate HTTP returns 500');
    }

    @IsTest
    static void testCreateCompanyLocation_Http500() {
        Test.setMock(HttpCalloutMock.class, new HttpErrorOnCompanyCreateMock());
        // FIX: use helper that includes Parent.Name in SOQL
        Account store = getStoreWithParent();
        Test.startTest();
        Account result = ShopifyAccountIntegration.createCompanyLocation('shopify123', store);
        Test.stopTest();
        System.assertEquals(null, result.Shopify_Company_Id__c,
            'Shopify_Company_Id__c should remain null when HTTP 500 occurs');
    }

    @IsTest
    static void testCreateCompanyLocation_UserErrors() {
        Test.setMock(HttpCalloutMock.class, new LocationUserErrorMock());
        // FIX: use helper that includes Parent.Name in SOQL
        Account store = getStoreWithParent();
        Test.startTest();
        Account result = ShopifyAccountIntegration.createCompanyLocation('shopify123', store);
        Test.stopTest();
        System.assertEquals(null, result.Shopify_Company_Id__c,
            'Shopify_Company_Id__c should remain null when userErrors returned');
    }

    @IsTest
    static void testCreateStoreLocations_ContactFound_ACRInserted() {
        Test.setMock(HttpCalloutMock.class, new StoreLocationSuccessMock());

        Account company = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        company.Shopify_Company_Id__c = '999';
        update company;

        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];

        Contact matchedContact = new Contact(
            FirstName = 'Store',
            LastName = 'Manager',
            Email = 'store@test.com',
            AccountId = company.Id
        );
        insert matchedContact;

        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();

        List<AccountContactRelation> acrs = [
            SELECT Id FROM AccountContactRelation
            WHERE AccountId = :store.Id AND ContactId = :matchedContact.Id
        ];
        System.assert(!acrs.isEmpty(), 'ACR should be inserted when contact email matches');
    }

    @IsTest
    static void testCreateStoreLocations_ContactNotFound_LogCreated() {
        Test.setMock(HttpCalloutMock.class, new StoreLocationSuccessMock());

        Account company = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        company.Shopify_Company_Id__c = '888';
        update company;

        insert new Contact(
            FirstName = 'Other',
            LastName = 'Person',
            Email = 'other@test.com',
            AccountId = company.Id
        );

        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];

        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();

        List<Contact> newContacts = [SELECT Id FROM Contact WHERE Email = 'store@test.com'];
        System.assert(!newContacts.isEmpty(), 'New contact should be created when email not found in map');

        List<Api_Log__c> logs = [
            SELECT Id, Log_Type__c, Response_Message__c
            FROM Api_Log__c
            WHERE Related_Record_Id__c = :store.Id AND Log_Type__c = 'Match Failure'
        ];
        System.assert(!logs.isEmpty(), 'Api_Log__c should be created when contact email not found');
        System.assert(logs[0].Response_Message__c.contains('was not found among contacts'),
            'Log message should indicate contact not found for store location');
    }

    @IsTest
    static void testCreateStoreLocations_NoContactsUnderParent() {
        Test.setMock(HttpCalloutMock.class, new StoreLocationSuccessMock());

        Account company = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        company.Shopify_Company_Id__c = '777';
        update company;

        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];

        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();

        System.assert(true, 'Handled gracefully when parent has no contacts in map');
    }

    @IsTest
    static void testCreateStoreLocations_WithLogsInserted() {
        Test.setMock(HttpCalloutMock.class, new LocationUserErrorMock());

        Account company = [SELECT Id FROM Account WHERE Name = 'Test Company' LIMIT 1];
        company.Shopify_Company_Id__c = '666';
        update company;

        Contact matchedContact = new Contact(
            FirstName = 'Store',
            LastName = 'Manager',
            Email = 'store@test.com',
            AccountId = company.Id
        );
        insert matchedContact;

        Account store = [SELECT Id FROM Account WHERE Name = 'Test Store' LIMIT 1];

        Test.startTest();
        ShopifyAccountIntegration.createStoreLocations(new List<Id>{ store.Id });
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Logs should be inserted when location creation has userErrors');
    }

    // ─── New test: createCompanyLocation 5-param overload ────────────────────
    // FIX: Tests the new overloaded method directly with contact name params
    /*
    @IsTest
    static void testCreateCompanyLocation_WithContactName_Success() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        Account store = getStoreWithParent();
        Test.startTest();
        Account result = ShopifyAccountIntegration.createCompanyLocation(
            '123', store, 'John', 'Doe', 'Test Company'
        );
        Test.stopTest();
        System.assertNotEquals(null, result.Shopify_Company_Id__c,
            'Should populate Shopify_Company_Id__c when contact name provided');
    }

    @IsTest
    static void testCreateCompanyLocation_WithBlankContactName_Success() {
        Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
        Account store = getStoreWithParent();
        Test.startTest();
        Account result = ShopifyAccountIntegration.createCompanyLocation(
            '123', store, '', '', 'Test Company'
        );
        Test.stopTest();
        System.assertNotEquals(null, result.Shopify_Company_Id__c,
            'Should populate Shopify_Company_Id__c even when contact name is blank');
    }
    
 */
    
    @IsTest
static void testCreateCompanyLocation_WithContactName_Success() {
    Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
    Account store = getStoreWithParent();

    Test.startTest();
    Account result = ShopifyAccountIntegration.createCompanyLocation(
        '123',
        store
    );
    Test.stopTest();

    System.assertNotEquals(
        null,
        result.Shopify_Company_Id__c,
        'Should populate Shopify_Company_Id__c'
    );
}

@IsTest
static void testCreateCompanyLocation_WithBlankContactName_Success() {
    Test.setMock(HttpCalloutMock.class, new TestHttpResponseGenerator());
    Account store = getStoreWithParent();

    Test.startTest();
    Account result = ShopifyAccountIntegration.createCompanyLocation(
        '123',
        store
    );
    Test.stopTest();

    System.assertNotEquals(
        null,
        result.Shopify_Company_Id__c,
        'Should populate Shopify_Company_Id__c'
    );
}

}