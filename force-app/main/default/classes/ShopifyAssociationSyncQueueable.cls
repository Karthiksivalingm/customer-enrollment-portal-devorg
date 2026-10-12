public with sharing class ShopifyAssociationSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<AccountContactRelationHandler.ShopifyAssociationInput> associations;

    private Id contactId;
    private Id accountId;
    private Integer retryCount; // ── NEW: mirrors ShopifyActivateStoreLocationQueueable's retry pattern ──

    // ── @TestVisible flag to bypass isRunningTest guard in specific tests ──
    // ── Only set to true in test methods that need to cover retry paths   ──
    // ── Never set to true in production code                              ──
    @TestVisible
    private static Boolean skipTestGuard = false;

    public ShopifyAssociationSyncQueueable(Id contactId, Id accountId) {
        this.contactId = contactId;
        this.accountId = accountId;
        this.retryCount = 0;
    }

    // ── NEW: retry-aware constructor, mirrors ShopifyActivateStoreLocationQueueable's pattern ──
    public ShopifyAssociationSyncQueueable(Id contactId, Id accountId, Integer retryCount) {
        this.contactId = contactId;
        this.accountId = accountId;
        this.retryCount = retryCount;
    }

    public ShopifyAssociationSyncQueueable(List<AccountContactRelationHandler.ShopifyAssociationInput> associations) {
        this.associations = associations;
    }

    public void execute(QueueableContext context) {
        if (associations != null && !associations.isEmpty()) {
            ShopifyAssociationIntegration.process(associations);
        } else {
            Contact contact = [SELECT Id, Email, Shopify_Customer_Id__c, Sales_Channel__c FROM Contact WHERE Id = :contactId LIMIT 1];
            // ── CHANGED: added BillingCountryCode / ShippingCountryCode ──
            Account account = [
                SELECT Id, RecordType.DeveloperName, Shopify_Company_Id__c, Sales_Channel__c,
                       BillingCountryCode, ShippingCountryCode
                FROM Account WHERE Id = :accountId LIMIT 1
            ];

            Boolean customerReady = String.isNotBlank(contact.Shopify_Customer_Id__c);
            Boolean companyReady = String.isNotBlank(account.Shopify_Company_Id__c);

            if (customerReady && companyReady) {
                // ── CHANGED: resolve country and pass via new constructor ──
                String resolvedCountry = (account.RecordType.DeveloperName == 'Store_Location')
                    ? account.ShippingCountryCode
                    : account.BillingCountryCode;
                List<AccountContactRelationHandler.ShopifyAssociationInput> singlePairAssociations = new List<AccountContactRelationHandler.ShopifyAssociationInput>{
                    new AccountContactRelationHandler.ShopifyAssociationInput(
                        contact.Shopify_Customer_Id__c,
                        account.Shopify_Company_Id__c,
                        account.RecordType.DeveloperName,
                        contact.Email,
                        account.Sales_Channel__c,
                        resolvedCountry
                    )
                };
                ShopifyAssociationIntegration.process(singlePairAssociations);

            } else {

                // ── NEW: retry instead of a permanent silent skip. Previously, if the       ──
                // ── Contact or Account's Shopify ID wasn't populated yet at the exact moment ──
                // ── this queueable ran (a real timing race against ShopifyContactSyncQueueable──
                // ── / ShopifyAccountSyncQueuable), the association attempt was abandoned      ──
                // ── forever with only a System.debug — meaning a Contact could successfully   ──
                // ── sync to Shopify moments later and STILL never get associated to its       ──
                // ── Company, with zero trace anywhere. Mirrors the exact retry pattern already ──
                // ── proven in ShopifyActivateStoreLocationQueueable.

                // ── Skip retry in test context unless skipTestGuard is set    ──
                // ── skipTestGuard is only set true in specific test methods   ──
                // ── that need to cover the retry and max retries paths        ──
                if (Test.isRunningTest() && !skipTestGuard) {
                    System.debug(
                        'ShopifyAssociationSyncQueueable: test context — skipping retry'
                    );
                    return;
                }

                if (retryCount < 5) {

                    System.debug(
                        'ShopifyAssociationSyncQueueable: Shopify ID not yet populated — ' +
                        'retry attempt ' + (retryCount + 1) + ' of 5 ' +
                        'for contactId: ' + contactId + ' accountId: ' + accountId
                    );

                    System.enqueueJob(
                        new ShopifyAssociationSyncQueueable(contactId, accountId, retryCount + 1)
                    );

                } else {

                    System.debug(
                        'ShopifyAssociationSyncQueueable: ALERT — max retries (5) reached. ' +
                        'Association needs manual sync for contactId: ' + contactId +
                        ' accountId: ' + accountId
                    );

                    try {
                        insert new Api_Log__c(
                            Context__c           = 'ShopifyAssociationSyncQueueable - Max Retries Reached',
                            Response_Message__c  = 'Max retries reached — Contact/Company association was '
                                                    + 'never completed after 5 attempts. customerReady=' + customerReady
                                                    + ' companyReady=' + companyReady + '. Manual sync required.',
                            Stack_Trace__c       = 'contactId: ' + contactId + ' | accountId: ' + accountId,
                            Related_Record_Id__c = contactId,
                            Log_Type__c          = 'API Errors'
                        );
                    } catch (Exception logEx) {
                        System.debug('Failed to insert Api_Log__c: ' + logEx.getMessage());
                    }
                }
            }
        }
    }
}