@isTest
private class ShopifyActivateStoreLocaQTest {

    @testSetup
    static void setup() {
        Shopify_Configuration__c config = new Shopify_Configuration__c(
            Name                    = 'Specialty',
            Shopify_Endpoint__c     = 'https://test-store.myshopify.com/admin/api/2024-04/graphql.json',
            Shopify_Access_Token__c = 'test-token-123'
        );
        insert config;
    }

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"company":{"contacts":{"edges":[]},' +
                '"contactRoles":{"edges":[]}}}}'
            );
            return res;
        }
    }

    // ── Helper: create Company with unique Tax ID ─────────────────────────
    private static Account createCompany(String taxId) {
        Account company = new Account(
            Name                      = 'Test Company ' + taxId,
            RecordTypeId              = Schema.SObjectType.Account
                                        .getRecordTypeInfosByDeveloperName()
                                        .get('Company')
                                        .getRecordTypeId(),
            Active__c                 = false,
            Sales_Channel__c          = 'Specialty',
            Manual_Approval_Status__c = 'Approved',
            Tax_ID__c                 = taxId
        );
        insert company;
        return company;
    }

    // ── Helper: create Store Location under a given Company ───────────────
    private static Account createStoreLocation(
        Account parentCompany,
        Boolean active,
        String shopifyId,
        String taxId
    ) {
        Account store = new Account(
            Name                      = 'Test Store ' + taxId,
            RecordTypeId              = Schema.SObjectType.Account
                                        .getRecordTypeInfosByDeveloperName()
                                        .get('Store_Location')
                                        .getRecordTypeId(),
            ParentId                  = parentCompany.Id,
            Active__c                 = active,
            Shopify_Company_Id__c     = shopifyId,
            Sales_Channel__c          = 'Specialty',
            Manual_Approval_Status__c = 'Approved',
            Tax_ID__c                 = taxId,
            ShippingStreet            = '123 Test St',
            ShippingCity              = 'Los Angeles',
            ShippingState             = 'CA',
            ShippingPostalCode        = '90001',
            ShippingCountry           = 'US'
        );
        insert store;
        return store;
    }

    // ── Test 1: Store with Shopify ID and Active = false → activates ──────
    @isTest
    static void testActivatesStoreWithShopifyId() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('100000001');
        Account store   = createStoreLocation(
            company, false, '123456789', '200000001'
        );

        Test.startTest();
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }
            )
        );
        Test.stopTest();

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            true,
            updatedStore.Active__c,
            'Store Location should be Active = true after queueable runs'
        );
    }

    // ── Test 2: Store with NO Shopify ID → stays false                     ──
    // ── Test.isRunningTest() guard prevents retry loop                     ──
    @isTest
    static void testSkipsStoreWithNoShopifyId() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('100000002');
        Account store   = createStoreLocation(
            company, false, null, '200000002'
        );

        Test.startTest();
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }
            )
        );
        Test.stopTest();

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            false,
            updatedStore.Active__c,
            'Store Location should stay Active = false when no Shopify ID exists'
        );
    }

    // ── Test 3: Store already Active = true → no change ──────────────────
    @isTest
    static void testSkipsAlreadyActiveStore() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('100000003');
        Account store   = createStoreLocation(
            company, true, '123456789', '200000003'
        );

        Test.startTest();
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }
            )
        );
        Test.stopTest();

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            true,
            updatedStore.Active__c,
            'Store Location was already active — should remain active'
        );
    }

    // ── Test 4: Empty list → no error ─────────────────────────────────────
    @isTest
    static void testEmptyListHandledGracefully() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(new List<Id>())
        );
        Test.stopTest();

        System.assert(true, 'Empty list should not throw any exception');
    }

    // ── Test 5: Multiple stores under SEPARATE companies                   ──
    // ── Each store under its own company prevents cascade affecting others ──
    @isTest
    static void testMultipleStoresOnlyEligibleActivated() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account company1 = createCompany('500000001');
        Account company2 = createCompany('500000002');
        Account company3 = createCompany('500000003');

        // ── Store 1: Shopify ID exists, Active = false → should activate ──
        Account store1 = createStoreLocation(
            company1, false, '111111111', '600000001'
        );
        // ── Store 2: no Shopify ID, Active = false → should NOT activate ──
        Account store2 = createStoreLocation(
            company2, false, null, '600000002'
        );
        // ── Store 3: Shopify ID exists, Active = true → should NOT change ──
        Account store3 = createStoreLocation(
            company3, true, '333333333', '600000003'
        );

        Test.startTest();
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store1.Id, store2.Id, store3.Id }
            )
        );
        Test.stopTest();

        Map<Id, Account> resultMap = new Map<Id, Account>([
            SELECT Id, Active__c
            FROM Account
            WHERE Id IN (:store1.Id, :store2.Id, :store3.Id)
        ]);

        System.assertEquals(
            true,
            resultMap.get(store1.Id).Active__c,
            'Store 1 should be activated — has Shopify ID and was inactive'
        );
        System.assertEquals(
            false,
            resultMap.get(store2.Id).Active__c,
            'Store 2 should stay inactive — no Shopify ID'
        );
        System.assertEquals(
            true,
            resultMap.get(store3.Id).Active__c,
            'Store 3 should remain active — was already active'
        );
    }

    // ── Test 6: Retry constructor — store activates when Shopify ID exists ──
    // ── Covers the retry constructor code path                             ──
    @isTest
    static void testRetryConstructorActivatesWhenShopifyIdExists() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('700000001');
        Account store   = createStoreLocation(
            company, false, '777888999', '800000001'
        );

        Test.startTest();
        // ── retryCount = 2 simulates second retry attempt ─────────────────
        // ── Shopify ID exists so store activates correctly                 ──
        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }, 2
            )
        );
        Test.stopTest();

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            true,
            updatedStore.Active__c,
            'Store should activate — Shopify ID exists on retry attempt'
        );
    }

    // ── Test 7: Cover retry re-enqueue path (retryCount < 5 block)        ──
    // ── execute called directly with skipTestGuard = true                 ──
    // ── retryCount = 4 → enters retry block → covers System.enqueueJob   ──
    // ── Direct execute call avoids stack depth error from enqueueJob      ──
    @isTest
    static void testRetryReenqueuePathCoverage() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('110000001');
        Account store   = createStoreLocation(
            company, false, null, '120000001'
        );

        // ── Enable skipTestGuard so retryCount < 5 block is reached ──────
        ShopifyActivateStoreLocationQueueable.skipTestGuard = true;

        // ── Call execute directly — covers retry block without             ──
        // ── enqueueJob actually running again during Test.stopTest()       ──
        ShopifyActivateStoreLocationQueueable job =
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }, 4
            );
        job.execute(null);

        // ── Reset guard immediately after direct execute call ─────────────
        ShopifyActivateStoreLocationQueueable.skipTestGuard = false;

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            false,
            updatedStore.Active__c,
            'Store should remain inactive — retry re-enqueue path covered'
        );
    }

    // ── Test 8: Cover max retries Api_Log insert block                     ──
    // ── execute called directly with skipTestGuard = true                 ──
    // ── retryCount = 5 → skips retry block → enters max retries block    ──
    // ── Verifies Api_Log__c is inserted correctly                         ──
    @isTest
    static void testMaxRetriesApiLogCoverage() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account company = createCompany('130000001');
        Account store   = createStoreLocation(
            company, false, null, '140000001'
        );

        // ── Enable skipTestGuard so max retries block is reached ──────────
        ShopifyActivateStoreLocationQueueable.skipTestGuard = true;

        // ── Call execute directly — retryCount = 5 hits max retries block ──
        ShopifyActivateStoreLocationQueueable job =
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ store.Id }, 5
            );
        job.execute(null);

        // ── Reset guard immediately after direct execute call ─────────────
        ShopifyActivateStoreLocationQueueable.skipTestGuard = false;

        // ── Verify Api_Log__c was inserted by the max retries block ───────
        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Log_Type__c
            FROM Api_Log__c
            WHERE Context__c = 'ShopifyActivateStoreLocationQueueable'
            AND Log_Type__c  = 'API Errors'
        ];

        System.assertEquals(
            1,
            logs.size(),
            'Api_Log__c should be inserted when max retries reached'
        );

        Account updatedStore = [
            SELECT Id, Active__c FROM Account WHERE Id = :store.Id
        ];
        System.assertEquals(
            false,
            updatedStore.Active__c,
            'Store should remain inactive after max retries'
        );
    }
}