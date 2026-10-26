/**
 * NetSuiteClient
 * The single place where the Create NetSuite button talks to NetSuite (REST record API and SuiteQL).
 *
 * Reuses the existing connection without changing it:
 *   - access token from NetSuiteOAuth2HelperES256.getAccessToken() (same as the product sync)
 *   - named credential NetSuite_Sandbox (points to the right NetSuite account in each org)
 *
 * Every method returns a Result instead of throwing. Failures are added to NetSuiteLogger;
 * the caller must call NetSuiteLogger.flush() after its last callout.
 */
public inherited sharing class NetSuiteClient {

    private static final String BASE_PATH = 'callout:NetSuite_Sandbox/services/rest';
    private static final Integer TIMEOUT_MS = 30000;

    @TestVisible
    private static String testAccessToken;

    public class Result {
        public Boolean success = false;
        public Integer statusCode;
        public String internalId;
        public String errorMessage;
        public String responseBody;
    }

    /** Duplicate check by Tax ID. success + internalId = existing customer; success + no internalId = none found. */
    public static Result findCustomerByTaxId(String taxId, Id relatedRecordId) {
        if (String.isBlank(taxId)) {
            Result r = new Result();
            r.errorMessage = 'Tax ID is required to check NetSuite for an existing customer.';
            return r;
        }
        String query = 'SELECT id FROM customer WHERE vatregnumber = \'' + taxId.trim().replace('\'', '\'\'') + '\'';
        Result r = send('POST', '/query/v1/suiteql?limit=1', JSON.serialize(new Map<String, Object>{ 'q' => query }),
            true, 'NetSuite Customer Duplicate Check (Tax ID)', relatedRecordId);
        if (r.success) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(r.responseBody);
            List<Object> items = (List<Object>) body.get('items');
            if (items != null && !items.isEmpty()) {
                r.internalId = String.valueOf(((Map<String, Object>) items[0]).get('id'));
            }
        }
        return r;
    }

    /** Creates a NetSuite Customer. On success internalId holds the new customer's internal ID. */
    public static Result createCustomer(Map<String, Object> payload, Id relatedRecordId) {
        return send('POST', '/record/v1/customer', JSON.serialize(payload), false, 'NetSuite Customer Create', relatedRecordId);
    }

    /** Creates a NetSuite Contact. On success internalId holds the new contact's internal ID. */
    public static Result createContact(Map<String, Object> payload, Id relatedRecordId) {
        return send('POST', '/record/v1/contact', JSON.serialize(payload), false, 'NetSuite Contact Create', relatedRecordId);
    }

    private static Result send(String method, String path, String body, Boolean isQuery, String context, Id relatedRecordId) {
        Result r = new Result();
        HttpResponse res;
        try {
            res = doSend(method, path, body, isQuery, accessToken(false));
            if (res.getStatusCode() == 401) {
                res = doSend(method, path, body, isQuery, accessToken(true)); // expired token: refresh once
            }
        } catch (Exception e) {
            r.errorMessage = 'Could not reach NetSuite: ' + e.getMessage();
            NetSuiteLogger.add(context, null, body, null, e.getTypeName() + ': ' + e.getMessage(), relatedRecordId);
            return r;
        }

        r.statusCode = res.getStatusCode();
        r.responseBody = res.getBody();
        if (r.statusCode >= 200 && r.statusCode < 300) {
            r.success = true;
            String location = res.getHeader('Location');
            if (String.isNotBlank(location)) {
                r.internalId = location.substringAfterLast('/');
            }
        } else {
            r.errorMessage = readError(r.responseBody, r.statusCode);
            NetSuiteLogger.add(context, r.statusCode, body, r.responseBody, r.errorMessage, relatedRecordId);
        }
        return r;
    }

    private static HttpResponse doSend(String method, String path, String body, Boolean isQuery, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_PATH + path);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        if (isQuery) {
            req.setHeader('Prefer', 'transient');
        }
        if (body != null) {
            req.setBody(body);
        }
        req.setTimeout(TIMEOUT_MS);
        return new Http().send(req);
    }

    private static String accessToken(Boolean forceRefresh) {
        if (Test.isRunningTest() && testAccessToken != null) {
            return testAccessToken;
        }
        return NetSuiteOAuth2HelperES256.getAccessToken(forceRefresh);
    }

    @TestVisible
    private static String readError(String responseBody, Integer statusCode) {
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> details = (List<Object>) body.get('o:errorDetails');
            if (details != null && !details.isEmpty()) {
                Object detail = ((Map<String, Object>) details[0]).get('detail');
                if (detail != null) {
                    return String.valueOf(detail);
                }
            }
        } catch (Exception e) {
            // not a NetSuite error body; fall through to the generic message
        }
        return 'NetSuite returned HTTP ' + statusCode + '.';
    }
}
