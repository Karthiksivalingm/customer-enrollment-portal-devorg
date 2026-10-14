// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyManualAssociationQueueable implements Queueable, Database.AllowsCallouts {
    private Id accountId;
    public ShopifyManualAssociationQueueable(Id accountId) {
        this.accountId = accountId;
    }
    public void execute(QueueableContext context) {
        // ── CHANGED: added Account.BillingCountryCode / Account.ShippingCountryCode ──
        List<AccountContactRelation> relations = [
            SELECT Id, ContactId, AccountId, Contact.Email, Contact.Shopify_Customer_Id__c,
            Account.Shopify_Company_Id__c, Account.RecordType.DeveloperName, Account.Sales_Channel__c,
            Account.BillingCountryCode, Account.ShippingCountryCode
            FROM AccountContactRelation
            WHERE (Account.ParentId = :accountId OR AccountId = :accountId)
            AND Contact.Shopify_Customer_Id__c != null
            AND Account.Shopify_Company_Id__c != null
           AND Account.Active__c = true  // NEW: skip deactivated store locations
        ];
        if (relations.isEmpty()) {
            System.debug('No AccountContactRelation records found with Shopify IDs populated');
            return;
        }
        List<AccountContactRelationHandler.ShopifyAssociationInput> companyAssociations =
            new List<AccountContactRelationHandler.ShopifyAssociationInput>();
        List<AccountContactRelationHandler.ShopifyAssociationInput> locationAssociations =
            new List<AccountContactRelationHandler.ShopifyAssociationInput>();
        for (AccountContactRelation relation : relations) {
            // ── CHANGED: resolve country and pass via new constructor ──
            String resolvedCountry = (relation.Account.RecordType.DeveloperName == 'Store_Location')
                ? relation.Account.ShippingCountryCode
                : relation.Account.BillingCountryCode;

            AccountContactRelationHandler.ShopifyAssociationInput association =
                new AccountContactRelationHandler.ShopifyAssociationInput(
                    relation.Contact.Shopify_Customer_Id__c,
                    relation.Account.Shopify_Company_Id__c,
                    relation.Account.RecordType.DeveloperName,
                    relation.Contact.Email,
                    relation.Account.Sales_Channel__c,
                    resolvedCountry
                );
            if (relation.Account.RecordType.DeveloperName == 'Company') {
                companyAssociations.add(association);
            } else if (relation.Account.RecordType.DeveloperName == 'Store_Location') {
                locationAssociations.add(association);
            }
        }
        if (!companyAssociations.isEmpty()) {
            ShopifyAssociationIntegration.process(companyAssociations);
        }
        if (!locationAssociations.isEmpty()) {
            ShopifyAssociationIntegration.process(locationAssociations);
        }
    }
}