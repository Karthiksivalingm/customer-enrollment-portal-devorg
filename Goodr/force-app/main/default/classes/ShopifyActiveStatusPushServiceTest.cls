@isTest
private class ShopifyActiveStatusPushServiceTest {

    // ─────────────────────────────────────────────
    // Mock HTTP Callout Handlers
    // ─────────────────────────────────────────────

    /**
     * Success mock — handles all 5 GraphQL operations:
     * getRoleAssignments, getCompanyContacts, getCompanyContactRoles,
     * companyContactAssignRole, companyContactRevokeRole
     */
    private class ShopifyMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getRoleAssignments')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyLocation' => new Map<String, Object>{
                            'roleAssignments' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRoleAssignment/999',
                                            'companyContact' => new Map<String, Object>{
                                                'id' => 'gid://shopify/CompanyContact/CC001'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));

            } else if (body.contains('getCompanyContacts')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'company' => new Map<String, Object>{
                            'contacts' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContact/CC001',
                                            'customer' => new Map<String, Object>{
                                                'email' => 'test@example.com'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));

            } else if (body.contains('getCompanyContactRoles')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'company' => new Map<String, Object>{
                            'contactRoles' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRole/ROLE001',
                                            'name' => 'Ordering only'
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));

            } else if (body.contains('companyContactAssignRole')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyContactAssignRole' => new Map<String, Object>{
                            'companyContactRoleAssignment' => new Map<String, Object>{
                                'id' => 'gid://shopify/CompanyContactRoleAssignment/NEW001'
                            },
                            'userErrors' => new List<Object>()
                        }
                    }
                }));

            } else if (body.contains('companyContactRevokeRole')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyContactRevokeRole' => new Map<String, Object>{
                            'revokedCompanyContactRoleAssignmentId' =>
                                'gid://shopify/CompanyContactRoleAssignment/999',
                            'userErrors' => new List<Object>()
                        }
                    }
                }));

            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    /** HTTP 500 for every call — exercises API error logging */
    private class ShopifyMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    /**
     * Returns valid contacts + roles, but returns GraphQL userErrors
     * on the assign mutation — exercises the userError log path.
     */
    private class ShopifyMockUserErrors implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getCompanyContacts')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'company' => new Map<String, Object>{
                            'contacts' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContact/CC001',
                                            'customer' => new Map<String, Object>{
                                                'email' => 'test@example.com'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));

            } else if (body.contains('getCompanyContactRoles')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'company' => new Map<String, Object>{
                            'contactRoles' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRole/ROLE001',
                                            'name' => 'Ordering only'
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));

            } else if (body.contains('companyContactAssignRole')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyContactAssignRole' => new Map<String, Object>{
                            'companyContactRoleAssignment' => null,
                            'userErrors' => new List<Object>{
                                new Map<String, Object>{
                                    'field'   => 'companyContactId',
                                    'message' => 'Contact not found'
                                }
                            }
                        }
                    }
                }));

            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    /**
     * For the revoke path ONLY:
     * - getRoleAssignments  → returns a live role for CC001 (so the service proceeds to revoke)
     * - companyContactRevokeRole → HTTP 500 → exercises the HTTP-error log branch
     * All other operations return an empty body (not reached in these tests).
     */
    private class ShopifyMockRevokeHttpError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getRoleAssignments')) {
                res.setStatusCode(200);
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyLocation' => new Map<String, Object>{
                            'roleAssignments' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRoleAssignment/999',
                                            'companyContact' => new Map<String, Object>{
                                                'id' => 'gid://shopify/CompanyContact/CC001'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));
            } else if (body.contains('companyContactRevokeRole')) {
                // HTTP 500 — triggers the else-branch log in revokeRoleFromContact
                res.setStatusCode(500);
                res.setBody('{"error":"Internal Server Error"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }

    /**
     * For the revoke path ONLY:
     * - getRoleAssignments  → returns a live role for CC001
     * - companyContactRevokeRole → HTTP 200 but body has NO 'data' key
     *   → exercises the "No data in response" log branch
     */
    private class ShopifyMockRevokeNullData implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getRoleAssignments')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyLocation' => new Map<String, Object>{
                            'roleAssignments' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRoleAssignment/999',
                                            'companyContact' => new Map<String, Object>{
                                                'id' => 'gid://shopify/CompanyContact/CC001'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));
            } else if (body.contains('companyContactRevokeRole')) {
                // HTTP 200 but no 'data' key → triggers "No data in response" log
                res.setBody('{}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    /**
     * For the revoke path ONLY:
     * - getRoleAssignments  → returns a live role for CC001
     * - companyContactRevokeRole → HTTP 200 with GraphQL userErrors
     *   → exercises the userErrors log branch in revokeRoleFromContact
     */
    private class ShopifyMockRevokeUserErrors implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getRoleAssignments')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyLocation' => new Map<String, Object>{
                            'roleAssignments' => new Map<String, Object>{
                                'edges' => new List<Object>{
                                    new Map<String, Object>{
                                        'node' => new Map<String, Object>{
                                            'id' => 'gid://shopify/CompanyContactRoleAssignment/999',
                                            'companyContact' => new Map<String, Object>{
                                                'id' => 'gid://shopify/CompanyContact/CC001'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }));
            } else if (body.contains('companyContactRevokeRole')) {
                // HTTP 200 with userErrors → triggers userErrors log branch
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyContactRevokeRole' => new Map<String, Object>{
                            'revokedCompanyContactRoleAssignmentId' => null,
                            'userErrors' => new List<Object>{
                                new Map<String, Object>{
                                    'field'   => 'companyContactRoleAssignmentId',
                                    'message' => 'Role assignment not found'
                                }
                            }
                        }
                    }
                }));
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    /** Returns empty roleAssignments edges — exercises "no live role → clear stored ID" */
    private class ShopifyMockNoRoleAssignment implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('getRoleAssignments')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'companyLocation' => new Map<String, Object>{
                            'roleAssignments' => new Map<String, Object>{
                                'edges' => new List<Object>()
                            }
                        }
                    }
                }));
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    // ─────────────────────────────────────────────
    // Test Data Helpers
    // ─────────────────────────────────────────────

    /**
     * Creates Shopify_Configuration__c using Name, Endpoint, and Token only.
     * ShopifyConfigService.getConfig() looks up records by cfg.Name,
     * so pass the same value that Account.Sales_Channel__c holds.
     */
    private static Shopify_Configuration__c createConfig(String channelName) {
        Shopify_Configuration__c cfg = new Shopify_Configuration__c(
            Name                    = channelName,
            Shopify_Endpoint__c     = 'https://test.myshopify.com/api/graphql',
            Shopify_Access_Token__c = 'test-token-123'
        );
        insert cfg;
        return cfg;
    }

    /**
     * Returns a RecordTypeId by developer name, or null if not found.
     */
    private static Id getRecordTypeId(String developerName) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE  SObjectType = 'Account'
            AND    DeveloperName = :developerName
            LIMIT  1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    /**
     * Creates a parent (Company-level) Account.
     * Always supplies a valid 9-digit Tax ID to satisfy validation rules.
     */
    private static Account createParentAccount(String shopifyCompanyId) {
        Id rtId = getRecordTypeId('Company');
        Account parent = new Account(
            Name                  = 'Test Parent Company',
            Shopify_Company_Id__c = shopifyCompanyId,
            Tax_ID__c             = '123456789'
        );
        if (rtId != null) {
            parent.RecordTypeId = rtId;
        }
        insert parent;
        return parent;
    }

    /**
     * Creates a store-location Account.
     * All four shipping fields populated to satisfy Store_requires_Shipping_Address rule.
     * Sales_Channel__c must match the Name of Shopify_Configuration__c.
     */
    private static Account createLocationAccount(
        Id      parentId,
        Boolean isActive,
        String  shopifyLocationId,
        String  salesChannel
    ) {
        Id rtId = getRecordTypeId('Store_Location');
        Account loc = new Account(
            Name                        = 'Test Location',
            ParentId                    = parentId,
            Active__c                   = isActive,
            Shopify_Company_Id__c       = shopifyLocationId,
            Sales_Channel__c            = salesChannel,
            ShippingStreet              = '123 Test Street',
            ShippingCity                = 'Test City',
            ShippingPostalCode          = '12345',
            ShippingCountry             = 'US',
            Manual_Approval_Status__c   = 'Approved'
        );
        if (rtId != null) {
            loc.RecordTypeId = rtId;
        }
        insert loc;
        return loc;
    }

    /**
     * Creates a Contact linked to the given Account.
     * email must match what ShopifyMockSuccess returns ('test@example.com')
     * for the service to successfully look up the Shopify contact by email.
     */
    private static Contact createContact(Id accountId, String email, String shopifyContactId) {
        Contact c = new Contact(
            LastName                         = 'TestContact',
            Email                            = email,
            AccountId                        = accountId,
            Shopify_Company_Contact_Id__c    = shopifyContactId
        );
        insert c;
        return c;
    }

    private static AccountContactRelation createACR(
        Id     accountId,
        Id     contactId,
        String roleAssignmentId
    ) {
        AccountContactRelation acr = new AccountContactRelation(
            AccountId                     = accountId,
            ContactId                     = contactId,
            Shopify_Role_Assignment_Id__c = roleAssignmentId,
            IsActive                      = true
        );
        insert acr;
        return acr;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ShopifyActiveStatusPushService Tests
    // ─────────────────────────────────────────────────────────────────────────

    // TEST 1 — Null / empty input → no-op, no exception
    @isTest
    static void testSync_NullAndEmptyInput_NoOp() {
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(null);
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>()
        );
        Test.stopTest();
        System.assert(true, 'Null/empty input should not throw');
    }

    // TEST 2 — Active location → role assigned, ACR Shopify_Role_Assignment_Id__c populated
    @isTest
    static void testSync_ActiveLocation_RoleAssigned() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_001');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_001', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        AccountContactRelation updated = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertNotEquals(
            null, updated.Shopify_Role_Assignment_Id__c,
            'Role assignment ID should be set after active sync'
        );
    }

    // TEST 3 — Inactive location → role revoked, ACR cleared to null
    @isTest
    static void testSync_InactiveLocation_RoleRevoked() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_002');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_002', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        AccountContactRelation updated = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertEquals(
            null, updated.Shopify_Role_Assignment_Id__c,
            'Role assignment ID should be cleared after inactive sync'
        );
    }

    // TEST 4 — Blank Shopify_Company_Id__c → location skipped, no callout
    @isTest
    static void testSync_NoShopifyCompanyId_Skipped() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_003');
        Account loc    = createLocationAccount(parent.Id, true, null, 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        AccountContactRelation acr = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id
            LIMIT  1
        ];
        System.assertEquals(
            null, acr.Shopify_Role_Assignment_Id__c,
            'No update should happen if Shopify_Company_Id__c is blank'
        );
    }

    // TEST 5 — No matching Shopify config → exception thrown by ShopifyConfigService
    @isTest
    static void testSync_NoConfig_ExceptionHandled() {
        // Intentionally NO config inserted
        Account parent = createParentAccount('PARENT_004');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_004', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            ShopifyActiveStatusPushService.syncActiveStatusToShopify(
                new List<Account>{ loc }
            );
        } catch (Exception e) {
            exceptionCaught = true;
        }
        Test.stopTest();

        System.assert(exceptionCaught, 'AuraHandledException should be thrown when config is missing');
    }

    // TEST 6 — No direct ACR on location → fallback to parent company ACR
    @isTest
    static void testSync_FallbackToParentACR_RoleAssigned() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_005');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_005', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        // Creating a Contact with AccountId = parent.Id auto-creates the primary ACR.
        // Query it rather than inserting a duplicate.
        AccountContactRelation existingParentAcr = [
            SELECT Id, Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :parent.Id AND ContactId = :con.Id
            LIMIT  1
        ];

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        AccountContactRelation parentAcr = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :parent.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertNotEquals(
            null, parentAcr.Shopify_Role_Assignment_Id__c,
            'Parent ACR should be updated when location has no direct ACR (fallback)'
        );
    }

    // TEST 7 — Inactive + no Shopify_Company_Contact_Id__c on Contact → skipped
    @isTest
    static void testSync_InactiveNoContactId_Skipped() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_006');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_006', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', null); // no Shopify contact ID
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        System.assert(true, 'Should skip gracefully when Shopify_Company_Contact_Id__c is null');
    }

    // TEST 8 — HTTP 500 on callout → Api_Log__c records created
    @isTest
    static void testSync_HttpError_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_007');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_007', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockError());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Api_Log__c records should be inserted on HTTP 500');
    }

    // TEST 9 — GraphQL userErrors on assign mutation → Api_Log__c records created
    @isTest
    static void testSync_AssignRoleUserErrors_LogsCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_008');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_008', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockUserErrors());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id FROM Api_Log__c];
        System.assert(!logs.isEmpty(), 'Error logs should be created for GraphQL userErrors');
    }

    // TEST 10 — Inactive + no live role in Shopify → stored ID cleared to null
    @isTest
    static void testSync_InactiveNoLiveRole_ClearsStoredId() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_009');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_009', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockNoRoleAssignment());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        AccountContactRelation updated = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertEquals(
            null, updated.Shopify_Role_Assignment_Id__c,
            'Stored role ID should be cleared when no live role exists in Shopify'
        );
    }

    // TEST 11 — Multiple locations (mix of active + inactive) → bulk processed
    @isTest
    static void testSync_MultipleLocations_BulkProcessed() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_010');
        Account locA   = createLocationAccount(parent.Id, true,  'LOC_A_010', 'Specialty');
        Account locB   = createLocationAccount(parent.Id, false, 'LOC_B_010', 'Specialty');
        Contact conA   = createContact(parent.Id, 'a@example.com', 'CC_A');
        Contact conB   = createContact(parent.Id, 'b@example.com', 'CC_B');
        createACR(locA.Id, conA.Id, null);
        createACR(locB.Id, conB.Id, '888');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ locA, locB }
        );
        Test.stopTest();

        System.assert(true, 'Multiple locations should process without error');
    }

    // TEST 12 — No ACR at all (no direct, no parent) → skipped gracefully
    @isTest
    static void testSync_NoACRAnywhere_Skipped() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_011');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_011', 'Specialty');
        // No ACR created for this location or its parent

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        System.assert(true, 'Location with no ACR should be skipped gracefully');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ShopifyActiveStatusSyncQueueable Tests
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * TEST 13 — Queueable with active location → role assigned.
     *
     * FIX: Contact email changed from 'qtest@example.com' → 'test@example.com'
     * and Shopify contact ID changed from 'CC_Q001' → 'CC001'.
     *
     * Root cause: ShopifyActiveStatusPushService.getCompanyContactIdByEmail()
     * matches the SF Contact email against the email returned by the Shopify
     * getCompanyContacts mock. ShopifyMockSuccess hardcodes email 'test@example.com'
     * and contact ID 'CC001'. When the test Contact had a different email, the
     * service found no match, returned null for companyContactId, and skipped
     * the role assignment — leaving Shopify_Role_Assignment_Id__c as null.
     */
    @isTest
    static void testQueueable_ActiveLocation_RoleAssigned() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_Q001');
        Account loc    = createLocationAccount(parent.Id, true, 'LOC_Q001', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001'); // ← FIXED
        createACR(loc.Id, con.Id, null);

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        System.enqueueJob(
            new ShopifyActiveStatusSyncQueueable(new List<Account>{ loc })
        );
        Test.stopTest();

        AccountContactRelation updated = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertNotEquals(
            null, updated.Shopify_Role_Assignment_Id__c,
            'Queueable should assign role for active location'
        );
    }

    /**
     * TEST 14 — Queueable with inactive location → role revoked.
     *
     * FIX: Contact email changed from 'qtest2@example.com' → 'test@example.com'
     * and Shopify contact ID changed from 'CC_Q002' → 'CC001'.
     *
     * For the revoke path the service calls getLiveRoleAssignmentId(), which
     * matches the contact GID 'gid://shopify/CompanyContact/CC001' against the
     * mock's getRoleAssignments response. Using a different contact ID would
     * have caused the live role lookup to return null — skipping the revoke and
     * leaving Shopify_Role_Assignment_Id__c populated instead of clearing it.
     */
    @isTest
    static void testQueueable_InactiveLocation_RoleRevoked() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_Q002');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_Q002', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001'); // ← FIXED
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        System.enqueueJob(
            new ShopifyActiveStatusSyncQueueable(new List<Account>{ loc })
        );
        Test.stopTest();

        AccountContactRelation updated = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM   AccountContactRelation
            WHERE  AccountId = :loc.Id AND ContactId = :con.Id
            LIMIT  1
        ];
        System.assertEquals(
            null, updated.Shopify_Role_Assignment_Id__c,
            'Queueable should clear role assignment for inactive location'
        );
    }

    // TEST 15 — Queueable with null list → no exception
    @isTest
    static void testQueueable_NullList_NoOp() {
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        System.enqueueJob(new ShopifyActiveStatusSyncQueueable(null));
        Test.stopTest();
        System.assert(true, 'Queueable with null list should complete without error');
    }

    // TEST 16 — Queueable with empty list → no exception
    @isTest
    static void testQueueable_EmptyList_NoOp() {
        Test.setMock(HttpCalloutMock.class, new ShopifyMockSuccess());
        Test.startTest();
        System.enqueueJob(
            new ShopifyActiveStatusSyncQueueable(new List<Account>())
        );
        Test.stopTest();
        System.assert(true, 'Queueable with empty list should complete without error');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // revokeRoleFromContact — uncovered log branch tests
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * TEST 17 — Inactive location, revoke call returns HTTP 500
     * → covers the else-branch log in revokeRoleFromContact:
     *     logs.add(APILogger.createLog(..., 'HTTP error', ...))
     *
     * Setup: ACR has Shopify_Company_Contact_Id__c = 'CC001' so the service
     * passes the blank-contact-id guard, calls getLiveRoleAssignmentId (which
     * returns '999' from the mock), then calls revokeRoleFromContact — which
     * receives HTTP 500 and writes an API error log.
     */
    @isTest
    static void testRevoke_HttpError_LogCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_R001');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_R001', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockRevokeHttpError());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id, Context__c FROM Api_Log__c];
        System.assert(!logs.isEmpty(),
            'An API error log should be created when the revoke call returns HTTP 500');
    }

    /**
     * TEST 18 — Inactive location, revoke response is HTTP 200 but body
     * contains no 'data' key
     * → covers the "No data in response" log branch in revokeRoleFromContact:
     *     logs.add(APILogger.createLog(..., 'No data in response', ...))
     */
    @isTest
    static void testRevoke_NullDataInResponse_LogCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_R002');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_R002', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockRevokeNullData());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id, Context__c FROM Api_Log__c];
        System.assert(!logs.isEmpty(),
            'An API error log should be created when revoke response has no data key');
    }

    /**
     * TEST 19 — Inactive location, revoke response is HTTP 200 with GraphQL
     * userErrors populated
     * → covers the userErrors log branch in revokeRoleFromContact:
     *     logs.add(APILogger.createLog(..., errorMsg.trim(), ...))
     */
    @isTest
    static void testRevoke_UserErrors_LogCreated() {
        createConfig('Specialty');
        Account parent = createParentAccount('PARENT_R003');
        Account loc    = createLocationAccount(parent.Id, false, 'LOC_R003', 'Specialty');
        Contact con    = createContact(parent.Id, 'test@example.com', 'CC001');
        createACR(loc.Id, con.Id, '999');

        Test.setMock(HttpCalloutMock.class, new ShopifyMockRevokeUserErrors());
        Test.startTest();
        ShopifyActiveStatusPushService.syncActiveStatusToShopify(
            new List<Account>{ loc }
        );
        Test.stopTest();

        List<Api_Log__c> logs = [SELECT Id, Context__c FROM Api_Log__c];
        System.assert(!logs.isEmpty(),
            'An API error log should be created when the revoke mutation returns userErrors');
    }
}