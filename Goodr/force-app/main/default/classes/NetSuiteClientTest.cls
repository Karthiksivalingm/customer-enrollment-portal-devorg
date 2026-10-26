@IsTest
private class NetSuiteClientTest {

    /** Returns queued responses in order; records what was called. */
    private class SequenceMock implements HttpCalloutMock {
        private List<HttpResponse> responses;
        public List<HttpRequest> requests = new List<HttpRequest>();
        SequenceMock(List<HttpResponse> responses) { this.responses = responses; }
        public HttpResponse respond(HttpRequest req) {
            requests.add(req);
            return responses.remove(0);
        }
    }

    private class FailingMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Read timed out');
        }
    }

    private static HttpResponse response(Integer status, String body, String location) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(status);
        if (body != null) {
            res.setBody(body);
        }
        if (location != null) {
            res.setHeader('Location', location);
        }
        return res;
    }

    private static final String ERROR_BODY =
        '{"title":"Bad Request","status":400,"o:errorDetails":[{"detail":"Please enter a value for Company Name.","o:errorCode":"USER_ERROR"}]}';

    @IsTest
    static void findCustomerByTaxIdReturnsExistingId() {
        NetSuiteClient.testAccessToken = 'test-token';
        SequenceMock mock = new SequenceMock(new List<HttpResponse>{
            response(200, '{"items":[{"id":"8812","links":[]}],"count":1}', null)
        });
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.findCustomerByTaxId('12-3456789', null);
        Test.stopTest();

        Assert.isTrue(r.success);
        Assert.areEqual('8812', r.internalId);
        HttpRequest sent = mock.requests[0];
        Assert.areEqual('POST', sent.getMethod());
        Assert.isTrue(sent.getEndpoint().endsWith('/query/v1/suiteql?limit=1'));
        Assert.areEqual('transient', sent.getHeader('Prefer'));
        Assert.areEqual('Bearer test-token', sent.getHeader('Authorization'));
        Assert.isTrue(sent.getBody().contains('vatregnumber'));
    }

    @IsTest
    static void findCustomerByTaxIdNoMatch() {
        NetSuiteClient.testAccessToken = 'test-token';
        Test.setMock(HttpCalloutMock.class, new SequenceMock(new List<HttpResponse>{ response(200, '{"items":[],"count":0}', null) }));
        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.findCustomerByTaxId('O\'Brien-1', null);
        Test.stopTest();
        Assert.isTrue(r.success);
        Assert.isNull(r.internalId, 'no existing customer');
    }

    @IsTest
    static void findCustomerByTaxIdRequiresTaxId() {
        NetSuiteClient.Result r = NetSuiteClient.findCustomerByTaxId('  ', null);
        Assert.isFalse(r.success);
        Assert.isTrue(r.errorMessage.contains('Tax ID'));
    }

    @IsTest
    static void createCustomerReturnsIdFromLocation() {
        NetSuiteClient.testAccessToken = 'test-token';
        SequenceMock mock = new SequenceMock(new List<HttpResponse>{
            response(204, null, 'https://acct.suitetalk.api.netsuite.com/services/rest/record/v1/customer/4567')
        });
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.createCustomer(new Map<String, Object>{ 'companyName' => 'Sunny Shades LLC' }, null);
        Test.stopTest();
        Assert.isTrue(r.success);
        Assert.areEqual(204, r.statusCode);
        Assert.areEqual('4567', r.internalId);
        Assert.isTrue(mock.requests[0].getEndpoint().endsWith('/record/v1/customer'));
        Assert.isNull(mock.requests[0].getHeader('Prefer'));
        Assert.areEqual(0, NetSuiteLogger.pendingCount(), 'success is not logged');
    }

    @IsTest
    static void createContactErrorIsLoggedWithNetSuiteMessage() {
        NetSuiteClient.testAccessToken = 'test-token';
        Id relatedId = '001000000000000AAA';
        Test.setMock(HttpCalloutMock.class, new SequenceMock(new List<HttpResponse>{ response(400, ERROR_BODY, null) }));
        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.createContact(new Map<String, Object>{ 'firstName' => 'Jane' }, relatedId);
        NetSuiteLogger.flush();
        Test.stopTest();
        Assert.isFalse(r.success);
        Assert.areEqual(400, r.statusCode);
        Assert.areEqual('Please enter a value for Company Name.', r.errorMessage);
        API_Log__c log = [SELECT Integration__c, Context__c, Status_Code__c, Related_Record_Id__c FROM API_Log__c LIMIT 1];
        Assert.areEqual('NetSuite', log.Integration__c);
        Assert.areEqual('NetSuite Contact Create', log.Context__c);
        Assert.areEqual(400, log.Status_Code__c);
        Assert.areEqual(String.valueOf(relatedId), log.Related_Record_Id__c);
    }

    @IsTest
    static void expiredTokenIsRetriedOnce() {
        NetSuiteClient.testAccessToken = 'test-token';
        SequenceMock mock = new SequenceMock(new List<HttpResponse>{
            response(401, '{"title":"Unauthorized"}', null),
            response(204, null, '/services/rest/record/v1/customer/99')
        });
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.createCustomer(new Map<String, Object>(), null);
        Test.stopTest();
        Assert.isTrue(r.success);
        Assert.areEqual('99', r.internalId);
        Assert.areEqual(2, mock.requests.size(), 'one retry after 401');
    }

    @IsTest
    static void calloutExceptionIsCaughtAndLogged() {
        NetSuiteClient.testAccessToken = 'test-token';
        Test.setMock(HttpCalloutMock.class, new FailingMock());
        Test.startTest();
        NetSuiteClient.Result r = NetSuiteClient.createCustomer(new Map<String, Object>(), null);
        Test.stopTest();
        Assert.isFalse(r.success);
        Assert.isNull(r.statusCode);
        Assert.isTrue(r.errorMessage.startsWith('Could not reach NetSuite'));
        Assert.areEqual(1, NetSuiteLogger.pendingCount());
    }

    @IsTest
    static void readErrorFallsBackForNonNetSuiteBody() {
        Assert.areEqual('NetSuite returned HTTP 502.', NetSuiteClient.readError('<html>Bad gateway</html>', 502));
        Assert.areEqual('NetSuite returned HTTP 500.', NetSuiteClient.readError('{"title":"x"}', 500));
    }
}
