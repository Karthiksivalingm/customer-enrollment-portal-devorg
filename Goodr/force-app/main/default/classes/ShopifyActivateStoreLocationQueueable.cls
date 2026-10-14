public class ShopifyActivateStoreLocationQueueable
    implements Queueable, Database.AllowsCallouts {

    private List<Id> storeLocationIds;
    private Integer  retryCount;

    // ── @TestVisible flag to bypass isRunningTest guard in specific tests ──
    // ── Only set to true in test methods that need to cover retry paths   ──
    // ── Never set to true in production code                              ──
    @TestVisible
    private static Boolean skipTestGuard = false;

    public ShopifyActivateStoreLocationQueueable(List<Id> storeLocationIds) {
        this.storeLocationIds = storeLocationIds;
        this.retryCount       = 0;
    }

    public ShopifyActivateStoreLocationQueueable(
        List<Id> storeLocationIds,
        Integer retryCount
    ) {
        this.storeLocationIds = storeLocationIds;
        this.retryCount       = retryCount;
    }

    public void execute(QueueableContext context) {

        List<Account> storesToActivate = [
            SELECT Id, Active__c, Shopify_Company_Id__c
            FROM Account
            WHERE Id IN :storeLocationIds
            AND Shopify_Company_Id__c != null
            AND Active__c = false
        ];

        if (storesToActivate.isEmpty()) {

            // ── Skip retry in test context unless skipTestGuard is set    ──
            // ── skipTestGuard is only set true in specific test methods   ──
            // ── that need to cover the retry and max retries paths        ──
            if (Test.isRunningTest() && !skipTestGuard) {
                System.debug(
                    'ShopifyActivateStoreLocationQueueable: ' +
                    'test context — skipping retry'
                );
                return;
            }

            if (retryCount < 5) {

                System.debug(
                    'ShopifyActivateStoreLocationQueueable: ' +
                    'Shopify_Company_Id__c not ready yet — ' +
                    'retry attempt ' + (retryCount + 1) + ' of 5 ' +
                    'for store ids: ' + storeLocationIds
                );

                System.enqueueJob(
                    new ShopifyActivateStoreLocationQueueable(
                        storeLocationIds,
                        retryCount + 1
                    )
                );

            } else {

                System.debug(
                    'ShopifyActivateStoreLocationQueueable: ' +
                    'ALERT — max retries (5) reached. ' +
                    'Store Locations need manual activation: ' +
                    storeLocationIds
                );

                try {
                    insert new Api_Log__c(
                        Context__c          =
                            'ShopifyActivateStoreLocationQueueable',
                        Response_Message__c =
                            'Max retries reached — Store Location ' +
                            'Active__c was not set to true after 5 attempts. ' +
                            'Shopify_Company_Id__c was never written. ' +
                            'Manual activation required.',
                        Stack_Trace__c      =
                            'Store Location Ids: ' + storeLocationIds,
                        Log_Type__c         = 'API Errors'
                    );
                } catch (Exception logEx) {
                    System.debug(
                        'Failed to insert Api_Log__c: ' +
                        logEx.getMessage()
                    );
                }
            }
            return;
        }

        List<Account> toUpdate = new List<Account>();
        for (Account store : storesToActivate) {
            toUpdate.add(new Account(
                Id        = store.Id,
                Active__c = true
            ));
        }

        System.debug(
            'ShopifyActivateStoreLocationQueueable: ' +
            'setting Active__c = true on ' + toUpdate.size() + ' stores' +
            ' (retry attempt: ' + retryCount + ')'
        );

        update toUpdate;
    }
}