// CHANGE 1: Added `inherited sharing` to class declaration
public inherited sharing class ShopifyAccountIntegration {

    private static List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

    @TestVisible
    private static String extractLastIdPart(String fullGid) {
        if (String.isBlank(fullGid)) {
            return null;
        }

        String[] parts = fullGid.split('/');
        return parts.isEmpty() ? null : parts[parts.size() - 1];
    }

    //TODO: Rewrite CompanyLocation delete. Create a Location in CompanyCreation request
    public static void sendAccountAndStoreLocationToShopify(List<Id> accountIds) {
        // ── CHANGED: added BillingCountryCode / ShippingCountryCode to both SELECTs ──
        List<Account> companies = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
               BillingPostalCode, BillingCountry, BillingCountryCode, Shopify_Company_Id__c,
               ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode, Sales_Channel__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        List<Account> storeLocations = [
            SELECT Id, Name, ParentId, BillingStreet, BillingCity, BillingState,
               BillingPostalCode, BillingCountry, BillingCountryCode, Shopify_Company_Id__c,
               ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode, Sales_Channel__c
            FROM Account
            WHERE ParentId IN :accountIds
            AND RecordTypeId = :getStoreLocationRecordTypeId()
        ];

        Map<Id, List<Account>> companyToLocationsMap = new Map<Id, List<Account>>();
        for (Account location : storeLocations) {
            if (!companyToLocationsMap.containsKey(location.ParentId)) {
                companyToLocationsMap.put(location.ParentId, new List<Account>());
            }
            companyToLocationsMap.get(location.ParentId).add(location);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : companies) {
            try {
                // ── CHANGED: resolved from acc.BillingCountryCode instead of Sales_Channel__c ──
                Shopify_Configuration__c cfg = ShopifyConfigService.getConfigByCountry(acc.BillingCountryCode);
                if (cfg == null) {
                    System.debug('No Shopify config found for country: ' + acc.BillingCountryCode);
                    continue;
                }
                String companyName = acc.Name;
                String compFullId = null;
                String locationId = null;

                String query = 'mutation CompanyCreate($input: CompanyCreateInput!) {' +
                               '  companyCreate(input: $input) {' +
                               '    company {' +
                               '      id' +
                               '      name' +
                               '    }' +
                               '    userErrors {' +
                               '      field' +
                               '      message' +
                               '      code' +
                               '    }' +
                               '  }' +
                               '}';

                Map<String, Object> variables = new Map<String, Object>{
                    'input' => new Map<String, Object>{
                        'company' => new Map<String, Object>{
                            'name' => companyName
                        }
                    }
                };

                HttpRequest req = new HttpRequest();
                req.setEndpoint(cfg.Shopify_Endpoint__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'query' => query,
                    'variables' => variables
                }));

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> data = (Map<String, Object>) response.get('data');
                    Map<String, Object> companyCreate = (Map<String, Object>) data.get('companyCreate');
                    List<Object> userErrors = (List<Object>) companyCreate.get('userErrors');
                    if (userErrors != null && !userErrors.isEmpty()) {
                        String errorMessage = '';
                        for (Object errObj : userErrors) {
                            Map<String, Object> err = (Map<String, Object>) errObj;
                            errorMessage += (String) err.get('message') + ' ';
                        }

                        logsToInsert.add(APILogger.createLog(
                            'Shopify Company Creation - ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify',
                            res.getStatusCode(),
                            req.getBody(),
                            res.getBody(),
                            errorMessage.trim(),
                            acc.Id,
                            'API Errors'
                        ));

                        continue;
                    }

                    Map<String, Object> company = (Map<String, Object>) companyCreate.get('company');
                    if (company != null && company.containsKey('id')) {
                        compFullId = (String) company.get('id');
                        String newCompanyId = extractLastIdPart(compFullId);
                        acc.Shopify_Company_Id__c = newCompanyId;
                        accountsToUpdate.add(acc);
                        System.debug('Company created for Account ' + acc.Id + ': ' + res.getBody());
                    }
                } else {
                    logsToInsert.add(APILogger.createLog(
                        'Shopify Company Creation - ShopifyAccountIntegration.sendAccountAndStoreLocationToShopify',
                        res.getStatusCode(),
                        req.getBody(),
                        res != null ? res.getBody() : '',
                        '',
                        acc.Id,
                        'API Errors'
                    ));
                    System.debug('Failed to create company for Account ' + acc.Id + ': ' + res.getBody());
                }

                String getLocationsQuery = 'query getCompanyLocations($id: ID!) {' +
                               '  company(id: $id) {' +
                               '    locations(first: 1) {' +
                               '      edges { node { id name } }' +
                               '    }' +
                               '  }' +
                               '}';

                HttpRequest getReq = new HttpRequest();
                getReq.setEndpoint(cfg.Shopify_Endpoint__c);
                getReq.setMethod('POST');
                getReq.setHeader('Content-Type', 'application/json');
                getReq.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
                getReq.setBody(JSON.serialize(new Map<String, Object>{
                    'query' => getLocationsQuery,
                    'variables' => new Map<String, Object>{ 'id' => compFullId }
                }));

                HttpResponse getRes = http.send(getReq);

                if (getRes.getStatusCode() == 200) {
                    Map<String, Object> getBody = (Map<String, Object>) JSON.deserializeUntyped(getRes.getBody());
                    Map<String, Object> companyData = (Map<String, Object>) ((Map<String, Object>) getBody.get('data')).get('company');
                    List<Object> edges = (List<Object>) ((Map<String, Object>) companyData.get('locations')).get('edges');

                    if (!edges.isEmpty()) {
                        Map<String, Object> node = (Map<String, Object>) ((Map<String, Object>) edges[0]).get('node');
                        locationId = (String) node.get('id');
                    }
                }

                if (acc.Shopify_Company_Id__c != null && companyToLocationsMap.containsKey(acc.Id)) {
                    for (Account location : companyToLocationsMap.get(acc.Id)) {
                        Account createdLocation = createCompanyLocation(acc.Shopify_Company_Id__c, location);
                        if (String.isNotBlank(createdLocation.Shopify_Company_Id__c)) {
                            accountsToUpdate.add(createdLocation);
                        }
                    }
                }

                String deleteMutation = 'mutation companyLocationDelete($companyLocationId: ID!) {' +
                                        '  companyLocationDelete(companyLocationId: $companyLocationId) {' +
                                        '    deletedCompanyLocationId' +
                                        '    userErrors { field message }' +
                                        '  }' +
                                        '}';

                HttpRequest deleteReq = new HttpRequest();
                deleteReq.setEndpoint(cfg.Shopify_Endpoint__c);
                deleteReq.setMethod('POST');
                deleteReq.setHeader('Content-Type', 'application/json');
                deleteReq.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
                deleteReq.setBody(JSON.serialize(new Map<String, Object>{
                    'query' => deleteMutation,
                    'variables' => new Map<String, Object>{ 'companyLocationId' => locationId }
                }));

                HttpResponse deleteRes = http.send(deleteReq);
                System.debug('Delete response: ' + deleteRes.getBody());

            } catch (Exception ex) {
                System.debug('Exception while sending Account ' + acc.Id + ' to Shopify: ' + ex.getMessage());
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }

    public static Account createCompanyLocation(String shopifyCompanyId, Account location) {
        String mutation = 'mutation companyLocationCreate($companyId: ID!, $input: CompanyLocationInput!) {' +
                          '  companyLocationCreate(companyId: $companyId, input: $input) {' +
                          '    companyLocation {' +
                          '      id' +
                          '      name' +
                          '    }' +
                          '    userErrors {' +
                          '      field' +
                          '      message' +
                          '    }' +
                          '  }' +
                          '}';

        Map<String, Object> shippingAddress = new Map<String, Object>{
            'address1' => location.ShippingStreet,
            'city' => location.ShippingCity,
            'countryCode' => CountryToCountryCodeHelper.getCountryCode(location.ShippingCountry),
            'firstName' => 'Store Location',
            'lastName' => location.Name,
            'recipient' => location.Name,
            'zip' => location.ShippingPostalCode,
            'zoneCode' => StateToStateCodeHelper.getStateCode(location.ShippingState)
        };

        Map<String, Object> input = new Map<String, Object>{
            'name' => location.Name,
            'shippingAddress' => shippingAddress,
            'billingSameAsShipping' => false,
            'locale' => 'en',
            'externalId' => location.Id
        };

        Map<String, Object> variables = new Map<String, Object>{
            'companyId' => 'gid://shopify/Company/' + shopifyCompanyId,
            'input' => input
        };

        // ── CHANGED: resolved from location.ShippingCountryCode instead of Sales_Channel__c ──
        Shopify_Configuration__c cfg = ShopifyConfigService.getConfigByCountry(location.ShippingCountryCode);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => mutation,
            'variables' => variables
        }));

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('CompanyLocation creation response: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) body.get('data');
            Map<String, Object> companyLocationCreate = (Map<String, Object>) data.get('companyLocationCreate');

            List<Object> userErrors = (List<Object>) companyLocationCreate.get('userErrors');
            if (userErrors != null && !userErrors.isEmpty()) {
                String errorMessage = '';
                for (Object errObj : userErrors) {
                    Map<String, Object> err = (Map<String, Object>) errObj;
                    errorMessage += (String) err.get('message') + ' ';
                }
                logsToInsert.add(APILogger.createLog(
                    'Shopify CompanyLocation Creation - ShopifyAccountIntegration.createCompanyLocation',
                    res.getStatusCode(),
                    req.getBody(),
                    res.getBody(),
                    errorMessage.trim(),
                    location.Id,
                    'API Errors'
                ));
            }
            Map<String, Object> companyLocation = (Map<String, Object>) companyLocationCreate.get('companyLocation');

            if (companyLocation != null && companyLocation.containsKey('id')) {
                String locationId = extractLastIdPart((String) companyLocation.get('id'));
                location.Shopify_Company_Id__c = locationId;
            }
        } else {
            logsToInsert.add(APILogger.createLog(
                'Shopify CompanyLocation Creation - ShopifyAccountIntegration.createCompanyLocation',
                res.getStatusCode(),
                req.getBody(),
                res != null ? res.getBody() : '',
                '',
                location.Id,
                'API Errors'
            ));
            System.debug('Failed to create company for Account ' + location.Id + ': ' + res.getBody());
        }

        return location;
    }

    public static void createStoreLocations(List<Id> storeLocationIds) {
        if (storeLocationIds.isEmpty()) {
            return;
        }

        // ── CHANGED: added ShippingCountryCode to SELECT (needed by createCompanyLocation) ──
        List<Account> storeLocations = [
            SELECT Id, Name, Parent.Shopify_Company_Id__c, New_User_Email__c, Shopify_Company_Id__c, Sales_Channel__c,
            ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode, First_Name__c, Last_Name__c
            FROM Account
            WHERE Id IN :storeLocationIds
        ];

        Set<Id> parentAccountIds = new Set<Id>();
        for (Account storeLocation : storeLocations) {
            if (storeLocation.ParentId != null) {
                parentAccountIds.add(storeLocation.ParentId);
            }
        }

        List<Contact> parentContacts = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE AccountId IN :parentAccountIds
        ];

        Map<Id, Map<String, List<Contact>>> contactsByParentAndEmail = new Map<Id, Map<String, List<Contact>>>();
        for (Contact con : parentContacts) {
            if (con.Email != null) {
                String emailLower = con.Email.toLowerCase();

                if (!contactsByParentAndEmail.containsKey(con.AccountId)) {
                    contactsByParentAndEmail.put(con.AccountId, new Map<String, List<Contact>>());
                }
                Map<String, List<Contact>> emailMap = contactsByParentAndEmail.get(con.AccountId);

                if (!emailMap.containsKey(emailLower)) {
                    emailMap.put(emailLower, new List<Contact>());
                }
                emailMap.get(emailLower).add(con);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        List<AccountContactRelation> acrToInsert = new List<AccountContactRelation>();
        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
        // List<Case> casesToInsert = new List<Case>();
        List<Contact> contactsToInsert = new List<Contact>();
        // ── NEW: Api_Log__c list replacing casesToInsert above ──
        List<Api_Log__c> notFoundLogsToInsert = new List<Api_Log__c>();

        for (Account storeLocation : storeLocations) {
            if (String.isBlank(storeLocation.Parent.Shopify_Company_Id__c)) {
                System.debug('Skipping store location ' + storeLocation.Id + ' because parent company has no Shopify_Company_Id__c');
                continue;
            }

            Account accToUpdate = createCompanyLocation(storeLocation.Parent.Shopify_Company_Id__c, storeLocation);

            if (String.isNotBlank(accToUpdate.Shopify_Company_Id__c)) {
                accountsToUpdate.add(accToUpdate);
            }

            if (String.isNotBlank(storeLocation.New_User_Email__c) && storeLocation.ParentId != null) {
                String emailLower = storeLocation.New_User_Email__c.toLowerCase();
                if (contactsByParentAndEmail.containsKey(storeLocation.ParentId)) {
                    Map<String, List<Contact>> emailMap = contactsByParentAndEmail.get(storeLocation.ParentId);
                    if (emailMap.containsKey(emailLower)) {
                        List<Contact> matchedContacts = emailMap.get(emailLower);

                        for (Contact con : matchedContacts) {
                            acrToInsert.add(new AccountContactRelation(
                                AccountId = storeLocation.Id,
                                ContactId = con.Id,
                                IsActive = true
                            ));
                        }
                    } else {
                        Contact newContact = new Contact(
                            FirstName = storeLocation.First_Name__c,
                            LastName = storeLocation.Last_Name__c,
                            Email = storeLocation.New_User_Email__c,
                            AccountId = storeLocation.ParentId
                        );
                        contactsToInsert.add(newContact);

                        // ── CHANGE: Case creation disabled — replaced with Api_Log__c below ──
                        // Case newCase = new Case(
                        //     Subject = 'Contact not found for store location: ' + storeLocation.Name,
                        //     Description = 'Email ' + storeLocation.New_User_Email__c + ' was not found among contacts for parent account. Store Location: ' + storeLocation.Name + ' (ID: ' + storeLocation.Id + ')',
                        //     AccountId = storeLocation.Id,
                        //     Status = 'New',
                        //     Priority = 'Medium',
                        //     Origin = 'System',
                        //     Type = 'API Errors'
                        // );
                        // casesToInsert.add(newCase);

                        // ── NEW: Api_Log__c creation replacing the Case creation above ──
                        Api_Log__c notFoundLog = new Api_Log__c(
                            Context__c = 'Store Location - Contact Not Found',
                            Response_Message__c = 'Email ' + storeLocation.New_User_Email__c + ' was not found among contacts for parent account. Store Location: ' + storeLocation.Name + ' (ID: ' + storeLocation.Id + ')',
                            Related_Record_Id__c = storeLocation.Id,
                            Log_Type__c = 'Match Failure'
                        );
                        notFoundLogsToInsert.add(notFoundLog);
                    }
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(accountsToUpdate, false);
        }

        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }

        if (!acrToInsert.isEmpty()) {
            insert acrToInsert;
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }

        // ── CHANGE: Case insert disabled — replaced with Api_Log__c insert below ──
        // if (!casesToInsert.isEmpty()) {
        //     insert casesToInsert;
        // }

        // ── NEW: Api_Log__c insert replacing the Case insert above ──
        if (!notFoundLogsToInsert.isEmpty()) {
            insert notFoundLogsToInsert;
        }
    }

    private static String getStoreLocationRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByName().get('Store Location').getRecordTypeId();
    }
}