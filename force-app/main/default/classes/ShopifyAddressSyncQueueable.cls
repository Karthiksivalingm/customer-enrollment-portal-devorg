public class ShopifyAddressSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    private List<Account> locations;

    public ShopifyAddressSyncQueueable(List<Account> locations) {
        this.locations = locations;
    }

    public void execute(QueueableContext context) {
        ShopifyAddressSyncService.syncAddressToShopify(locations);
    }
}