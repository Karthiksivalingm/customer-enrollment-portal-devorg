/**
 * NetSuiteOAuth2HelperES256
 * --------------------------------------------------------------------------
 * FULLY SELF-CONTAINED NetSuite OAuth 2.0 Client Credentials (M2M) auth in
 * Apex -- no external signer service.
 *
 * Apex cannot sign PS256 (RSA-PSS), but it CAN sign ES256 (ECDSA P-256) via
 * Crypto.sign('ECDSA-SHA256', ...), and NetSuite accepts ES256 for M2M. The
 * only twist: Apex returns the ECDSA signature DER-encoded, while JWS ES256
 * needs the raw R||S (64-byte) form -- handled by derToRawEcdsa() below.
 *
 * CONFIGURATION
 *   All config -- client id, certificate id, account id, scope, AND the EC
 *   private key -- lives in Custom Metadata Type "NetSuite_Config__mdt".
 *
 *   NOTE: Custom Metadata records are readable via SOQL by any user with
 *   read access to the type, and are exported in full by the Metadata API
 *   (packages, sandbox refreshes, CI/CD retrieves). Unlike a protected
 *   custom setting, there is no row-level lockdown. Restrict who has
 *   "Customize Application" / access to this type accordingly, and keep the
 *   private key out of any metadata you commit to a public repo.
 *
 * ONE-TIME SETUP
 *   1. Upload the EC public cert (netsuite_es256_public.pem) in NetSuite:
 *      Setup > Integration > OAuth 2.0 Client Credentials (M2M) Setup > Create
 *      New, with Entity + Role + your integration.
 *   2. Create a NetSuite_Config__mdt record (DeveloperName = CONFIG_RECORD
 *      below) with Client_Id__c, Certificate_Id__c, Account_Id__c, Scope__c,
 *      and Private_Key__c (base64 PKCS#8 DER private key).
 *   3. Named Credential / Remote Site for the suitetalk host so callouts pass.
 *
 * TESTING
 *   Custom Metadata records cannot be inserted via DML in test context, and
 *   this org's real "Default_Config" record (if any) contains a live
 *   private key you don't want exercised in a test signing operation.
 *   setTestConfig() below lets tests inject an in-memory
 *   NetSuite_Config__mdt (never persisted) so buildAssertionJwt(),
 *   derToRawEcdsa(), and the token/cache flow can all be unit tested with a
 *   throwaway EC key. It only takes effect when Test.isRunningTest() is true.
 * --------------------------------------------------------------------------
 */
