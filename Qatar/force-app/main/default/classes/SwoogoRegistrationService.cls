@RestResource(urlMapping='/swoogo/registrations')
global with sharing class SwoogoRegistrationService {

    // Inner class representing a registrant for Salesforce
    global class Registrant {
        public String first_name;
        public String last_name;
        public String email;
        public String registration_status;
        public Boolean attended;
        public String company;
        public String job_title;
        public String mobile_phone;
        public String work_phone;
        public String twitter_handle;
        public String contact_id; // <-- added
    }

    // Payload containing event_id and registrants
    global class RegistrationPayload {
        public String event_id;
        public String event_name;
        public List<Registrant> items;
    }

    // Wrapper class for webhook JSON
    global class WebhookPayload {
        public String action;
        @JsonProperty('object')
        public String objectType;
        public WebhookRegistrant registrant;
        public String initiated_by;
        public String idempotency_key;
    }

    global class WebhookRegistrant {
        public Long id;
        public Long event_id;
        public String first_name;
        public String last_name;
        public String email;
        public String registration_status;
        public RegType reg_type_id;
        public String checked_in_at;
        public String company;
        public String job_title;
        public String mobile_phone;
        public String work_phone;
        public String twitter_handle;
        public String contact_id;
    }

    global class RegType {
        public String value;
    }

    @HttpPost
    global static void handleRegistrations() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Webhook_Log_c__c log = new Webhook_Log_c__c();

        try {
            // --- Step 0: Validate request body ---
            if (req.requestBody == null || req.requestBody.size() == 0) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Empty body');
                return;
            }

            // --- Step 1: Deserialize webhook JSON ---
            WebhookPayload wp = (WebhookPayload) JSON.deserialize(req.requestBody.toString(), WebhookPayload.class);

            if (wp == null || wp.registrant == null || wp.registrant.event_id == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Missing event_id');
                return;
            }

            // --- Step 2: Log the raw payload ---
            try {
                log.Name = 'Swoogo-' + wp.registrant.id + '-' + Datetime.now().format('yyyyMMdd-HHmmss');
                log.Raw_Body__c = req.requestBody.toString();
                log.Status__c = 'Received';
                insert log;
            } catch (Exception logEx) {
                // Swallow logging errors
            }

            // --- Step 3: Map to internal payload format ---
            RegistrationPayload payload = new RegistrationPayload();
            payload.event_id = String.valueOf(wp.registrant.event_id);
            payload.event_name = 'Swoogo Event ' + wp.registrant.event_id;

            payload.items = new List<Registrant>();
            Registrant r = new Registrant();
            r.first_name = wp.registrant.first_name;
            r.last_name = wp.registrant.last_name;
            r.email = wp.registrant.email;
            r.registration_status = wp.registrant.registration_status;
            r.attended = wp.registrant.reg_type_id.value == 'Attendee';
            r.company = wp.registrant.company;
            r.job_title = wp.registrant.job_title;
            r.mobile_phone = wp.registrant.mobile_phone;
            r.work_phone = wp.registrant.work_phone;
            r.twitter_handle = wp.registrant.twitter_handle;

            // --- NEW: map contact_id from webhook to internal Registrant ---
            r.contact_id = wp.registrant.contact_id;

            payload.items.add(r);

            // --- STEP 4: Upsert Invitation__c ---
            Map<String, Invitation__c> invitationByExtId = new Map<String, Invitation__c>();
            Invitation__c inv;
            List<Invitation__c> invToInsert = new List<Invitation__c>();

            for (Invitation__c e : [SELECT Id, External_Event_Id__c FROM Invitation__c WHERE External_Event_Id__c = :payload.event_id LIMIT 1]) {
                invitationByExtId.put(e.External_Event_Id__c, e);
            }

            if (!invitationByExtId.containsKey(payload.event_id)) {
                inv = new Invitation__c(
                    External_Event_Id__c = payload.event_id,
                    Name = String.isBlank(payload.event_name) ? 'Swoogo Event ' + payload.event_id : payload.event_name
                );
                invToInsert.add(inv);
                insert invToInsert;
            } else {
                inv = invitationByExtId.get(payload.event_id);
            }

            // --- STEP 5: Upsert Contacts (with External ID and email update) ---
            Map<String, Contact> contactByEmail = new Map<String, Contact>();
            Set<String> emails = new Set<String>();
            Set<String> externalIds = new Set<String>();

            for (Registrant reg : payload.items) {
                if (String.isNotBlank(reg.email)) emails.add(reg.email.toLowerCase());
                if (reg.contact_id != null) externalIds.add(reg.contact_id);
            }

            if (!emails.isEmpty() || !externalIds.isEmpty()) {
                for (Contact c : [
                    SELECT Id, Email, FirstName, LastName, Title, MobilePhone, Phone,
                           Social_Media_Twitter__c, Admin_Email__c, Email_Office__c,
                           Email_2__c, Private_Email__c, Contact_External_Id__c
                    FROM Contact
                    WHERE Email IN :emails
                       OR Admin_Email__c IN :emails
                       OR Email_Office__c IN :emails
                       OR Email_2__c IN :emails
                       OR Private_Email__c IN :emails
                       OR Contact_External_Id__c IN :externalIds
                ]) {
                    if (String.isNotBlank(c.Email)) contactByEmail.put(c.Email.toLowerCase(), c);
                    if (String.isNotBlank(c.Admin_Email__c)) contactByEmail.put(c.Admin_Email__c.toLowerCase(), c);
                    if (String.isNotBlank(c.Email_Office__c)) contactByEmail.put(c.Email_Office__c.toLowerCase(), c);
                    if (String.isNotBlank(c.Email_2__c)) contactByEmail.put(c.Email_2__c.toLowerCase(), c);
                    if (String.isNotBlank(c.Private_Email__c)) contactByEmail.put(c.Private_Email__c.toLowerCase(), c);
                    if (String.isNotBlank(c.Contact_External_Id__c)) contactByEmail.put(c.Contact_External_Id__c, c);
                }
            }

            List<Contact> contactsToInsert = new List<Contact>();
            List<Contact> contactsToUpdate = new List<Contact>();

            for (Registrant reg : payload.items) {
                if (String.isBlank(reg.email) && reg.contact_id == null) continue;

                String emailKey = (reg.email != null) ? reg.email.toLowerCase() : null;
                String externalId = (reg.contact_id != null) ? reg.contact_id : null;

                Contact c;
                if (externalId != null && contactByEmail.containsKey(externalId)) {
                    c = contactByEmail.get(externalId);
                } else if (emailKey != null && contactByEmail.containsKey(emailKey)) {
                    c = contactByEmail.get(emailKey);
                }

                if (c == null) {
                    c = new Contact(
                        FirstName = String.isBlank(reg.first_name) ? 'Unknown' : reg.first_name,
                        LastName = String.isBlank(reg.last_name) ? (reg.email != null ? reg.email.split('@')[0] : 'Unknown') : reg.last_name,
                        Email_Office__c = reg.email,
                       
                        Title = reg.job_title,
                        MobilePhone = reg.mobile_phone,
                        Phone = reg.work_phone,
                        Swoogo__c = true,
                        Social_Media_Twitter__c = reg.twitter_handle
                    );

                    if (externalId != null) c.Contact_External_Id__c = externalId;

                    contactsToInsert.add(c);
                    if (emailKey != null) contactByEmail.put(emailKey, c);
                    if (externalId != null) contactByEmail.put(externalId, c);

                } else {
                    Boolean changed = false;

                    if (reg.job_title != null && c.Title != reg.job_title) { c.Title = reg.job_title; changed = true; }
                    if (reg.mobile_phone != null && c.MobilePhone != reg.mobile_phone) { c.MobilePhone = reg.mobile_phone; changed = true; }
                    if (reg.work_phone != null && c.Phone != reg.work_phone) { c.Phone = reg.work_phone; changed = true; }
                    if (reg.twitter_handle != null && c.Social_Media_Twitter__c != reg.twitter_handle) { c.Social_Media_Twitter__c = reg.twitter_handle; changed = true; }

                    if (String.isBlank(c.Contact_External_Id__c) && externalId != null) {
                        c.Contact_External_Id__c = externalId;
                        changed = true;
                    }

                 
if (reg.email != null && c.Email_Office__c != reg.email) {
    c.Email_Office__c = reg.email;
    changed = true;
}

                    if (changed) contactsToUpdate.add(c);
                }
            }

            if (!contactsToInsert.isEmpty()) insert contactsToInsert;
            if (!contactsToUpdate.isEmpty()) update contactsToUpdate;

           // --- STEP 6: Upsert Guest_List__c ---
Map<String, Guest_List__c> guestByKey = new Map<String, Guest_List__c>();
List<Id> contactIds = new List<Id>();

// Collect all Contact IDs from contactByEmail map
for (Contact c : contactByEmail.values()) contactIds.add(c.Id);

if (!contactIds.isEmpty() && inv != null && inv.Id != null) {
    for (Guest_List__c g : [SELECT Id, Invitation__c, Contact__c, RSVP__c, Attended__c
                             FROM Guest_List__c
                             WHERE Invitation__c = :inv.Id AND Contact__c IN :contactIds]) {
        String key = g.Invitation__c + '|' + g.Contact__c;
        guestByKey.put(key, g);
    }
}

List<Guest_List__c> guestToInsert = new List<Guest_List__c>();
List<Guest_List__c> guestToUpdate = new List<Guest_List__c>();

for (Registrant reg : payload.items) {
    // Skip if no email and no external ID
    if (String.isBlank(reg.email) && reg.contact_id == null) continue;

    // Find Contact by external ID first, then email
    Contact c;
    String emailKey = (reg.email != null) ? reg.email.toLowerCase() : null;
    String externalId = (reg.contact_id != null) ? reg.contact_id : null;

    if (externalId != null && contactByEmail.containsKey(externalId)) {
        c = contactByEmail.get(externalId);
    } else if (emailKey != null && contactByEmail.containsKey(emailKey)) {
        c = contactByEmail.get(emailKey);
    }

    if (c == null) continue;

    String key = inv.Id + '|' + c.Id;

    if (guestByKey.containsKey(key)) {
        // Update existing Guest_List__c
        Guest_List__c g = guestByKey.get(key);
        Boolean changed = false;

        if (reg.registration_status != null && g.RSVP__c != reg.registration_status) {
            g.RSVP__c = reg.registration_status;
            changed = true;
        }
        if (reg.attended != null && g.Attended__c != reg.attended) {
            g.Attended__c = reg.attended;
            changed = true;
        }

        if (changed) guestToUpdate.add(g);
    } else {
        // Insert new Guest_List__c
        Guest_List__c g = new Guest_List__c(
            Invitation__c = inv.Id,
            Contact__c = c.Id,
            RSVP__c = reg.registration_status,
            Attended__c = reg.attended
        );
        guestToInsert.add(g);
    }
}

// Perform DML
if (!guestToInsert.isEmpty()) insert guestToInsert;
if (!guestToUpdate.isEmpty()) update guestToUpdate;

            // --- STEP 7: Success response ---
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Processed ' + payload.items.size() + ' registrant(s) successfully');

            // --- Update log status ---
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