@isTest
private class NetSuiteProductSyncBatchTest {

    // ==========================================================================
    // Shared test fixtures
    // ==========================================================================

    // Throwaway EC P-256 private key (PKCS#8 DER, base64), generated only for
    // this test class. It signs nothing real and is never sent anywhere except
    // to Apex's own Crypto.sign() inside HttpCalloutMock-stubbed callouts.
    private static final String TEST_PRIVATE_KEY_B64 =
        'MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgyhPHEftzfLoVO17HTe1/tFjt' +
        'I2MjZzbIJ3/W+33YmV+hRANCAAR7SPPLUg2s5+kxwkd/QBSyOjpoEOrxpC23NUCT9LYK6/UZ' +
        '4d4J2loOVsnqGxubJ7xjx+OZMzXvjMNgpsObKSr9';

    private static void injectTestConfig() {
        NetSuite_Config__mdt fake = new NetSuite_Config__mdt(
            Client_Id__c      = 'test-client-id',
            Certificate_Id__c = 'test-cert-id',
            Account_Id__c     = 'TSTACCT',
            Scope__c          = 'rest_webservices',
            Private_Key__c    = TEST_PRIVATE_KEY_B64
        );
        NetSuiteOAuth2HelperES256.setTestConfig(fake);
    }

    private static HttpResponse tokenResponse(Integer statusCode, String accessToken) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setHeader('Content-Type', 'application/json');
        if (statusCode == 200) {
            res.setBody(JSON.serialize(new Map<String, Object>{
                'access_token' => accessToken,
                'token_type'   => 'Bearer',
                'expires_in'   => 3600
            }));
        } else {
            res.setHeader('WWW-Authenticate', 'Bearer error="invalid_client"');
            res.setBody('{"error":"invalid_client","error_description":"Simulated auth failure"}');
        }
        return res;
    }

    private static HttpResponse suiteqlResponse(List<Map<String, Object>> items, Boolean hasMore) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(new Map<String, Object>{ 'items' => items, 'hasMore' => hasMore }));
        return res;
    }

    private static Map<String, Object> item(String id, String itemId, String displayName, Map<String, Object> extra) {
        Map<String, Object> m = new Map<String, Object>{
            'id' => id, 'itemid' => itemId, 'displayname' => displayName,
            'description' => 'Desc ' + itemId, 'isinactive' => 'F', 'upccode' => '000' + id
        };
        if (extra != null) m.putAll(extra);
        return m;
    }

    private static void setupPricebooks() {
        // Querying "WHERE IsStandard = true" is unreliable in test context.
        // Test.getStandardPricebookId() is the documented way to get/activate
        // the Standard Price Book inside a unit test.
        Id stdPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = stdPricebookId, IsActive = true);
        insert new List<Pricebook2>{
            new Pricebook2(Name = 'Global', IsActive = true),
            new Pricebook2(Name = 'USA', IsActive = true),
            new Pricebook2(Name = 'CAN', IsActive = true)
        };
    }

    // A single flexible mock: routes by endpoint (token vs SuiteQL), supports a
    // fixed token response and a *sequence* of SuiteQL responses (for
    // pagination), or throws to simulate a network-level callout failure.
    private class FlexMock implements HttpCalloutMock {
        public HttpResponse tokenResp;
        public List<HttpResponse> suiteqlResponses = new List<HttpResponse>();
        public Boolean throwOnSuiteql = false;
        public Integer suiteqlCallCount = 0;

        public HttpResponse respond(HttpRequest req) {
            if (req.getEndpoint().contains('/oauth2/v1/token')) {
                return tokenResp;
            }
            if (throwOnSuiteql) {
                throw new CalloutException('Simulated network failure');
            }
            Integer idx = Math.min(suiteqlCallCount, suiteqlResponses.size() - 1);
            suiteqlCallCount++;
            return suiteqlResponses[idx];
        }
    }

    // ==========================================================================
    // NetSuiteProductSyncBatch
    // ==========================================================================

    @isTest
    static void testSuccessfulSyncCreatesAndUpdatesProducts() {
        injectTestConfig();
        setupPricebooks();

        // Pre-insert one product to exercise the UPDATE path alongside a CREATE.
        insert new Product2(Name = 'Old Name', NetSuite_Internal_Id__c = '100', IsActive = true);

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-1');
        mock.suiteqlResponses.add(suiteqlResponse(new List<Map<String, Object>>{
            item('100', 'TEST-SKU-1', 'Test Product 1', new Map<String, Object>{
                'unitprice' => 19.99,
                'custitem_goodrglobal_item' => 'T',
                'custitem_sellgoodr_item' => 'T',
                'custitemcustitem_sellgoodrcad_item' => 'F',
                'custitemplm_launch_year' => '2024',
                'custitem3' => '1.5',
                'custitem_goodr_ip_length' => '10.2',
                'custitem_good_ip_width' => '5.1',
                'custitem_goodr_ip_height' => '3.0',
                'custitem16' => '01/15/2024',
                'custitem7' => '02/01/2024'
            }),
            item('101', 'TEST-SKU-2', 'Test Product 2', new Map<String, Object>{ 'isinactive' => 'T' })
        }, false));
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        Map<String, Product2> byNsId = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name, IsActive, NetSuite_Status__c, NetSuite_Internal_Id__c FROM Product2]) {
            byNsId.put(p.NetSuite_Internal_Id__c, p);
        }
        System.assertEquals(2, byNsId.size(), 'Expected one created + one updated product.');
        System.assertEquals('Test Product 1', byNsId.get('100').Name, 'Existing product should be updated in place.');
        System.assertEquals(true, byNsId.get('100').IsActive);
        System.assertEquals(false, byNsId.get('101').IsActive);

        List<PricebookEntry> entries = [SELECT Id, Pricebook2Id, UnitPrice FROM PricebookEntry
                                         WHERE Product2Id = :byNsId.get('100').Id];
        System.assert(!entries.isEmpty(), 'Product flagged for Global/USA should get pricebook entries.');

        Sync_Config__c cfg = Sync_Config__c.getOrgDefaults();
        System.assertNotEquals(null, cfg.Last_Sync_DateTime__c, 'Last sync time should advance after a clean run.');
    }

    @isTest
    static void testPaginationFollowsHasMoreAcrossPages() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-2');
        // Page 1: hasMore = true so the batch loops and increments offset.
        mock.suiteqlResponses.add(suiteqlResponse(
            new List<Map<String, Object>>{ item('200', 'PAGE1-SKU', 'Page One Product', null) }, true));
        // Page 2: hasMore = false, ends the loop.
        mock.suiteqlResponses.add(suiteqlResponse(
            new List<Map<String, Object>>{ item('201', 'PAGE2-SKU', 'Page Two Product', null) }, false));
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        System.assertEquals(2, mock.suiteqlCallCount, 'Both pages should have been fetched.');
        List<Product2> products = [SELECT Id FROM Product2 WHERE NetSuite_Internal_Id__c IN ('200', '201')];
        System.assertEquals(2, products.size(), 'Products from both pages should be synced.');
    }

    @isTest
    static void testTokenFetchFailureAbortsRunAndLogsError() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(401, null); // token endpoint itself fails
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id, Context__c FROM Api_Log__c
                                  WHERE Context__c = 'NetSuite Product Sync - OAuth2 Token Exception'];
        System.assert(!logs.isEmpty(), 'A token failure should be logged.');
        System.assertEquals(0, [SELECT COUNT() FROM Product2], 'No products should sync when auth fails.');

        Sync_Config__c cfg = Sync_Config__c.getOrgDefaults();
        System.assertEquals(null, cfg.Last_Sync_DateTime__c, 'Last sync time must not advance after a failed run.');
    }

    @isTest
    static void testCalloutExceptionDuringQueryLogsError() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-3');
        mock.throwOnSuiteql = true; // simulate a network-level failure on the SuiteQL call
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c
                                  WHERE Context__c = 'NetSuite Product Sync - Callout Exception'];
        System.assert(!logs.isEmpty(), 'A callout exception during SuiteQL query should be logged.');
    }

    @isTest
    static void testSuiteQlNon200LogsError() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-4');
        HttpResponse badRes = new HttpResponse();
        badRes.setStatusCode(500);
        badRes.setBody('{"error":"Internal Server Error"}');
        mock.suiteqlResponses.add(badRes);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c
                                  WHERE Context__c = 'NetSuite Product Sync - SuiteQL Callout'];
        System.assert(!logs.isEmpty(), 'A non-200 SuiteQL response should be logged.');
    }

    @isTest
    static void testMalformedDateAndNumberFieldsAreLoggedAndSkipped() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-5');
        mock.suiteqlResponses.add(suiteqlResponse(new List<Map<String, Object>>{
            item('300', 'BAD-DATA-SKU', 'Bad Data Product', new Map<String, Object>{
                'unitprice' => 'not-a-number',
                'custitem16' => '2024-99-99',       // malformed, no slashes in the right shape
                'custitem7' => 'not/a/date',
                'custitemplm_launch_year' => 'twenty-twenty-four',
                'custitem3' => 'heavy',
                'custitem_goodr_ip_length' => 'long',
                'custitem_good_ip_width' => 'wide',
                'custitem_goodr_ip_height' => 'tall'
            })
        }, false));
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.executeBatch(new NetSuiteProductSyncBatch(), 100);
        Test.stopTest();

        // The product itself should still be created; only the bad fields are skipped.
        List<Product2> products = [SELECT Id FROM Product2 WHERE NetSuite_Internal_Id__c = '300'];
        System.assertEquals(1, products.size(), 'Product should still sync despite bad optional fields.');

        List<Api_Log__c> warnings = [SELECT Id, Context__c FROM Api_Log__c
                                      WHERE Context__c IN ('Date Parse Warning', 'Number Parse Warning', 'Price Parse Error')];
        System.assert(warnings.size() >= 3, 'Each malformed field should produce its own parse warning log.');
    }

    @isTest
    static void testSchedulerExecuteRunsBatch() {
        // Calling execute() directly (rather than relying on System.schedule's
        // cron firing at Test.stopTest()) avoids the timing fragility of a
        // batch job nested inside a scheduled job — both still run
        // synchronously inside the same startTest/stopTest window, but this
        // way the assertion isn't dependent on nested-async flush ordering.
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'fake-token-6');
        mock.suiteqlResponses.add(suiteqlResponse(new List<Map<String, Object>>{
            item('400', 'SCHED-SKU', 'Scheduled Product', null)
        }, false));
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        new NetSuiteSyncScheduler().execute(null);
        Test.stopTest();

        List<Product2> results = [SELECT Id FROM Product2 WHERE NetSuite_Internal_Id__c = '400'];
        System.assertEquals(1, results.size(), 'Scheduler execute() should trigger the batch and create the product.');
    }

    @isTest
    static void testSchedulerCanBeScheduledViaCron() {
        // Separate, narrower test just for System.schedule()/CronTrigger
        // registration coverage - no dependency on nested batch execution
        // timing.
        Test.startTest();
        String cronExp = '0 0 0 15 3 ? 2099'; // far-future one-time schedule
        String jobId = System.schedule('Test NetSuite Sync', cronExp, new NetSuiteSyncScheduler());
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, jobs.size(), 'The job should be registered on the cron schedule.');
        System.assertEquals(cronExp, jobs[0].CronExpression);
    }

    // ==========================================================================
    // NetSuiteOAuth2HelperES256 (direct unit tests)
    // ==========================================================================

    @isTest
    static void testBuildAssertionJwtProducesWellFormedJws() {
        injectTestConfig();

        Test.startTest();
        String jwt = NetSuiteOAuth2HelperES256.buildAssertionJwt();
        Test.stopTest();

        List<String> parts = jwt.split('\\.');
        System.assertEquals(3, parts.size(), 'A JWS compact serialization has header.payload.signature.');
    }

    @isTest
    static void testDerToRawEcdsaConversion() {
        injectTestConfig();

        // Sign arbitrary data to get a real DER-encoded ECDSA signature, then
        // confirm the helper's DER->raw conversion always yields 64 bytes (R||S
        // for P-256), regardless of DER's variable-length encoding.
        Blob keyBlob = EncodingUtil.base64Decode(TEST_PRIVATE_KEY_B64);
        Blob der = Crypto.sign('ECDSA-SHA256', Blob.valueOf('sample signing input'), keyBlob);

        Test.startTest();
        Blob raw = NetSuiteOAuth2HelperES256.derToRawEcdsa(der, 32);
        Test.stopTest();

        System.assertEquals(64, raw.size(), 'Raw ECDSA signature for P-256 must be exactly 64 bytes.');
    }

    @isTest
    static void testGetAccessTokenFetchesAndReturnsToken() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        mock.tokenResp = tokenResponse(200, 'direct-token-abc');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String token = NetSuiteOAuth2HelperES256.getAccessToken();
        Test.stopTest();

        System.assertEquals('direct-token-abc', token);
    }

    @isTest
    static void testGetAccessTokenThrowsOnMissingAccessToken() {
        injectTestConfig();

        FlexMock mock = new FlexMock();
        HttpResponse emptyOk = new HttpResponse();
        emptyOk.setStatusCode(200);
        emptyOk.setBody('{"token_type":"Bearer"}'); // no access_token key
        mock.tokenResp = emptyOk;
        Test.setMock(HttpCalloutMock.class, mock);

        Boolean threw = false;
        Test.startTest();
        try {
            NetSuiteOAuth2HelperES256.getAccessToken();
        } catch (NetSuiteOAuth2HelperES256.NetSuiteAuthException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Missing access_token in a 200 response should raise NetSuiteAuthException.');
    }

    @isTest
    static void testCallRestRetriesOnceOn401() {
        injectTestConfig();

        // callRest() issues a GET to a REST path after fetching a token; this
        // mock services both, with the REST call reporting 401 on its first
        // hit to force the internal single-retry branch.
        RetryMock retryMock = new RetryMock(tokenResponse(200, 'retry-token'));
        Test.setMock(HttpCalloutMock.class, retryMock);

        Test.startTest();
        HttpResponse res = NetSuiteOAuth2HelperES256.callRest('/record/v1/customer?limit=1');
        Test.stopTest();

        System.assertEquals(2, retryMock.restCallCount, 'A 401 should trigger exactly one retry with a fresh token.');
        System.assertEquals(200, res.getStatusCode());
    }

    private class RetryMock implements HttpCalloutMock {
        HttpResponse tokenResp;
        Integer restCallCount = 0;
        RetryMock(HttpResponse tokenResp) { this.tokenResp = tokenResp; }

        public HttpResponse respond(HttpRequest req) {
            if (req.getEndpoint().contains('/oauth2/v1/token')) {
                return tokenResp;
            }
            restCallCount++;
            HttpResponse res = new HttpResponse();
            if (restCallCount == 1) {
                res.setStatusCode(401);
                res.setBody('{"error":"expired token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"items":[]}');
            }
            return res;
        }
    }

    @isTest
    static void testMissingConfigFieldThrowsAuthException() {
        NetSuite_Config__mdt incomplete = new NetSuite_Config__mdt(
            Client_Id__c = 'only-client-id'
            // Certificate_Id__c / Account_Id__c / Scope__c / Private_Key__c left blank
        );
        NetSuiteOAuth2HelperES256.setTestConfig(incomplete);

        Boolean threw = false;
        Test.startTest();
        try {
            NetSuiteOAuth2HelperES256.buildAssertionJwt();
        } catch (NetSuiteOAuth2HelperES256.NetSuiteAuthException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Incomplete config should raise NetSuiteAuthException.');
    }
}