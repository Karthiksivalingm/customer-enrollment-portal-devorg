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
        if (!forceRefresh) {
            String cached = getCachedToken();
            if (String.isNotBlank(cached)) return cached;
        }
        String token = fetchNewAccessToken();
        putCachedToken(token);
        return token;
    }

    /** Authenticated GET, e.g. callRest('/record/v1/customer?limit=5'). */
    public static HttpResponse callRest(String relativePath) {
        HttpResponse res = doRest(relativePath, getAccessToken(false));
        if (res.getStatusCode() == 401) {
            res = doRest(relativePath, getAccessToken(true)); // stale token -> refresh once
        }
        return res;
    }

    /** Exposed for unit testing / debugging. */
    @TestVisible
    private static String buildAssertionJwt() {
        NetSuite_Config__mdt c = getConfig();

        String headerJson = '{"alg":"ES256","typ":"JWT","kid":"' + c.Certificate_Id__c + '"}';

        Long nowSec = DateTime.now().getTime() / 1000;
        String scopeArr = buildScopeArray(c.Scope__c);
        String payloadJson =
            '{"iss":"' + c.Client_Id__c + '"' +
            ',"scope":' + scopeArr +
            ',"aud":"' + getTokenEndpoint() + '"' +
            ',"iat":' + nowSec +
            ',"exp":' + (nowSec + 300) + '}';

        String signingInput = base64url(headerJson) + '.' + base64url(payloadJson);

        Blob keyBlob = EncodingUtil.base64Decode(getPrivateKeyB64());
        Blob derSig  = Crypto.sign('ECDSA-SHA256', Blob.valueOf(signingInput), keyBlob);
        Blob rawSig  = derToRawEcdsa(derSig, 32); // P-256 -> 32-byte R and S

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

        HttpResponse res = new Http().send(req);
        System.debug('NetSuite token status: ' + res.getStatusCode());

        if (res.getStatusCode() == 200) {
            Map<String, Object> t = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String token = (String) t.get('access_token');
            if (String.isBlank(token)) {
                throw new NetSuiteAuthException('Token response contained no access_token: ' + res.getBody());
            }
            return token;
        }
        throw new NetSuiteAuthException(describeError('NetSuite token request', res));
    }

    private static HttpResponse doRest(String relativePath, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getRestBase() + relativePath);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_MS);
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
                throw new NetSuiteAuthException(
                    'NetSuite_Config__mdt record "' + CONFIG_RECORD + '" not found. ' +
                    'Create it under Setup > Custom Metadata Types > NetSuite Config.'
                );
            }
            if (String.isBlank(cfg.Client_Id__c) || String.isBlank(cfg.Certificate_Id__c)
                    || String.isBlank(cfg.Account_Id__c) || String.isBlank(cfg.Scope__c)
                    || String.isBlank(cfg.Private_Key__c)) {
                throw new NetSuiteAuthException(
                    'NetSuite_Config__mdt record "' + CONFIG_RECORD + '" is missing one or more required fields.'
                );
            }
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
        } catch (Exception e) {
            System.debug('Token cache write skipped: ' + e.getMessage());
        }
    }

    public class NetSuiteAuthException extends Exception {}
}