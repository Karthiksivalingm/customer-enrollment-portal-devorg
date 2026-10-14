public class ShopifyContactSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> contactIds;
    public ShopifyContactSyncQueueable(List<Id> contactIds) {
        this.contactIds = contactIds;
    }
    public void execute(QueueableContext context) {
        try {
            ShopifyContactIntegration.sendToShopify(contactIds);
        } catch (Exception ex) {
            System.debug('Error syncing contact to Shopify: ' + ex.getMessage());

            // ── NEW: Persist the failure so it's visible in Api_Log__c ──
            // ── instead of only appearing in a debug log that's lost   ──
            // ── once the async transaction completes.                 ──
            List<Api_Log__c> failureLogs = new List<Api_Log__c>();
            if (contactIds != null && !contactIds.isEmpty()) {
                for (Id conId : contactIds) {
                    failureLogs.add(new Api_Log__c(
                        Context__c            = 'ShopifyContactSyncQueueable - Unhandled Exception',
                        Response_Message__c   = ex.getMessage(),
                        Stack_Trace__c        = ex.getStackTraceString(),
                        Related_Record_Id__c  = conId,
                        Log_Type__c           = 'API Errors'
                    ));
                }
            } else {
                failureLogs.add(new Api_Log__c(
                    Context__c           = 'ShopifyContactSyncQueueable - Unhandled Exception',
                    Response_Message__c  = ex.getMessage(),
                    Stack_Trace__c       = ex.getStackTraceString(),
                    Log_Type__c          = 'API Errors'
                ));
            }

            try {
                insert failureLogs;
            } catch (Exception logEx) {
                System.debug('Failed to insert Api_Log__c for ShopifyContactSyncQueueable failure: ' + logEx.getMessage());
            }
        }
    }
}