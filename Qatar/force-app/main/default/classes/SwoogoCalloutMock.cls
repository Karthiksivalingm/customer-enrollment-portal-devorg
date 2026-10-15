/**
 * SwoogoCalloutMock
 *
 * Shared HttpCalloutMock for all Swoogo test classes. Routes canned
 * responses by endpoint substring so every SwoogoApiClient method has
 * something sane to deserialize.
 *
 * PRECONDITION: SwoogoApiClient.getBearerToken() queries SwoogoConfig__mdt
 * directly with no try/catch. Custom metadata records are visible in test
 * context automatically (no @isTest(SeeAllData=true) needed), but at least
 * one SwoogoConfig__mdt record must already be deployed to this org, or
 * every test that reaches a real callout will fail on that SOQL with
 * "List has no rows for assignment".
 *
 * Two optional failure-injection flags:
 *   forceRateLimitOnce - first non-token callout returns 429 (tests retry paths)
 *   forceUnauthorizedOnce - first non-token callout returns 401 (tests token refresh)
 */
@isTest
public class SwoogoCalloutMock implements HttpCalloutMock {

    public Integer callCount = 0;
    public Boolean forceRateLimitOnce = false;
    public Boolean forceUnauthorizedOnce = false;
    private Boolean rateLimited = false;
    private Boolean unauthorized = false;

    public HttpResponse respond(HttpRequest req) {
        callCount++;
        String endpoint = req.getEndpoint();
        String method   = req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        Boolean isTokenCall = endpoint.contains('/oauth2/token');

        if (!isTokenCall && forceRateLimitOnce && !rateLimited) {
            rateLimited = true;
            res.setStatusCode(429);
            res.setHeader('X-Rate-Limit-Reset', '5');
            res.setBody('{"error":"rate limited"}');
            return res;
        }

        if (!isTokenCall && forceUnauthorizedOnce && !unauthorized) {
            unauthorized = true;
            res.setStatusCode(401);
            res.setBody('{"error":"unauthorized"}');
            return res;
        }

        if (isTokenCall) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"test-token-123"}');
            return res;
        }

        if (endpoint.contains('/events/') && endpoint.contains('.json')) {
            res.setStatusCode(200);
            res.setBody('{"id":1001,"name":"Test Event","status":"active",'
                + '"start_date":"2026-06-01","end_date":"2026-06-02",'
                + '"location":"Test City","event_venue_type":"In Person",'
                + '"updated_at":"2026-01-01 00:00:00","created_at":"2026-01-01 00:00:00"}');
            return res;
        }

        if (endpoint.contains('/events.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"id":1001,"name":"Test Event","status":"active",'
                + '"start_date":"2026-06-01","end_date":"2026-06-02",'
                + '"location":"Test City","event_venue_type":"In Person",'
                + '"updated_at":"2026-01-01 00:00:00","created_at":"2026-01-01 00:00:00"}]}');
            return res;
        }

        if (endpoint.contains('/sessions.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"id":2001,"name":"Test Session","start_time":"09:00:00",'
                + '"end_time":"10:00:00","date":"2026-06-01","location":"Room A",'
                + '"updated_at":"2026-01-01 00:00:00","event_id":1001,'
                + '"description":"<p>Desc</p>","body":null}]}');
            return res;
        }

        if (endpoint.contains('/session-attendances.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"registrant_id":3001,"session_id":2001,"event_id":1001,'
                + '"check_in_date":"2026-06-01 09:05:00","on_demand_date":null,'
                + '"updated_at":"2026-06-01 09:05:00"}]}');
            return res;
        }

        if (endpoint.contains('/registrants/create.json')) {
            res.setStatusCode(200);
            res.setBody('{"id":3002}');
            return res;
        }

        if (endpoint.contains('/registrants.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"id":3001,"first_name":"Jane","last_name":"Doe",'
                + '"email":"jane.doe@example.com","job_title":"Manager",'
                + '"mobile_phone":"1234567890","work_phone":"0987654321",'
                + '"registration_status":"accepted","contact_id":"9001",'
                + '"deleted":false,"event_id":1001,"session_ids":["2001"],'
                + '"c_8598114":null,"c_1001":"Hilton Downtown",'
                + '"c_1002":"2026-05-30","c_1003":"14:00:00",'
                + '"c_1004":"2026-06-03","c_1005":"09:00:00"}]}');
            return res;
        }

        if (endpoint.contains('/registrants/') && endpoint.contains('/groups/')) {
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }

        if (endpoint.contains('/contacts/create')) {
            res.setStatusCode(200);
            res.setBody('{"id":9002}');
            return res;
        }

        if (endpoint.contains('/cfs-contacts/update/')) {
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }

        // NOTE: this check MUST come before the generic '/contacts.json' check
        // below — '/invitation-lists/{id}/contacts.json' also contains the
        // substring '/contacts.json', so a wrong check order here silently
        // routes invitation-list-member calls to the plain contact-search
        // response shape (wrong fields, contact_id ends up null downstream).
        if (endpoint.contains('/invitation-lists/') && endpoint.contains('/contacts.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"contact_id":9001,"status":"accepted",'
                + '"created_at":"2026-01-01 00:00:00","updated_at":"2026-01-02 00:00:00"}]}');
            return res;
        }

        if (endpoint.contains('/invitation-lists/') && endpoint.contains('/contact/')) {
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }

        if (endpoint.contains('/invitation-lists.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"id":5001,"name":"VIP","event_id":1001}]}');
            return res;
        }

        if (endpoint.contains('/contacts.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":1,"pageCount":1},"items":['
                + '{"id":9001,"email":"jane.doe@example.com"}]}');
            return res;
        }

        if (endpoint.contains('/event-questions.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":6,"pageCount":1},"items":['
                + '{"id":1,"name":"Hotel Name","attribute":"c_1001"},'
                + '{"id":2,"name":"I/B Date","attribute":"c_1002"},'
                + '{"id":3,"name":"I/B Time","attribute":"c_1003"},'
                + '{"id":4,"name":"O/B Date","attribute":"c_1004"},'
                + '{"id":5,"name":"O/B Time","attribute":"c_1005"},'
                + '{"id":6,"name":"Relationship to Main Guest","attribute":"c_1006"}]}');
            return res;
        }

        if (endpoint.contains('/reg-types/create')) {
            res.setStatusCode(200);
            res.setBody('{"id":7001}');
            return res;
        }

        if (endpoint.contains('/reg-types.json')) {
            res.setStatusCode(200);
            res.setBody('{"_meta":{"totalCount":0,"pageCount":1},"items":[]}');
            return res;
        }

        res.setStatusCode(200);
        res.setBody('{}');
        return res;
    }
}