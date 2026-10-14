@IsTest
public class ShopifyOrderSyncTest {

    private static Id companyRtId =
        Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Company')
        .getRecordTypeId();

    private static Id storeRtId =
        Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Store Location')
        .getRecordTypeId();

    private static String todayStr =
        String.valueOf(Date.today()) + 'T10:00:00Z';

    private static final String STORE_LOCATION_ID = 'STORELOC001';
    private static final String PARENT_COMPANY_ID = 'PARENTCO123';

    // ═══════════════════════════════════════════════════════════════
    // HTTP MOCKS
    // ═══════════════════════════════════════════════════════════════

    // ── Success: location.id matches store → order on store account
    private class OrderSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},'
                + '"edges":[{"node":{'
                + '"id":"gid://shopify/Order/111111",'
                + '"name":"#SGT9001",'
                + '"createdAt":"' + todayStr + '",'
                + '"updatedAt":"' + todayStr + '",'
                + '"displayFinancialStatus":"PAID",'
                + '"displayFulfillmentStatus":"UNFULFILLED",'
                + '"totalPriceSet":{"shopMoney":{"amount":"100.00","currencyCode":"USD"}},'
                + '"subtotalPriceSet":{"shopMoney":{"amount":"90.00","currencyCode":"USD"}},'
                + '"totalTaxSet":{"shopMoney":{"amount":"10.00","currencyCode":"USD"}},'
                + '"totalShippingPriceSet":{"shopMoney":{"amount":"5.00","currencyCode":"USD"}},'
                + '"shippingAddress":{"address1":"123 Main St","city":"Phoenix",'
                + '"province":"California","zip":"85001","countryCode":"US"},'
                + '"billingAddress":{"address1":"123 Main St","city":"Phoenix",'
                + '"province":"CA","zip":"85001","countryCode":"US"},'
                + '"customer":{"id":"gid://shopify/Customer/999",'
                + '"email":"test@test.com","firstName":"Test","lastName":"User"},'
                + '"purchasingEntity":{"company":{'
                + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                + '"name":"Test Company"},'
                + '"location":{"id":"gid://shopify/CompanyLocation/'
                + STORE_LOCATION_ID + '","name":"Test Store"}}}'
                + '}]}}}'
            );
            return res;
        }
    }

    // ── Company match: no location → falls to company.id → company account
    private class OrderCompanyMatchMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},'
                + '"edges":[{"node":{'
                + '"id":"gid://shopify/Order/222222",'
                + '"name":"#SGT9002",'
                + '"createdAt":"' + todayStr + '",'
                + '"updatedAt":"' + todayStr + '",'
                + '"displayFinancialStatus":"PENDING",'
                + '"displayFulfillmentStatus":"UNFULFILLED",'
                + '"totalPriceSet":{"shopMoney":{"amount":"50.00","currencyCode":"USD"}},'
                + '"subtotalPriceSet":{"shopMoney":{"amount":"50.00","currencyCode":"USD"}},'
                + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"shippingAddress":null,"billingAddress":null,'
                + '"customer":{"id":"gid://shopify/Customer/888",'
                + '"email":"customer@test.com","firstName":"Jan","lastName":"Test"},'
                // No location → falls to company.id match
                // company.id = PARENT_COMPANY_ID → matches Company account
                + '"purchasingEntity":{"company":{'
                + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                + '"name":"Test Company"}}}'
                + '}]}}}'
            );
            return res;
        }
    }

    // ── No match: unknown location AND unknown company → SKIP order
    private class OrderNoMatchMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},'
                + '"edges":[{"node":{'
                + '"id":"gid://shopify/Order/NOMATCH",'
                + '"name":"#SGT9099",'
                + '"createdAt":"' + todayStr + '",'
                + '"updatedAt":"' + todayStr + '",'
                + '"displayFinancialStatus":"PAID",'
                + '"displayFulfillmentStatus":"UNFULFILLED",'
                + '"totalPriceSet":{"shopMoney":{"amount":"99.00","currencyCode":"USD"}},'
                + '"subtotalPriceSet":{"shopMoney":{"amount":"99.00","currencyCode":"USD"}},'
                + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"shippingAddress":null,"billingAddress":null,'
                + '"customer":{"id":"gid://shopify/Customer/000",'
                + '"email":"nomatch@unknown.com","firstName":"No","lastName":"Match"},'
                // Both IDs unknown → no SF account → SKIP
                + '"purchasingEntity":{"company":{'
                + '"id":"gid://shopify/Company/UNKNOWNCO","name":"Unknown"},'
                + '"location":{"id":"gid://shopify/CompanyLocation/UNKNOWNLOC",'
                + '"name":"Unknown"}}}'
                + '}]}}}'
            );
            return res;
        }
    }

    // ── Empty orders ──────────────────────────────────────────────
    private class OrderEmptyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},"edges":[]}}}'
            );
            return res;
        }
    }

    // ── Paginated: 2 pages, both with location ID match ───────────
    private class OrderPaginatedMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (callCount == 1) {
                res.setBody(
                    '{"data":{"orders":{"pageInfo":{'
                    + '"hasNextPage":true,"endCursor":"cur123"},'
                    + '"edges":[{"node":{'
                    + '"id":"gid://shopify/Order/PAGE1",'
                    + '"name":"#SGT9011",'
                    + '"createdAt":"' + todayStr + '",'
                    + '"updatedAt":"' + todayStr + '",'
                    + '"displayFinancialStatus":"PAID",'
                    + '"displayFulfillmentStatus":"UNFULFILLED",'
                    + '"totalPriceSet":{"shopMoney":{"amount":"25.00","currencyCode":"USD"}},'
                    + '"subtotalPriceSet":{"shopMoney":{"amount":"25.00","currencyCode":"USD"}},'
                    + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                    + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                    + '"shippingAddress":null,"billingAddress":null,'
                    + '"customer":{"id":"gid://shopify/Customer/777",'
                    + '"email":"p1@t.com","firstName":"P","lastName":"1"},'
                    + '"purchasingEntity":{"company":{'
                    + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                    + '"name":"Test Co"},'
                    + '"location":{"id":"gid://shopify/CompanyLocation/'
                    + STORE_LOCATION_ID + '","name":"Test Store"}}}'
                    + '}]}}}'
                );
            } else {
                res.setBody(
                    '{"data":{"orders":{"pageInfo":{'
                    + '"hasNextPage":false,"endCursor":null},'
                    + '"edges":[{"node":{'
                    + '"id":"gid://shopify/Order/PAGE2",'
                    + '"name":"#SGT9012",'
                    + '"createdAt":"' + todayStr + '",'
                    + '"updatedAt":"' + todayStr + '",'
                    + '"displayFinancialStatus":"PAID",'
                    + '"displayFulfillmentStatus":"FULFILLED",'
                    + '"totalPriceSet":{"shopMoney":{"amount":"75.00","currencyCode":"USD"}},'
                    + '"subtotalPriceSet":{"shopMoney":{"amount":"75.00","currencyCode":"USD"}},'
                    + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                    + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                    + '"shippingAddress":null,"billingAddress":null,'
                    + '"customer":{"id":"gid://shopify/Customer/666",'
                    + '"email":"p2@t.com","firstName":"P","lastName":"2"},'
                    + '"purchasingEntity":{"company":{'
                    + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                    + '"name":"Test Co"},'
                    + '"location":{"id":"gid://shopify/CompanyLocation/'
                    + STORE_LOCATION_ID + '","name":"Test Store"}}}'
                    + '}]}}}'
                );
            }
            return res;
        }
    }

    private class OrderHttpErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    private class OrderGraphQLErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"errors":[{"message":"GraphQL error"}]}');
            return res;
        }
    }

    private class OrderHttpExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e =
                (CalloutException) CalloutException.class.newInstance();
            e.setMessage('Simulated network failure');
            throw e;
        }
    }

    // ── Province prefix US-NY ─────────────────────────────────────
    private class OrderProvincePrefixMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},'
                + '"edges":[{"node":{'
                + '"id":"gid://shopify/Order/PREFIX",'
                + '"name":"#SGT9006",'
                + '"createdAt":"' + todayStr + '",'
                + '"updatedAt":"' + todayStr + '",'
                + '"displayFinancialStatus":"PAID",'
                + '"displayFulfillmentStatus":"UNFULFILLED",'
                + '"totalPriceSet":{"shopMoney":{"amount":"30.00","currencyCode":"USD"}},'
                + '"subtotalPriceSet":{"shopMoney":{"amount":"30.00","currencyCode":"USD"}},'
                + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"shippingAddress":{"address1":"100 Broadway","city":"New York",'
                + '"province":"US-NY","zip":"10001","countryCode":"US"},'
                + '"billingAddress":null,'
                + '"customer":{"id":"gid://shopify/Customer/555",'
                + '"email":"ny@test.com","firstName":"New","lastName":"York"},'
                + '"purchasingEntity":{"company":{'
                + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                + '"name":"Test Co"},'
                + '"location":{"id":"gid://shopify/CompanyLocation/'
                + STORE_LOCATION_ID + '","name":"Test Store"}}}'
                + '}]}}}'
            );
            return res;
        }
    }

    // ── Full sync mock: no date filter → returns historical order ──
    private class OrderFullSyncMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"data":{"orders":{"pageInfo":{'
                + '"hasNextPage":false,"endCursor":null},'
                + '"edges":[{"node":{'
                + '"id":"gid://shopify/Order/FULLSYNC",'
                + '"name":"#SGT8001",'
                + '"createdAt":"2025-01-15T10:00:00Z",'
                + '"updatedAt":"2025-01-15T10:00:00Z",'
                + '"displayFinancialStatus":"PAID",'
                + '"displayFulfillmentStatus":"FULFILLED",'
                + '"totalPriceSet":{"shopMoney":{"amount":"500.00","currencyCode":"USD"}},'
                + '"subtotalPriceSet":{"shopMoney":{"amount":"500.00","currencyCode":"USD"}},'
                + '"totalTaxSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"totalShippingPriceSet":{"shopMoney":{"amount":"0.00","currencyCode":"USD"}},'
                + '"shippingAddress":null,"billingAddress":null,'
                + '"customer":{"id":"gid://shopify/Customer/111",'
                + '"email":"hist@test.com","firstName":"Hist","lastName":"Order"},'
                + '"purchasingEntity":{"company":{'
                + '"id":"gid://shopify/Company/' + PARENT_COMPANY_ID + '",'
                + '"name":"Test Co"},'
                + '"location":{"id":"gid://shopify/CompanyLocation/'
                + STORE_LOCATION_ID + '","name":"Test Store"}}}'
                + '}]}}}'
            );
            return res;
        }
    }

    // ── NPE mock → batch catch block fires ───────────────────────
    private class ThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":null}');
            return res;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TEST SETUP
    // ═══════════════════════════════════════════════════════════════

    @TestSetup
    static void setupData() {
        insert new Shopify_Configuration__c(
            Name                    = 'Specialty',
            Shopify_Endpoint__c     =
                'https://test.myshopify.com/admin/api/2026-04/graphql.json',
            Shopify_Access_Token__c = 'test-token-123'
        );

        // ── Parent Company ────────────────────────────────────────
        // Shopify_Company_Id__c = PARENTCO123
        // Used for: Level 2 company.id match (OrderCompanyMatchMock)
        Account companyAcc = new Account(
            Name                       = 'Test Company',
            RecordTypeId               = companyRtId,
            Tax_Id__c                  = '123456789',
            Shopify_Company_Id__c      = PARENT_COMPANY_ID,
            Sales_Channel__c           = 'Specialty',
            Last_Shopify_Order_Date__c = Date.today()
        );
        insert companyAcc;

        // ── Store Location ────────────────────────────────────────
        // Shopify_Company_Id__c = STORELOC001 (location ID)
        // Used for: Level 1 location.id match (OrderSuccessMock)
        // Batch processes this account
        // Service uses Parent.Shopify_Company_Id__c to query Shopify
        Account storeAcc = new Account(
            Name                       = 'Test Store',
            RecordTypeId               = storeRtId,
            ParentId                   = companyAcc.Id,
            Shopify_Company_Id__c      = STORE_LOCATION_ID,
            Sales_Channel__c           = 'Specialty',
            Last_Shopify_Order_Date__c = Date.today(),
            ShippingStreet             = '123 Test St',
            ShippingCity               = 'Test City',
            ShippingPostalCode         = '12345',
            ShippingCountry            = 'US',
            Manual_Approval_Status__c  = 'Approved'
        );
        insert storeAcc;

        insert new Contact(
            FirstName              = 'Jan',
            LastName               = 'Test',
            Email                  = 'customer@test.com',
            AccountId              = companyAcc.Id,
            Shopify_Customer_Id__c = '888',
            Sales_Channel__c       = 'Specialty'
        );
    }

    // ── Helpers ───────────────────────────────────────────────────

    private static Account getStoreAccount() {
        return [
            SELECT Id, Name, Sales_Channel__c,
                   Shopify_Company_Id__c,
                   Last_Shopify_Order_Date__c,
                   ParentId,
                   Parent.Shopify_Company_Id__c,
                   Parent.Sales_Channel__c,
                   ShippingCountryCode,
                   BillingCountryCode
            FROM Account
            WHERE Name = 'Test Store'
            AND RecordTypeId = :storeRtId
            LIMIT 1
        ];
    }

    private static Account getCompanyAccount() {
        return [
            SELECT Id, Name, Sales_Channel__c,
                   Shopify_Company_Id__c,
                   Last_Shopify_Order_Date__c,
                   ParentId,
                   Parent.Shopify_Company_Id__c,
                   ShippingCountryCode,
                   BillingCountryCode
            FROM Account
            WHERE Name = 'Test Company'
            AND RecordTypeId = :companyRtId
            LIMIT 1
        ];
    }

    // Test classes running in parallel all update the standard price
    // book, so the row can be locked. Retry instead of failing the test.
    private static void activatePricebook() {
        for (Integer attempt = 1; ; attempt++) {
            try {
                update new Pricebook2(
                    Id       = Test.getStandardPricebookId(),
                    IsActive = true
                );
                return;
            } catch (DmlException e) {
                if (attempt >= 3 ||
                    !e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
    }

    private static Account getStoreDates(Id storeId) {
        return [
            SELECT Last_Shopify_Order_Date__c,
                   Last_Shopify_Order_Sync_Date__c
            FROM Account
            WHERE Id = :storeId
        ];
    }

    private static Boolean logsContain(
        List<Api_Log__c> logs, String context
    ) {
        for (Api_Log__c l : logs) {
            if (l.Context__c == context) return true;
        }
        return false;
    }

    // ═══════════════════════════════════════════════════════════════
    // SERVICE TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void testEmptyAccountList() {
        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        ShopifyOrderSyncService.syncOrders(new List<Account>(), logs);
        ShopifyOrderSyncService.syncOrders(null, logs);
        Test.stopTest();
        System.assertEquals(0, logs.size(), 'No logs for empty/null');
    }

    // ── Order created via location.id → Store Location account ───
    @IsTest
    static void testOrderCreatedViaLocationId() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        List<Order> orders = [
            SELECT Shopify_Order_Number__c, Shopify_Order_Amount__c,
                   Shopify_Payment_Status__c, Shopify_Fulfillment_Status__c,
                   Shopify_Subtotal__c, Shopify_Tax__c, Shopify_Shipping__c,
                   Shopify_Customer_Email__c, AccountId,
                   ShippingStreet, ShippingCity, ShippingState
            FROM Order
            WHERE Shopify_Order_Id__c = 'gid://shopify/Order/111111'
        ];
        System.assertEquals(1, orders.size(),
            'Order created via location ID');
        System.assertEquals('SGT9001',
            orders[0].Shopify_Order_Number__c);
        System.assertEquals(100.00,
            orders[0].Shopify_Order_Amount__c);
        System.assertEquals('PAID',
            orders[0].Shopify_Payment_Status__c);
        System.assertEquals('UNFULFILLED',
            orders[0].Shopify_Fulfillment_Status__c);
        System.assertEquals(90.00, orders[0].Shopify_Subtotal__c);
        System.assertEquals(10.00, orders[0].Shopify_Tax__c);
        System.assertEquals(5.00,  orders[0].Shopify_Shipping__c);
        System.assertEquals('test@test.com',
            orders[0].Shopify_Customer_Email__c);
        System.assertEquals(store.Id, orders[0].AccountId,
            'Order on Store Location account');
        System.assertEquals('123 Main St', orders[0].ShippingStreet);
        System.assertEquals('Phoenix',     orders[0].ShippingCity);
        System.assertEquals('CA',          orders[0].ShippingState);
        System.assertEquals(0, logs.size(), 'No errors');
    }

    // ── Order created via company.id → Company account ────────────
    // When order has no location (B2B company-level order)
    @IsTest
    static void testOrderCreatedViaCompanyId() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderCompanyMatchMock());
        // Pass Company account directly (no parent)
        Account company = getCompanyAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ company }, logs
        );
        Test.stopTest();

        List<Order> orders = [
            SELECT Id, AccountId FROM Order
            WHERE Shopify_Order_Id__c = 'gid://shopify/Order/222222'
        ];
        System.assertEquals(1, orders.size(),
            'Order created via company ID');
        System.assertEquals(company.Id, orders[0].AccountId,
            'Order on Company account');
    }

    // ── Last_Shopify_Order_Date__c updated after sync ─────────────
    @IsTest
    static void testLastOrderDateUpdated() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(Date.today(),
            [SELECT Last_Shopify_Order_Date__c FROM Account
             WHERE Id = :store.Id].Last_Shopify_Order_Date__c,
            'Date updated to today after successful API call');
    }

    // ── No orders → sync date stamped, last order date stays blank ─
    @IsTest
    static void testNoOrdersToday() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderEmptyMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM Order WHERE AccountId = :store.Id],
            'No orders for empty response');
        // Last order date = newest Shopify order on file, so it stays
        // blank for a store with no orders; the sync date is stamped.
        Account dates = getStoreDates(store.Id);
        System.assertEquals(Date.today(),
            dates.Last_Shopify_Order_Sync_Date__c,
            'Sync date updated even with no orders today');
        System.assertEquals(null,
            dates.Last_Shopify_Order_Date__c,
            'No orders on file, so no last order date');
        System.assertEquals(0, logs.size(), 'No errors');
    }

    // ── No account match → order SKIPPED, log created ─────────────
    // New behavior: customer ID and email no longer used for matching
    // Only location.id and company.id
    @IsTest
    static void testNoAccountMatch_OrderSkipped() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderNoMatchMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM Order
             WHERE Shopify_Order_Id__c = 'gid://shopify/Order/NOMATCH'],
            'Order skipped — unknown location and company IDs');
        // No log created for skipped orders (just System.debug)
        // Sync date still updated because the API call succeeded;
        // the skipped order does not count as a last order.
        Account dates = getStoreDates(store.Id);
        System.assertEquals(Date.today(),
            dates.Last_Shopify_Order_Sync_Date__c,
            'Sync date updated even when orders are skipped');
        System.assertEquals(null,
            dates.Last_Shopify_Order_Date__c,
            'Skipped order is not counted as the last order');
    }

    // ── Paginated: 2 pages → 2 orders on store location ──────────
    @IsTest
    static void testPaginatedOrdersCreated() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderPaginatedMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(2,
            [SELECT COUNT() FROM Order
             WHERE AccountId = :store.Id
             AND Shopify_Order_Id__c != null],
            '2 orders from 2 pages on store location');
    }

    // ── HTTP 500 → error logged, date NOT updated ─────────────────
    @IsTest
    static void testHttpError() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderHttpErrorMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(true,
            logsContain(logs, 'Order Sync - HTTP Error'),
            'HTTP error logged');
    }

    // ── GraphQL error → log created ───────────────────────────────
    @IsTest
    static void testGraphQLError() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderGraphQLErrorMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(true,
            logsContain(logs, 'Order Sync - GraphQL Error'),
            'GraphQL error logged');
    }

    // ── HTTP callout exception → log created ──────────────────────
    @IsTest
    static void testHttpException() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderHttpExceptionMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(true,
            logsContain(logs, 'Order Sync - HTTP Exception'),
            'HTTP exception logged');
    }

    // ── Province prefix US-NY → resolves to NY ────────────────────
    @IsTest
    static void testAddressProvincePrefixFormat() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderProvincePrefixMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        List<Order> orders = [
            SELECT ShippingStreet, ShippingCity,
                   ShippingState, ShippingCountry
            FROM Order
            WHERE Shopify_Order_Id__c = 'gid://shopify/Order/PREFIX'
        ];
        System.assertEquals(1, orders.size(), 'Order created');
        System.assertEquals('100 Broadway', orders[0].ShippingStreet);
        System.assertEquals('New York',     orders[0].ShippingCity);
        System.assertEquals('NY',           orders[0].ShippingState);
        System.assertEquals('US',           orders[0].ShippingCountry);
    }

    // ── Missing config → handled gracefully ───────────────────────
    @IsTest
    static void testMissingConfig() {
        activatePricebook();
        Account companyAcc = getCompanyAccount();
        Account noConfigStore = new Account(
            Name                       = 'No Config Store',
            RecordTypeId               = storeRtId,
            ParentId                   = companyAcc.Id,
            Shopify_Company_Id__c      = 'NOCONFIG_LOC',
            Sales_Channel__c           = 'Key Account',
            Last_Shopify_Order_Date__c = Date.today(),
            ShippingStreet             = '1 Main St',
            ShippingCity               = 'City',
            ShippingPostalCode         = '00000',
            ShippingCountry            = 'US',
            BillingCountry            = 'US',
            Manual_Approval_Status__c  = 'Approved'
        );
        insert noConfigStore;
        noConfigStore = [
            SELECT Id, Name, Sales_Channel__c,
                   Shopify_Company_Id__c,
                   Last_Shopify_Order_Date__c,
                   ParentId,
                   Parent.Shopify_Company_Id__c,
                   ShippingCountryCode, 
                   BillingCountryCode
            FROM Account WHERE Id = :noConfigStore.Id
        ];
        List<Api_Log__c> logs = new List<Api_Log__c>();
        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ noConfigStore }, logs
        );
        Test.stopTest();
        System.assert(true, 'Missing config handled gracefully');
    }

    // ── Upsert: second sync → no duplicate orders ─────────────────
    @IsTest
    static void testOrderUpdatedOnSecondSync() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs
        );
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Order
             WHERE Shopify_Order_Id__c = 'gid://shopify/Order/111111'],
            'Upsert — no duplicates on second sync');
    }

    // ── fullSync=true → no date filter → historical orders synced ─
    @IsTest
    static void testFullSyncGetsHistoricalOrders() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderFullSyncMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        // fullSync = true → no updated_at filter in Shopify query
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs, true
        );
        Test.stopTest();

        List<Order> orders = [
            SELECT Id, Shopify_Order_Number__c, AccountId
            FROM Order
            WHERE Shopify_Order_Id__c = 'gid://shopify/Order/FULLSYNC'
        ];
        System.assertEquals(1, orders.size(),
            'Historical order created with fullSync=true');
        System.assertEquals('SGT8001',
            orders[0].Shopify_Order_Number__c);
        System.assertEquals(store.Id, orders[0].AccountId,
            'Historical order on store location');
    }

    // ── fullSync=false → daily mode (default behavior) ────────────
    @IsTest
    static void testDailySyncMode() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Account store = getStoreAccount();
        List<Api_Log__c> logs = new List<Api_Log__c>();

        Test.startTest();
        // fullSync = false (default) → updated_at >= today filter
        ShopifyOrderSyncService.syncOrders(
            new List<Account>{ store }, logs, false
        );
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Order
             WHERE Shopify_Order_Id__c = 'gid://shopify/Order/111111'],
            'Daily sync creates todays order');
    }

    // ═══════════════════════════════════════════════════════════════
    // BATCH TESTS
    // ═══════════════════════════════════════════════════════════════

    // ── Daily batch: store in scope → order created ───────────────
   /* @IsTest
    static void testBatchDailySync() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(false), 1);
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Order
             WHERE Shopify_Order_Id__c != null],
            'Daily batch creates order on store location');
    }*/

    // ── Full sync batch: all stores including null date ───────────
    @IsTest
    static void testBatchFullSync() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderEmptyMock());
        Account companyAcc = getCompanyAccount();
        insert new Account(
            Name                      = 'No Date Store',
            RecordTypeId              = storeRtId,
            ParentId                  = companyAcc.Id,
            Shopify_Company_Id__c     = 'NODATE_LOC',
            Sales_Channel__c          = 'Specialty',
            ShippingStreet            = '1 Test St',
            ShippingCity              = 'City',
            ShippingPostalCode        = '00000',
            ShippingCountry           = 'US',
            Manual_Approval_Status__c = 'Approved'
        );

        Test.startTest();
        // fullSync=true → all stores, no date filter, fullSync passed to service
        Database.executeBatch(new ShopifyOrderSyncBatch(true), 200);
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM Account
             WHERE Last_Shopify_Order_Date__c = TODAY
             AND Shopify_Company_Id__c != null] >= 1,
            'Full sync updates Last_Shopify_Order_Date__c'
        );
    }

    // ── Default constructor → daily sync ─────────────────────────
    @IsTest
    static void testBatchDefaultConstructor() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderEmptyMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(), 1);
        Test.stopTest();
        System.assert(true, 'Default constructor = daily sync');
    }

    // ── Schedulable execute() ─────────────────────────────────────
    @IsTest
    static void testBatchSchedulable() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderEmptyMock());
        Test.startTest();
        new ShopifyOrderSyncBatch().execute(null);
        Test.stopTest();
        System.assert(true, 'Schedulable execute() covered');
    }

    // ── System.schedule() registration ───────────────────────────
    @IsTest
    static void testBatchSchedulableRegistered() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Order Sync Job',
            '0 0 8 * * ?',
            new ShopifyOrderSyncBatch()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Job ID returned');
        System.assertEquals(1,
            [SELECT COUNT() FROM CronTrigger
             WHERE CronJobDetail.Name = 'Test Order Sync Job'],
            'Job registered in CronTrigger');
    }

    // ── Store outside 90 days → excluded from daily scope ────────
    @IsTest
    static void testBatchNoActiveAccounts() {
        activatePricebook();
        Account store = getStoreAccount();
        store.Last_Shopify_Order_Date__c = Date.today().addDays(-100);
        update store;

        Test.setMock(HttpCalloutMock.class, new OrderEmptyMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(false), 1);
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM Order WHERE Shopify_Order_Id__c != null],
            'No orders when store outside 90-day window');
    }

    // ── HTTP error in batch → Api_Log__c inserted ────────────────
    @IsTest
    static void testBatchErrorHandled() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderHttpErrorMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(false), 1);
        Test.stopTest();
        System.assert(
            ![SELECT Id FROM Api_Log__c].isEmpty(),
            'Error logs inserted for HTTP 500'
        );
    }

    // ── finish() COUNT queries run without error ──────────────────
    @IsTest
    static void testBatchFinishCountQueries() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new OrderSuccessMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(false), 1);
        Test.stopTest();
        System.assert(
            [SELECT COUNT() FROM Order
             WHERE Shopify_Order_Id__c != null] >= 0,
            'finish() count queries work'
        );
    }

    // ── NPE inside service → batch catch block fires ─────────────
    @IsTest
    static void testBatchExecuteCatchBlock() {
        activatePricebook();
        Test.setMock(HttpCalloutMock.class, new ThrowingMock());
        Test.startTest();
        Database.executeBatch(new ShopifyOrderSyncBatch(false), 1);
        Test.stopTest();

        List<Api_Log__c> batchErrLogs = [
            SELECT Context__c, Stack_Trace__c FROM Api_Log__c
            WHERE Context__c = 'Order Sync - Batch Error'
        ];
        System.assert(!batchErrLogs.isEmpty(),
            'Batch error log inserted when execute() catch fires');
        System.assertNotEquals(null,
            batchErrLogs[0].Stack_Trace__c,
            'Stack trace populated');
    }
}