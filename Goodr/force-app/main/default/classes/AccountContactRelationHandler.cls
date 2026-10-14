public inherited sharing class AccountContactRelationHandler {
   public static void handleAfterInsert(List<AccountContactRelation> acrList) {
       if (acrList == null || acrList.isEmpty()) {
           return;
       }
       Set<Id> contactIds = new Set<Id>();
       Set<Id> accountIds = new Set<Id>();
       for (AccountContactRelation acr : acrList) {
           if (acr.ContactId != null && acr.AccountId != null) {
               contactIds.add(acr.ContactId);
               accountIds.add(acr.AccountId);
           }
       }
       if (contactIds.isEmpty() || accountIds.isEmpty()) {
           return;
       }
       // SOQL queries outside loops
       List<Contact> contactList = [
           SELECT Id, Email, Shopify_Customer_Id__c, Sales_Channel__c
           FROM Contact
           WHERE Id IN :contactIds
       ];
       // ── CHANGED: added BillingCountryCode / ShippingCountryCode ──
       List<Account> accountList = [
           SELECT Id, RecordType.DeveloperName, Shopify_Company_Id__c, Sales_Channel__c,
                  BillingCountryCode, ShippingCountryCode
           FROM Account
           WHERE Id IN :accountIds
       ];
       Map<Id, Contact> contactMap = new Map<Id, Contact>(contactList);
       Map<Id, Account> accountMap = new Map<Id, Account>(accountList);
       List<ShopifyAssociationInput> companyList = new List<ShopifyAssociationInput>();
       List<ShopifyAssociationInput> storeLocationList = new List<ShopifyAssociationInput>();
       for (AccountContactRelation acr : acrList) {
           Contact con = contactMap.get(acr.ContactId);
           Account acc = accountMap.get(acr.AccountId);
           if (
               con != null &&
               acc != null &&
               String.isNotBlank(con.Shopify_Customer_Id__c) &&
               String.isNotBlank(acc.Shopify_Company_Id__c)
           ) {
               // ── CHANGED: pass resolved country — Store_Location uses Shipping, Company uses Billing ──
               String resolvedCountry = (acc.RecordType.DeveloperName == 'Store_Location')
                   ? acc.ShippingCountryCode
                   : acc.BillingCountryCode;

               ShopifyAssociationInput input = new ShopifyAssociationInput(
                   con.Shopify_Customer_Id__c,
                   acc.Shopify_Company_Id__c,
                   acc.RecordType.DeveloperName,
                   con.Email,
                   acc.Sales_Channel__c,
                   resolvedCountry
               );
               if (acc.RecordType.DeveloperName == 'Company') {
                   companyList.add(input);
               }
               else if (acc.RecordType.DeveloperName == 'Store_Location') {
                   storeLocationList.add(input);
               }
           }
       }
       if (!companyList.isEmpty()) {
           System.enqueueJob(new ShopifyAssociationSyncQueueable(companyList));
       }
       if (!storeLocationList.isEmpty()) {
           System.enqueueJob(new ShopifyAssociationSyncQueueable(storeLocationList));
       }
   }
   public class ShopifyAssociationInput {
       public String shopifyCustomerId;
       public String shopifyCompanyId;
       public String accountRecordType;
       public String customerEmail;
       public String salesChannel;
       public String country; // ── NEW FIELD ──

       // ── CHANGED: new constructor with country, old 5-arg constructor kept for backward compatibility ──
       public ShopifyAssociationInput(
           String customerId,
           String companyId,
           String accountRecordType,
           String email,
           String channel
       ) {
           this.shopifyCustomerId = customerId;
           this.shopifyCompanyId = companyId;
           this.accountRecordType = accountRecordType;
           this.customerEmail = email;
           this.salesChannel = channel;
       }

       // ── NEW: overloaded constructor accepting country ──
       public ShopifyAssociationInput(
           String customerId,
           String companyId,
           String accountRecordType,
           String email,
           String channel,
           String country
       ) {
           this.shopifyCustomerId = customerId;
           this.shopifyCompanyId = companyId;
           this.accountRecordType = accountRecordType;
           this.customerEmail = email;
           this.salesChannel = channel;
           this.country = country;
       }
   }
}