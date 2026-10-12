public inherited sharing class ShopifyActiveStatusSyncQueueable
    implements Queueable, Database.AllowsCallouts {
    private List<Account> locations;

    public ShopifyActiveStatusSyncQueueable(List<Account> locations) {
        this.locations = locations;
    }

    public void execute(QueueableContext context) {
        // ── FIX: Call the new dedicated service, not ShopifyAccountIntegration ──
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(locations);
    }
}