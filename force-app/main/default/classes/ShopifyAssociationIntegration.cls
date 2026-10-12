public inherited sharing class ShopifyAssociationIntegration {

    public static void process(List<AccountContactRelationHandler.ShopifyAssociationInput> inputs) {
        // CHANGE 2: Collect all shopifyCompanyIds upfront to bulk-query Accounts OUTSIDE the loop
        Set<String> shopifyCompanyIds = new Set<String>();
        for (AccountContactRelationHandler.ShopifyAssociationInput input : inputs) {
            if (input.accountRecordType == 'Store_Location' && input.shopifyCompanyId != null) {
                shopifyCompanyIds.add(input.shopifyCompanyId);
            }
        }

        // CHANGE 2: Bulk query companyAcc records — replaces SOQL inside loop (was line 57)
        Map<String, Account> companyAccByShopifyId = new Map<String, Account>();
        if (!shopifyCompanyIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, Shopify_Company_Id__c, ParentId
                FROM Account
                WHERE Shopify_Company_Id__c IN :shopifyCompanyIds
            ]) {
                companyAccByShopifyId.put(acc.Shopify_Company_Id__c, acc);
            }
        }

        // CHANGE 2: Collect all ParentIds to bulk query parent Accounts — replaces SOQL inside loop (was line 62)
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : companyAccByShopifyId.values()) {
            if (acc.ParentId != null) {
                parentIds.add(acc.ParentId);
            }
        }

        Map<Id, Account> parentAccById = new Map<Id, Account>();
        if (!parentIds.isEmpty()) {
            parentAccById = new Map<Id, Account>([
                SELECT Id, Shopify_Company_Id__c
                FROM Account
                WHERE Id IN :parentIds
            ]);
        }

        // ── local buffer, flushed once at the end of process(). ──
        List<Api_Log__c> logsToInsert = new List<Api_Log__c>();

        // ── NEW: accumulate Contact updates instead of updating them immediately    ──
        // ── inside processCompanyLocation(). This is the fix for:                   ──
        // ── "You have uncommitted work pending. Please commit or rollback before    ──
        // ── calling out" — previously, processCompanyLocation() ran an update on    ──
        // ── the Contact (DML), then immediately called assignCompanyContactRole(),  ──
        // ── which makes an HTTP callout in the SAME transaction. Salesforce blocks   ──
        // ── any callout that comes after uncommitted DML. Deferring every Contact    ──
        // ── update to a single DML at the very end of process() — after ALL          ──
        // ── callouts for ALL inputs have completed — eliminates this entirely.       ──
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        for (AccountContactRelationHandler.ShopifyAssociationInput input : inputs) {
            try {
                if (input.accountRecordType == 'Store_Location') {
                    // CHANGE 2: Pass pre-fetched maps into processCompanyLocation instead of querying inside
                    // ── CHANGED: now also passes the shared contactsToUpdate accumulator ──
                    processCompanyLocation(input, companyAccByShopifyId, parentAccById, logsToInsert, contactsToUpdate);
                } else if (input.accountRecordType == 'Company') {
                    processCompanyContact(input, logsToInsert);
                } else {
                    System.debug('Unknown Account Record Type: ' + input.accountRecordType);
                }
            } catch (Exception e) {
                System.debug('Exception while processing Shopify association: ' + e.getMessage());
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Association - Unhandled Exception',
                    Response_Message__c   = e.getMessage(),
                    Stack_Trace__c        = e.getStackTraceString(),
                    Related_Record_Id__c  = null,
                    Log_Type__c           = 'API Errors'
                ));
            }
        }

        // ── NEW: single guaranteed DML for all accumulated Contact updates, only  ──
        // ── AFTER every callout for every input in this entire process() call     ──
        // ── has already completed.                                               ──
        if (!contactsToUpdate.isEmpty()) {
            try {
                update contactsToUpdate.values();
            } catch (Exception updateEx) {
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Association - Contact Update Failed',
                    Response_Message__c   = updateEx.getMessage(),
                    Log_Type__c           = 'API Errors'
                ));
            }
        }

        // ── single flush at the very end of process() ──
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception logInsertEx) {
                System.debug('Failed to insert Api_Log__c records: ' + logInsertEx.getMessage());
            }
        }
    }

    private static void processCompanyContact(
        AccountContactRelationHandler.ShopifyAssociationInput input,
        List<Api_Log__c> logsToInsert
    ) {
        Shopify_Configuration__c cfg = ShopifyConfigService.getConfigByCountry(input.country);
        if (cfg == null) {
            System.debug('No Shopify config found for country: ' + input.country);
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - No Config Found (Company Contact)',
                Response_Message__c   = 'No config found for country: ' + input.country,
                Log_Type__c           = 'API Errors'
            ));
            return;
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String gqlQuery = 'mutation companyAssignCustomerAsContact($companyId: ID!, $customerId: ID!) {' +
                          ' companyAssignCustomerAsContact(companyId: $companyId, customerId: $customerId) {' +
                          '  companyContact { id }' +
                          '  userErrors { field message }' +
                          ' }' +
                          '}';

        System.debug('Company Contact - Company: ' + input.shopifyCompanyId + ' Customer: ' + input.shopifyCustomerId);

        Map<String, Object> variables = new Map<String, Object>{
            'companyId' => 'gid://shopify/Company/' + input.shopifyCompanyId,
            'customerId' => 'gid://shopify/Customer/' + input.shopifyCustomerId
        };

        Map<String, Object> requestBody = new Map<String, Object>{
            'query' => gqlQuery,
            'variables' => variables
        };

        executeRequest(req, requestBody, 'Company Contact Association', logsToInsert);
    }

    // CHANGE 2: Method signature updated to accept pre-fetched Account maps instead of running SOQL internally
    // ── CHANGED: added contactsToUpdate accumulator parameter ──
    private static void processCompanyLocation(
        AccountContactRelationHandler.ShopifyAssociationInput input,
        Map<String, Account> companyAccByShopifyId,
        Map<Id, Account> parentAccById,
        List<Api_Log__c> logsToInsert,
        Map<Id, Contact> contactsToUpdate
    ) {
        Shopify_Configuration__c cfg = ShopifyConfigService.getConfigByCountry(input.country);
        if (cfg == null) {
            System.debug('No Shopify config found for country: ' + input.country);
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - No Config Found (Company Location)',
                Response_Message__c   = 'No config found for country: ' + input.country,
                Log_Type__c           = 'API Errors'
            ));
            return;
        }

        Account companyAcc = companyAccByShopifyId.get(input.shopifyCompanyId);
        if (companyAcc == null) {
            System.debug('No Account found for Shopify Company Id: ' + input.shopifyCompanyId);
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - No Account Found for Shopify Company Id',
                Response_Message__c   = 'Shopify Company Id: ' + input.shopifyCompanyId,
                Log_Type__c           = 'API Errors'
            ));
            return;
        }

        Account parent = parentAccById.get(companyAcc.ParentId);
        if (parent == null) {
            System.debug('No parent Account found for Account Id: ' + companyAcc.ParentId);
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - No Parent Account Found',
                Response_Message__c   = 'Account Id: ' + companyAcc.ParentId,
                Related_Record_Id__c  = companyAcc.Id,
                Log_Type__c           = 'API Errors'
            ));
            return;
        }

        Http http = new Http();

        // ── Fetch Ordering Only Role Id from Shopify ──────────────────────────────
        String roleQuery = 'query getCompanyContactRoles($companyId: ID!) { ' +
                            '  company(id: $companyId) { ' +
                            '    contactRoles(first: 50) { ' +
                            '      edges { ' +
                            '        node { ' +
                            '          id ' +
                            '          name ' +
                            '        } ' +
                            '      } ' +
                            '    } ' +
                            '  } ' +
                            '}';

        Map<String, Object> roleQueryVariables = new Map<String, Object>{
            'companyId' => 'gid://shopify/Company/' + parent.Shopify_Company_Id__c
        };

        HttpRequest roleRequest = new HttpRequest();
        roleRequest.setEndpoint(cfg.Shopify_Endpoint__c);
        roleRequest.setMethod('POST');
        roleRequest.setHeader('Content-Type', 'application/json');
        roleRequest.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);
        roleRequest.setBody(JSON.serialize(new Map<String, Object>{
            'query' => roleQuery,
            'variables' => roleQueryVariables
        }));

        HttpResponse roleResponse = http.send(roleRequest);
        String orderingOnlyRoleId = null;

        if (roleResponse.getStatusCode() == 200) {
            Map<String, Object> roleRespMap = (Map<String, Object>) JSON.deserializeUntyped(roleResponse.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) roleRespMap.get('data');
            Map<String, Object> companyMap = (Map<String, Object>) dataMap.get('company');

            if (companyMap != null && companyMap.containsKey('contactRoles')) {
                Map<String, Object> contactRolesMap = (Map<String, Object>) companyMap.get('contactRoles');
                List<Object> roleEdges = (List<Object>) contactRolesMap.get('edges');

                for (Object edgeObj : roleEdges) {
                    Map<String, Object> edge = (Map<String, Object>) edgeObj;
                    Map<String, Object> node = (Map<String, Object>) edge.get('node');
                    if ('Ordering only'.equalsIgnoreCase((String) node.get('name'))) {
                        orderingOnlyRoleId = (String) node.get('id');
                        break;
                    }
                }
            } else {
                System.debug('No contactRoles found in company');
            }
        } else {
            System.debug('Failed to fetch company contact roles. Status: ' + roleResponse.getStatusCode());
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - Fetch Contact Roles Failed',
                Status_Code__c        = roleResponse.getStatusCode(),
                Request_Message__c    = roleRequest.getBody(),
                Response_Message__c   = 'HTTP ' + roleResponse.getStatusCode(),
                Stack_Trace__c        = roleResponse.getBody(),
                Related_Record_Id__c  = parent.Id,
                Log_Type__c           = 'API Errors'
            ));
        }

        // ── Fetch Company Contacts from Shopify to find companyContactId by email ──
        HttpRequest queryRequest = new HttpRequest();
        queryRequest.setEndpoint(cfg.Shopify_Endpoint__c);
        queryRequest.setMethod('POST');
        queryRequest.setHeader('Content-Type', 'application/json');
        queryRequest.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String contactQuery = 'query getCompanyContacts($companyId: ID!) {' +
                              ' company(id: $companyId) {' +
                              '   contacts(first: 20) {' +
                              '     edges {' +
                              '       node { id customer { email } }' +
                              '     }' +
                              '   }' +
                              ' }' +
                              '}';

        queryRequest.setBody(JSON.serialize(new Map<String, Object>{
            'query' => contactQuery,
            'variables' => new Map<String, Object>{
                'companyId' => 'gid://shopify/Company/' + parent.Shopify_Company_Id__c
            }
        }));

        HttpResponse queryResponse = http.send(queryRequest);

        if (queryResponse.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(queryResponse.getBody());
            Map<String, Object> data = (Map<String, Object>) response.get('data');

            if (data != null && ((Map<String, Object>) data.get('company')) != null) {
                Map<String, Object> company = (Map<String, Object>) data.get('company');
                List<Object> edges = (List<Object>) ((Map<String, Object>) company.get('contacts')).get('edges');

                String foundCompanyContactId = null;

                for (Object edgeObj : edges) {
                    Map<String, Object> edge = (Map<String, Object>) edgeObj;
                    Map<String, Object> node = (Map<String, Object>) edge.get('node');
                    String email = null;
                    if (node.containsKey('customer') && node.get('customer') != null) {
                        Map<String, Object> customer = (Map<String, Object>) node.get('customer');
                        email = (String) customer.get('email');
                    }
                    if (email != null && email.equalsIgnoreCase(input.customerEmail)) {
                        foundCompanyContactId = (String) node.get('id');
                        break;
                    }
                }

                if (foundCompanyContactId != null) {

                    String shortCompanyContactId = foundCompanyContactId.contains('/')
                        ? foundCompanyContactId.substringAfterLast('/')
                        : foundCompanyContactId;

                    // ── CHANGED: instead of querying + updating the Contact immediately   ──
                    // ── (DML) right here, find it and STAGE it into the shared            ──
                    // ── accumulator map. The actual update() now happens exactly once, in  ──
                    // ── process(), after every callout for every input has completed.      ──
                    // ── This is what eliminates the "uncommitted work pending" error —      ──
                    // ── assignCompanyContactRole() below makes another callout right after, ──
                    // ── which was previously blocked by the DML that used to run here.      ──
                    List<Contact> matchedContacts = [
                        SELECT Id
                        FROM Contact
                        WHERE Email = :input.customerEmail
                        LIMIT 1
                    ];
                    if (!matchedContacts.isEmpty()) {
                        Contact c = matchedContacts[0];
                        c.Shopify_Company_Contact_Id__c = shortCompanyContactId;
                        contactsToUpdate.put(c.Id, c);
                        System.debug('Staged Shopify_Company_Contact_Id__c: '
                            + shortCompanyContactId + ' for Contact: ' + c.Id);
                    }

                    assignCompanyContactRole(
                        foundCompanyContactId,
                        input.shopifyCompanyId,
                        orderingOnlyRoleId,
                        cfg,
                        input.customerEmail,
                        input.shopifyCompanyId,
                        logsToInsert
                    );

                } else {
                    System.debug('No company contact found with email: ' + input.customerEmail);
                    logsToInsert.add(new Api_Log__c(
                        Context__c            = 'Shopify Association - No Company Contact Found By Email',
                        Response_Message__c   = 'No Shopify company contact found matching email: ' + input.customerEmail,
                        Related_Record_Id__c  = parent.Id,
                        Log_Type__c           = 'API Errors'
                    ));
                }
            } else {
                System.debug('Invalid response structure when fetching company contacts.');
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Association - Invalid Response Structure',
                    Response_Message__c   = 'Invalid response structure when fetching company contacts.',
                    Stack_Trace__c        = queryResponse.getBody(),
                    Related_Record_Id__c  = parent.Id,
                    Log_Type__c           = 'API Errors'
                ));
            }
        } else {
            System.debug('Failed to fetch company contacts. Status: ' + queryResponse.getStatusCode());
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - Fetch Company Contacts Failed',
                Status_Code__c        = queryResponse.getStatusCode(),
                Request_Message__c    = queryRequest.getBody(),
                Response_Message__c   = 'HTTP ' + queryResponse.getStatusCode(),
                Stack_Trace__c        = queryResponse.getBody(),
                Related_Record_Id__c  = parent.Id,
                Log_Type__c           = 'API Errors'
            ));
        }
    }

    private static void assignCompanyContactRole(
        String companyContactId,
        String companyLocationId,
        String companyContactRoleId,
        Shopify_Configuration__c cfg,
        String customerEmail,
        String shopifyLocationId,
        List<Api_Log__c> logsToInsert
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Shopify_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Shopify-Access-Token', cfg.Shopify_Access_Token__c);

        String mutation =
            'mutation companyContactAssignRole(' +
            '  $companyContactId: ID!, $companyContactRoleId: ID!, $companyLocationId: ID!) {' +
            '  companyContactAssignRole(' +
            '    companyContactId: $companyContactId,' +
            '    companyContactRoleId: $companyContactRoleId,' +
            '    companyLocationId: $companyLocationId) {' +
            '    companyContactRoleAssignment {' +
            '      id' +
            '      role { id name }' +
            '      companyLocation { id name }' +
            '    }' +
            '    userErrors { field message }' +
            '  }' +
            '}';

        Map<String, Object> variables = new Map<String, Object>{
            'companyContactId' => companyContactId,
            'companyContactRoleId' => companyContactRoleId,
            'companyLocationId' => 'gid://shopify/CompanyLocation/' + companyLocationId
        };

        req.setBody(JSON.serialize(new Map<String, Object>{
            'query' => mutation,
            'variables' => variables
        }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) response.get('data');
            Map<String, Object> assignResult =
                (Map<String, Object>) data.get('companyContactAssignRole');
            List<Object> userErrors = (List<Object>) assignResult.get('userErrors');

            if (userErrors != null && !userErrors.isEmpty()) {
                String errMsg = '';
                for (Object e : userErrors) {
                    Map<String, Object> err = (Map<String, Object>) e;
                    errMsg += (String) err.get('message') + ' ';
                }
                System.debug('Role assignment errors: ' + errMsg);
                logsToInsert.add(new Api_Log__c(
                    Context__c            = 'Shopify Association - Assign Company Contact Role - userErrors',
                    Status_Code__c        = res.getStatusCode(),
                    Request_Message__c    = req.getBody(),
                    Response_Message__c   = errMsg.trim(),
                    Stack_Trace__c        = res.getBody(),
                    Related_Record_Id__c  = null,
                    Log_Type__c           = 'API Errors'
                ));
                return;
            }

            Map<String, Object> roleAssignment =
                (Map<String, Object>) assignResult.get('companyContactRoleAssignment');

            System.debug('Assign Company Contact Role successful: ' + JSON.serialize(assignResult));

            if (roleAssignment != null && roleAssignment.containsKey('id')) {
                String fullRoleAssignmentId = (String) roleAssignment.get('id');
                String shortRoleAssignmentId = fullRoleAssignmentId.contains('/')
                    ? fullRoleAssignmentId.substringAfterLast('/')
                    : fullRoleAssignmentId;

                List<AccountContactRelation> acrs = [
                    SELECT Id
                    FROM AccountContactRelation
                    WHERE Contact.Email = :customerEmail
                    AND Account.Shopify_Company_Id__c = :shopifyLocationId
                    LIMIT 1
                ];

                if (!acrs.isEmpty()) {
                    acrs[0].Shopify_Role_Assignment_Id__c = shortRoleAssignmentId;
                    update acrs[0]; // ── OK: no callout follows this DML within this method ──
                    System.debug('Saved Shopify_Role_Assignment_Id__c: '
                        + shortRoleAssignmentId + ' to ACR: ' + acrs[0].Id);
                } else {
                    System.debug('No ACR found for email: ' + customerEmail
                        + ' and location: ' + shopifyLocationId);
                    logsToInsert.add(new Api_Log__c(
                        Context__c            = 'Shopify Association - No ACR Found To Save Role Assignment',
                        Response_Message__c   = 'No ACR found for email: ' + customerEmail
                                                 + ' and location: ' + shopifyLocationId,
                        Log_Type__c           = 'API Errors'
                    ));
                }
            }

        } else {
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - Assign Company Contact Role - HTTP Error',
                Status_Code__c        = res != null ? res.getStatusCode() : 0,
                Request_Message__c    = req.getBody(),
                Response_Message__c   = 'HTTP ' + (res != null ? String.valueOf(res.getStatusCode()) : '0'),
                Stack_Trace__c        = res != null ? res.getBody() : '',
                Related_Record_Id__c  = null,
                Log_Type__c           = 'API Errors'
            ));
            System.debug('Failed to process Assign Company Contact Role');
        }
    }

    private static void executeRequest(
        HttpRequest req,
        Map<String, Object> requestBody,
        String operationType,
        List<Api_Log__c> logsToInsert
    ) {
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) response.get('data');
            System.debug(operationType + ' successful: ' + JSON.serialize(data));
        } else {
            logsToInsert.add(new Api_Log__c(
                Context__c            = 'Shopify Association - ' + operationType,
                Status_Code__c        = res != null ? res.getStatusCode() : 0,
                Request_Message__c    = req.getBody(),
                Response_Message__c   = 'HTTP ' + (res != null ? String.valueOf(res.getStatusCode()) : '0'),
                Stack_Trace__c        = res != null ? res.getBody() : '',
                Log_Type__c           = 'API Errors'
            ));
            System.debug('Failed to process ' + operationType);
        }
    }
}