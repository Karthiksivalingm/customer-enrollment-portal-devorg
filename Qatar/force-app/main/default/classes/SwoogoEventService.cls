@RestResource(urlMapping='/swoogo/events')
global with sharing class SwoogoEventService {

    // --- Inner class for Event payload ---
    global class EventPayload {
        public Long id;
        public String name;
        public String start_date;
        public String end_date;
        public String location;
    }

    global class WebhookPayload {
        public String action;
        @JsonProperty('object')
        public String objectType;
        public EventPayload event;
        public String initiated_by;
        public String idempotency_key;
    }

    @HttpPost
    global static void handleEventCreated() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Webhook_Log_c__c log = new Webhook_Log_c__c();

        try {
            // --- Step 0: Validate body ---
            if (req.requestBody == null || req.requestBody.size() == 0) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Empty body');
                return;
            }

            // --- Step 1: Deserialize payload ---
            WebhookPayload wp = (WebhookPayload) JSON.deserialize(req.requestBody.toString(), WebhookPayload.class);

            if (wp == null || wp.event == null || wp.event.id == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Missing event payload');
                return;
            }

            // --- Step 2: Log raw body ---
            try {
                log.Name = 'Swoogo-Event-' + wp.event.id + '-' + Datetime.now().format('yyyyMMdd-HHmmss');
                log.Raw_Body__c = req.requestBody.toString();
                log.Status__c = 'Received';
                insert log;
            } catch (Exception logEx) {
                // swallow logging error
            }

            // --- Step 3: Upsert Invitation__c ---
            Invitation__c inv;
            List<Invitation__c> existing = [
                SELECT Id, External_Event_Id__c 
                FROM Invitation__c 
                WHERE External_Event_Id__c = :String.valueOf(wp.event.id) 
                LIMIT 1
            ];

            if (existing.isEmpty()) {
                inv = new Invitation__c(
                    External_Event_Id__c = String.valueOf(wp.event.id),
                    Name = String.isBlank(wp.event.name) ? 'Swoogo Event ' + wp.event.id : wp.event.name,
                    Event_Start_Date__c = wp.event.start_date != null ? Date.valueOf(wp.event.start_date) : null,
                    Event_End_Date__c   = wp.event.end_date   != null ? Date.valueOf(wp.event.end_date) : null,
                    Location__c         = wp.event.location
                );
                insert inv;
            } else {
                inv = existing[0];
                Boolean changed = false;
                if (wp.event.name != null && inv.Name != wp.event.name) { inv.Name = wp.event.name; changed = true; }
                if (wp.event.start_date != null) { inv.Event_Start_Date__c = Date.valueOf(wp.event.start_date); changed = true; }
                if (wp.event.end_date != null) { inv.Event_End_Date__c = Date.valueOf(wp.event.end_date); changed = true; }
                if (wp.event.location != null && inv.Location__c != wp.event.location) { inv.Location__c = wp.event.location; changed = true; }
                if (changed) update inv;
            }

            // --- Step 4: Success response ---
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Processed event ' + wp.event.id + ' successfully');

            // --- Step 5: Update log ---
            try {
                log.Status__c = 'Processed';
                update log;
            } catch (Exception logUpdateEx) { }

        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
            try {
                log.Status__c = 'Error';
                update log;
            } catch (Exception logUpdateEx) { }
        }
    }
}