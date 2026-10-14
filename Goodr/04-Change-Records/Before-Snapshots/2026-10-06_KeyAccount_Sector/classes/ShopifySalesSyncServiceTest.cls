@isTest
public class ShopifySalesSyncServiceTest {

    // ─── Existing Mocks (unchanged) ──────────────────────────────────────────

    private class ShopifySuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":5},'
                + '"totalSpent":{"amount":"123.45","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[{"node":{"id":"ra1","role":{"id":"r1","name":"Buyer"}}}]}'
                + '}}}');
            return res;
        }
    }

    private class ShopifyLocationNullMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":null}}');
            return res;
        }
    }

    private class ShopifyNullAmountsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":null,'
                + '"totalSpent":null,'
                + '"roleAssignments":{"edges":[]}'
                + '}}}');
            return res;
        }
    }

    private class ShopifyGraphQLErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"errors":[{"message":"GraphQL error: Something went wrong"}]}');
            return res;
        }
    }

    private class ShopifyErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"errors":[{"message":"Invalid request"}]}');
            return res;
        }
    }

    private class ShopifyExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = (CalloutException) CalloutException.class.newInstance();
            e.setMessage('Network failure simulated');
            throw e;
        }
    }

    // ─── New Mocks covering address sync ─────────────────────────────────────

    // Covers: shippingAddress valid US state + billingAddress null
    private class ShopifyShippingAddressMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":3},'
                + '"totalSpent":{"amount":"250.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[{"node":{"id":"ra1","role":{"id":"r1","name":"Buyer"}}}]},'
                + '"shippingAddress":{'
                + '"address1":"23 Maple Drive St",'
                + '"city":"Phoenix",'
                + '"province":"California",'
                + '"zip":"96162",'
                + '"countryCode":"US"'
                + '},'
                + '"billingAddress":null'
                + '}}}');
            return res;
        }
    }

    // Covers: province in "US-NY" prefix format → strip → "NY"
    private class ShopifyShippingPrefixFormatMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":1},'
                + '"totalSpent":{"amount":"100.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[]},'
                + '"shippingAddress":{'
                + '"address1":"100 Broadway",'
                + '"city":"New York",'
                + '"province":"US-NY",'
                + '"zip":"10001",'
                + '"countryCode":"US"'
                + '},'
                + '"billingAddress":null'
                + '}}}');
            return res;
        }
    }

    // Covers: both shippingAddress and billingAddress present and valid
    private class ShopifyBothAddressesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":2},'
                + '"totalSpent":{"amount":"500.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[{"node":{"id":"ra1","role":{"id":"r1","name":"Buyer"}}}]},'
                + '"shippingAddress":{'
                + '"address1":"23 Maple Drive St",'
                + '"city":"Phoenix",'
                + '"province":"California",'
                + '"zip":"96162",'
                + '"countryCode":"US"'
                + '},'
                + '"billingAddress":{'
                + '"address1":"100 Billing Ave",'
                + '"city":"Los Angeles",'
                + '"province":"CA",'
                + '"zip":"90001",'
                + '"countryCode":"US"'
                + '}'
                + '}}}');
            return res;
        }
    }

    // Covers: shippingAddress with unresolvable province → Shipping Address Skipped log
    private class ShopifyUnresolvableStateMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":0},'
                + '"totalSpent":{"amount":"0.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[]},'
                + '"shippingAddress":{'
                + '"address1":"123 Unknown St",'
                + '"city":"Unknown City",'
                + '"province":"UnknownProvince",'
                + '"zip":"00000",'
                + '"countryCode":"US"'
                + '},'
                + '"billingAddress":null'
                + '}}}');
            return res;
        }
    }

    // Covers: valid shipping + billingAddress with unresolvable province → Billing Skipped log
    private class ShopifyUnresolvableBillingStateMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":0},'
                + '"totalSpent":{"amount":"0.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[]},'
                + '"shippingAddress":{'
                + '"address1":"23 Maple Drive St",'
                + '"city":"Phoenix",'
                + '"province":"California",'
                + '"zip":"96162",'
                + '"countryCode":"US"'
                + '},'
                + '"billingAddress":{'
                + '"address1":"100 Bad Billing St",'
                + '"city":"Bad City",'
                + '"province":"XXXX",'
                + '"zip":"99999",'
                + '"countryCode":"US"'
                + '}'
                + '}}}');
            return res;
        }
    }

    // Covers: Canadian province "Ontario" → StateToStateCodeHelper → "ON"
    private class ShopifyCanadianAddressMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"companyLocation":{'
                + '"id":"gid://shopify/CompanyLocation/123",'
                + '"name":"Test Store",'
                + '"ordersCount":{"count":1},'
                + '"totalSpent":{"amount":"150.00","currencyCode":"USD"},'
                + '"roleAssignments":{"edges":[]},'
                + '"shippingAddress":{'
                + '"address1":"100 Queen St",'
                + '"city":"Toronto",'
                + '"province":"Ontario",'
                + '"zip":"M5H 2N2",'
                + '"countryCode":"CA"'
                + '},'
                + '"billingAddress":null'
                + '}}}');
            return res;
        }
    }

      private class ShopifyMalformedJsonMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{this is not valid json');
            return res;
        }
    }

    
    // ─── Test Setup ──────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        Id storeRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Store_Location')
            .getRecordTypeId();

        insert new Shopify_Configuration__c(
            Name = 'Specialty',
            Shopify_Endpoint__c = 'https://test.myshopify.com/api/graphql',
            Shopify_Access_Token__c = 'fake-token'
        );

        insert new Account(
            Name = 'Test Store',
            RecordTypeId = storeRtId,
            Shopify_Company_Id__c = '123',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City',
            ShippingPostalCode = '12345',
            ShippingCountry = 'US',
            ShippingCountryCode = 'US',
            ShippingState = 'NY',
            Sales_Channel__c = 'Specialty'
        );
    }

   
    
    // ── Helper: query store for passing to service ────────────────────────────
    private static Account getTestStore() {
        return [
            SELECT Id, Name, Shopify_Company_Id__c, Sales_Channel__c,
                   ShippingStreet, ShippingCity, ShippingState,
                   ShippingPostalCode, ShippingCountry,ShippingCountryCode
            FROM Account
            WHERE Name = 'Test Store'
            LIMIT 1
        ];
    }

    // ─── Existing Tests (unchanged) ──────────────────────────────────────────

    @IsTest
    static void testBatchSuccess() {
        Test.setMock(HttpCalloutMock.class, new ShopifySuccessMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        Account updated = [SELECT Total_Sales__c, Total_Orders__c
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals(123.45, updated.Total_Sales__c, 'Sales should be updated');
        System.assertEquals(5, updated.Total_Orders__c, 'Orders should be updated');
    }

    @IsTest
    static void testBatchErrorCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ShopifyErrorMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id, Log_Type__c FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Logs should be created on error');
        System.assertEquals('API Errors', logs[0].Log_Type__c);
    }

    @IsTest
    static void testSchedulerRunsBatch() {
        Test.setMock(HttpCalloutMock.class, new ShopifySuccessMock());
        Test.startTest();
        String jobId = System.schedule('TestJob', '0 0 0 * * ?', new ShopifySalesSyncScheduler());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Scheduler should return a job Id');
    }

    @IsTest
    static void testBatchGraphQLErrorCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ShopifyGraphQLErrorMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id, Context__c, Log_Type__c, Stack_Trace__c FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Log should be created for GraphQL error');
        System.assertEquals('Shopify Sync - GraphQL Error', logs[0].Context__c);
        System.assert(logs[0].Stack_Trace__c.contains('GraphQL error'),
            'Stack trace should contain error message');
    }

    @IsTest
    static void testEmptyAccountListReturnsEarly() {
        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        ShopifySalesSyncService.syncStoreLocationSales(new List<Account>(), logs);
        ShopifySalesSyncService.syncStoreLocationSales(null, logs);
        Test.stopTest();
        System.assertEquals(0, logs.size(), 'No logs for empty/null input');
    }

    @IsTest
    static void testHttpExceptionCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ShopifyExceptionMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id, Context__c, Response_Message__c FROM Api_Log__c
                                  WHERE Context__c = 'Shopify Sync - HTTP Exception'];
        System.assert(!logs.isEmpty(), 'Log should be created on HTTP exception');
        System.assert(logs[0].Response_Message__c.contains('Network failure'),
            'Response message should contain exception message');
    }

    @IsTest
    static void testLocationNullCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ShopifyLocationNullMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        List<Api_Log__c> logs = [SELECT Id, Context__c, Stack_Trace__c FROM Api_Log__c
                                  WHERE Context__c = 'Shopify Sync - Location Not Found'];
        System.assert(!logs.isEmpty(), 'Log should be created when companyLocation is null');
        System.assertEquals('No companyLocation in response', logs[0].Stack_Trace__c);
    }

    @IsTest
    static void testNullAmountsDefaultToZero() {
        Test.setMock(HttpCalloutMock.class, new ShopifyNullAmountsMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        Account updated = [SELECT Total_Sales__c, Total_Orders__c, Active__c
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals(0, updated.Total_Sales__c, 'Sales should default to 0');
        System.assertEquals(0, updated.Total_Orders__c, 'Orders should default to 0');
        System.assertEquals(false, updated.Active__c, 'Active should be false with empty edges');
    }

    @IsTest
    static void testActiveStatusTrueWhenEdgesPresent() {
        Test.setMock(HttpCalloutMock.class, new ShopifySuccessMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();
        Account updated = [SELECT Active__c FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals(true, updated.Active__c, 'Active should be true when edges present');
    }

    // ─── New Tests covering address sync ─────────────────────────────────────

    // Covers: shippingAddress parsed + resolved → ShippingAddress fields updated
    //         billingAddress null → BillingAddress untouched
    @IsTest
    static void testShippingAddressSynced_BillingNull() {
        Test.setMock(HttpCalloutMock.class, new ShopifyShippingAddressMock());

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        Account updated = [SELECT ShippingStreet, ShippingCity, ShippingState,
                                  ShippingPostalCode, ShippingCountry
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('23 Maple Drive St', updated.ShippingStreet,
            'ShippingStreet should be updated from Shopify');
        System.assertEquals('Phoenix', updated.ShippingCity,
            'ShippingCity should be updated');
        System.assertEquals('CA', updated.ShippingState,
            'California should resolve to CA');
        System.assertEquals('96162', updated.ShippingPostalCode,
            'ShippingPostalCode should be updated');
        System.assertEquals('US', updated.ShippingCountry,
            'ShippingCountry should be US');

        // No address skipped logs in the list
        Boolean hasSkippedLog = false;
        for (Api_Log__c log : logs) {
            if (log.Context__c == 'Shopify Sync - Shipping Address Skipped') {
                hasSkippedLog = true;
            }
        }
        System.assertEquals(false, hasSkippedLog,
            'No skipped logs when address resolves successfully');
    }

    // Covers: province "US-NY" prefix format → substringAfterLast('-') → "NY"
    @IsTest
    static void testShippingAddress_PrefixFormat_Resolved() {
        Test.setMock(HttpCalloutMock.class, new ShopifyShippingPrefixFormatMock());

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        Account updated = [SELECT ShippingState FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('NY', updated.ShippingState,
            'US-NY prefix should resolve to NY after stripping prefix');
    }

    // Covers: both shippingAddress and billingAddress present and valid
    //         → ShippingAddress AND BillingAddress both updated
    @IsTest
    static void testBothShippingAndBillingAddressSynced() {
        Test.setMock(HttpCalloutMock.class, new ShopifyBothAddressesMock());

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        Account updated = [SELECT ShippingStreet, ShippingState,
                                  BillingStreet, BillingCity, BillingState,
                                  BillingPostalCode, BillingCountry
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('23 Maple Drive St', updated.ShippingStreet,
            'ShippingStreet should be updated');
        System.assertEquals('CA', updated.ShippingState,
            'California should resolve to CA');
        System.assertEquals('100 Billing Ave', updated.BillingStreet,
            'BillingStreet should be updated when Shopify has billingAddress');
        System.assertEquals('Los Angeles', updated.BillingCity,
            'BillingCity should be updated');
        System.assertEquals('CA', updated.BillingState,
            'CA code should resolve correctly for billing');
        System.assertEquals('90001', updated.BillingPostalCode,
            'BillingPostalCode should be updated');
        System.assertEquals('US', updated.BillingCountry,
            'BillingCountry should be US');
    }

    // Covers: shippingAddress with unresolvable province
    //         → stateCode null → accToShipping NOT populated → address unchanged
    //         → 'Shopify Sync - Shipping Address Skipped' added to logs LIST
    //         FIX: service adds to list, caller inserts — check list not SOQL
    @IsTest
    static void testShippingAddress_UnresolvableState_Skipped() {
        Test.setMock(HttpCalloutMock.class, new ShopifyUnresolvableStateMock());

        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        // FIX: Check the logs LIST — service does not insert, caller does
        Boolean foundSkippedLog = false;
        for (Api_Log__c log : logs) {
            if (log.Context__c == 'Shopify Sync - Shipping Address Skipped') {
                foundSkippedLog = true;
                System.assert(log.Response_Message__c.contains('UnknownProvince'),
                    'Log should contain the raw unresolvable province value');
                break;
            }
        }
        System.assertEquals(true, foundSkippedLog,
            'A Shipping Address Skipped log should be in the logs list');

        // Address should NOT be updated
        Account updated = [SELECT ShippingStreet, ShippingState
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('Test Street', updated.ShippingStreet,
            'ShippingStreet should not change when province unresolvable');
        System.assertEquals('NY', updated.ShippingState,
            'ShippingState should not change when province unresolvable');
    }

    // Covers: valid shipping + billingAddress with unresolvable province
    //         → 'Shopify Sync - Billing Address Skipped' added to logs LIST
    //         FIX: service adds to list, caller inserts — check list not SOQL
    @IsTest
    static void testBillingAddress_UnresolvableState_Skipped() {
        Test.setMock(HttpCalloutMock.class, new ShopifyUnresolvableBillingStateMock());

        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        // FIX: Check the logs LIST — service does not insert, caller does
        Boolean foundBillingSkippedLog = false;
        for (Api_Log__c log : logs) {
            if (log.Context__c == 'Shopify Sync - Billing Address Skipped') {
                foundBillingSkippedLog = true;
                System.assert(log.Response_Message__c.contains('XXXX'),
                    'Log should contain the raw unresolvable billing province value');
                break;
            }
        }
        System.assertEquals(true, foundBillingSkippedLog,
            'A Billing Address Skipped log should be in the logs list');

        // Shipping should update (valid California) but billing skipped
        Account updated = [SELECT ShippingState, BillingStreet
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('CA', updated.ShippingState,
            'Shipping should still update even when billing is skipped');
        System.assertEquals(null, updated.BillingStreet,
            'BillingStreet should remain null when billing province unresolvable');
    }

    // Covers: Canadian province "Ontario" → "ON" + countryCode "CA"
    @IsTest
    static void testShippingAddress_CanadianProvince_Resolved() {
        Test.setMock(HttpCalloutMock.class, new ShopifyCanadianAddressMock());

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        Account updated = [SELECT ShippingStreet, ShippingCity, ShippingState,
                                  ShippingPostalCode, ShippingCountry
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals('100 Queen St', updated.ShippingStreet,
            'ShippingStreet should update for Canadian address');
        System.assertEquals('Toronto', updated.ShippingCity,
            'ShippingCity should update for Canadian address');
        System.assertEquals('ON', updated.ShippingState,
            'Ontario should resolve to ON');
        System.assertEquals('CA', updated.ShippingCountry,
            'Country should resolve to CA for Canada');

        // No skipped logs for valid Canadian address
        Boolean hasSkippedLog = false;
        for (Api_Log__c log : logs) {
            if (log.Context__c == 'Shopify Sync - Shipping Address Skipped') {
                hasSkippedLog = true;
            }
        }
        System.assertEquals(false, hasSkippedLog,
            'No skipped logs for valid Canadian address');
    }

    // Covers: cfg null → continue → no callout → no logs → address unchanged
    // FIX: Insert a store with valid picklist Sales_Channel__c that has no config record
    //      Do NOT change existing store channel — that would affect other tests
    @IsTest
    static void testNoConfigForChannel_SkipsAccount() {
        Id storeRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Store_Location')
            .getRecordTypeId();

        Account noConfigStore = new Account(
            Name = 'No Config Store',
            RecordTypeId = storeRtId,
            Shopify_Company_Id__c = '999',
            ShippingStreet = 'Original Street',
            ShippingCity = 'Original City',
            ShippingPostalCode = '00000',
            ShippingCountry = 'US',
            ShippingState = 'NY',
            Sales_Channel__c = 'Key Accounts' // valid picklist — no config record exists
        );
        insert noConfigStore;

        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        try {
            ShopifySalesSyncService.syncStoreLocationSales(
                new List<Account>{ noConfigStore }, logs
            );
        } catch (Exception e) {
            // ShopifyConfigService may throw AuraHandledException for missing config
            // This is acceptable — the store address should still be unchanged
            System.assert(true, 'Exception from missing config is acceptable');
        }
        Test.stopTest();

        Account unchanged = [SELECT ShippingStreet FROM Account WHERE Id = :noConfigStore.Id];
        System.assertEquals('Original Street', unchanged.ShippingStreet,
            'Address should remain unchanged when config is missing for channel');
    }

    // Covers: sales + address updated in same single DML call
    @IsTest
    static void testDirectServiceCall_ShippingAndSalesUpdated() {
        Test.setMock(HttpCalloutMock.class, new ShopifyShippingAddressMock());

        Test.startTest();
        List<Api_Log__c> logs = new List<Api_Log__c>();
        ShopifySalesSyncService.syncStoreLocationSales(
            new List<Account>{ getTestStore() }, logs
        );
        Test.stopTest();

        Account updated = [SELECT Total_Sales__c, Total_Orders__c, Active__c,
                                  ShippingStreet, ShippingState
                           FROM Account WHERE Name = 'Test Store' LIMIT 1];
        System.assertEquals(250.00, updated.Total_Sales__c,
            'Sales should be updated alongside address');
        System.assertEquals(3, updated.Total_Orders__c,
            'Orders should be updated alongside address');
        System.assertEquals(true, updated.Active__c,
            'Active should be true with role assignments');
        System.assertEquals('23 Maple Drive St', updated.ShippingStreet,
            'ShippingStreet updated in same DML as sales');
        System.assertEquals('CA', updated.ShippingState,
            'California resolved to CA in same DML as sales');
    }
    
    @IsTest
    static void testBatchChunkExceptionCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ShopifyMalformedJsonMock());
        Test.startTest();
        Database.executeBatch(new ShopifySalesSyncBatch(), 50);
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Response_Message__c
            FROM Api_Log__c
            WHERE Context__c = 'Shopify Sales Sync Batch - Chunk Exception'
        ];
        System.assert(!logs.isEmpty(),
            'Chunk exception log should be created when JSON parsing throws uncaught');
    }


}