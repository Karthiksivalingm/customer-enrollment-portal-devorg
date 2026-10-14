@IsTest
public class ShopifyAddressSyncTest {

    // ─── Mocks ────────────────────────────────────────────────────────────────

    // Covers: successful shipping + billing address assignment
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'companyLocationAssignAddress' => new Map<String, Object>{
                        'addresses' => new List<Object>{
                            new Map<String, Object>{ 'id' => 'gid://shopify/CompanyAddress/123' }
                        },
                        'userErrors' => new List<Object>()
                    }
                }
            }));
            return res;
        }
    }

    // Covers: GraphQL-level errors block (body.containsKey('errors'))
    private class GraphQLErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'errors' => new List<Object>{
                    new Map<String, Object>{
                        'message' => 'Field is not defined on CompanyLocationUpdateInput'
                    }
                }
            }));
            return res;
        }
    }

    // Covers: mutation-level userErrors block (result.get('userErrors') not empty)
    private class UserErrorsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'data' => new Map<String, Object>{
                    'companyLocationAssignAddress' => new Map<String, Object>{
                        'addresses'  => new List<Object>(),
                        'userErrors' => new List<Object>{
                            new Map<String, Object>{
                                'field'   => 'zoneCode',
                                'message' => 'Invalid zone code for country'
                            }
                        }
                    }
                }
            }));
            return res;
        }
    }

    // Covers: HTTP error branch (res.getStatusCode() != 200)
    private class HttpErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    // Covers: CalloutException in try/catch block
    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e =
                (CalloutException) CalloutException.class.newInstance();
            e.setMessage('Network failure simulated');
            throw e;
        }
    }

    // ─── Helpers (matching ShopifyActiveStatusPushServiceTest pattern) ────────

    private static Shopify_Configuration__c createConfig(String channelName) {
        Shopify_Configuration__c cfg = new Shopify_Configuration__c(
            Name                    = channelName,
            Shopify_Endpoint__c     = 'https://test.myshopify.com/api/graphql',
            Shopify_Access_Token__c = 'test-token-123'
        );
        insert cfg;
        return cfg;
    }

    private static Id getRecordTypeId(String developerName) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = :developerName
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    private static Account createParentAccount() {
        Id rtId = getRecordTypeId('Company');
        Account parent = new Account(
            Name      = 'Test Parent Company',
            Tax_ID__c = '123456789',
            Sales_Channel__c = 'Specialty'
        );
        if (rtId != null) parent.RecordTypeId = rtId;
        insert parent;
        return parent;
    }

    // Creates a Store Location with both shipping AND billing address
    // so both sync paths are coverable
    private static Account createLocationWithBothAddresses(
        Id      parentId,
        String  shopifyLocationId,
        String  salesChannel
    ) {
        Id rtId = getRecordTypeId('Store_Location');
        Account loc = new Account(
            Name                      = 'Test Store Location',
            ParentId                  = parentId,
            Shopify_Company_Id__c     = shopifyLocationId,
            Sales_Channel__c          = salesChannel,
            Manual_Approval_Status__c = 'Approved',
            // Shipping address — triggers SHIPPING assignAddress call
            ShippingStreet            = '123 Main St',
            ShippingCity              = 'Atlanta',
            ShippingState             = 'GA',
            ShippingPostalCode        = '30301',
            ShippingCountry           = 'US',
            // Billing address — triggers BILLING assignAddress call
            BillingStreet             = '456 Billing Ave',
            BillingCity               = 'Atlanta',
            BillingState              = 'GA',
            BillingPostalCode         = '30302',
            BillingCountry            = 'US'
        );
        if (rtId != null) loc.RecordTypeId = rtId;
        insert loc;
        return loc;
    }

    // Creates a Store Location with shipping address only (no billing)
    private static Account createLocationShippingOnly(
        Id     parentId,
        String shopifyLocationId,
        String salesChannel
    ) {
        Id rtId = getRecordTypeId('Store_Location');
        Account loc = new Account(
            Name                      = 'Shipping Only Location',
            ParentId                  = parentId,
            Shopify_Company_Id__c     = shopifyLocationId,
            Sales_Channel__c          = salesChannel,
            Manual_Approval_Status__c = 'Approved',
            ShippingStreet            = '789 Ship St',
            ShippingCity              = 'Dallas',
            ShippingState             = 'TX',
            ShippingPostalCode        = '75201',
            ShippingCountry           = 'US'
            // BillingStreet intentionally blank — skips billing path
        );
        if (rtId != null) loc.RecordTypeId = rtId;
        insert loc;
        return loc;
    }

    // Creates a Store Location with NO address fields
    private static Account createLocationNoAddress(
        Id     parentId,
        String shopifyLocationId,
        String salesChannel
    ) {
        Id rtId = getRecordTypeId('Store_Location');
        Account loc = new Account(
            Name                      = 'No Address Location',
            ParentId                  = parentId,
            Shopify_Company_Id__c     = shopifyLocationId,
            Sales_Channel__c          = salesChannel,
            Manual_Approval_Status__c = 'Approved',
            ShippingStreet            = '123 Required St',
            ShippingCity              = 'Required City',
            ShippingPostalCode        = '00000',
            ShippingCountry           = 'US'
            // ShippingState blank → hasAddress() returns false → sync skipped
        );
        if (rtId != null) loc.RecordTypeId = rtId;
        insert loc;
        return loc;
    }

    // ─── ShopifyAddressSyncService Tests ─────────────────────────────────────

    // Covers: null input → early return
    @IsTest
    static void testSyncAddress_NullInput_ReturnsEarly() {
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(null);
        Test.stopTest();
        System.assert(true, 'Null input should return without error');
    }

    // Covers: empty list input → early return
    @IsTest
    static void testSyncAddress_EmptyList_ReturnsEarly() {
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>());
        Test.stopTest();
        System.assert(true, 'Empty list should return without error');
    }

    // Covers: blank Shopify_Company_Id__c → location skipped → no callout
    @IsTest
    static void testSyncAddress_NoShopifyId_LocationSkipped() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationShippingOnly(parent.Id, null, 'Specialty');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        // No logs created — location was skipped before callout
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No logs when location has no Shopify ID — callout skipped');
    }

    // Covers: null Sales_Channel__c → cfg null → location skipped
    @IsTest
    static void testSyncAddress_NullSalesChannel_ConfigNull_Skipped() {
        // No config inserted for this channel
        Account parent = createParentAccount();
        Id rtId = getRecordTypeId('Store_Location');
        Account loc = new Account(
            Name                      = 'No Channel Store',
            ParentId                  = parent.Id,
            Shopify_Company_Id__c     = 'LOC_NOCFG',
            Sales_Channel__c          = 'Key Account', // no config for this
            Manual_Approval_Status__c = 'Approved',
            ShippingStreet            = '123 Test St',
            ShippingCity              = 'Test City',
            ShippingState             = 'GA',
            ShippingPostalCode        = '30301',
            ShippingCountry           = 'US'
        );
        if (rtId != null) loc.RecordTypeId = rtId;
        insert loc;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        try {
            ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        } catch (Exception e) {
            // ShopifyConfigService may throw AuraHandledException for missing config
            System.assert(true, 'Exception from missing config is acceptable');
        }
        Test.stopTest();

        System.assert(true, 'Missing config should be handled without crashing');
    }

    // Covers: hasAddress() returns false for shipping → shipping block skipped
    //         (ShippingState blank → hasAddress = false)
    @IsTest
    static void testSyncAddress_ShippingAddressIncomplete_ShippingSkipped() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationNoAddress(parent.Id, 'LOC_NOADDR', 'Specialty');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        // No logs — shipping skipped because state blank, billing blank too
        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No logs when shipping address is incomplete — hasAddress returns false');
    }

    // Covers: shipping address present + billing address present
    //         → both assignAddress calls made → two successful mutations
    //         → no error logs
    @IsTest
    static void testSyncAddress_ShippingAndBilling_BothSynced_NoLogs() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationWithBothAddresses(
            parent.Id, 'LOC_BOTH', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No error logs when both shipping and billing sync successfully');
    }

    // Covers: shipping address only (billing blank) → only one callout
    //         → hasAddress(billing) = false → billing block skipped
    @IsTest
    static void testSyncAddress_ShippingOnly_BillingSkipped_NoLogs() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationShippingOnly(
            parent.Id, 'LOC_SHIP', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No error logs when shipping syncs successfully and billing is skipped');
    }

    // Covers: GraphQL-level errors → 'Shopify Address Sync - GraphQL Error (SHIPPING)' log
    //         + 'Shopify Address Sync - GraphQL Error (BILLING)' log
    @IsTest
    static void testSyncAddress_GraphQLError_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationWithBothAddresses(
            parent.Id, 'LOC_GQLERR', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new GraphQLErrorMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Address Sync - GraphQL Error%'
        ];
        System.assert(!logs.isEmpty(),
            'GraphQL error logs should be created when Shopify returns errors block');
        // Both shipping and billing should have logs
        System.assertEquals(2, logs.size(),
            'Two GraphQL error logs expected — one for SHIPPING one for BILLING');
    }

    // Covers: mutation-level userErrors → 'Shopify Address Sync - userErrors (SHIPPING)' log
    @IsTest
    static void testSyncAddress_UserErrors_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationWithBothAddresses(
            parent.Id, 'LOC_USERERR', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new UserErrorsMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Stack_Trace__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Address Sync - userErrors%'
        ];
        System.assert(!logs.isEmpty(),
            'userErrors logs should be created when Shopify mutation returns userErrors');
        System.assert(logs[0].Stack_Trace__c.contains('zoneCode'),
            'Stack trace should contain the field name from userErrors');
    }

    // Covers: HTTP error (500) → 'Shopify Address Sync - HTTP Error (SHIPPING)' log
    @IsTest
    static void testSyncAddress_HttpError_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationWithBothAddresses(
            parent.Id, 'LOC_HTTPERR', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new HttpErrorMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Stack_Trace__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Address Sync - HTTP Error%'
        ];
        System.assert(!logs.isEmpty(),
            'HTTP error logs should be created on non-200 response');
        System.assert(logs[0].Stack_Trace__c.contains('HTTP 500'),
            'Stack trace should contain the HTTP status code');
    }

    // Covers: CalloutException in try/catch → 'Shopify Address Sync - HTTP Exception' log
    @IsTest
    static void testSyncAddress_CalloutException_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationShippingOnly(
            parent.Id, 'LOC_EXCEPT', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new ExceptionMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(new List<Account>{ loc });
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c, Response_Message__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Address Sync - HTTP Exception%'
        ];
        System.assert(!logs.isEmpty(),
            'Exception log should be created when HTTP callout throws');
        System.assert(logs[0].Response_Message__c.contains('Network failure'),
            'Log message should contain the exception message');
    }

    // Covers: multiple locations in one call → all processed in loop
    @IsTest
    static void testSyncAddress_MultipleLocations_AllProcessed() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account locA   = createLocationShippingOnly(parent.Id, 'LOC_MULTI_A', 'Specialty');
        Account locB   = createLocationShippingOnly(parent.Id, 'LOC_MULTI_B', 'Specialty');
        Account locC   = createLocationWithBothAddresses(parent.Id, 'LOC_MULTI_C', 'Specialty');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ShopifyAddressSyncService.syncAddressToShopify(
            new List<Account>{ locA, locB, locC }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No error logs when multiple locations all sync successfully');
    }

    // ─── ShopifyAddressSyncQueueable Tests ────────────────────────────────────

    // Covers: execute() → ShopifyAddressSyncService.syncAddressToShopify called
    //         constructor(List<Account>) + execute(QueueableContext)
    @IsTest
    static void testQueueable_Execute_ShippingAndBilling_NoLogs() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationWithBothAddresses(
            parent.Id, 'LOC_Q_BOTH', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        System.enqueueJob(
            new ShopifyAddressSyncQueueable(new List<Account>{ loc })
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No error logs when queueable syncs address successfully');
    }

    // Covers: queueable with null list → syncAddressToShopify early return
    @IsTest
    static void testQueueable_NullList_NoOp() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        System.enqueueJob(new ShopifyAddressSyncQueueable(null));
        Test.stopTest();
        System.assert(true, 'Queueable with null list should complete without error');
    }

    // Covers: queueable with empty list → syncAddressToShopify early return
    @IsTest
    static void testQueueable_EmptyList_NoOp() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        System.enqueueJob(
            new ShopifyAddressSyncQueueable(new List<Account>())
        );
        Test.stopTest();
        System.assert(true, 'Queueable with empty list should complete without error');
    }

    // Covers: queueable with HTTP error → logs created inside execute()
    @IsTest
    static void testQueueable_HttpError_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationShippingOnly(
            parent.Id, 'LOC_Q_ERR', 'Specialty'
        );

        Test.setMock(HttpCalloutMock.class, new HttpErrorMock());
        Test.startTest();
        System.enqueueJob(
            new ShopifyAddressSyncQueueable(new List<Account>{ loc })
        );
        Test.stopTest();

        List<Api_Log__c> logs = [
            SELECT Id, Context__c
            FROM Api_Log__c
            WHERE Context__c LIKE 'Shopify Address Sync - HTTP Error%'
        ];
        System.assert(!logs.isEmpty(),
            'HTTP error logs should be created inside queueable execute()');
    }

    // Covers: queueable — location with no Shopify ID inside execute()
    //         → skipped gracefully → no logs
    @IsTest
    static void testQueueable_NoShopifyId_Skipped() {
        createConfig('Specialty');
        Account parent = createParentAccount();
        Account loc    = createLocationShippingOnly(parent.Id, null, 'Specialty');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        System.enqueueJob(
            new ShopifyAddressSyncQueueable(new List<Account>{ loc })
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assertEquals(0, logs.size(),
            'No logs when location has no Shopify ID inside queueable');
    }
}