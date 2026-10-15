public without sharing class PandaDocApi {

    public static final String BASE         = 'https://api.pandadoc.com/public/v1';
    public static final String PANDADOC_APP = 'https://app.pandadoc.com';

    /*
     * Salesforce Site URL that PandaDoc posts events to.
     * It must match the URL saved on the PandaDoc webhook "Salesforce Form Completion".
     */
    public static final String WEBHOOK_URL =
        'https://azlionhearts--arizonalh.sandbox.my.salesforce-sites.com/services/apexrest/pandadoc/webhook';

    /* Returns the API key from the PandaDoc_API_Key Custom Label. The value is never logged. */
    public static String apiKey() {
        String raw = Label.PandaDoc_API_Key;
        if (String.isBlank(raw)) {
            logError('apiKey: Custom Label PandaDoc_API_Key is empty or missing');
            throw new AuraHandledException('PandaDoc API key is missing. Create the Custom Label PandaDoc_API_Key.');
        }
        String k = raw.replaceAll('\\s', '');
        if (!Pattern.matches('[A-Za-z0-9]+', k)) {
            logError('apiKey: PandaDoc_API_Key contains characters other than letters and digits');
            throw new AuraHandledException('PandaDoc_API_Key contains invalid characters. Re-enter it on one line.');
        }
        return k;
    }

    /* One PandaDoc API call. Throws with the response text when the status is 300 or higher. */
    public static String send(String method, String path, String body) {
        String key = apiKey();
        logInfo('request ' + method + ' ' + path);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE + path);
        req.setMethod(method);
        req.setHeader('Authorization', 'API-Key ' + key);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        if (body != null) {
            req.setBody(body);
        }
        req.setTimeout(30000);

        HttpResponse r = new Http().send(req);
        String responseBody = str(r.getBody());
        logInfo('response ' + method + ' ' + path + ' status=' + r.getStatusCode()
            + ' body=' + responseBody.left(1500));

        if (r.getStatusCode() >= 300) {
            logError('error ' + r.getStatusCode() + ' on ' + method + ' ' + path);
            throw new AuraHandledException(
                'PandaDoc error ' + r.getStatusCode() + ' (' + method + ' ' + path + '): '
                + responseBody.replaceAll('\\s+', ' ').left(900)
            );
        }
        return responseBody;
    }

    public static Map<String, Object> getDocument(String docId) {
        return (Map<String, Object>) JSON.deserializeUntyped(send('GET', '/documents/' + docId, null));
    }

    /* Template details: the tokens and recipient roles the template defines. */
    public static Map<String, Object> getTemplateDetails(String templateId) {
        return (Map<String, Object>) JSON.deserializeUntyped(
            send('GET', '/templates/' + templateId + '/details', null)
        );
    }

    /* Downloads the completed PDF of a document. */
    public static Blob downloadPdf(String docId) {
        String key = apiKey();
        logInfo('download doc=' + docId);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE + '/documents/' + docId + '/download');
        req.setMethod('GET');
        req.setHeader('Authorization', 'API-Key ' + key);
        req.setTimeout(60000);

        HttpResponse r = new Http().send(req);
        if (r.getStatusCode() >= 300) {
            logError('download failed ' + r.getStatusCode() + ' ' + str(r.getBody()).left(300));
            throw new AuraHandledException('PandaDoc download failed: ' + r.getStatusCode());
        }
        Blob pdf = r.getBodyAsBlob();
        logInfo('download ok bytes=' + pdf.size());
        return pdf;
    }

    public static String str(Object o) {
        return (o == null) ? '' : String.valueOf(o);
    }

    public static void logInfo(String message) {
        System.debug(LoggingLevel.INFO, '[PandaDoc] ' + message);
    }

    public static void logError(String message) {
        System.debug(LoggingLevel.ERROR, '[PandaDoc] ' + message);
    }
}