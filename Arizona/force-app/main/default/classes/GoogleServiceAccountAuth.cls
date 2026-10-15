/**
 * GoogleServiceAccountAuth
 * -----------------------------------------------------------------------
 * Gets a short-lived Google OAuth access token by impersonating a
 * Workspace user via a service account (JWT Bearer flow / domain-wide
 * delegation). This is what lets TSDocumentService export a template's
 * Google Doc to PDF while the doc itself stays fully private (Restricted
 * / domain-only) - no "Anyone with the link" sharing required.
 *
 * SETUP THIS CLASS DEPENDS ON (all done outside Salesforce/Apex):
 *   1. Google Cloud project with the Drive API enabled.
 *   2. A Service Account in that project, with a downloaded JSON key.
 *   3. That service account's numeric Client ID authorized for
 *      domain-wide delegation in Google Workspace Admin, scoped to
 *      https://www.googleapis.com/auth/drive.readonly
 *   4. The service account's private key (from the JSON key) imported
 *      into Salesforce under Certificate and Key Management, referenced
 *      below by CERT_DEVELOPER_NAME.
 *
 * v2 - CONFIG MOVED TO CUSTOM METADATA
 * SERVICE_ACCOUNT_EMAIL and IMPERSONATE_EMAIL used to be hardcoded
 * String constants with placeholder values that were never filled in
 * (YOUR_PROJECT_ID / YOURDOMAIN.com) - every environment needed a code
 * change and redeploy just to set a real email address, and the
 * placeholders shipping to production as literal strings was itself a
 * live bug (Google's token endpoint returns 400 invalid_grant for a
 * service account that doesn't exist).
 *
 * Both values now come from a Custom Metadata Type,
 * Google_Service_Account_Config__mdt, record name 'Default':
 *   - Service_Account_Email__c : the service account's "client_email"
 *     from its downloaded JSON key (looks like
 *     something@your-project-id.iam.gserviceaccount.com - Google
 *     generates this, you don't choose it).
 *   - Impersonate_Email__c : the real Workspace user's email whose
 *     Drive access the service account borrows - must have access to
 *     the template Google Docs.
 * Edit these under Setup > Custom Metadata Types > Google Service
 * Account Config > Manage Records - no code deploy required.
 */
public without sharing class GoogleServiceAccountAuth {

    // Values now come from Custom Metadata (Google_Service_Account_Config__mdt),
    // not hardcoded here - see getConfig() below. This lets the real
    // service account email and impersonated Workspace user be set per-org
    // via Setup, with no code deploy required to change them.
    private static Google_Service_Account_Config__mdt cachedConfig;

    private static Google_Service_Account_Config__mdt getConfig() {
        if (cachedConfig != null) {
            return cachedConfig;
        }
        cachedConfig = Google_Service_Account_Config__mdt.getInstance('Default');
        if (cachedConfig == null
            || String.isBlank(cachedConfig.Service_Account_Email__c)
            || String.isBlank(cachedConfig.Impersonate_Email__c)) {
            throw new GoogleAuthException(
                'Google_Service_Account_Config__mdt.Default is missing or incomplete. '
                + 'Set Service_Account_Email__c and Impersonate_Email__c under '
                + 'Setup > Custom Metadata Types > Google Service Account Config > Manage Records.'
            );
        }
        return cachedConfig;
    }

    // Unique Name of the certificate imported under
    // Setup > Certificate and Key Management (the service account's
    // private key, wrapped in a keystore)
    private static final String CERT_DEVELOPER_NAME = 'GoogleServiceAccountCert';

    private static final String SCOPE          = 'https://www.googleapis.com/auth/drive.readonly';
    private static final String TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
    private static final Integer TOKEN_LIFETIME_SECONDS = 3600;

    public class GoogleAuthException extends Exception {}

    /** Cached per-transaction so repeated exports in one request don't re-auth every time. */
    private static String cachedAccessToken;
    private static Datetime cachedExpiry;

    public static String getAccessToken() {
        if (cachedAccessToken != null
            && cachedExpiry != null
            && cachedExpiry > Datetime.now().addSeconds(30)) {
            return cachedAccessToken;
        }

        String jwt = buildSignedJwt();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(TOKEN_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(
            'grant_type=' + EncodingUtil.urlEncode(
                'urn:ietf:params:oauth:grant-type:jwt-bearer', 'UTF-8')
            + '&assertion=' + EncodingUtil.urlEncode(jwt, 'UTF-8')
        );

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new GoogleAuthException(
                'Google token endpoint returned ' + res.getStatusCode()
                + ': ' + res.getBody()
            );
        }

        Map<String, Object> parsed =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String accessToken = (String) parsed.get('access_token');
        Integer expiresIn  = (Integer) parsed.get('expires_in');
        if (String.isBlank(accessToken)) {
            throw new GoogleAuthException('No access_token in Google response: ' + res.getBody());
        }

        cachedAccessToken = accessToken;
        cachedExpiry = Datetime.now().addSeconds(
            expiresIn == null ? TOKEN_LIFETIME_SECONDS : expiresIn
        );
        return cachedAccessToken;
    }

    private static String buildSignedJwt() {
        Google_Service_Account_Config__mdt config = getConfig();

        Long nowEpoch = Datetime.now().getTime() / 1000;

        Map<String, Object> header = new Map<String, Object>{
            'alg' => 'RS256',
            'typ' => 'JWT'
        };
        Map<String, Object> claims = new Map<String, Object>{
            'iss'   => config.Service_Account_Email__c,
            'scope' => SCOPE,
            'aud'   => TOKEN_ENDPOINT,
            'sub'   => config.Impersonate_Email__c,
            'iat'   => nowEpoch,
            'exp'   => nowEpoch + TOKEN_LIFETIME_SECONDS
        };

        String headerB64 = base64UrlEncode(Blob.valueOf(JSON.serialize(header)));
        String claimsB64 = base64UrlEncode(Blob.valueOf(JSON.serialize(claims)));
        String signingInput = headerB64 + '.' + claimsB64;

        Blob signature;
        try {
            signature = Crypto.signWithCertificate(
                'RSA-SHA256', Blob.valueOf(signingInput), CERT_DEVELOPER_NAME
            );
        } catch (Exception e) {
            throw new GoogleAuthException(
                'Could not sign the Google JWT using certificate "'
                + CERT_DEVELOPER_NAME + '": ' + e.getMessage()
            );
        }

        return signingInput + '.' + base64UrlEncode(signature);
    }

    private static String base64UrlEncode(Blob data) {
        String b64 = EncodingUtil.base64Encode(data);
        return b64.replace('+', '-').replace('/', '_').replace('=', '');
    }
}