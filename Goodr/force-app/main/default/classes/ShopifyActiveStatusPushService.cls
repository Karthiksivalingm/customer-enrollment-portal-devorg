public inherited sharing class ShopifyActiveStatusPushService {

    public static void syncActiveStatusToShopify(List<Account> locations) {
        if (locations == null || locations.isEmpty()) return;

        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

   
        Set<Id> locationIds = new Set<Id>();
        for (Account loc : locations) {
            locationIds.add(loc.Id);
        }

        // ── CHANGED: added ShippingCountryCode ──
        List<Account> storeLocations = [
            SELECT Id, Name, Active__c, Shopify_Company_Id__c,
                   Sales_Channel__c, ShippingCountryCode, ParentId,
                   Parent.Shopify_Company_Id__c
            FROM Account
            WHERE Id IN :locationIds
        ];

        
        Set<Id> parentCompanyIds = new Set<Id>();
        for (Account loc : storeLocations) {
            if (loc.ParentId != null) {
                parentCompanyIds.add(loc.ParentId);
            }
        }

        
        List<AccountContactRelation> allAcrs = [
            SELECT Id, ContactId, AccountId,
                   Contact.Email,
                   Contact.Shopify_Company_Contact_Id__c,
                   Account.Shopify_Company_Id__c,
                   Account.Sales_Channel__c,
                   Account.Parent.Shopify_Company_Id__c,
                   Account.RecordType.DeveloperName,
                   Shopify_Role_Assignment_Id__c
            FROM AccountContactRelation
            WHERE (AccountId IN :locationIds
                   OR AccountId IN :parentCompanyIds)
            AND Contact.Email != null
        ];

       
        Map<Id, List<AccountContactRelation>> directAcrByLocation =
            new Map<Id, List<AccountContactRelation>>();
        Map<Id, List<AccountContactRelation>> acrByParentCompany =
            new Map<Id, List<AccountContactRelation>>();

        for (AccountContactRelation acr : allAcrs) {
            if (locationIds.contains(acr.AccountId)) {
                // Direct ACR on a store location
                if (!directAcrByLocation.containsKey(acr.AccountId)) {
                    directAcrByLocation.put(acr.AccountId,
                        new List<AccountContactRelation>());
                }
                directAcrByLocation.get(acr.AccountId).add(acr);

            } else if (parentCompanyIds.contains(acr.AccountId)) {
                // ACR on a parent company — used as fallback
                if (!acrByParentCompany.containsKey(acr.AccountId)) {
                    acrByParentCompany.put(acr.AccountId,
                        new List<AccountContactRelation>());
                }
                acrByParentCompany.get(acr.AccountId).add(acr);
            }
        }

        // Step 6: Build final acrByLocation map for ALL locations
        // For each location:
        //   → if direct ACR exists → use it
        //   → if no direct ACR → fall back to parent company ACR
        Map<Id, List<AccountContactRelation>> acrByLocation =
            new Map<Id, List<AccountContactRelation>>();

        for (Account loc : storeLocations) {
            if (directAcrByLocation.containsKey(loc.Id)) {
                // Has direct ACR — use it
                acrByLocation.put(loc.Id,
                    directAcrByLocation.get(loc.Id));
            } else if (loc.ParentId != null
                    && acrByParentCompany.containsKey(loc.ParentId)) {
                // No direct ACR — fall back to parent company contacts
                System.debug('No direct ACR for location: ' + loc.Id
                    + ' — using parent company ACR fallback');
                acrByLocation.put(loc.Id,
                    acrByParentCompany.get(loc.ParentId));
            } else {
                System.debug('No ACR found anywhere for location: ' + loc.Id
                    + ' — skipping');
            }
        }

        // ── Step 7: Process each location 
        List<AccountContactRelation> acrsToUpdate =
            new List<AccountContactRelation>();

        for (Account loc : storeLocations) {
            if (String.isBlank(loc.Shopify_Company_Id__c)) {
                System.debug('Skipping ' + loc.Id
                    + ' — no Shopify_Company_Id__c');
                continue;
            }

            // ── CHANGED: resolved from loc.ShippingCountryCode instead of Sales_Channel__c ──
            Shopify_Configuration__c cfg =
                ShopifyConfigService.getConfigByCountry(loc.ShippingCountryCode);
            if (cfg == null) {
                System.debug('No config for country: ' + loc.ShippingCountryCode);
                continue;
            }

            List<AccountContactRelation> locationAcrs =
                acrByLocation.containsKey(loc.Id)
                    ? acrByLocation.get(loc.Id)
                    : new List<AccountContactRelation>();

            if (locationAcrs.isEmpty()) {
                System.debug('No contacts to process for location: ' + loc.Id);
                continue;
            }

            for (AccountContactRelation acr : locationAcrs) {

                if (loc.Active__c == true) {
                    // ── ACTIVE = TRUE: Assign Ordering Only role

                    String companyContactId = getCompanyContactIdByEmail(
                        loc.Parent.Shopify_Company_Id__c,
                        acr.Contact.Email,
                        cfg, logsToInsert
                    );
                    if (String.isBlank(companyContactId)) {
                        System.debug('No Shopify contact found for email: '
                            + acr.Contact.Email
                            + ' on location: ' + loc.Id);
                        continue;
                    }

                    String orderingOnlyRoleId = getOrderingOnlyRoleId(
                        loc.Parent.Shopify_Company_Id__c,
                        cfg, logsToInsert
                    );
                    if (String.isBlank(orderingOnlyRoleId)) {
                        System.debug('No Ordering Only role for company: '
                            + loc.Parent.Shopify_Company_Id__c);
                        continue;
                    }

                    String newRoleAssignmentId = assignRoleToContact(
                        companyContactId,
                        loc.Shopify_Company_Id__c,
                        orderingOnlyRoleId,
                        cfg, logsToInsert
                    );

                    if (String.isNotBlank(newRoleAssignmentId)) {
                        acr.Shopify_Role_Assignment_Id__c = newRoleAssignmentId;
                        acrsToUpdate.add(acr);
                        System.debug('Role assigned — location: ' + loc.Id
                            + ' ACR: ' + acr.Id
                            + ' assignmentId: ' + newRoleAssignmentId);
                    }

                } else {
                    // ── ACTIVE = FALSE: Revoke Ordering Only role 

                    if (String.isBlank(
                            acr.Contact.Shopify_Company_Contact_Id__c)) {
                        System.debug(
                            'No Shopify_Company_Contact_Id__c on Contact: '
                            + acr.ContactId + ' — cannot revoke');
                        continue;
                    }

                    // Always fetch live ID — never trust stored ID
                    String liveRoleAssignmentId = getLiveRoleAssignmentId(
                        loc.Shopify_Company_Id__c,
                        acr.Contact.Shopify_Company_Contact_Id__c,
                        cfg, logsToInsert
                    );

                    if (String.isBlank(liveRoleAssignmentId)) {
                        // No role in Shopify — already clean, just clear stored ID
                        System.debug('No live role assignment in Shopify '
                            + 'for ACR: ' + acr.Id + ' — clearing stored ID');
                        acr.Shopify_Role_Assignment_Id__c = null;
                        acrsToUpdate.add(acr);
                        continue;
                    }

                    revokeRoleFromContact(
                        liveRoleAssignmentId,
                        acr.Contact.Shopify_Company_Contact_Id__c,
                        cfg, logsToInsert
                    );

                    acr.Shopify_Role_Assignment_Id__c = null;
                    acrsToUpdate.add(acr);
                    System.debug('Role revoked and ID cleared — ACR: ' + acr.Id
                        + ' location: ' + loc.Id);
                }
            }
        }

        // ── Step 8: Bulk DML at the end — one update for all ACRs 
        if (!acrsToUpdate.isEmpty()) {
            update acrsToUpdate;
        }
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }

    // ── (all remaining private methods unchanged — getLiveRoleAssignmentId, getCompanyContactIdByEmail, getOrderingOnlyRoleId, assignRoleToContact, revokeRoleFromContact) ──
    private static String getLiveRoleAssignmentId(
        String shopifyLocationId,
        String shopifyCompanyContactId,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String query =
            'query getRoleAssignments($locationId: ID!) {' +
            '  companyLocation(id: $locationId) {' +
            '    roleAssignments(first: 10) {' +
            '      edges {' +
            '        node {' +
            '          id' +
            '          companyContact { id }' +
            '        }' +
            '      }' +
            '    }' +
            '  }' +
            '}';

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => query,
            'variables' => new Map<String, Object>{
                'locationId' =>
                    'gid://shopify/CompanyLocation/' + shopifyLocationId
            }
        }));

        HttpResponse res = new Http().send(req);
        System.debug('getLiveRoleAssignmentId response: ' + res.getBody());

        if (res.getStatusCode() != 200) {
            logs.add(APILogger.createLog(
                'ShopifyActiveStatusPushService.getLiveRoleAssignmentId',
                res.getStatusCode(), req.getBody(), res.getBody(),
                'HTTP error', null, 'API Errors'
            ));
            return null;
        }

        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) body.get('data');
        if (data == null) return null;

        Map<String, Object> locationData =
            (Map<String, Object>) data.get('companyLocation');
        if (locationData == null) return null;

        Map<String, Object> roleAssignments =
            (Map<String, Object>) locationData.get('roleAssignments');
        if (roleAssignments == null) return null;

        List<Object> edges = (List<Object>) roleAssignments.get('edges');
        if (edges == null || edges.isEmpty()) return null;

        String contactGid =
            'gid://shopify/CompanyContact/' + shopifyCompanyContactId;

        for (Object edgeObj : edges) {
            Map<String, Object> edge = (Map<String, Object>) edgeObj;
            Map<String, Object> node = (Map<String, Object>) edge.get('node');
            Map<String, Object> companyContact =
                (Map<String, Object>) node.get('companyContact');

            if (companyContact != null) {
                String contactId = (String) companyContact.get('id');
                if (contactGid.equalsIgnoreCase(contactId)) {
                    String fullId = (String) node.get('id');
                    return fullId.contains('/')
                        ? fullId.substringAfterLast('/') : fullId;
                }
            }
        }
        return null;
    }

    private static String getCompanyContactIdByEmail(
        String parentShopifyCompanyId,
        String email,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String query =
            'query getCompanyContacts($companyId: ID!) {' +
            '  company(id: $companyId) {' +
            '    contacts(first: 20) {' +
            '      edges { node { id customer { email } } }' +
            '    }' +
            '  }' +
            '}';

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => query,
            'variables' => new Map<String, Object>{
                'companyId' =>
                    'gid://shopify/Company/' + parentShopifyCompanyId
            }
        }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            logs.add(APILogger.createLog(
                'ShopifyActiveStatusPushService.getCompanyContactIdByEmail',
                res.getStatusCode(), req.getBody(), res.getBody(),
                'HTTP error', null, 'API Errors'
            ));
            return null;
        }

        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) body.get('data');
        if (data == null) return null;

        Map<String, Object> company =
            (Map<String, Object>) data.get('company');
        if (company == null) return null;

        List<Object> edges = (List<Object>)
            ((Map<String, Object>) company.get('contacts')).get('edges');

        for (Object edgeObj : edges) {
            Map<String, Object> node =
                (Map<String, Object>)
                    ((Map<String, Object>) edgeObj).get('node');
            if (node.get('customer') != null) {
                Map<String, Object> customer =
                    (Map<String, Object>) node.get('customer');
                String contactEmail = (String) customer.get('email');
                if (contactEmail != null
                        && contactEmail.equalsIgnoreCase(email)) {
                    return (String) node.get('id');
                }
            }
        }
        return null;
    }

    private static String getOrderingOnlyRoleId(
        String parentShopifyCompanyId,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String query =
            'query getCompanyContactRoles($companyId: ID!) {' +
            '  company(id: $companyId) {' +
            '    contactRoles(first: 50) {' +
            '      edges { node { id name } }' +
            '    }' +
            '  }' +
            '}';

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => query,
            'variables' => new Map<String, Object>{
                'companyId' =>
                    'gid://shopify/Company/' + parentShopifyCompanyId
            }
        }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            logs.add(APILogger.createLog(
                'ShopifyActiveStatusPushService.getOrderingOnlyRoleId',
                res.getStatusCode(), req.getBody(), res.getBody(),
                'HTTP error', null, 'API Errors'
            ));
            return null;
        }

        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) body.get('data');
        if (data == null) return null;

        Map<String, Object> company =
            (Map<String, Object>) data.get('company');
        if (company == null) return null;

        List<Object> edges = (List<Object>)
            ((Map<String, Object>) company.get('contactRoles')).get('edges');

        for (Object edgeObj : edges) {
            Map<String, Object> node =
                (Map<String, Object>)
                    ((Map<String, Object>) edgeObj).get('node');
            if ('Ordering only'.equalsIgnoreCase(
                    (String) node.get('name'))) {
                return (String) node.get('id');
            }
        }
        return null;
    }

    private static String assignRoleToContact(
        String companyContactId,
        String shopifyLocationId,
        String orderingOnlyRoleId,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String mutation =
            'mutation companyContactAssignRole(' +
            '  $companyContactId: ID!,' +
            '  $companyContactRoleId: ID!,' +
            '  $companyLocationId: ID!) {' +
            '  companyContactAssignRole(' +
            '    companyContactId: $companyContactId,' +
            '    companyContactRoleId: $companyContactRoleId,' +
            '    companyLocationId: $companyLocationId) {' +
            '    companyContactRoleAssignment { id }' +
            '    userErrors { field message }' +
            '  }' +
            '}';

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => mutation,
            'variables' => new Map<String, Object>{
                'companyContactId'     => companyContactId,
                'companyContactRoleId' => orderingOnlyRoleId,
                'companyLocationId'    =>
                    'gid://shopify/CompanyLocation/' + shopifyLocationId
            }
        }));

        HttpResponse res = new Http().send(req);
        System.debug('AssignRole response: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> body =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) body.get('data');
            Map<String, Object> result =
                (Map<String, Object>) data.get('companyContactAssignRole');

            List<Object> userErrors =
                (List<Object>) result.get('userErrors');
            if (userErrors != null && !userErrors.isEmpty()) {
                String errorMsg = '';
                for (Object e : userErrors) {
                    Map<String, Object> err = (Map<String, Object>) e;
                    errorMsg += err.get('field') + ': '
                        + err.get('message') + ' ';
                }
                logs.add(APILogger.createLog(
                    'ShopifyActiveStatusPushService.assignRoleToContact',
                    res.getStatusCode(), req.getBody(), res.getBody(),
                    errorMsg.trim(), null, 'API Errors'
                ));
                return null;
            }

            Map<String, Object> assignment =
                (Map<String, Object>)
                    result.get('companyContactRoleAssignment');
            if (assignment != null) {
                String fullId = (String) assignment.get('id');
                return fullId.contains('/')
                    ? fullId.substringAfterLast('/') : fullId;
            }
        } else {
            logs.add(APILogger.createLog(
                'ShopifyActiveStatusPushService.assignRoleToContact',
                res.getStatusCode(), req.getBody(), res.getBody(),
                'HTTP error', null, 'API Errors'
            ));
        }
        return null;
    }

    private static void revokeRoleFromContact(
        String shopifyRoleAssignmentId,
        String companyContactId,
        Shopify_Configuration__c cfg,
        List<Api_Log__c> logs
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String mutation =
            'mutation companyContactRevokeRole(' +
            '  $companyContactId: ID!,' +
            '  $companyContactRoleAssignmentId: ID!) {' +
            '  companyContactRevokeRole(' +
            '    companyContactId: $companyContactId,' +
            '    companyContactRoleAssignmentId: $companyContactRoleAssignmentId) {' +
            '    revokedCompanyContactRoleAssignmentId' +
            '    userErrors { field message }' +
            '  }' +
            '}';

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => mutation,
            'variables' => new Map<String, Object>{
                'companyContactId' =>
                    'gid://shopify/CompanyContact/' + companyContactId,
                'companyContactRoleAssignmentId' =>
                    'gid://shopify/CompanyContactRoleAssignment/'
                        + shopifyRoleAssignmentId
            }
        }));

        HttpResponse res = new Http().send(req);
        System.debug('Revoke raw response: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> body =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) body.get('data');

            if (data == null) {
                logs.add(APILogger.createLog(
                    'ShopifyActiveStatusPushService.revokeRoleFromContact',
                    res.getStatusCode(), req.getBody(), res.getBody(),
                    'No data in response', null, 'API Errors'
                ));
                return;
            }

            Map<String, Object> result =
                (Map<String, Object>) data.get('companyContactRevokeRole');
            List<Object> userErrors = (List<Object>) result.get('userErrors');

            if (userErrors != null && !userErrors.isEmpty()) {
                String errorMsg = '';
                for (Object e : userErrors) {
                    Map<String, Object> err = (Map<String, Object>) e;
                    errorMsg += err.get('field') + ': '
                        + err.get('message') + ' ';
                }
                System.debug('Revoke userErrors: ' + errorMsg);
                logs.add(APILogger.createLog(
                    'ShopifyActiveStatusPushService.revokeRoleFromContact',
                    res.getStatusCode(), req.getBody(), res.getBody(),
                    errorMsg.trim(), null, 'API Errors'
                ));
                return;
            }

            System.debug('Role successfully revoked: '
                + shopifyRoleAssignmentId);

        } else {
            logs.add(APILogger.createLog(
                'ShopifyActiveStatusPushService.revokeRoleFromContact',
                res.getStatusCode(), req.getBody(), res.getBody(),
                'HTTP error', null, 'API Errors'
            ));
        }
    }
}