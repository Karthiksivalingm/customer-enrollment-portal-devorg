// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyContactManualSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id accountId;

    public ShopifyContactManualSyncQueueable(Id accountId) {
        this.accountId = accountId;
    }

    public void execute(QueueableContext context) {
        List<Contact> contactsToSync = [
            SELECT Id, Shopify_Customer_Id__c
            FROM Contact
            WHERE AccountId = :accountId
        ];

        List<Id> newContacts = new List<Id>();
        for (Contact c : contactsToSync) {
            if (String.isBlank(c.Shopify_Customer_Id__c)) {
                newContacts.add(c.Id);
            }
        }

        if (!newContacts.isEmpty()) {
            ShopifyContactIntegration.sendToShopify(newContacts);
        }

        System.enqueueJob(new ShopifyManualAssociationQueueable(accountId));
    }
}