public with sharing class NetSuiteOAuth2HelperES256 {

    // Developer name of the config record to load.
    private static final String CONFIG_RECORD = 'Default_Config';

    private static final Integer TIMEOUT_MS = 30000;

    // --- Platform Cache (optional; create an Org partition named "NetSuite") ---
    private static final String  CACHE_PARTITION = 'NetSuite';
    private static final String  CACHE_KEY       = 'accessTokenES256';
    private static final Integer CACHE_TTL_SECS  = 3300;

    // Lazily-resolved config, loaded once per transaction.
    private static NetSuite_Config__mdt cfg;
    private static String cachedTokenEndpoint;
    private static String cachedRestBase;

    // --- Test seam: lets unit tests inject config without deployed metadata ---
    @TestVisible
    private static NetSuite_Config__mdt testConfigOverride;

    @TestVisible
    private static void setTestConfig(NetSuite_Config__mdt testCfg) {
        testConfigOverride = testCfg;
        // force re-resolution of anything derived from config
        cfg = null;
        cachedTokenEndpoint = null;
        cachedRestBase = null;
    }

    // ================================================================ public

    public static String getAccessToken() {
        return getAccessToken(false);
    }

    public static String getAccessToken(Boolean forceRefresh) {
        System.debug('NetSuiteAuth | 1. getAccessToken start (forceRefresh=' + forceRefresh + ')');
        if (!forceRefresh) {
            String cached = getCachedToken();
            System.debug('NetSuiteAuth | 2. cached token available: ' + String.isNotBlank(cached));
            if (String.isNotBlank(cached)) return cached;
        }
        String token = fetchNewAccessToken();
        putCachedToken(token);
        System.debug('NetSuiteAuth | 9. getAccessToken done: new token ready (value not logged)');
        return token;
    }

    /** Authenticated GET, e.g. callRest('/record/v1/customer?limit=5'). */
    public static HttpResponse callRest(String relativePath) {
        System.debug('NetSuiteAuth | REST callRest start: GET ' + relativePath);
        HttpResponse res = doRest(relativePath, getAccessToken(false));
        if (res.getStatusCode() == 401) {
            System.debug('NetSuiteAuth | REST got HTTP 401 (token rejected or expired) -> getting a new token and retrying once');
            res = doRest(relativePath, getAccessToken(true)); // stale token -> refresh once
        }
        System.debug('NetSuiteAuth | REST GET ' + relativePath + ' -> HTTP ' + res.getStatusCode());
        if (res.getStatusCode() >= 300) {
            System.debug('NetSuiteAuth | REST error body: ' + String.valueOf(res.getBody()).left(1000));
        }
        return res;
    }

    /** Exposed for unit testing / debugging. */
    @TestVisible
    private static String buildAssertionJwt() {
        NetSuite_Config__mdt c = getConfig();
        System.debug('NetSuiteAuth | 4. building JWT assertion (kid = Certificate ID ' + c.Certificate_Id__c + ')');

        String headerJson = '{"alg":"ES256","typ":"JWT","kid":"' + c.Certificate_Id__c + '"}';

        Long nowSec = DateTime.now().getTime() / 1000;
        String scopeArr = buildScopeArray(c.Scope__c);
        String payloadJson =
            '{"iss":"' + c.Client_Id__c + '"' +
            ',"scope":' + scopeArr +
            ',"aud":"' + getTokenEndpoint() + '"' +
            ',"iat":' + nowSec +
            ',"exp":' + (nowSec + 300) + '}';

        System.debug('NetSuiteAuth | 5. JWT claims: iss(Client ID)=' + maskValue(c.Client_Id__c) + ', scope=' + scopeArr
            + ', aud=' + getTokenEndpoint() + ', iat=' + nowSec + ', exp=' + (nowSec + 300));

        String signingInput = base64url(headerJson) + '.' + base64url(payloadJson);

        System.debug('NetSuiteAuth | 6. decoding private key from NetSuite_Config__mdt and signing with ES256 (fails here = bad/RSA key)');
        Blob keyBlob = EncodingUtil.base64Decode(getPrivateKeyB64());
        Blob derSig  = Crypto.sign('ECDSA-SHA256', Blob.valueOf(signingInput), keyBlob);
        Blob rawSig  = derToRawEcdsa(derSig, 32); // P-256 -> 32-byte R and S
        System.debug('NetSuiteAuth | 6. JWT signed OK (key ' + keyBlob.size() + ' bytes, signature ' + rawSig.size() + ' bytes)');

        return signingInput + '.' + base64url(rawSig);
    }

    // =============================================================== internals

    private static String fetchNewAccessToken() {
        String assertion = buildAssertionJwt();

        String body =
            'grant_type='             + EncodingUtil.urlEncode('client_credentials', 'UTF-8') +
            '&client_assertion_type=' + EncodingUtil.urlEncode('urn:ietf:params:oauth:client-assertion-type:jwt-bearer', 'UTF-8') +
            '&client_assertion='      + EncodingUtil.urlEncode(assertion, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(getTokenEndpoint());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(TIMEOUT_MS);
        req.setBody(body);

        System.debug('NetSuiteAuth | 7. token request -> POST ' + getTokenEndpoint());
        HttpResponse res = new Http().send(req);
        System.debug('NetSuite token status: ' + res.getStatusCode());

        if (res.getStatusCode() == 200) {
            Map<String, Object> t = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String token = (String) t.get('access_token');
            if (String.isBlank(token)) {
                System.debug('NetSuiteAuth | 8. token request FAILED: HTTP 200 but no access_token in reply: ' + String.valueOf(res.getBody()).left(500));
                throw new NetSuiteAuthException('Token response contained no access_token: ' + res.getBody());
            }
            System.debug('NetSuiteAuth | 8. access token received (length ' + token.length() + ', expires_in=' + t.get('expires_in') + 's, value not logged)');
            return token;
        }
        System.debug('NetSuiteAuth | 8. token request FAILED: HTTP ' + res.getStatusCode()
            + ' | reply: ' + String.valueOf(res.getBody()).left(1000)
            + ' | WWW-Authenticate: ' + res.getHeader('WWW-Authenticate')
            + ' | likely cause: ' + tokenFailureHint(res.getStatusCode(), res.getBody()));
        throw new NetSuiteAuthException(describeError('NetSuite token request', res));
    }

    private static HttpResponse doRest(String relativePath, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getRestBase() + relativePath);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_MS);
        System.debug('NetSuiteAuth | REST request -> GET ' + getRestBase() + relativePath);
        return new Http().send(req);
    }

    // --- Custom Metadata (non-secret config) ----------------------------------

    private static NetSuite_Config__mdt getConfig() {
        if (cfg == null) {
            if (Test.isRunningTest() && testConfigOverride != null) {
                cfg = testConfigOverride;
            } else {
                cfg = NetSuite_Config__mdt.getInstance(CONFIG_RECORD);
            }
            if (cfg == null) {
                System.debug('NetSuiteAuth | 3. config FAILED: NetSuite_Config__mdt record "' + CONFIG_RECORD + '" not found');
                throw new NetSuiteAuthException(
                    'NetSuite_Config__mdt record "' + CONFIG_RECORD + '" not found. ' +
                    'Create it under Setup > Custom Metadata Types > NetSuite Config.'
                );
            }
            if (String.isBlank(cfg.Client_Id__c) || String.isBlank(cfg.Certificate_Id__c)
                    || String.isBlank(cfg.Account_Id__c) || String.isBlank(cfg.Scope__c)
                    || String.isBlank(cfg.Private_Key__c)) {
                System.debug('NetSuiteAuth | 3. config FAILED: blank field(s) in "' + CONFIG_RECORD + '": ' + missingConfigFields(cfg));
                throw new NetSuiteAuthException(
                    'NetSuite_Config__mdt record "' + CONFIG_RECORD + '" is missing one or more required fields.'
                );
            }
            System.debug('NetSuiteAuth | 3. config loaded from ' + (testConfigOverride != null && Test.isRunningTest() ? 'test override' : 'NetSuite_Config__mdt.' + CONFIG_RECORD)
                + ': Account ID=' + cfg.Account_Id__c + ', Certificate ID=' + cfg.Certificate_Id__c
                + ', Client ID=' + maskValue(cfg.Client_Id__c) + ', Scope=' + cfg.Scope__c
                + ', private key present (' + cfg.Private_Key__c.length() + ' chars)');
        }
        return cfg;
    }

    private static String getTokenEndpoint() {
        if (cachedTokenEndpoint == null) {
            cachedTokenEndpoint = 'https://' + getConfig().Account_Id__c
                + '.suitetalk.api.netsuite.com/services/rest/auth/oauth2/v1/token';
        }
        return cachedTokenEndpoint;
    }

    private static String getRestBase() {
        if (cachedRestBase == null) {
            cachedRestBase = 'https://' + getConfig().Account_Id__c
                + '.suitetalk.api.netsuite.com/services/rest';
        }
        return cachedRestBase;
    }

    // --- Private key (from the same Custom Metadata record) --------------------

    private static String getPrivateKeyB64() {
        // Long Text Area fields can wrap with newlines when edited via UI; strip
        // whitespace before base64-decoding.
        return getConfig().Private_Key__c.replaceAll('\\s+', '');
    }

    // ---------------------------------------------------------------------------

    private static String buildScopeArray(String scopeStr) {
        List<String> quoted = new List<String>();
        for (String s : scopeStr.split(' ')) {
            if (String.isNotBlank(s)) quoted.add('"' + s.trim() + '"');
        }
        return '[' + String.join(quoted, ',') + ']';
    }

    // --- ECDSA DER (SEQUENCE{INTEGER r, INTEGER s}) -> raw R||S ---------------
    // partLen = 32 for P-256.
    @TestVisible
    private static Blob derToRawEcdsa(Blob der, Integer partLen) {
        String hex = EncodingUtil.convertToHex(der); // lowercase
        Integer pos = 0;

        if (hex.substring(pos, pos + 2) != '30') {
            throw new NetSuiteAuthException('Bad ECDSA DER: missing SEQUENCE');
        }
        pos += 2;
        Integer seqLen = hexToInt(hex.substring(pos, pos + 2));
        pos += 2;
        if (seqLen >= 128) {                 // long-form length: skip length bytes
            pos += (seqLen - 128) * 2;
        }

        // INTEGER r
        if (hex.substring(pos, pos + 2) != '02') {
            throw new NetSuiteAuthException('Bad ECDSA DER: missing INTEGER r');
        }
        pos += 2;
        Integer rLen = hexToInt(hex.substring(pos, pos + 2));
        pos += 2;
        String rHex = hex.substring(pos, pos + rLen * 2);
        pos += rLen * 2;

        // INTEGER s
        if (hex.substring(pos, pos + 2) != '02') {
            throw new NetSuiteAuthException('Bad ECDSA DER: missing INTEGER s');
        }
        pos += 2;
        Integer sLen = hexToInt(hex.substring(pos, pos + 2));
        pos += 2;
        String sHex = hex.substring(pos, pos + sLen * 2);

        rHex = normalizeHex(rHex, partLen);
        sHex = normalizeHex(sHex, partLen);
        return EncodingUtil.convertFromHex(rHex + sHex);
    }

    private static final String HEXCHARS = '0123456789abcdef';

    private static Integer hexToInt(String h) {
        Integer val = 0;
        for (Integer i = 0; i < h.length(); i++) {
            val = val * 16 + HEXCHARS.indexOf(h.substring(i, i + 1).toLowerCase());
        }
        return val;
    }

    private static String normalizeHex(String h, Integer partLen) {
        Integer want = partLen * 2;
        while (h.length() > want && h.substring(0, 2) == '00') { // strip sign padding
            h = h.substring(2);
        }
        while (h.length() < want) {                              // left-pad
            h = '00' + h;
        }
        return h;
    }

    // --- base64url ---
    private static String base64url(String s) {
        return base64url(Blob.valueOf(s));
    }
    private static String base64url(Blob b) {
        return EncodingUtil.base64Encode(b).replace('+', '-').replace('/', '_').replace('=', '');
    }

    private static String describeError(String label, HttpResponse res) {
        String msg = label + ' failed: HTTP ' + res.getStatusCode() + ' - ' + res.getBody();
        String www = res.getHeader('WWW-Authenticate');
        if (String.isNotBlank(www)) msg += ' | WWW-Authenticate: ' + www;
        return msg;
    }

    // --- Platform Cache (fail-safe: any cache error => no caching) ---
    private static String getCachedToken() {
        try {
            Cache.OrgPartition part = Cache.Org.getPartition(CACHE_PARTITION);
            System.debug('NetSuiteAuth | cache read: partition "' + CACHE_PARTITION + '" found=' + (part != null) + ', token stored=' + (part != null && part.contains(CACHE_KEY)));
            if (part != null && part.contains(CACHE_KEY)) return (String) part.get(CACHE_KEY);
        } catch (Exception e) {
            System.debug('Token cache read skipped: ' + e.getMessage());
        }
        return null;
    }
    private static void putCachedToken(String token) {
        try {
            Cache.OrgPartition part = Cache.Org.getPartition(CACHE_PARTITION);
            if (part != null) part.put(CACHE_KEY, token, CACHE_TTL_SECS);
            System.debug('NetSuiteAuth | cache write: token saved for ' + CACHE_TTL_SECS + 's = ' + (part != null));
        } catch (Exception e) {
            System.debug('Token cache write skipped: ' + e.getMessage());
        }
    }

    // --- Debug helpers (only used in System.debug lines; never log secrets) ---
    private static String maskValue(String value) {
        if (String.isBlank(value)) return '(blank)';
        return value.length() > 8 ? value.left(4) + '...' + value.right(4) : '(set)';
    }

    private static String missingConfigFields(NetSuite_Config__mdt c) {
        List<String> missing = new List<String>();
        if (String.isBlank(c.Client_Id__c))      missing.add('Client_Id__c');
        if (String.isBlank(c.Certificate_Id__c)) missing.add('Certificate_Id__c');
        if (String.isBlank(c.Account_Id__c))     missing.add('Account_Id__c');
        if (String.isBlank(c.Scope__c))          missing.add('Scope__c');
        if (String.isBlank(c.Private_Key__c))    missing.add('Private_Key__c');
        return String.join(missing, ', ');
    }

    private static String tokenFailureHint(Integer statusCode, String body) {
        String b = body == null ? '' : body.toLowerCase();
        if (b.contains('invalid_client')) return 'Client ID unknown/disabled, or Certificate ID does not match an active M2M mapping';
        if (b.contains('invalid_grant'))  return 'JWT rejected: certificate/private key mismatch, expired certificate, or clock/exp issue';
        if (b.contains('invalid_scope'))  return 'Scope not allowed for this integration record (check Scope__c and the integration record scopes)';
        if (statusCode == 500)            return 'NetSuite server_error: M2M mapping missing/inactive after refresh, certificate not EC P-256, or key mismatch';
        if (statusCode == 401 || statusCode == 403) return 'Integration user/role not allowed to log in with OAuth 2.0 or REST Web Services';
        return 'see NetSuite Setup > Users/Roles > User Management > View Login Audit Trail';
    }

    public class NetSuiteAuthException extends Exception {}
}