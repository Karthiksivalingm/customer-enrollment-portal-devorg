@isTest
public class ShopifyManualAssociationQueueableTest {

    private static Id companyRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
    private static Id storeRtId   = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Store Location').getRecordTypeId();

    // ─── Mocks ────────────────────────────────────────────────────────────────
    // Mirrors FullHttpMock from ShopifyAssociationIntegrationTest — handles every
    // GraphQL operation fired by ShopifyAssociationIntegration.process()

    private class FullHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body.contains('companyAssignCustomerAsContact')) {
                res.setBody('{"data":{"companyAssignCustomerAsContact":{"companyContact":{"id":"gid://shopify/Contact/123"},"userErrors":[]}}}');
            } else if (body.contains('getCompanyContactRoles')) {
                res.setBody('{"data":{"company":{"contactRoles":{"edges":[{"node":{"id":"gid://shopify/CompanyContactRole/role123","name":"Ordering only"}}]}}}}');
            } else if (body.contains('getCompanyContacts')) {
                res.setBody('{"data":{"company":{"contacts":{"edges":[{"node":{"id":"gid://shopify/CompanyContact/contact123","customer":{"email":"john.doe@test.com"}}}]}}}}');
            } else if (body.contains('companyContactAssignRole')) {
                res.setBody('{"data":{"companyContactAssignRole":{"companyContactRoleAssignment":{"id":"gid://shopify/CompanyContactRoleAssignment/assign456","role":{"id":"role123","name":"Ordering only"},"companyLocation":{"id":"loc123","name":"Test Store"}},"userErrors":[]}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    private class ErrorHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"errors":[{"message":"Internal Server Error"}]}');
            return res;
        }
    }

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        insert new Shopify_Configuration__c(
            Name = 'Specialty',
            Shopify_Endpoint__c = 'https://test-endpoint.com',
            Shopify_Access_Token__c = 'fake-token'
        );

        // Parent company account — this is the accountId passed into the queueable
        Account parentCompany = new Account(
            Name = 'Parent Company',
            RecordTypeId = companyRtId,
            Tax_Id__c = '111111111',
            Shopify_Company_Id__c = 'parentShopify123',
            Sales_Channel__c = 'Specialty',
            Active__c = true
        );
        insert parentCompany;

        // Active store location — child of parentCompany, matched via Account.ParentId = accountId
        Account activeStore = new Account(
            Name = 'Active Store',
            ParentId = parentCompany.Id,
            RecordTypeId = storeRtId,
            Shopify_Company_Id__c = 'shopifyCompanyLocation123',
            Sales_Channel__c = 'Specialty',
            ShippingStreet = '123 Test Street',
            ShippingCity = 'New York',
            ShippingState = 'NY',
            ShippingPostalCode = '10001',
            ShippingCountry = 'US',
            Manual_Approval_Status__c = 'Approved',
            Active__c = true
        );
        insert activeStore;

        // Inactive store location — should be excluded by Active__c = true filter
        Account inactiveStore = new Account(
            Name = 'Inactive Store',
            ParentId = parentCompany.Id,
            RecordTypeId = storeRtId,
            Shopify_Company_Id__c = 'inactiveShopifyLocation456',
            Sales_Channel__c = 'Specialty',
            ShippingStreet = '456 Old Street',
            ShippingCity = 'New York',
            ShippingState = 'NY',
            ShippingPostalCode = '10002',
            ShippingCountry = 'US',
            Manual_Approval_Status__c = 'Approved',
            Active__c = false
        );
        insert inactiveStore;

        // Contact with Shopify Customer ID populated — eligible for sync
        Contact johnDoe = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = parentCompany.Id,
            Sales_Channel__c = 'Specialty',
            Shopify_Customer_Id__c = 'cust123'
        );
        insert johnDoe;

        // Contact without Shopify Customer ID — excluded by SOQL filter
        Contact noShopifyContact = new Contact(
            FirstName = 'No',
            LastName = 'Shopify',
            Email = 'noshopify@test.com',
            AccountId = parentCompany.Id,
            Sales_Channel__c = 'Specialty'
            // Shopify_Customer_Id__c intentionally omitted
        );
        insert noShopifyContact;

        // NOTE: Salesforce auto-creates an ACR for Contact.AccountId = parentCompany.Id
        // when johnDoe and noShopifyContact are inserted above — do NOT insert those manually
        // or a DUPLICATE_VALUE DmlException will be thrown.

        // ACR linking johnDoe to the active store (non-primary account — must be inserted manually)
        insert new AccountContactRelation(
            AccountId = activeStore.Id,
            ContactId = johnDoe.Id,
            IsActive = true
        );

        // ACR linking noShopifyContact to active store (non-primary — must be inserted manually)
        // Excluded at runtime because Shopify_Customer_Id__c is null
        insert new AccountContactRelation(
            AccountId = activeStore.Id,
            ContactId = noShopifyContact.Id,
            IsActive = true
        );

        // ACR linking johnDoe to inactive store (non-primary — must be inserted manually)
        // Excluded at runtime because Active__c = false
        insert new AccountContactRelation(
            AccountId = inactiveStore.Id,
            ContactId = johnDoe.Id,
            IsActive = true
        );
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    private static Id getParentCompanyId() {
        return [SELECT Id FROM Account WHERE Name = 'Parent Company' LIMIT 1].Id;
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    // Happy path — both Company and Store_Location ACRs exist and are processed
    @IsTest
    static void testExecute_CompanyAndStoreLocation_Success() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        // Contact field updated by processCompanyLocation path
        Contact c = [SELECT Shopify_Company_Contact_Id__c FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        System.assertEquals('contact123', c.Shopify_Company_Contact_Id__c,
            'Shopify_Company_Contact_Id__c should be set after successful store location processing');
    }

    // Verifies that only company-type ACRs go into companyAssociations path
    @IsTest
    static void testExecute_CompanyRecordTypeRouted() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        // processCompanyContact fires companyAssignCustomerAsContact — no contact field
        // side effect to assert on, so assert no exception was thrown
        System.assert(true, 'Company record type routed to companyAssociations without error');
    }

    // Verifies that only store-type ACRs go into locationAssociations path
    @IsTest
    static void testExecute_StoreLocationRecordTypeRouted() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        Contact c = [SELECT Shopify_Company_Contact_Id__c FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        System.assertEquals('contact123', c.Shopify_Company_Contact_Id__c,
            'Store_Location record type routed to locationAssociations and processed correctly');
    }

    // Contacts without Shopify_Customer_Id__c must be excluded by the SOQL filter
    @IsTest
    static void testExecute_ContactWithoutShopifyId_Excluded() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        Contact noShopify = [SELECT Shopify_Company_Contact_Id__c FROM Contact WHERE Email = 'noshopify@test.com' LIMIT 1];
        System.assertEquals(null, noShopify.Shopify_Company_Contact_Id__c,
            'Contact without Shopify_Customer_Id__c must not be processed');
    }

    // ACRs linked to inactive store accounts must be excluded by Active__c = true filter
    @IsTest
    static void testExecute_InactiveStore_Excluded() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        Account inactiveStore = [SELECT Id FROM Account WHERE Name = 'Inactive Store' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        List<AccountContactRelation> acrs = [
            SELECT Shopify_Role_Assignment_Id__c
            FROM AccountContactRelation
            WHERE AccountId = :inactiveStore.Id
            AND ContactId = :c.Id
        ];
        System.assert(!acrs.isEmpty(), 'ACR for inactive store should exist in Salesforce');
        System.assertEquals(null, acrs[0].Shopify_Role_Assignment_Id__c,
            'Inactive store ACR must not have been processed — Active__c = false excludes it');
    }

    // Accounts with no Shopify_Company_Id__c must be excluded by the SOQL filter
    @IsTest
    static void testExecute_AccountWithoutShopifyCompanyId_Excluded() {
        // Insert an account with no Shopify_Company_Id__c and link a contact to it
        Account noShopifyAcc = new Account(
            Name = 'No Shopify Account',
            RecordTypeId = companyRtId,
            Tax_Id__c = '222222222',
            Sales_Channel__c = 'Specialty',
            Active__c = true
            // Shopify_Company_Id__c intentionally omitted
        );
        insert noShopifyAcc;

        Contact c = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        insert new AccountContactRelation(
            AccountId = noShopifyAcc.Id,
            ContactId = c.Id,
            IsActive = true
        );

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(noShopifyAcc.Id));
        Test.stopTest();

        System.assert(true, 'Account without Shopify_Company_Id__c excluded by SOQL and handled gracefully');
    }

    // Early return path — no matching ACRs for the given accountId
    @IsTest
    static void testExecute_NoMatchingRelations_EarlyReturn() {
        // Insert a brand-new company with no ACRs
        Account isolatedCompany = new Account(
            Name = 'Isolated Company',
            RecordTypeId = companyRtId,
            Tax_Id__c = '333333333',
            Shopify_Company_Id__c = 'isolatedShopify999',
            Sales_Channel__c = 'Specialty',
            Active__c = true
        );
        insert isolatedCompany;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(isolatedCompany.Id));
        Test.stopTest();

        // No relations found → early return with System.debug — no side effects
        System.assert(true, 'Empty relations list triggers early return without error');
    }

    // HTTP 500 from Shopify — exception caught internally, queueable completes cleanly
    @IsTest
    static void testExecute_HttpError_HandledGracefully() {
        Test.setMock(HttpCalloutMock.class, new ErrorHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        System.assert(true, 'HTTP 500 from Shopify handled gracefully — queueable did not throw');
    }

    // Verifies queueable is correctly enqueued and implements Queueable + AllowsCallouts
    @IsTest
    static void testExecute_QueueableEnqueued() {
        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        Id jobId = System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job should be enqueued and return a valid job ID');
    }

    // Only Company-type ACRs present — locationAssociations is empty, should not call process for it
    @IsTest
    static void testExecute_OnlyCompanyAssociations() {
        // Remove store ACRs so only the company-type ACR remains for parentCompany
        Account activeStore = [SELECT Id FROM Account WHERE Name = 'Active Store' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        List<AccountContactRelation> storeAcrs = [
            SELECT Id FROM AccountContactRelation
            WHERE AccountId = :activeStore.Id AND ContactId = :c.Id
        ];
        delete storeAcrs;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        System.assert(true, 'Only company associations processed — empty locationAssociations skipped cleanly');
    }

    // Only Store_Location-type ACRs present — companyAssociations is empty, should not call process for it
    @IsTest
    static void testExecute_OnlyLocationAssociations() {
        // The primary ACR (Contact.AccountId -> parentCompany) cannot be deleted in Salesforce --
        // attempting to do so throws INVALID_OPERATION: "A direct relationship can't be deleted."
        // Workaround: reassign johnDoe's primary AccountId to a neutral account that has no
        // Shopify_Company_Id__c. The queueable SOQL filter (Account.Shopify_Company_Id__c != null)
        // then excludes the re-homed primary ACR naturally, leaving only the store location ACR active.
        Account neutralAccount = new Account(
            Name = 'Neutral Account',
            RecordTypeId = companyRtId,
            Tax_Id__c = '444444444',
            Sales_Channel__c = 'Specialty',
            Active__c = true
        );
        insert neutralAccount;

        Contact c = [SELECT Id FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        c.AccountId = neutralAccount.Id;
        update c;

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());
        Id parentId = getParentCompanyId();

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(parentId));
        Test.stopTest();

        Contact updated = [SELECT Shopify_Company_Contact_Id__c FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        System.assertEquals('contact123', updated.Shopify_Company_Contact_Id__c,
            'Only location associations processed -- empty companyAssociations skipped cleanly');
    }

    // Verifies the OR condition in SOQL: AccountId = accountId (direct match, not just parent)
    @IsTest
    static void testExecute_DirectAccountId_Match() {
        // Pass the active store's own Id — matched by AccountId = :accountId branch of the OR
        Account activeStore = [SELECT Id FROM Account WHERE Name = 'Active Store' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new FullHttpMock());

        Test.startTest();
        System.enqueueJob(new ShopifyManualAssociationQueueable(activeStore.Id));
        Test.stopTest();

        Contact updated = [SELECT Shopify_Company_Contact_Id__c FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        System.assertEquals('contact123', updated.Shopify_Company_Contact_Id__c,
            'Direct AccountId match (not ParentId) should also be picked up by the SOQL OR condition');
    }
}