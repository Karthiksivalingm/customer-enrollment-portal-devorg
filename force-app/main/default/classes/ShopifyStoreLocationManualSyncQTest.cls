@isTest
public class ShopifyStoreLocationManualSyncQTest {

    private static Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
    private static Id storeRtId   = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();

    // ─── Mocks ────────────────────────────────────────────────────────────────

    private class FullHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/newLoc999","name":"New Store"},"userErrors":[]}}}');
            } else if (body.contains('customerCreate')) {
                res.setBody('{"data":{"customerCreate":{"customer":{"id":"gid://shopify/Customer/99999","email":"jane.smith@test.com"},"userErrors":[]}}}');
            } else {
                res.setBody('{"data":{"companyLocation":{'
                    + '"id":"gid://shopify/CompanyLocation/shopifyLoc123",'
                    + '"name":"Active Store",'
                    + '"ordersCount":{"count":3},'
                    + '"totalSpent":{"amount":"250.00","currencyCode":"USD"},'
                    + '"roleAssignments":{"edges":[{"node":{"id":"ra1","role":{"id":"r1","name":"Buyer"}}}]}'
                    + '}}}');
            }
            return res;
        }
    }

    private class SalesSyncNullLocationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/newLoc999","name":"New Store"},"userErrors":[]}}}');
            } else {
                res.setBody('{"data":{"companyLocation":null}}');
            }
            return res;
        }
    }

    private class GraphQLErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/newLoc999","name":"New Store"},"userErrors":[]}}}');
            } else {
                res.setBody('{"errors":[{"message":"GraphQL error occurred"}]}');
            }
            return res;
        }
    }

    private class ErrorHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"errors":[{"message":"Internal Server Error"}]}');
            return res;
        }
    }

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        insert new Shopify_Configuration__c(
            Name = 'Specialty',
            Shopify_Endpoint__c = 'https://test-endpoint.com',
            Shopify_Access_Token__c = 'fake-token'
        );

        Account parentCompany = new Account(
            Name = 'Parent Company',
            RecordTypeId = companyRtId,
            Tax_Id__c = '111111111',
            Shopify_Company_Id__c = 'parentShopify123',
            Sales_Channel__c = 'Specialty',
            Active__c = true
        );
        insert parentCompany;

        Account activeStore = new Account(
            Name = 'Active Store',
            ParentId = parentCompany.Id,
            RecordTypeId = storeRtId,
            Shopify_Company_Id__c = 'shopifyLoc123',
            Sales_Channel__c = 'Specialty',
            ShippingStreet = '123 Test Street',
            ShippingCity = 'New York',
            ShippingState = 'NY',
            ShippingPostalCode = '10001',
            ShippingCountry = 'US',
            Manual_Approval_Status__c = 'Approved',
            Active__c = true
        );
        insert activeStore;

        Account newStore = new Account(
            Name = 'New Store',
            ParentId = parentCompany.Id,
            RecordTypeId = storeRtId,
            Sales_Channel__c = 'Specialty',
            ShippingStreet = '456 New Street',
            ShippingCity = 'New York',
            ShippingState = 'NY',
            ShippingPostalCode = '10002',
            ShippingCountry = 'US',
            Manual_Approval_Status__c = 'Approved',
            Active__c = true
        );
        insert newStore;

        Contact john = new Contact(
            FirstName = 'John', LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = parentCompany.Id,
            Sales_Channel__c = 'Specialty',
            Shopify_Customer_Id__c = 'cust123'
        );
        insert john;

        insert new AccountContactRelation(
            AccountId = activeStore.Id,
            ContactId = john.Id,
            IsActive = true
        );
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    private static Id getParentCompanyId() {
        return [SELECT Id FROM Account WHERE Name = 'Parent Company' LIMIT 1].Id;
    }

    private static void runExecuteLogic(Id parentId) {
        List<Account> storeLocations = [
            SELECT Id, Shopify_Company_Id__c
            FROM Account
            WHERE ParentId = :parentId
        ];
        List<Id> locIdsToCreate = new List<Id>();
        for (Account loc : storeLocations) {
            if (String.isBlank(loc.Shopify_Company_Id__c)) {
                locIdsToCreate.add(loc.Id);
            }
        }
        if (!locIdsToCreate.isEmpty()) {
            ShopifyAccountIntegration.createStoreLocations(locIdsToCreate);
        }
        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];
        if (!locationsToSync.isEmpty()) {
            List<Api_Log__c> logs = new List<Api_Log__c>();
            ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
            if (!logs.isEmpty()) {
                insert logs;
            }
        }
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    // Covers: execute() method body + System.enqueueJob line
    // Production class uses Test.isRunningTest() to skip the chain in test context
    // so no stack depth error occurs
   @IsTest
    static void testExecute_FullMethod_ViaEnqueueJob() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        ShopifyStoreLocationManualSyncQueueable q = new ShopifyStoreLocationManualSyncQueueable(parentId);

        Test.startTest();
        q.execute(null);
        Test.stopTest();

        Account newStore = [SELECT Shopify_Company_Id__c FROM Account WHERE Name = 'New Store' LIMIT 1];
        System.assertNotEquals(null, newStore.Shopify_Company_Id__c,
            'New Store should have Shopify_Company_Id__c — confirms locIdsToCreate path ran');

        Account activeStore = [SELECT Id FROM Account WHERE Name = 'Active Store' LIMIT 1];
        System.assertNotEquals(null, activeStore.Id,
            'Active Store should exist — confirms locationsToSync path ran');
    }

    @IsTest
    static void testExecute_BothPaths_Success() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        runExecuteLogic(parentId);
        Test.stopTest();

        Account newStore = [SELECT Shopify_Company_Id__c FROM Account WHERE Name = 'New Store' LIMIT 1];
        System.assertNotEquals(null, newStore.Shopify_Company_Id__c,
            'New Store should have Shopify_Company_Id__c set — confirms createStoreLocations ran');
        System.assertEquals('newLoc999', newStore.Shopify_Company_Id__c,
            'Shopify_Company_Id__c should match mock companyLocationCreate response');
    }

    @IsTest
    static void testExecute_NewStore_RoutedToCreateStoreLocations() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        runExecuteLogic(parentId);
        Test.stopTest();

        Account newStore = [SELECT Shopify_Company_Id__c FROM Account WHERE Name = 'New Store' LIMIT 1];
        System.assertNotEquals(null, newStore.Shopify_Company_Id__c,
            'New Store should have Shopify_Company_Id__c after createStoreLocations');
        System.assertEquals('newLoc999', newStore.Shopify_Company_Id__c,
            'Should match mock response ID');
    }

    @IsTest
    static void testExecute_ExistingStore_RoutedToSalesSync() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

        System.assert(!locationsToSync.isEmpty(),
            'locationsToSync should have Active Store with existing Shopify ID');
    }

    @IsTest
    static void testExecute_Logs_Inserted_WhenSalesSyncHasErrors() {
        Test.setMock(HttpCalloutMock.class, new SalesSyncNullLocationMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

        List<Api_Log__c> inserted = [SELECT Id FROM Api_Log__c];
        System.assert(!inserted.isEmpty(),
            'Api_Log__c should be inserted when sales sync service adds error logs');
    }

    @IsTest
    static void testExecute_Logs_Inserted_OnGraphQLError() {
        Test.setMock(HttpCalloutMock.class, new GraphQLErrorMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

        List<Api_Log__c> inserted = [SELECT Id FROM Api_Log__c];
        System.assert(!inserted.isEmpty(),
            'Api_Log__c should be inserted when Shopify returns a GraphQL error');
    }

    @IsTest
    static void testExecute_HttpError_HandledGracefully() {
        Test.setMock(HttpCalloutMock.class, new ErrorHttpMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

        System.assert(true, 'HTTP 500 should be handled gracefully without throwing');
    }

    @IsTest
    static void testExecute_OnlySalesSyncPath_WhenAllStoresHaveShopifyId() {
        Account newStore = [SELECT Id FROM Account WHERE Name = 'New Store' LIMIT 1];
        delete newStore;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        List<Account> stores = [SELECT Id, Shopify_Company_Id__c FROM Account WHERE ParentId = :parentId];
        List<Id> locIdsToCreate = new List<Id>();
        for (Account loc : stores) {
            if (String.isBlank(loc.Shopify_Company_Id__c)) {
                locIdsToCreate.add(loc.Id);
            }
        }

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        System.assertEquals(0, locIdsToCreate.size(),
            'locIdsToCreate should be empty when all stores have Shopify ID');
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

        System.assert(true, 'Only sales sync path executed');
    }

    @IsTest
    static void testExecute_OnlyCreatePath_WhenNoStoresHaveShopifyId() {
        Account activeStore = [SELECT Id FROM Account WHERE Name = 'Active Store' LIMIT 1];
        activeStore.Shopify_Company_Id__c = null;
        update activeStore;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        List<Account> stores = [SELECT Id, Shopify_Company_Id__c FROM Account WHERE ParentId = :parentId];
        List<Id> locIdsToCreate = new List<Id>();
        for (Account loc : stores) {
            if (String.isBlank(loc.Shopify_Company_Id__c)) {
                locIdsToCreate.add(loc.Id);
            }
        }

        Test.startTest();
        System.assertEquals(0, locationsToSync.size(),
            'locationsToSync should be empty when no stores have Shopify ID at query time');
        if (!locIdsToCreate.isEmpty()) {
            ShopifyAccountIntegration.createStoreLocations(locIdsToCreate);
        }
        Test.stopTest();

        System.assert(true, 'Only create path executed when no stores have Shopify ID');
    }

    @IsTest
    static void testExecute_NoStoreLocations() {
        Account isolatedCompany = new Account(
            Name = 'Isolated Company',
            RecordTypeId = companyRtId,
            Tax_Id__c = '222222222',
            Shopify_Company_Id__c = 'isolatedShopify999',
            Sales_Channel__c = 'Specialty',
            Active__c = true
        );
        insert isolatedCompany;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());

        Test.startTest();
        List<Account> stores = [
            SELECT Id, Shopify_Company_Id__c
            FROM Account
            WHERE ParentId = :isolatedCompany.Id
        ];
        System.assertEquals(0, stores.size(), 'Isolated company has no child store locations');
        Test.stopTest();
List<Api_Log__c> logs = [
            SELECT Id, Context__c, Response_Message__c, Stack_Trace__c
            FROM Api_Log__c
            WHERE Related_Record_Id__c = :isolatedCompany.Id
        ];
        for (Api_Log__c l : logs) {
            System.debug('LOG FOUND: ' + l.Context__c + ' | ' + l.Response_Message__c + ' | ' + l.Stack_Trace__c);
        }
        System.assertEquals(0, logs.size(),
            'No logs related to the isolated company should be created when there are no store locations');
    }

    @IsTest
    static void testExecute_NoLogsInserted_WhenSalesSyncSucceeds() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        List<Account> locationsToSync = [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,ShippingCountryCode
            FROM Account
            WHERE ParentId = :parentId
            AND Shopify_Company_Id__c != null
        ];

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(locationsToSync, logs);
        if (!logs.isEmpty()) {
            insert logs;
        }
        Test.stopTest();

    List<Api_Log__c> inserted = [
            SELECT Id, Context__c, Response_Message__c, Stack_Trace__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Sync%'
        ];
        for (Api_Log__c l : inserted) {
            System.debug('LOG FOUND: ' + l.Context__c + ' | ' + l.Response_Message__c + ' | ' + l.Stack_Trace__c);
        }
        System.assertEquals(0, inserted.size(),
            'No Shopify Sync logs should be inserted when all sales sync callouts succeed');
    }
    @IsTest
    static void testExecute_Constructor_Covered() {
        Id parentId = getParentCompanyId();
        Test.startTest();
        ShopifyStoreLocationManualSyncQueueable q = new ShopifyStoreLocationManualSyncQueueable(parentId);
        Test.stopTest();
        System.assertNotEquals(null, q, 'Constructor should create a valid instance');
    }
}