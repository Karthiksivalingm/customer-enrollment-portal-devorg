public with sharing class ShopifyAssociationRetryBatch
    implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // ── Find Store Locations created in the last 60 minutes that:  ──
        // ── 1. Are Active = true                                        ──
        // ── 2. Have a Shopify ID (location created in Shopify)          ──
        // ── 3. Not Key Accounts                                         ──
        DateTime cutoff = DateTime.now().addMinutes(-60);
        return Database.getQueryLocator([
            SELECT Id, Active__c, Shopify_Company_Id__c,
                   Sales_Channel__c, ParentId,
                   Parent.Shopify_Company_Id__c
            FROM Account
            WHERE RecordType.DeveloperName = 'Store_Location'
            AND Active__c = true
            AND Shopify_Company_Id__c != null
            AND Sales_Channel__c NOT IN ('Key Accounts')
            AND CreatedDate >= :cutoff
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Account> storeLocations
    ) {
        Set<Id> locationIds = new Set<Id>();
        for (Account loc : storeLocations) {
            locationIds.add(loc.Id);
        }

        // ── Find ACRs on these locations where:                        ──
        // ── Contact has Shopify_Customer_Id__c (customer exists)       ──
        // ── ACR has no Shopify_Role_Assignment_Id__c (not yet approved)──
        List<AccountContactRelation> pendingAcrs = [
            SELECT Id, ContactId, AccountId,
                   Contact.Email,
                   Contact.Shopify_Customer_Id__c,
                   Account.Shopify_Company_Id__c,
                   Account.Sales_Channel__c,
                   Account.RecordType.DeveloperName
            FROM AccountContactRelation
            WHERE AccountId IN :locationIds
            AND Contact.Shopify_Customer_Id__c != null
            AND Contact.Email != null
            AND Shopify_Role_Assignment_Id__c = null
        ];

        if (pendingAcrs.isEmpty()) {
            System.debug(
                'ShopifyAssociationRetryBatch: no pending ACRs found ' +
                'for locations: ' + locationIds
            );
            return;
        }

        // ── Build association inputs and process ───────────────────────
        List<AccountContactRelationHandler.ShopifyAssociationInput> inputs =
            new List<AccountContactRelationHandler.ShopifyAssociationInput>();

        for (AccountContactRelation acr : pendingAcrs) {
            inputs.add(
                new AccountContactRelationHandler.ShopifyAssociationInput(
                    acr.Contact.Shopify_Customer_Id__c,
                    acr.Account.Shopify_Company_Id__c,
                    acr.Account.RecordType.DeveloperName,
                    acr.Contact.Email,
                    acr.Account.Sales_Channel__c
                )
            );
        }

        System.debug(
            'ShopifyAssociationRetryBatch: processing ' +
            inputs.size() + ' pending associations'
        );

        ShopifyAssociationIntegration.process(inputs);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ShopifyAssociationRetryBatch: completed');
    }
}