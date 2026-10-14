// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyAssociationSyncSchedulable implements Schedulable {
    private List<Id> contactIds;
    public ShopifyAssociationSyncSchedulable(List<Id> contactIds) {
        this.contactIds = contactIds;
    }
    public void execute(SchedulableContext sc) {
        // ── CHANGED: added Account.BillingCountryCode / Account.ShippingCountryCode ──
        List<Contact> conns = [
            SELECT Id, Shopify_Customer_Id__c, Account.Shopify_Company_Id__c,
                   Account.RecordType.DeveloperName, Email, New_User_Email__c,
                   Account.Sales_Channel__c, Account.BillingCountryCode, Account.ShippingCountryCode
            FROM Contact
            WHERE Id IN :contactIds
        ];
        List<AccountContactRelationHandler.ShopifyAssociationInput> assigns = new List<AccountContactRelationHandler.ShopifyAssociationInput>();
        // ── NEW: track Contacts that still aren't ready, so this doesn't silently drop them ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

        for (Contact c : conns) {
            if (String.isNotBlank(c.Shopify_Customer_Id__c) &&
                c.Account != null &&
                String.isNotBlank(c.Account.Shopify_Company_Id__c)) {

                // ── NEW: resolve country the same way every other class in this project does ──
                String resolvedCountry = (c.Account.RecordType.DeveloperName == 'Store_Location')
                    ? c.Account.ShippingCountryCode
                    : c.Account.BillingCountryCode;

                assigns.add(new AccountContactRelationHandler.ShopifyAssociationInput(
                    c.Shopify_Customer_Id__c,
                    c.Account.Shopify_Company_Id__c,
                    c.Account.RecordType.DeveloperName,
                    c.Email != null ? c.Email : c.New_User_Email__c,
                    c.Account.Sales_Channel__c,
                    resolvedCountry   // ── NEW: uses the country-aware constructor ──
                ));
            } else {
                // ── NEW: log instead of silently dropping — this Contact still isn't ready ──
                // ── even after the 1-minute delay, and this scheduled job is a one-shot     ──
                // ── (it aborts itself below), so without this log there would be zero      ──
                // ── trace that the association was ever attempted or why it didn't happen.  ──
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'ShopifyAssociationSyncSchedulable - Still Not Ready After Delay',
                    Response_Message__c   = 'Contact or Account Shopify ID still not populated 1 minute after '
                                             + 'sync retry. Shopify_Customer_Id__c present: '
                                             + String.isNotBlank(c.Shopify_Customer_Id__c)
                                             + ' | Account Shopify_Company_Id__c present: '
                                             + (c.Account != null && String.isNotBlank(c.Account.Shopify_Company_Id__c)),
                    Related_Record_Id__c  = c.Id,
                    Log_Type__c           = 'API Errors'
                ));
            }
        }

        if (!assigns.isEmpty()) {
            System.enqueueJob(new ShopifyAssociationSyncQueueable(assigns));
        }

        // ── NEW: flush any not-ready logs before this scheduled job aborts itself ──
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception logEx) {
                System.debug('Failed to insert Api_Log__c records: ' + logEx.getMessage());
            }
        }

        System.abortJob(sc.getTriggerId());
    }
}