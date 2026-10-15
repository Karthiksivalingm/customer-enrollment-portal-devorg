@RestResource(urlMapping='/pandadoc/webhook/*')
global without sharing class PandaDocWebhook {

    // CHANGED: this class runs as the site guest user, which cannot access Contacts.
    // It now checks the signature and publishes a PandaDoc_Webhook__e event per document.
    // PandaDocWebhookTrigger and PandaDocEventProcessor do the work as a Salesforce user.

    // NEW: debug switch. Set to false to turn debug lines off.
    private static final Boolean DEBUG_ON = true;

    @HttpPost
    global static void receive() {
        RestRequest req = RestContext.request;
        String body = (req.requestBody == null) ? '' : req.requestBody.toString();
        PandaDocApi.logInfo('webhook: headers=' + req.headers.keySet() + ' body=' + body.left(3000));

        if (!isValidSignature(req, body)) {
            PandaDocApi.logError('webhook: signature check failed');
            reply(401, 'Invalid signature');
            return;
        }

        // 1. Read the event list
        List<Map<String, Object>> events = new List<Map<String, Object>>();
        try {
            for (Object o : toEvents(body)) {
                events.add((Map<String, Object>) o);
            }
        } catch (Exception e) {
            PandaDocApi.logError('webhook: could not read payload - ' + e.getMessage());
            reply(400, 'Could not read payload: ' + e.getMessage());
            return;
        }
        dbg('received ' + events.size() + ' event(s)');

        // 2. Decide what each event needs (no record access here)
        List<PandaDoc_Webhook__e> toPublish = new List<PandaDoc_Webhook__e>();
        List<String> failures = new List<String>();
        Set<String> queued = new Set<String>();
        Integer skipped = 0;
        for (Map<String, Object> ev : events) {
            String eventName = lower(PandaDocApi.str(ev.get('event')));
            try {
                Object d = ev.get('data');
                Map<String, Object> data = (d == null) ? ev : (Map<String, Object>) d;
                PandaDocEventProcessor.Job j = PandaDocEventProcessor.buildJob(data, eventName);
                if (j == null || queued.contains(j.key())) {
                    skipped++;
                    continue;
                }
                // CHANGED: completed is handled only on the PDF-ready event (state changed and recipient completed are skipped)
                if (PandaDocEventProcessor.PD_COMPLETED.equals(j.pandaDocStatus)
                        && !PandaDocEventProcessor.EVENT_PDF_READY.equals(eventName)) {
                    PandaDocApi.logInfo('webhook: ' + j.docId + ' completed on ' + eventName
                        + ', waiting for document_completed_pdf_ready');
                    skipped++;
                    continue;
                }
                queued.add(j.key());
                toPublish.add(new PandaDoc_Webhook__e(
                    Document_Id__c     = j.docId,
                    PandaDoc_Status__c = j.pandaDocStatus,
                    Contact_Id__c      = String.valueOf(j.contactId),
                    Form_Api_Name__c   = j.formApiName,
                    Form_Label__c      = j.formLabel
                ));
            } catch (Exception e) {
                failures.add(eventName + ': ' + e.getMessage());
                PandaDocApi.logError('webhook: could not read ' + eventName + ' event - ' + e.getMessage());
            }
        }

        // 3. NEW: publish the events. Their trigger runs PandaDocEventProcessor.
        Integer published = 0;
        if (!toPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(toPublish);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    published++;
                } else {
                    String msg = results[i].getErrors().isEmpty() ? 'unknown error' : results[i].getErrors()[0].getMessage();
                    failures.add(toPublish[i].Document_Id__c + ': publish failed - ' + msg);
                    PandaDocApi.logError('webhook: publish failed for ' + toPublish[i].Document_Id__c + ' - ' + msg);
                }
            }
        }

        // A 500 keeps the event in PandaDoc's webhook history, so it can be retried
        String summary = 'queued=' + published + ' skipped=' + skipped;
        dbg('done ' + summary + ' failures=' + failures.size());
        if (!failures.isEmpty()) {
            reply(500, 'Failed: ' + String.join(failures, '; ') + ' (' + summary + ')');
        } else {
            reply(200, 'OK ' + summary);
        }
    }

    /*
     * Test helper. Run in Execute Anonymous to process one document without
     * waiting for PandaDoc:
     *   System.debug(PandaDocWebhook.syncDocument('DOCUMENT_ID'));
     */
    public static String syncDocument(String docId) {
        // CHANGED: runs the processor directly, as the user running this
        return PandaDocEventProcessor.syncDocument(docId);
    }

    private static String lower(String s) {
        return (s == null) ? '' : s.trim().toLowerCase();
    }

    private static void dbg(String msg) {
        if (DEBUG_ON) {
            System.debug(LoggingLevel.ERROR, 'PDS-DEBUG webhook ' + msg);
        }
    }

    /*
     * HMAC-SHA256 of the raw request bytes with the shared key. Accepts hex or base64,
     * with or without a "sha256=" prefix. Logs diagnostics only; the key is never logged.
     */
    private static Boolean isValidSignature(RestRequest req, String body) {
            String received = headerValue(req, 'X-PandaDoc-Signature');
if (String.isBlank(received)) {
    received = req.params.get('signature');   // PandaDoc sends it as ?signature=... on delivery
}
        
        String rawKey   = Label.PandaDoc_Webhook_Key;
        String key      = String.isBlank(rawKey) ? '' : rawKey.trim();
        Blob rawBody    = (req.requestBody == null) ? Blob.valueOf('') : req.requestBody;
       
        PandaDocApi.logInfo('sig: signaturePresent=' + String.isNotBlank(received)
    + ' keyPresent=' + String.isNotBlank(key)
    + ' keyLength=' + key.length()
    + ' rawBodyBytes=' + rawBody.size()
    + ' bodyChars=' + body.length());

        if (String.isBlank(received) || String.isBlank(key)) {
            return false;
        }

        String r = received.trim();
        if (r.toLowerCase().startsWith('sha256=')) {
            r = r.substring(7);
        }

        Blob mac = Crypto.generateMac('hmacSHA256', rawBody, Blob.valueOf(key));
        String expectedHex = EncodingUtil.convertToHex(mac);
        String expectedB64 = EncodingUtil.base64Encode(mac);
        Boolean match = r.equalsIgnoreCase(expectedHex) || r.equals(expectedB64);

        PandaDocApi.logInfo('sig: receivedLength=' + r.length()
            + ' receivedPrefix=' + r.left(8)
            + ' expectedHexPrefix=' + expectedHex.left(8)
            + ' match=' + match);

        return match;
    }

    private static String headerValue(RestRequest req, String name) {
        for (String k : req.headers.keySet()) {
            if (k != null && k.equalsIgnoreCase(name)) {
                return req.headers.get(k);
            }
        }
        return null;
    }

    /* A payload is a list of events or a single event. */
    private static List<Object> toEvents(String body) {
        String t = (body == null) ? '' : body.trim();
        if (String.isBlank(t)) {
            return new List<Object>();
        }
        if (t.startsWith('[')) {
            return (List<Object>) JSON.deserializeUntyped(t);
        }
        return new List<Object>{ JSON.deserializeUntyped(t) };
    }

    private static void reply(Integer code, String message) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        res.addHeader('Content-Type', 'text/plain');
        res.responseBody = Blob.valueOf(message.left(500));
    }
}