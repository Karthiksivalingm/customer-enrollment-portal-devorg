/**
 * SwoogoWebhookHandler
 *
 * Salesforce REST endpoint that receives webhook POSTs from Swoogo.
 * Swoogo calls this URL immediately when:
 *   - A registrant is added to a session
 *   - A registrant is checked in to a session
 *   - A registrant status is updated
 *
 * Every payload is logged to Webhook_Log_c__c for visibility. The event_id
 * is still extracted and identified by type (session/attendance vs.
 * registrant), but no real-time sync is triggered — that would require a
 * SwoogoEventSyncQueueable class, which isn't part of this package.
 * Affected events sync on the next scheduled 15-min run
 * (SwoogoSyncBatch → SwoogoSessionSyncBatch) instead of instantly.
 *
 * URL: POST /services/apexrest/swoogo/webhook
 *
 * To register in Swoogo:
 *   POST https://api.swoogo.com/api/v1/webhooks/create
 *   {
 *     "url": "https://YOUR_SF_DOMAIN/services/apexrest/swoogo/webhook",
 *     "event_type": "registrant.session.added",
 *     "method": "POST"
 *   }
 *   Repeat for: registrant.session.checkin, registrant.updated
 */
@RestResource(urlMapping='/swoogo/webhook')
global with sharing class SwoogoWebhookHandler {

    @HttpPost
    global static void handlePost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        String rawBody = req.requestBody != null
            ? req.requestBody.toString() : '';

        System.debug('SwoogoWebhook received: ' + rawBody.left(500));

        // Always return 200 immediately — Swoogo expects a fast response
        res.statusCode = 200;

        if (String.isBlank(rawBody)) {
            res.responseBody = Blob.valueOf('{"status":"empty body"}');
            return;
        }

        try {
            // Log the raw webhook payload
            insert new Webhook_Log_c__c(
                Name        = 'Webhook-' + Datetime.now().format('yyyyMMdd-HHmmss'),
                Raw_Body__c = rawBody,
                Status__c   = 'Received'
            );
        } catch (Exception e) {
            System.debug('Webhook log insert failed: ' + e.getMessage());
        }

        try {
            Map<String, Object> payload =
                (Map<String, Object>) JSON.deserializeUntyped(rawBody);

            String eventType = String.valueOf(payload.get('event_type'));
            System.debug('Webhook event_type: ' + eventType);

            if (eventType == null) {
                // Some Swoogo webhooks use 'type' instead of 'event_type'
                eventType = String.valueOf(payload.get('type'));
            }

            // Route by event type
            if (eventType != null && (
                eventType.containsIgnoreCase('session') ||
                eventType.containsIgnoreCase('checkin') ||
                eventType.containsIgnoreCase('attendance')))
            {
                // Session-related: enqueue attendance sync for this event
                handleSessionEvent(payload, eventType);

            } else if (eventType != null && (
                eventType.containsIgnoreCase('registrant') ||
                eventType.containsIgnoreCase('registration')))
            {
                // Registrant status change: enqueue registrant sync
                handleRegistrantEvent(payload, eventType);
            } else {
                System.debug('Webhook: unhandled event_type=' + eventType);
            }

            res.responseBody = Blob.valueOf('{"status":"ok"}');

        } catch (Exception e) {
            System.debug('Webhook processing error: ' + e.getMessage()
                + '\n' + e.getStackTraceString());
            // Still return 200 so Swoogo doesn't retry endlessly
            res.responseBody = Blob.valueOf('{"status":"error","message":"'
                + e.getMessage().left(200) + '"}');
        }
    }

    // ── Session attendance event ───────────────────────────────
    // Payload typically contains event_id, registrant_id, session_id

    private static void handleSessionEvent(
        Map<String, Object> payload, String eventType)
    {
        // Extract event_id — may be at top level or nested under 'data'
        String eventId = extractEventId(payload);
        if (String.isBlank(eventId)) {
            System.debug('Webhook handleSessionEvent: no event_id found in payload');
            return;
        }

        // No real-time enqueue — SwoogoEventSyncQueueable doesn't exist in
        // the org (or its signature doesn't match what was called here).
        // The webhook is still logged to Webhook_Log_c__c above for
        // visibility, but the actual sync for this event now happens on
        // the next scheduled 15-min run (SwoogoSyncBatch/SwoogoSessionSyncBatch)
        // rather than instantly.
        System.debug('Webhook: attendance change noted for event=' + eventId
            + ' trigger=' + eventType + ' — will sync on next scheduled run');
    }

    // ── Registrant status event ────────────────────────────────

    private static void handleRegistrantEvent(
        Map<String, Object> payload, String eventType)
    {
        String eventId = extractEventId(payload);
        if (String.isBlank(eventId)) {
            System.debug('Webhook handleRegistrantEvent: no event_id found');
            return;
        }

        // No real-time enqueue — see note in handleSessionEvent() above.
        // This event's registrant data will sync on the next scheduled run.
        System.debug('Webhook: registrant change noted for event=' + eventId
            + ' trigger=' + eventType + ' — will sync on next scheduled run');
    }

    // ── Extract event_id from various payload shapes ──────────

    private static String extractEventId(Map<String, Object> payload) {
        // Try top-level event_id
        Object eid = payload.get('event_id');
        if (eid != null) return String.valueOf(eid);

        // Try nested under 'data'
        Object data = payload.get('data');
        if (data != null) {
            Map<String, Object> dataMap = (Map<String, Object>) data;
            Object nestedEid = dataMap.get('event_id');
            if (nestedEid != null) return String.valueOf(nestedEid);
        }

        // Try nested under 'registrant'
        Object reg = payload.get('registrant');
        if (reg != null) {
            Map<String, Object> regMap = (Map<String, Object>) reg;
            Object regEid = regMap.get('event_id');
            if (regEid != null) return String.valueOf(regEid);
        }

        return null;
    }
}