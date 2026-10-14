public class NetSuiteOAuthHelper {

    public static String buildAuthHeader(String httpMethod, String baseUrl, Map<String, String> queryParams) {
        NetSuite_Credential__mdt cred = [
            SELECT Account_Id__c, Consumer_Key__c, Consumer_Secret__c,
                   Token_Id__c, Token_Secret__c, Realm__c
            FROM NetSuite_Credential__mdt
            LIMIT 1
        ];

        String nonce = generateNonce();
        String timestamp = String.valueOf(DateTime.now().getTime() / 1000);

        Map<String, String> params = new Map<String, String>{
            'oauth_consumer_key' => cred.Consumer_Key__c,
            'oauth_token' => cred.Token_Id__c,
            'oauth_signature_method' => 'HMAC-SHA256',
            'oauth_timestamp' => timestamp,
            'oauth_nonce' => nonce,
            'oauth_version' => '1.0'
        };

        // IMPORTANT: merge in query params so they're part of the signature
        if (queryParams != null) {
            params.putAll(queryParams);
        }

        List<String> keys = new List<String>(params.keySet());
        keys.sort();
        List<String> encodedParams = new List<String>();
        for (String key : keys) {
            encodedParams.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' +
                               EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }
        String paramString = String.join(encodedParams, '&');

        String baseString = httpMethod.toUpperCase() + '&' +
                             EncodingUtil.urlEncode(baseUrl, 'UTF-8') + '&' +
                             EncodingUtil.urlEncode(paramString, 'UTF-8');

        String signingKey = EncodingUtil.urlEncode(cred.Consumer_Secret__c, 'UTF-8') + '&' +
                             EncodingUtil.urlEncode(cred.Token_Secret__c, 'UTF-8');

        Blob signatureBlob = Crypto.generateMac('hmacSHA256', Blob.valueOf(baseString), Blob.valueOf(signingKey));
        String signature = EncodingUtil.base64Encode(signatureBlob);

        // Note: oauth_ params only in the header — query params stay in the URL, not repeated here
        String authHeader = 'OAuth realm="' + cred.Realm__c + '"' +
            ', oauth_consumer_key="' + EncodingUtil.urlEncode(cred.Consumer_Key__c, 'UTF-8') + '"' +
            ', oauth_token="' + EncodingUtil.urlEncode(cred.Token_Id__c, 'UTF-8') + '"' +
            ', oauth_signature_method="HMAC-SHA256"' +
            ', oauth_timestamp="' + timestamp + '"' +
            ', oauth_nonce="' + nonce + '"' +
            ', oauth_version="1.0"' +
            ', oauth_signature="' + EncodingUtil.urlEncode(signature, 'UTF-8') + '"';

        return authHeader;
    }

    // Safer nonce generator — avoids negative numbers / non-alphanumeric characters
    private static String generateNonce() {
        Blob b = Crypto.generateAesKey(128);
        String hex = EncodingUtil.convertToHex(b);
        return hex.substring(0, 32);
    }
}