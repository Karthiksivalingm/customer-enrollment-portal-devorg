@IsTest
private class ShopifyOffboardRolePushQueueableTest {

    // Tests for ShopifyOffboardRolePushQueueable and the call from ShopifyAtRiskNoticeBatch.finish().
    // Shopify is mocked: the role lookup returns one role for the contact, the revoke succeeds.

    private static final Id COMPANY_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
    private static final Id STORE_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();

    private static Integer seq = 0;

    // Counts the Shopify calls made through the mock
    private class ShopifyRoleMock implements HttpCalloutMock {
        public Integer lookups = 0;
        public Integer revokes = 0;
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            Map<String, Object> vars = (Map<String, Object>)
                ((Map<String, Object>) JSON.deserializeUntyped(req.getBody())).get('variables');
            if (req.getBody().contains('companyContactRevokeRole')) {
                revokes++;
                res.setBody('{"data":{"companyContactRevokeRole":{"revokedCompanyContactRoleAssignmentId":' +
                            '"gid://shopify/CompanyContactRoleAssignment/999","userErrors":[]}}}');
            } else {
                lookups++;
                // Every store has one Ordering Only role held by contact SFTEST-<n>; return a match for any contact
                res.setBody('{"data":{"companyLocation":{"roleAssignments":{"edges":[{"node":{' +
                            '"id":"gid://shopify/CompanyContactRoleAssignment/999",' +
                            '"companyContact":{"id":"gid://shopify/CompanyContact/' + contactIdFor(vars) + '"}}}]}}}}');
            }
            return res;
        }
    }

    // The mock answers with the contact id the push asks about, so the role always matches
    private static String lastContactId;
    private static String contactIdFor(Map<String, Object> vars) {
        return lastContactId;
    }

    private static void insertShopifyConfig() {
        insert new List<Shopify_Configuration__c>{
            new Shopify_Configuration__c(Name = 'Specialty', Shopify_Access_Token__c = 'test-token-us',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json'),
            new Shopify_Configuration__c(Name = 'Specialty CAN', Shopify_Access_Token__c = 'test-token-ca',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json')
        };
    }

    // Company + US store + contact linked to Shopify with an Ordering Only role on the store
    private static Account makeStore(Boolean active, Date lastOrder, Boolean excluded) {
        seq++;
        String tag = 'ORPQ' + seq;
        Account company = new Account(
            Name = tag + ' Company', RecordTypeId = COMPANY_RT, Tax_ID__c = '98765432' + Math.mod(seq, 10),
            Shopify_Company_Id__c = 'SHOPCO-' + tag, Manual_Approval_Status__c = 'Approved',
            ShippingStreet = '1 Test St', ShippingCity = 'Austin', ShippingPostalCode = '78701',
            ShippingCountryCode = 'US', ShippingStateCode = 'TX'
        );
        insert company;
        Account store = new Account(
            Name = tag + ' Store', RecordTypeId = STORE_RT, ParentId = company.Id, Active__c = active,
            Shopify_Company_Id__c = 'SHOPLOC-' + tag, Manual_Approval_Status__c = 'Approved',
            Last_Shopify_Order_Date__c = lastOrder, Shopify_Sales_At_Risk__c = false,
            Exclude_From_Auto_Offboarding__c = excluded,
            ShippingStreet = '1 Test St', ShippingCity = 'Austin', ShippingPostalCode = '78701',
            ShippingCountryCode = 'US', ShippingStateCode = 'TX'
        );
        insert store;
        lastContactId = 'SFTEST-' + seq;
        Contact c = new Contact(FirstName = 'Test', LastName = 'ZTest-' + tag, AccountId = company.Id,
                                Email = tag.toLowerCase() + '@example.com',
                                Shopify_Company_Contact_Id__c = lastContactId);
        insert c;
        insert new AccountContactRelation(AccountId = store.Id, ContactId = c.Id, IsActive = true,
                                          Shopify_Role_Assignment_Id__c = '999');
        return store;
    }

    private static String storedRoleId(Id storeId) {
        return [SELECT Shopify_Role_Assignment_Id__c FROM AccountContactRelation
                WHERE AccountId = :storeId LIMIT 1].Shopify_Role_Assignment_Id__c;
    }

    private static Shopify_At_Risk_Config__mdt config() {
        return new Shopify_At_Risk_Config__mdt(
            Active__c = true, Auto_Offboard__c = true, At_Risk_Mode__c = 'Every Stage',
            Deactivation_Months__c = 18, Require_Opt_In__c = false, Exclude_Bounced__c = false,
            Offboard_Reason__c = 'Store At Risk', Legacy_Notice_Enabled__c = false,
            Email_Template_Name__c = 'Shopify At Risk Notice',
            Template_Stage_1__c = 'Warm Off 1 - Check In', Template_Stage_2__c = 'Warm Off 2 - Early Notice',
            Template_Stage_3__c = 'Warm Off 3 - 30 Day Warning', Template_Stage_4__c = 'Warm Off 4 - 15 Day Reminder',
            Template_Stage_5__c = 'Warm Off 5 - Deactivation Notice'
        );
    }

    // Email 3 and Email 4 already sent, so the store is due for deactivation at 18 months
    private static void seedWarnings(Account store) {
        Id contactId = [SELECT ContactId FROM AccountContactRelation WHERE AccountId = :store.Id LIMIT 1].ContactId;
        Date last = store.Last_Shopify_Order_Date__c;
        insert new List<Shopify_At_Risk_Notice__c>{
            new Shopify_At_Risk_Notice__c(Store_Account__c = store.Id, Contact__c = contactId,
                Stage__c = ShopifyAtRiskNoticeBatch.STAGE_3, Status__c = ShopifyAtRiskNoticeBatch.ST_SENT,
                Email_Sent__c = true, Notice_Date__c = Date.today().addMonths(-1), Last_Order_Date_At_Notice__c = last,
                Notice_Key__c = contactId + '-' + store.Id + '-' + ShopifyAtRiskNoticeBatch.STAGE_3 + '-' + String.valueOf(last)),
            new Shopify_At_Risk_Notice__c(Store_Account__c = store.Id, Contact__c = contactId,
                Stage__c = ShopifyAtRiskNoticeBatch.STAGE_4, Status__c = ShopifyAtRiskNoticeBatch.ST_SENT,
                Email_Sent__c = true, Notice_Date__c = Date.today().addDays(-15), Last_Order_Date_At_Notice__c = last,
                Notice_Key__c = contactId + '-' + store.Id + '-' + ShopifyAtRiskNoticeBatch.STAGE_4 + '-' + String.valueOf(last))
        };
    }

    private static Integer pushJobs() {
        return [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'ShopifyOffboardRolePushQueueable'];
    }

    // ── Queueable ─────────────────────────────────────────────────

    @IsTest static void inactiveStore_roleRevokedAndCleared() {
        insertShopifyConfig();
        Account s = makeStore(false, null, false);
        ShopifyRoleMock mock = new ShopifyRoleMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.enqueueJob(new ShopifyOffboardRolePushQueueable(new List<Id>{ s.Id }));
        Test.stopTest();
        System.assertEquals(1, mock.revokes, 'Ordering role revoked in Shopify');
        System.assertEquals(null, storedRoleId(s.Id), 'Stored role id cleared');
    }

    @IsTest static void reactivatedStore_keepsRole() {
        insertShopifyConfig();
        Account s = makeStore(true, null, false);
        ShopifyRoleMock mock = new ShopifyRoleMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.enqueueJob(new ShopifyOffboardRolePushQueueable(new List<Id>{ s.Id }));
        Test.stopTest();
        System.assertEquals(0, mock.lookups + mock.revokes, 'No Shopify call for an active store');
        System.assertEquals('999', storedRoleId(s.Id), 'Role kept');
    }

    @IsTest static void manyStores_firstJobTakesOnlyItsShare() {
        insertShopifyConfig();
        // One company with several inactive stores, created in bulk (one save per object)
        Account company = new Account(
            Name = 'ORPQ Bulk Company', RecordTypeId = COMPANY_RT, Tax_ID__c = '987654320',
            Shopify_Company_Id__c = 'SHOPCO-BULK', Manual_Approval_Status__c = 'Approved',
            ShippingStreet = '1 Test St', ShippingCity = 'Austin', ShippingPostalCode = '78701',
            ShippingCountryCode = 'US', ShippingStateCode = 'TX'
        );
        insert company;
        List<Account> stores = new List<Account>();
        for (Integer i = 0; i < ShopifyOffboardRolePushQueueable.STORES_PER_JOB + 2; i++) {
            stores.add(new Account(
                Name = 'ORPQ Bulk Store ' + i, RecordTypeId = STORE_RT, ParentId = company.Id, Active__c = false,
                Shopify_Company_Id__c = 'SHOPLOC-BULK-' + i, Manual_Approval_Status__c = 'Approved',
                ShippingStreet = '1 Test St', ShippingCity = 'Austin', ShippingPostalCode = '78701',
                ShippingCountryCode = 'US', ShippingStateCode = 'TX'
            ));
        }
        insert stores;
        lastContactId = 'SFTEST-BULK';
        Contact c = new Contact(FirstName = 'Test', LastName = 'ZTest-Bulk', AccountId = company.Id,
                                Email = 'orpq.bulk@example.com', Shopify_Company_Contact_Id__c = lastContactId);
        insert c;
        List<AccountContactRelation> acrs = new List<AccountContactRelation>();
        List<Id> ids = new List<Id>();
        for (Account s : stores) {
            acrs.add(new AccountContactRelation(AccountId = s.Id, ContactId = c.Id, IsActive = true,
                                                Shopify_Role_Assignment_Id__c = '999'));
            ids.add(s.Id);
        }
        insert acrs;
        ShopifyRoleMock mock = new ShopifyRoleMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.enqueueJob(new ShopifyOffboardRolePushQueueable(ids));
        Test.stopTest();
        System.assertEquals(ShopifyOffboardRolePushQueueable.STORES_PER_JOB, mock.lookups,
            'One job handles STORES_PER_JOB stores; the rest go to the next chained job');
    }

    @IsTest static void emptyList_noCalls() {
        ShopifyRoleMock mock = new ShopifyRoleMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        System.enqueueJob(new ShopifyOffboardRolePushQueueable(null));
        Test.stopTest();
        System.assertEquals(0, mock.lookups + mock.revokes);
    }

    // ── Called from the notice batch ──────────────────────────────

    @IsTest static void batchDeactivation_queuesRoleRemoval() {
        insertShopifyConfig();
        Account s = makeStore(true, Date.today().addMonths(-18).addDays(-1), false);
        seedWarnings(s);
        Test.setMock(HttpCalloutMock.class, new ShopifyRoleMock());
        ShopifyAtRiskNoticeBatch.pushRolesInTests = true;
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(config()), 50);
        Test.stopTest();
        System.assertEquals(false, [SELECT Active__c FROM Account WHERE Id = :s.Id].Active__c, 'Store deactivated');
        System.assertEquals(1, pushJobs(), 'Shopify role removal queued for the deactivated store');
    }

    @IsTest static void noDeactivation_nothingQueued() {
        insertShopifyConfig();
        makeStore(true, Date.today().addMonths(-12).addDays(-3), false);
        Test.setMock(HttpCalloutMock.class, new ShopifyRoleMock());
        ShopifyAtRiskNoticeBatch.pushRolesInTests = true;
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(config()), 50);
        Test.stopTest();
        System.assertEquals(0, pushJobs(), 'No role removal when no store is deactivated');
    }

    @IsTest static void excludedStore_nothingQueued() {
        insertShopifyConfig();
        Account s = makeStore(true, Date.today().addMonths(-18).addDays(-1), true);
        seedWarnings(s);
        Test.setMock(HttpCalloutMock.class, new ShopifyRoleMock());
        ShopifyAtRiskNoticeBatch.pushRolesInTests = true;
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(config()), 50);
        Test.stopTest();
        System.assertEquals(true, [SELECT Active__c FROM Account WHERE Id = :s.Id].Active__c, 'Excluded store stays active');
        System.assertEquals(0, pushJobs(), 'Excluded store is never pushed');
    }
}
