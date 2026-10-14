public class ShopifyAccountSyncQueuable implements Queueable, Database.AllowsCallouts {

    private List<Id> accountIds;

    public ShopifyAccountSyncQueuable(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        try {
            ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify(accountIds);
        } catch (Exception ex) {
            System.debug('Error syncing accounts to Shopify: ' + ex.getMessage());
        }
    }
}