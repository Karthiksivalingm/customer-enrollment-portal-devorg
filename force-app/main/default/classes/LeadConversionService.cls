public with sharing class LeadConversionService {

    private static Map<Id, Account> parentCompanyCache = new Map<Id, Account>();

    @AuraEnabled
    public static Boolean canConvert(Id leadId) {

        Lead l = [SELECT Status, Parent_Vertical__c FROM Lead WHERE Id = :leadId LIMIT 1];

        Boolean isLeadReady = l.Status == 'Qualified' && l.Parent_Vertical__c != null;

        List<Store__c> stores = [
            SELECT Parent_Vertical__c
            FROM Store__c
            WHERE Lead__c = :leadId
        ];

        Boolean isStoresReady = true;

        if (!stores.isEmpty()) {
            for (Store__c store : stores) {
                if (store.Parent_Vertical__c == null) {
                    isStoresReady = false;
                    break;
                }
            }
        }

        return isLeadReady && isStoresReady;
    }

    @AuraEnabled
    public static void convertLead(Id leadId) {

        try {

            Lead lead = getLeadById(leadId);

            checkEmailDuplicate(lead);
            checkEmailDuplicateInShopify(lead);

            Account matchedCompany = findMatchingCompany(lead.Tax_ID__c);

            Account matchedStore = null;

            if (matchedCompany != null && lead.Address != null) {
                matchedStore = findMatchingStore(matchedCompany.Id, lead.Address);
            }

            convertLeadBasedOnMatches(lead, matchedCompany, matchedStore);

            matchedCompany = findMatchingCompany(lead.Tax_ID__c);

            if (matchedCompany != null) {
                processStoreRecords(leadId, matchedCompany.Id, lead.Sales_Channel__c);
            }

            // ── ADDED: last statement of the happy path. Stamps the flag that ──
            // ── triggers the "Approval Email" flow. If anything above threw,  ──
            // ── we never reach this line, so no email is sent on a failure.   ──
            markShopifyCreated(leadId);

        } catch (AuraHandledException ahe) {

            throw ahe;

        } catch (DmlException dml) {

            String dmlMessage = dml.getDmlMessage(0);
            String userMessage;

            if (dmlMessage.contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST')
                || dmlMessage.contains('bad value for restricted picklist')) {

                String fieldName  = '';
                String badValue   = '';

                if (dmlMessage.contains('[') && dmlMessage.contains(']')) {
                    fieldName = dmlMessage.substringBetween('[', ']');
                }

                if (dmlMessage.contains('bad value for restricted picklist field:')) {
                    String afterColon = dmlMessage
                        .substringAfter('bad value for restricted picklist field:')
                        .trim();
                    if (afterColon.contains(':')) {
                        badValue = afterColon.substringBefore(':').trim();
                    } else if (afterColon.contains('[')) {
                        badValue = afterColon.substringBefore('[').trim();
                    }
                }

                userMessage =
                    'Lead conversion failed: The Lead Source value'
                    + (String.isNotBlank(badValue) ? ' "' + badValue + '"' : '')
                    + ' is not a valid option on the Account'
                    + (String.isNotBlank(fieldName) ? ' (' + fieldName + ')' : '')
                    + ' field. '
                    + 'Please ask your Salesforce administrator to add this value '
                    + 'to the Account picklist, or update the Lead Source on this '
                    + 'Lead to an existing valid value before converting.';

            } else if (dmlMessage.contains('FIELD_INTEGRITY_EXCEPTION')
                || dmlMessage.contains('Owner ID: id value of incorrect type')) {

                userMessage =
                    'Lead conversion failed: This Lead is currently assigned to a '
                    + 'Queue instead of a specific User. '
                    + 'Please reassign the Lead to an individual User '
                    + '(not a Queue) and try converting again.';

            } else if (dmlMessage.contains('REQUIRED_FIELD_MISSING')) {

                String fieldName = '';
                if (dmlMessage.contains('[') && dmlMessage.contains(']')) {
                    fieldName = dmlMessage.substringBetween('[', ']');
                }
                userMessage =
                    'Lead conversion failed: A required field is missing'
                    + (String.isNotBlank(fieldName) ? ' (' + fieldName + ')' : '')
                    + '. Please fill in all required fields on the Lead '
                    + 'and try converting again.';

            } else if (dmlMessage.contains('DUPLICATE_VALUE')) {

                userMessage =
                    'Lead conversion failed: A duplicate record was detected. '
                    + 'A Company or Contact with this information may already exist. '
                    + 'Please check for existing records and try again.';

            } else {
                userMessage =
                    'Lead conversion failed: ' + dmlMessage
                    + ' Please review the Lead data and try again, or contact '
                    + 'your Salesforce administrator.';
            }

            throw new AuraHandledException(userMessage);

        } catch (Exception e) {

            throw new AuraHandledException(
                'An unexpected error occurred during Lead conversion: '
                + e.getMessage()
                + ' Please try again or contact your Salesforce administrator.'
            );
        }
    }

    // ── ADDED: stamps the two new fields. Shopify_Created__c flipping        ──
    // ── false -> true is the entry condition of the Approval Email flow.     ──
    // ── Guarded so a re-run on an already-stamped Lead does no DML and       ──
    // ── therefore cannot re-fire the email.                                  ──
    private static void markShopifyCreated(Id leadId) {

        List<Lead> leads = [
            SELECT Id, Shopify_Created__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        if (leads.isEmpty() || leads[0].Shopify_Created__c == true) {
            return;
        }

        update new Lead(
            Id                      = leadId,
            Shopify_Created__c      = true,
            Shopify_Created_Date__c = System.now()
        );
    }

    private static Lead getLeadById(Id leadId) {

        // ── CHANGED: added CountryCode (standard field backing Address.getCountry()) ──
        List<Lead> leads = [
            SELECT Id, Tax_ID__c, Address, FirstName, LastName, Email, Phone, Company, Status, Sales_Channel__c,
            Billing_Address__c, LeadSource, Website, Facebook__c, Instagram__c, Twitter__c,
            Is_Tax_Exempt__c, Resale_Certificate_Status__c, Affinity_Brands__c,
            Goodr_Visual_Merchandising__c, Retailer_Communication_Opt_In__c,
            Terms_of_Service_Agreement__c, Final_Comments__c, Resale_Number__c,
            Is_Franchise__c, Franchise_Name__c, HST_Number__c, GST_Number__c,Title,Cluster__c,
            PST_Number__c, QST_Number__c, Parent_Vertical__c, Vertical__c, Sport_Category__c,Sector__c,ownerId,
            CountryCode,
            Shopify_Created__c, Shopify_Created_Date__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        return leads.isEmpty() ? null : leads[0];
    }

    private static List<Store__c> getStoresByLeadId(Id leadId) {

        List<Store__c> leadStores = [
            SELECT Id, Name, Address__c, Store_Square_Footage__c,
                   Parent_Vertical__c, Vertical__c, Sport_Category__c
            FROM Store__c
            WHERE Lead__c = :leadId
        ];

        return leadStores.isEmpty() ? null : leadStores;
    }

    private static void convertLeadBasedOnMatches(Lead lead, Account matchedCompany, Account matchedStore) {

        if (matchedStore != null) {
            handleExistingStoreScenario(lead, matchedStore, matchedCompany);

        } else if (matchedCompany != null) {
            handleExistingCompanyScenario(lead, matchedCompany);

        } else {
            handleNewCompanyScenario(lead);
        }
    }

    private static Contact createContact(Lead lead, Id accountId) {

        Contact newContact = new Contact(
            FirstName = lead.FirstName,
            LastName = lead.LastName,
            Email = lead.Email,
            Phone = lead.Phone,
            Sales_Channel__c = lead.Sales_Channel__c,
            AccountId = accountId,
            Tax_ID__c = lead.Tax_ID__c,
            Manual_Approval_Status__c = 'Approved',
            Retailer_Communication_Opt_In__c = lead.Retailer_Communication_Opt_In__c,
            LeadSource = lead.LeadSource,
            Facebook__c = lead.Facebook__c,
            Instagram__c = lead.Instagram__c,
            Twitter__c = lead.Twitter__c,
            Final_Comments__c = lead.Final_Comments__c,
            Title = lead.Title,
            Parent_Vertical__c = lead.Parent_Vertical__c,
            Vertical__c = lead.Vertical__c,
            Sport_Category__c = lead.Sport_Category__c,
            GST_Number__c = lead.GST_Number__c,
            HST_Number__c = lead.HST_Number__c,
            PST_Number__c = lead.PST_Number__c,
            QST_Number__c = lead.QST_Number__c,
            OwnerId = lead.OwnerId,
            Resale_Certificate_Status__c = lead.Resale_Certificate_Status__c,
            Resale_Number__c = lead.Resale_Number__c,
            Sector__c = lead.Sector__c,
            Terms_of_Service_Agreement__c = lead.Terms_of_Service_Agreement__c
        );

        setAddressToContact(newContact, lead);

        return newContact;
    }

    private static void setAddressToContact(Contact newContact, Lead lead) {

        newContact.MailingStreet = lead.Address.getStreet();
        newContact.MailingCity = lead.Address.getCity();
        newContact.MailingState = lead.Address.getState();
        newContact.MailingPostalCode = lead.Address.getPostalCode();
        newContact.MailingCountry = lead.Address.getCountry();

        newContact.Billing_Address__Street__s = lead.Billing_Address__c.getStreet();
        newContact.Billing_Address__City__s = lead.Billing_Address__c.getCity();
        newContact.Billing_Address__StateCode__s = StateToStateCodeHelper.getStateCode(lead.Billing_Address__c.getState());
        newContact.Billing_Address__PostalCode__s = lead.Billing_Address__c.getPostalCode();
        newContact.Billing_Address__CountryCode__s = lead.Billing_Address__c.getCountryCode();
    }

    private static void handleExistingStoreScenario(Lead lead, Account matchedStore, Account matchedCompany) {

        Contact newContact = createContact(lead, matchedCompany.Id);
        insert newContact;

        System.enqueueJob(new ShopifyAssociationSyncQueueable(newContact.Id, matchedCompany.Id), 1);

        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ matchedStore.Id }
            ), 2
        );

        update new Lead(
            Id                  = lead.Id,
            Related_Account__c  = matchedCompany.Id,
            Related_Contact__c  = newContact.Id
        );
    }

    private static void handleExistingCompanyScenario(Lead lead, Account matchedCompany) {

        Account newStore = createStore(lead, matchedCompany.Id);
        insert newStore;

        Contact newContact = createContact(lead, matchedCompany.Id);
        insert newContact;

        System.enqueueJob(new ShopifyAssociationSyncQueueable(newContact.Id, matchedCompany.Id), 1);

        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ newStore.Id }
            ), 2
        );

        update new Lead(
            Id                  = lead.Id,
            Related_Account__c  = matchedCompany.Id,
            Related_Contact__c  = newContact.Id
        );
    }

    private static void handleNewCompanyScenario(Lead lead) {

        Account newCompany = createCompany(lead);
        insert newCompany;

        Account newStore = createStore(lead, newCompany.Id);
        insert newStore;

        Contact newContact = createContact(lead, newCompany.Id);
        insert newContact;

        createAccountContactRelation(newStore.Id, newContact.Id);

        System.enqueueJob(new ShopifyAssociationSyncQueueable(newContact.Id, newCompany.Id), 1);

        System.enqueueJob(
            new ShopifyActivateStoreLocationQueueable(
                new List<Id>{ newStore.Id }
            ), 2
        );

        update new Lead(
            Id                  = lead.Id,
            Related_Account__c  = newCompany.Id,
            Related_Contact__c  = newContact.Id
        );
    }

    private static Account findMatchingCompany(String taxId) {

        if (String.isBlank(taxId)) {
            return null;
        }

        List<Account> companies = [
            SELECT Id, Name
            FROM Account
            WHERE Tax_ID__c = :taxId
            AND RecordType.DeveloperName = 'Company'
            LIMIT 1
        ];

        return companies.isEmpty() ? null : companies[0];
    }

    private static void processStoreRecords(Id leadId, Id parentCompanyId, String salesChannel) {

        try {

            List<Store__c> storeRecords = getStoresByLeadId(leadId);

            if (storeRecords.isEmpty()) {
                return;
            }

            List<Account> existingStores = [
                SELECT Id, BillingStreet, BillingCity, BillingState,
                       BillingPostalCode, BillingCountry
                FROM Account
                WHERE ParentId = :parentCompanyId
                AND RecordType.DeveloperName = 'Store_Location'
            ];

            List<Account> newStoreAccounts = new List<Account>();

            for (Store__c storeRecord : storeRecords) {

                if (!isStoreAccountExists(storeRecord, existingStores)) {

                    Account newStoreAccount =
                        createStoreAccountFromStoreRecord(storeRecord, parentCompanyId, salesChannel);

                    newStoreAccounts.add(newStoreAccount);
                }
            }

            if (!newStoreAccounts.isEmpty()) {

                insert newStoreAccounts;

                Lead lead = getLeadById(leadId);

                List<Contact> leadContacts = [
                    SELECT Id
                    FROM Contact
                    WHERE Email = :lead.Email
                    AND FirstName = :lead.FirstName
                    AND LastName = :lead.LastName
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!leadContacts.isEmpty()) {

                    Contact leadContact = leadContacts[0];

                    List<AccountContactRelation> relationsToInsert = new List<AccountContactRelation>();

                    for (Account storeAccount : newStoreAccounts) {

                        relationsToInsert.add(new AccountContactRelation(
                            AccountId = storeAccount.Id,
                            ContactId = leadContact.Id,
                            IsActive = true
                        ));
                    }

                    if (!relationsToInsert.isEmpty()) {
                        insert relationsToInsert;
                    }
                }
            }

        } catch (Exception e) {

            System.debug('Error processing Store__c records: ' + e.getMessage());
        }
    }

    private static Boolean isStoreAccountExists(
        Store__c storeRecord,
        List<Account> existingStores
    ) {

        if (String.isBlank(storeRecord.Address__c)) {
            return false;
        }

        Map<String, String> addressComponents = parseAddress(storeRecord.Address__c);

        for (Account existingStore : existingStores) {

            if (isAddressComponentsMatching(existingStore, addressComponents)) {
                return true;
            }
        }

        return false;
    }

    private static Account createStoreAccountFromStoreRecord(
        Store__c storeRecord,
        Id parentCompanyId,
        String salesChannel
    ) {

        Account parentCompany;

        if (!parentCompanyCache.containsKey(parentCompanyId)) {

            parentCompany = [
                SELECT Name, Tax_ID__c
                FROM Account
                WHERE Id = :parentCompanyId
                LIMIT 1
            ];

            parentCompanyCache.put(parentCompanyId, parentCompany);

        } else {

            parentCompany = parentCompanyCache.get(parentCompanyId);
        }

        Map<String, String> addressComponents = parseAddress(storeRecord.Address__c);

        String storeName = parentCompany.Name;

        if (addressComponents.containsKey('street')
            && String.isNotBlank(addressComponents.get('street'))) {

            storeName += ' ' + addressComponents.get('street');
        }

        if (addressComponents.containsKey('postalCode')
            && String.isNotBlank(addressComponents.get('postalCode'))) {

            storeName += ' ' + addressComponents.get('postalCode');
        }

        // ── Active__c = false on insert — ShopifyActivateStoreLocationQueueable ──
        // ── will set it to true after all Shopify IDs are written               ──
        return new Account(
            Name = storeName.trim(),
            RecordTypeId = getRecordTypeId('Store_Location', 'Account'),
            ParentId = parentCompanyId,
            Tax_ID__c = parentCompany.Tax_ID__c,
            Manual_Approval_Status__c = 'Approved',
            Active__c = false,
            ShippingStreet = addressComponents.get('street'),
            ShippingCity = addressComponents.get('city'),
            ShippingState = addressComponents.get('state'),
            ShippingPostalCode = addressComponents.get('postalCode'),
            ShippingCountry = addressComponents.get('country'),
            Parent_Vertical__c = storeRecord.Parent_Vertical__c,
            Vertical__c = storeRecord.Vertical__c,
            Sport_Category__c = storeRecord.Sport_Category__c,
            Sales_Channel__c = salesChannel
        );
    }

    private static Map<String, String> parseAddress(String addressString) {
        Map<String, String> components = new Map<String, String>();

        if (String.isBlank(addressString)) {
            return components;
        }

        List<String> parts = new List<String>();
        for (String part : addressString.split(',')) {
            parts.add(part.trim());
        }

        if (parts.size() == 6) {
            components.put('street', parts[0] + ', ' + parts[1]);
            components.put('city', parts[2]);
            components.put('state', parts[3]);
            components.put('postalCode', parts[4]);
            components.put('country', parts[5]);
        } else if (parts.size() == 5) {
            components.put('street', parts[0]);
            components.put('city', parts[1]);
            components.put('state', parts[2]);
            components.put('postalCode', parts[3]);
            components.put('country', parts[4]);
        } else {
            components.put('street', addressString);
            components.put('city', '');
            components.put('state', '');
            components.put('postalCode', '');
            components.put('country', '');
        }

        return components;
    }

    private static Boolean isAddressComponentsMatching(Account existingStore, Map<String, String> addressComponents) {
        return normalizeString(existingStore.BillingStreet) == normalizeString(addressComponents.get('street')) &&
               normalizeString(existingStore.BillingCity) == normalizeString(addressComponents.get('city')) &&
               normalizeString(existingStore.BillingState) == normalizeString(addressComponents.get('state')) &&
               normalizeString(existingStore.BillingPostalCode) == normalizeString(addressComponents.get('postalCode')) &&
               normalizeString(existingStore.BillingCountry) == normalizeString(addressComponents.get('country'));
    }

    private static Account findMatchingStore(Id parentCompanyId, Address leadAddress) {
        if (leadAddress == null) {
            return null;
        }

        List<Account> stores = [
            SELECT Id, Name, BillingAddress
            FROM Account
            WHERE ParentId = :parentCompanyId
            AND RecordType.DeveloperName = 'Store_Location'
        ];

        for (Account store : stores) {
            if (isAddressMatching(store.BillingAddress, leadAddress)) {
                return store;
            }
        }

        return null;
    }

    private static Boolean isAddressMatching(Address storeAddress, Address leadAddress) {
        if (storeAddress == null || leadAddress == null) {
            return false;
        }

        return normalizeString(storeAddress.getStreet()) == normalizeString(leadAddress.getStreet()) &&
               normalizeString(storeAddress.getCity()) == normalizeString(leadAddress.getCity()) &&
               normalizeString(storeAddress.getState()) == normalizeString(leadAddress.getState()) &&
               normalizeString(storeAddress.getPostalCode()) == normalizeString(leadAddress.getPostalCode()) &&
               normalizeString(storeAddress.getCountry()) == normalizeString(leadAddress.getCountry());
    }

    private static String normalizeString(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    private static Account createCompany(Lead lead) {
        return new Account(
            Name = lead.Company,
            Sales_Channel__c = lead.Sales_Channel__c,
            Manual_Approval_Status__c = 'Approved',
            RecordTypeId = getRecordTypeId('Company', 'Account'),
            Tax_ID__c = lead.Tax_ID__c,
            BillingStreet = lead.Billing_Address__c != null ? lead.Billing_Address__c.getStreet() : null,
            BillingCity = lead.Billing_Address__c != null ? lead.Billing_Address__c.getCity() : null,
            BillingState = lead.Billing_Address__c != null ? lead.Billing_Address__c.getState() : null,
            BillingPostalCode = lead.Billing_Address__c != null ? lead.Billing_Address__c.getPostalCode() : null,
            BillingCountry = lead.Billing_Address__c != null ? lead.Billing_Address__c.getCountry() : null,
            AccountSource = lead.LeadSource,
            Lead_Source__c = lead.LeadSource,
            Website = lead.Website,
            Facebook__c = lead.Facebook__c,
            Twitter__c = lead.Twitter__c,
            Instagram__c = lead.Instagram__c,
            Is_Tax_Exempt__c = lead.Is_Tax_Exempt__c,
            Resale_Certificate_Status__c = lead.Resale_Certificate_Status__c,
            Affinity_Brands__c = lead.Affinity_Brands__c,
            Goodr_Visual_Merchandising__c = lead.Goodr_Visual_Merchandising__c,
            Retailer_Communication_Opt_In__c = lead.Retailer_Communication_Opt_In__c,
            Terms_of_Service_Agreement__c = lead.Terms_of_Service_Agreement__c,
            Final_Comments__c = lead.Final_Comments__c,
            Resale_Number__c = lead.Resale_Number__c,
            Is_Franchise__c = lead.Is_Franchise__c,
            Franchise_Name__c = lead.Franchise_Name__c,
            HST_Number__c = lead.HST_Number__c,
            GST_Number__c = lead.GST_Number__c,
            PST_Number__c = lead.PST_Number__c,
            QST_Number__c = lead.QST_Number__c,
            Phone = lead.Phone,
            Parent_Vertical__c = lead.Parent_Vertical__c,
            Vertical__c = lead.Vertical__c,
            Sport_Category__c = lead.Sport_Category__c,
            Cluster__c = lead.Cluster__c,
            Sector__c = lead.Sector__c
        );
    }

    private static Account createStore(Lead lead, Id parentCompanyId) {
        String storeName = lead.Company;
        if (lead.Address.getStreet() != null) {
            storeName += ' ' + lead.Address.getStreet();
        }
        if (lead.Address.getPostalCode() != null) {
            storeName += ' ' + lead.Address.getPostalCode();
        }

        return new Account(
            Name = storeName,
            Tax_ID__c = lead.Tax_ID__c,
            Sales_Channel__c = lead.Sales_Channel__c,
            RecordTypeId = getRecordTypeId('Store_Location', 'Account'),
            ParentId = parentCompanyId,
            Manual_Approval_Status__c = 'Approved',
            Active__c = false,
            Parent_Vertical__c = lead.Parent_Vertical__c,
            Vertical__c = lead.Vertical__c,
            Sport_Category__c = lead.Sport_Category__c,
            ShippingStreet = lead.Address != null ? lead.Address.getStreet() : null,
            ShippingCity = lead.Address != null ? lead.Address.getCity() : null,
            ShippingState = lead.Address != null ? lead.Address.getState() : null,
            ShippingPostalCode = lead.Address != null ? lead.Address.getPostalCode() : null,
            ShippingCountry = lead.Address != null ? lead.Address.getCountry() : null,
            BillingStreet = lead.Billing_Address__c != null ? lead.Billing_Address__c.getStreet() : null,
            BillingCity = lead.Billing_Address__c != null ? lead.Billing_Address__c.getCity() : null,
            BillingState = lead.Billing_Address__c != null ? lead.Billing_Address__c.getState() : null,
            BillingPostalCode = lead.Billing_Address__c != null ? lead.Billing_Address__c.getPostalCode() : null,
            BillingCountry = lead.Billing_Address__c != null ? lead.Billing_Address__c.getCountry() : null,
            Website = lead.Website,
            Phone = lead.Phone,
            Lead_Source__c = lead.LeadSource,
            Cluster__c = lead.Cluster__c,
            Sector__c = lead.Sector__c
        );
    }

    private static Id getRecordTypeId(String developerName, String sObjectType) {
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.getGlobalDescribe()
            .get(sObjectType)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();

        if (!recordTypes.containsKey(developerName)) {
            throw new AuraHandledException('RecordType ' + developerName + ' not found for ' + sObjectType);
        }

        return recordTypes.get(developerName).getRecordTypeId();
    }

    private static void createAccountContactRelation(Id accountId, Id contactId) {
        try {
            List<AccountContactRelation> existingRelations = [
                SELECT Id
                FROM AccountContactRelation
                WHERE AccountId = :accountId AND ContactId = :contactId
                LIMIT 1
            ];

            if (existingRelations.isEmpty()) {
                AccountContactRelation acr = new AccountContactRelation(
                    AccountId = accountId,
                    ContactId = contactId,
                    IsActive = true
                );
                insert acr;

                System.enqueueJob(new ShopifyAssociationSyncQueueable(contactId, accountId), 2);
            }
        } catch (Exception e) {
            System.debug('Error creating AccountContactRelation: ' + e.getMessage());
        }
    }

    private static void checkEmailDuplicate(Lead lead) {
        if (String.isNotBlank(lead.Email)) {
            List<Contact> existingContacts = [
                SELECT Id, Email
                FROM Contact
                WHERE Email = :lead.Email
                LIMIT 1
            ];
            if (!existingContacts.isEmpty()) {
                throw new AuraHandledException('Lead conversion blocked: Email already exists in Salesforce.');
            }
        }
    }

    private static void checkEmailDuplicateInShopify(Lead lead) {
        if (String.isNotBlank(lead.Email)) {
            // ── CHANGED: resolved from lead.CountryCode instead of Sales_Channel__c ──
            Shopify_Configuration__c cfg = ShopifyConfigService.getConfigByCountry(lead.CountryCode);
            String configUrl = cfg.Shopify_Endpoint__c;
            String baseUrl = configUrl.substringBefore('/admin/');
            String shopifyUrl = baseUrl + '/admin/api/2024-04/customers/search.json?query=email:' + EncodingUtil.urlEncode(lead.Email, 'UTF-8');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(shopifyUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

            Http http = new Http();
            HTTPResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> customers = (List<Object>) result.get('customers');
                if (customers != null && !customers.isEmpty()) {
                    throw new AuraHandledException('Lead conversion blocked: Email already exists in Shopify.');
                }
            } else {
                throw new AuraHandledException('Shopify API Error: ' + res.getBody());
            }
        }
    }
}