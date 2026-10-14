public class NetSuiteOAuth2Helper {

    // Confirmed working values (validated via Postman)
    private static final String CLIENT_ID = 'f204c093e771b28810c9e5ac7f607fa5c3fb728068a4bd856e45bca6244f1920'; // consumer_key
    private static final String CERTIFICATE_ID = 'V3FgBNfF8Ow6x_huBxf-eLssmeP89gd2x9VYcLtn110'; // certificate_id (kid)
    private static final String ACCOUNT_ID = '5631345-sb2';
    private static final String TOKEN_ENDPOINT = 'https://' + ACCOUNT_ID + '.suitetalk.api.netsuite.com/services/rest/auth/oauth2/v1/token';
    private static final String SCOPE = 'rest_webservices';

    // Named Credential pointing to your deployed external PS256 signer service (e.g., Vercel URL)
    private static final String SIGNER_ENDPOINT = 'callout:NetSuite_JWT_Signer/api/get-jwt';

    public static String getAccessToken() {
        // Step 1: request a PS256-signed JWT from the external signer service
        HttpRequest signerReq = new HttpRequest();
        signerReq.setEndpoint(SIGNER_ENDPOINT);
        signerReq.setMethod('GET');

        Http http = new Http();
        HttpResponse signerRes = http.send(signerReq);

        if (signerRes.getStatusCode() != 200) {
            throw new NetSuiteAuthException('Signer service failed: ' + signerRes.getStatusCode() + ' - ' + signerRes.getBody());
        }

        Map<String, Object> signerResponse = (Map<String, Object>) JSON.deserializeUntyped(signerRes.getBody());
        String jwt = (String) signerResponse.get('jwt');

        if (String.isBlank(jwt)) {
            throw new NetSuiteAuthException('Signer service returned an empty JWT: ' + signerRes.getBody());
        }

        // Step 2: exchange the JWT for a NetSuite access token
        String body = 'grant_type=' + EncodingUtil.urlEncode('client_credentials', 'UTF-8') +
                       '&client_assertion_type=' + EncodingUtil.urlEncode('urn:ietf:params:oauth:client-assertion-type:jwt-bearer', 'UTF-8') +
                       '&client_assertion=' + EncodingUtil.urlEncode(jwt, 'UTF-8') +
                       '&scope=' + EncodingUtil.urlEncode(SCOPE, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(TOKEN_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(body);

        HttpResponse res = http.send(req);

        System.debug('NetSuite token response status: ' + res.getStatusCode());
        System.debug('NetSuite token response body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) tokenResponse.get('access_token');
        } else {
            throw new NetSuiteAuthException('Failed to obtain OAuth2 access token: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }

    public class NetSuiteAuthException extends Exception {}
}