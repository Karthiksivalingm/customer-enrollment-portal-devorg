// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyContactIntegration {

    private static String newCustomerId;

    // ── NEW: local buffer inserted explicitly at the end of sendToShopify(), mirroring the ──
    // ── proven working pattern already used in ShopifyAccountIntegration and                ──
    // ── ShopifyAddressSyncService. This replaces every APILogger.logCalloutError() call in   ──
    // ── this class — that method only adds to APILogger's own static buffer, which nothing   ──
    // ── in this class ever flushed, meaning EVERY failure logged via that method (config      ──
    // ── errors, HTTP errors, GraphQL userErrors, exceptions) was being silently lost with     ──
    // ── zero DML ever occurring. Confirmed directly from a debug log showing                  ──
    // ── "Number of DML statements: 0 out of 150" despite a real "Phone is invalid" userError  ──
    // ── having occurred and reached the logging call.                                         ──
    private static List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

    public static void sendToShopify(List<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            System.debug('No contacts to sync.');
            return;
        }

        List<Contact> contactsToSync = [
            SELECT Id, FirstName, LastName, Email, Phone, Shopify_Customer_Id__c, Sales_Channel__c,
                   Retailer_Communication_Opt_In__c, MailingCountryCode
            FROM Contact
            WHERE Id IN :contactIds
        ];

        Map<Id, String> contactToShopifyId = new Map<Id, String>();

        for (Contact con : contactsToSync) {
            Shopify_Configuration__c cfg;
            try {
                cfg = ShopifyConfigService.getConfigByCountry(con.MailingCountryCode);
            } catch (Exception configEx) {
                // ── CHANGED: direct Api_Log__c insert instead of APILogger.logCalloutError() ──
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Customer Creation - Config Resolution Failed',
                    Response_Message__c   = 'Country: ' + con.MailingCountryCode + ' | ' + configEx.getMessage(),
                    Related_Record_Id__c  = con.Id,
                    Log_Type__c           = 'API Errors'
                ));
                continue;
            }

            if (cfg == null) {
                System.debug('No Shopify config found for country: ' + con.MailingCountryCode);
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Customer Creation - No Config Found',
                    Response_Message__c   = 'No config found for country: ' + con.MailingCountryCode,
                    Related_Record_Id__c  = con.Id,
                    Log_Type__c           = 'API Errors'
                ));
                continue;
            }

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res;

            String query = 'mutation customerCreate($input: CustomerInput!) {' +
                           '  customerCreate(input: $input) {' +
                           '    customer {' +
                           '      id' +
                           '      email' +
                           '      phone' +
                           '      taxExempt' +
                           '      firstName' +
                           '      lastName' +
                           '      emailMarketingConsent {' +
                           '        marketingState' +
                           '        marketingOptInLevel' +
                           '      }' +
                           '    }' +
                           '    userErrors {' +
                           '      field' +
                           '      message' +
                           '    }' +
                           '  }' +
                           '}';

            Map<String, Object> variables = new Map<String, Object>{
                'input' => new Map<String, Object>{
                    'email' => con.Email != null ? con.Email : '',
                    'phone' => con.Phone != null ? con.Phone : '',
                    'firstName' => con.FirstName != null ? con.FirstName : '',
                    'lastName' => con.LastName != null ? con.LastName : '',
                    'emailMarketingConsent' => new Map<String, Object>{
                        'marketingState' => con.Retailer_Communication_Opt_In__c == true ? 'SUBSCRIBED' : 'NOT_SUBSCRIBED',
                        'marketingOptInLevel' => con.Retailer_Communication_Opt_In__c == true ? 'SINGLE_OPT_IN' : 'UNKNOWN'
                    }
                }
            };

            Map<String, Object> payload = new Map<String, Object>{
                'query' => query,
                'variables' => variables
            };

            req.setEndpoint(cfg.Shopify_Endpoint__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
            req.setBody(JSON.serialize(payload));

            try {
                res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> data = (Map<String, Object>) response.get('data');
                    Map<String, Object> customerCreate = (Map<String, Object>) data.get('customerCreate');

                    List<Object> userErrors = (List<Object>) customerCreate.get('userErrors');
                    if (userErrors != null && !userErrors.isEmpty()) {
                        String errorMessage = '';
                        for (Object errObj : userErrors) {
                            Map<String, Object> err = (Map<String, Object>) errObj;
                            errorMessage += (String) err.get('message') + ' ';
                        }

                        // ── CHANGED: direct Api_Log__c insert. The clean, human-readable ──
                        // ── Shopify error text (e.g. "Phone is invalid") is stored in     ──
                        // ── Response_Message__c specifically so it's visible at a glance   ──
                        // ── without needing to parse a raw JSON blob.                      ──
                        logsToInsert.add(new Api_Log__c(
                            Context__c            = 'Shopify Customer Creation - userErrors',
                            Status_Code__c        = res.getStatusCode(),
                            Request_Message__c    = req.getBody(),
                            Response_Message__c   = errorMessage.trim(),
                            Stack_Trace__c        = res.getBody(),
                            Related_Record_Id__c  = con.Id,
                            Log_Type__c           = 'API Errors'
                        ));

                        continue;
                    }

                    Map<String, Object> customer = (Map<String, Object>) customerCreate.get('customer');
                    if (customer != null) {
                        String customerId = extractLastIdPart((String) customer.get('id'));
                        System.debug('Customer created with ID: ' + customerId + ' for Contact: ' + con.Id);
                        contactToShopifyId.put(con.Id, customerId);
                    } else {
                        logsToInsert.add(new Api_Log__c(
                            Context__c            = 'Shopify Customer Creation - Missing customer object',
                            Status_Code__c        = res.getStatusCode(),
                            Request_Message__c    = req.getBody(),
                            Response_Message__c   = 'Customer object is null',
                            Stack_Trace__c        = res.getBody(),
                            Related_Record_Id__c  = con.Id,
                            Log_Type__c           = 'API Errors'
                        ));
                    }

                } else {
                    logsToInsert.add(new Api_Log__c(
                        Context__c            = 'Shopify Customer Creation - HTTP Error',
                        Status_Code__c        = res != null ? res.getStatusCode() : 0,
                        Request_Message__c    = req.getBody(),
                        Response_Message__c   = 'HTTP ' + (res != null ? String.valueOf(res.getStatusCode()) : '0'),
                        Stack_Trace__c        = res != null ? res.getBody() : '',
                        Related_Record_Id__c  = con.Id,
                        Log_Type__c           = 'API Errors'
                    ));
                    System.debug('Failed to sync Contact ' + con.Id + '. Status: ' + res.getStatusCode() + '. Body: ' + res.getBody());
                }
            } catch (Exception ex) {
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Customer Creation - Exception',
                    Request_Message__c    = req.getBody(),
                    Response_Message__c   = ex.getMessage(),
                    Stack_Trace__c        = ex.getStackTraceString(),
                    Related_Record_Id__c  = con.Id,
                    Log_Type__c           = 'API Errors'
                ));
                System.debug('Exception while sending Contact ' + con.Id + ' to Shopify: ' + ex.getMessage());
            }
        }

        if (!contactToShopifyId.isEmpty()) {
            List<Contact> contactsToUpdate = new List<Contact>();

            for (Id contactId : contactToShopifyId.keySet()) {
                contactsToUpdate.add(new Contact(
                    Id = contactId,
                    Shopify_Customer_Id__c = contactToShopifyId.get(contactId)
                ));
            }

            try {
                update contactsToUpdate;
                System.debug('Successfully updated contacts with Shopify Customer IDs.');
            } catch (DmlException dmx) {
                System.debug('Error updating contacts with Shopify Customer IDs: ' + dmx.getMessage());

                for (Contact c : contactsToUpdate) {
                    logsToInsert.add(new Api_Log__c(
                        Context__c            = 'Shopify Customer Creation - DML Update Failed (customer WAS created in Shopify)',
                        Response_Message__c   = dmx.getMessage(),
                        Related_Record_Id__c  = c.Id,
                        Log_Type__c           = 'API Errors'
                    ));
                }
            }
        }

        // ── NEW: single, guaranteed flush at the very end of this method. This is the ──
        // ── critical missing piece — every logsToInsert.add() above now actually gets ──
        // ── written to the database, regardless of which failure branch was hit.      ──
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception logInsertEx) {
                System.debug('Failed to insert Api_Log__c records: ' + logInsertEx.getMessage());
            }
        }
    }

    @TestVisible
    private static String extractLastIdPart(String fullGid) {
        if (String.isBlank(fullGid)) {
            return null;
        }

        String[] parts = fullGid.split('/');
        return parts.isEmpty() ? null : parts[parts.size() - 1];
    }
}