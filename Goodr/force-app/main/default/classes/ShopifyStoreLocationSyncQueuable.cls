public class ShopifyStoreLocationSyncQueuable implements Queueable, Database.AllowsCallouts {
    private List<Id> storeLocationIds;

    public ShopifyStoreLocationSyncQueuable(List<Id> storeLocationIds) {
        this.storeLocationIds = storeLocationIds;
    }

    public void execute(QueueableContext context) {
        ShopifyAccountIntegration.createStoreLocations(storeLocationIds);
    }
}