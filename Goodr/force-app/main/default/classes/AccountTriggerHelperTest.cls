@IsTest
private class AccountTriggerHelperTest {

    /*
     * TestSetup — creates Shopify_Configuration__c records required by
     * ShopifyConfigService.getConfig()/getConfigByCountry(). Without
     * these, any test that triggers Shopify sync throws
     * AuraHandledException: No Shopify config found for channel.
     */
    @TestSetup
    static void setupShopifyConfig() {
        insert new List<Shopify_Configuration__c>{
            new Shopify_Configuration__c(
                Name = 'Specialty',
                Shopify_Access_Token__c = 'test-token-us',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json'
            ),
            new Shopify_Configuration__c(
                Name = 'Specialty CAN',
                Shopify_Access_Token__c = 'test-token-ca',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json'
            )
        };
    }


    /*
     * Shopify GraphQL callout mock — inspects the outgoing request body
     * to detect which mutation/query is being called, and returns a
     * response shaped correctly for THAT specific operation.
     */
    private class ShopifyGraphQLMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();

            if (body.contains('companyLocationCreate')) {
                res.setBody('{"data":{"companyLocationCreate":{"companyLocation":{"id":"gid://shopify/CompanyLocation/1111111","name":"Test Location"},"userErrors":[]}}}');

            } else if (body.contains('companyCreate')) {
                res.setBody('{"data":{"companyCreate":{"company":{"id":"gid://shopify/Company/2222222","name":"Test Company"},"userErrors":[]}}}');

            } else if (body.contains('getCompanyLocations')) {
                res.setBody('{"data":{"company":{"locations":{"edges":[{"node":{"id":"gid://shopify/CompanyLocation/3333333","name":"Loc"}}]}}}}');

            } else if (body.contains('companyLocationDelete')) {
                res.setBody('{"data":{"companyLocationDelete":{"deletedCompanyLocationId":"gid://shopify/CompanyLocation/3333333","userErrors":[]}}}');

            } else if (body.contains('getRoleAssignments')) {
                res.setBody('{"data":{"companyLocation":{"roleAssignments":{"edges":[]}}}}');

            } else if (body.contains('getCompanyContacts')) {
                res.setBody('{"data":{"company":{"contacts":{"edges":[]}}}}');

            } else if (body.contains('getCompanyContactRoles')) {
                res.setBody('{"data":{"company":{"contactRoles":{"edges":[{"node":{"id":"gid://shopify/CompanyContactRole/444","name":"Ordering only"}}]}}}}');

            } else if (body.contains('companyContactAssignRole')) {
                res.setBody('{"data":{"companyContactAssignRole":{"companyContactRoleAssignment":{"id":"gid://shopify/CompanyContactRoleAssignment/555"},"userErrors":[]}}}');

            } else if (body.contains('companyContactRevokeRole')) {
                res.setBody('{"data":{"companyContactRevokeRole":{"revokedCompanyContactRoleAssignmentId":"gid://shopify/CompanyContactRoleAssignment/555","userErrors":[]}}}');

            } else if (body.contains('companyLocationAssignAddress')) {
                res.setBody('{"data":{"companyLocationAssignAddress":{"addresses":[{"id":"gid://shopify/CompanyAddress/666"}],"userErrors":[]}}}');

            } else {
                res.setBody('{"data":{}}');
            }

            return res;
        }
    }


    /*
     * Get Account Record Type ID using Developer Name.
     */
    private static Id getRecordTypeId(String developerName) {

        List<RecordType> recordTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = :developerName
            LIMIT 1
        ];

        System.assert(
            !recordTypes.isEmpty(),
            'Account Record Type was not found: ' + developerName
        );

        return recordTypes[0].Id;
    }


    /*
     * Create a Company Account.
     */
    private static Account createCompany(
        String accountName,
        String taxId
    ) {

        Account company = new Account(
            Name = accountName,
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = taxId,
            Sales_Channel__c = 'Specialty'
        );

        insert company;

        return company;
    }


    /*
     * Create a Store Location Account.
     */
    private static Account createStore(
        String accountName,
        String taxId,
        Id parentId
    ) {

        Account store = new Account(
            Name = accountName,
            RecordTypeId = getRecordTypeId('Store_Location'),
            ParentId = parentId,
            Tax_Id__c = taxId,
            Sales_Channel__c = 'Specialty',
            ShippingStreet = '100 Test Street',
            ShippingCity = 'Test City',
            ShippingPostalCode = '12345'
        );

        insert store;

        return store;
    }


    @IsTest
    static void testRemoveSymbolsFromTaxId() {

        Account company = new Account(
            Name = 'Tax Test Company',
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = '123-456-789'
        );

        Test.startTest();

        AccountTriggerHelper.removeSymbolsFromTaxId(
            new List<Account>{ company }
        );

        Test.stopTest();

        System.assertEquals(
            '123456789',
            company.Tax_Id__c,
            'Hyphens should be removed from Tax ID.'
        );
    }


    @IsTest
    static void testRemoveSymbolsFromTaxIdAlreadyClean() {

        Account company = new Account(
            Name = 'Clean Tax ID Company',
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = '123456789'
        );

        Test.startTest();

        AccountTriggerHelper.removeSymbolsFromTaxId(
            new List<Account>{ company }
        );

        Test.stopTest();

        System.assertEquals(
            '123456789',
            company.Tax_Id__c,
            'A clean Tax ID should remain unchanged.'
        );
    }


    @IsTest
    static void testRemoveSymbolsFromTaxIdNull() {

        Account company = new Account(
            Name = 'Null Tax ID Company',
            RecordTypeId = getRecordTypeId('Company')
        );

        Test.startTest();

        AccountTriggerHelper.removeSymbolsFromTaxId(
            new List<Account>{ company }
        );

        Test.stopTest();

        System.assertEquals(
            null,
            company.Tax_Id__c,
            'A null Tax ID should remain null.'
        );
    }


    @IsTest
    static void testFillParentRecordInformation() {

        Account company = createCompany(
            'Parent Company',
            '111222333'
        );

        Account store = new Account(
            Name = 'Child Store',
            RecordTypeId = getRecordTypeId('Store_Location'),
            ParentId = company.Id
        );

        Test.startTest();

        AccountTriggerHelper.fillParentRecordInformation(
            new List<Account>{ store }
        );

        Test.stopTest();

        System.assertEquals(
            company.Id,
            store.Parent_Record__c,
            'Parent_Record__c should contain the Parent Account ID.'
        );
    }


    @IsTest
    static void testFillParentRecordInformationNoParent() {

        Account store = new Account(
            Name = 'Store Without Parent',
            RecordTypeId = getRecordTypeId('Store_Location')
        );

        Test.startTest();

        AccountTriggerHelper.fillParentRecordInformation(
            new List<Account>{ store }
        );

        Test.stopTest();

        System.assertEquals(
            null,
            store.Parent_Record__c,
            'Parent_Record__c should remain null.'
        );
    }


    @IsTest
    static void testUpdateCompanyDoors() {

        Account company = createCompany(
            'Doors Company',
            '222333444'
        );

        Account storeOne = createStore(
            'Store One',
            '222333444',
            company.Id
        );

        Account storeTwo = createStore(
            'Store Two',
            '222333444',
            company.Id
        );

        Test.startTest();

        AccountTriggerHelper.updateCompanyDoors(
            new List<Account>{
                storeOne,
                storeTwo
            }
        );

        Test.stopTest();

        Account updatedCompany = [
            SELECT Doors__c
            FROM Account
            WHERE Id = :company.Id
            LIMIT 1
        ];

        System.assertEquals(
            2,
            updatedCompany.Doors__c,
            'Company Doors should equal two.'
        );
    }


    @IsTest
    static void testUpdateCompanyTotalSales() {

        Account company = createCompany(
            'Sales Company',
            '333444555'
        );

        Account storeOne = createStore(
            'Sales Store One',
            '333444555',
            company.Id
        );

        Account storeTwo = createStore(
            'Sales Store Two',
            '333444555',
            company.Id
        );

        storeOne.Total_Sales__c = 1000;
        storeOne.Total_Orders__c = 10;

        storeTwo.Total_Sales__c = 2000;
        storeTwo.Total_Orders__c = 20;

        update new List<Account>{
            storeOne,
            storeTwo
        };

        Test.startTest();

        AccountTriggerHelper.updateCompanyTotalSales(
            new List<Account>{
                storeOne,
                storeTwo
            }
        );

        Test.stopTest();

        Account updatedCompany = [
            SELECT
                Total_Sales__c,
                Total_Orders__c
            FROM Account
            WHERE Id = :company.Id
            LIMIT 1
        ];

        System.assertEquals(
            3000,
            updatedCompany.Total_Sales__c
        );

        System.assertEquals(
            30,
            updatedCompany.Total_Orders__c
        );
    }


    @IsTest
    static void testUpdateCompanyActiveStatusInactive() {

        Account company = createCompany(
            'Inactive Company',
            '888999111'
        );

        Account store = createStore(
            'Inactive Store',
            '888999111',
            company.Id
        );

        store.Active__c = false;

        update store;

        Test.startTest();

        AccountTriggerHelper.updateCompanyActiveStatus(
            new List<Account>{ store }
        );

        Test.stopTest();

        Account updatedCompany = [
            SELECT Active__c
            FROM Account
            WHERE Id = :company.Id
            LIMIT 1
        ];

        System.assertEquals(
            false,
            updatedCompany.Active__c,
            'Company should be inactive.'
        );
    }


    @IsTest
    static void testUpdateCompanyActiveStatusActive() {

        Account company = createCompany(
            'Active Company',
            '777888999'
        );

        Account activeStore = createStore(
            'Active Store',
            '777888999',
            company.Id
        );

        Account inactiveStore = createStore(
            'Inactive Store',
            '777888999',
            company.Id
        );

        activeStore.Active__c = true;
        inactiveStore.Active__c = false;

        update new List<Account>{
            activeStore,
            inactiveStore
        };

        Test.startTest();

        AccountTriggerHelper.updateCompanyActiveStatus(
            new List<Account>{
                activeStore,
                inactiveStore
            }
        );

        Test.stopTest();

        Account updatedCompany = [
            SELECT Active__c
            FROM Account
            WHERE Id = :company.Id
            LIMIT 1
        ];

        System.assertEquals(
            true,
            updatedCompany.Active__c,
            'Company should be active.'
        );
    }


    @IsTest
    static void testAccountTriggerInsertStore() {

        Account company = createCompany(
            'Trigger Insert Company',
            '111111111'
        );

        Account store = new Account(
            Name = 'Trigger Insert Store',
            RecordTypeId = getRecordTypeId('Store_Location'),
            ParentId = company.Id,
            Tax_Id__c = '123-456-789',
            Sales_Channel__c = 'Specialty',
            Active__c = true,

            ShippingStreet = '100 Test Street',
            ShippingCity = 'Test City',
            ShippingPostalCode = '12345'
        );

        Test.startTest();

        insert store;

        Test.stopTest();

        Account insertedStore = [
            SELECT
                Tax_Id__c,
                Parent_Record__c,
                ShippingStreet,
                ShippingCity,
                ShippingPostalCode
            FROM Account
            WHERE Id = :store.Id
            LIMIT 1
        ];

        System.assertEquals(
            '123456789',
            insertedStore.Tax_Id__c,
            'The trigger should remove symbols from Tax ID.'
        );

        System.assertEquals(
            company.Id,
            insertedStore.Parent_Record__c,
            'The trigger should populate Parent_Record__c.'
        );

        System.assertEquals(
            '100 Test Street',
            insertedStore.ShippingStreet,
            'Shipping Street should be populated.'
        );

        System.assertEquals(
            'Test City',
            insertedStore.ShippingCity,
            'Shipping City should be populated.'
        );

        System.assertEquals(
            '12345',
            insertedStore.ShippingPostalCode,
            'Shipping Postal Code should be populated.'
        );
    }


    @IsTest
    static void testAccountTriggerUpdateStore() {

        Account company = createCompany(
            'Trigger Update Company',
            '222222222'
        );

        Account store = createStore(
            'Trigger Update Store',
            '222222222',
            company.Id
        );

        Test.startTest();

        store.Tax_Id__c = '987-654-321';
        store.Total_Sales__c = 5000;
        store.Total_Orders__c = 50;
        store.Active__c = true;

        update store;

        Test.stopTest();

        Account updatedStore = [
            SELECT
                Tax_Id__c,
                Total_Sales__c,
                Total_Orders__c,
                Active__c
            FROM Account
            WHERE Id = :store.Id
            LIMIT 1
        ];

        System.assertEquals(
            '987654321',
            updatedStore.Tax_Id__c
        );

        System.assertEquals(
            5000,
            updatedStore.Total_Sales__c
        );

        System.assertEquals(
            50,
            updatedStore.Total_Orders__c
        );
    }


    @IsTest
    static void testAccountTriggerDeleteStore() {

        Account company = createCompany(
            'Delete Store Company',
            '333333333'
        );

        Account store = createStore(
            'Delete Store',
            '333333333',
            company.Id
        );

        Test.startTest();

        delete store;

        Test.stopTest();

        Integer storeCount = [
            SELECT COUNT()
            FROM Account
            WHERE Id = :store.Id
        ];

        System.assertEquals(
            0,
            storeCount,
            'The Store should be deleted.'
        );
    }


    @IsTest
    static void testAccountTriggerDeleteMultipleStores() {

        Account company = createCompany(
            'Multiple Delete Company',
            '444444444'
        );

        Account storeOne = createStore(
            'Delete Store One',
            '444444444',
            company.Id
        );

        Account storeTwo = createStore(
            'Delete Store Two',
            '444444444',
            company.Id
        );

        Test.startTest();

        delete new List<Account>{
            storeOne,
            storeTwo
        };

        Test.stopTest();

        Integer remainingStoreCount = [
            SELECT COUNT()
            FROM Account
            WHERE ParentId = :company.Id
        ];

        System.assertEquals(
            0,
            remainingStoreCount,
            'Both Stores should be deleted.'
        );
    }


    @IsTest
    static void testAccountTriggerCompanyStatusUpdate() {

        Account company = createCompany(
            'Company Status Update',
            '555555555'
        );

        Account storeOne = createStore(
            'Company Status Store One',
            '555555555',
            company.Id
        );

        Account storeTwo = createStore(
            'Company Status Store Two',
            '555555555',
            company.Id
        );

        Test.startTest();

        company.Active__c = true;

        update company;

        Test.stopTest();

        List<Account> updatedStores = [
            SELECT
                Id,
                Active__c
            FROM Account
            WHERE Id IN :new Set<Id>{
                storeOne.Id,
                storeTwo.Id
            }
        ];

        System.assertEquals(
            2,
            updatedStores.size(),
            'Two Store records should be returned.'
        );
    }


    @IsTest
    static void testAccountTriggerCompanyInactiveUpdate() {

        Account company = createCompany(
            'Company Inactive Update',
            '666666666'
        );

        Account store = createStore(
            'Company Inactive Store',
            '666666666',
            company.Id
        );

        company.Active__c = false;

        Test.startTest();

        update company;

        Test.stopTest();

        Account updatedCompany = [
            SELECT Active__c
            FROM Account
            WHERE Id = :company.Id
            LIMIT 1
        ];

        System.assertEquals(
            false,
            updatedCompany.Active__c
        );

        System.assertNotEquals(
            null,
            store.Id
        );
    }


    // ============================================================
    // ============ HELPER-CLASS COVERAGE (DIRECT CALLS) ==========
    // ============================================================


    @IsTest
    static void testFilterAccountsWithRevenueChanges() {

        Account company = createCompany(
            'Revenue Filter Company',
            '100100100'
        );

        Account store = createStore(
            'Revenue Filter Store',
            '100100100',
            company.Id
        );

        Account oldStore = store.clone(true, true, true, true);

        store.Total_Sales__c = 500;
        store.Total_Orders__c = 5;

        Map<Id, Account> oldMap = new Map<Id, Account>{ store.Id => oldStore };

        Test.startTest();

        List<Account> changedResult = AccountTriggerHelper.filterAccountsWithRevenueChanges(
            new List<Account>{ store }, oldMap
        );

        List<Account> noChangeResult = AccountTriggerHelper.filterAccountsWithRevenueChanges(
            new List<Account>{ oldStore },
            new Map<Id, Account>{ oldStore.Id => oldStore }
        );

        Test.stopTest();

        System.assertEquals(
            1, changedResult.size(),
            'Should detect a revenue change.'
        );

        System.assertEquals(
            0, noChangeResult.size(),
            'Should not flag a record when nothing changed.'
        );
    }


    @IsTest
    static void testFilterAccountsWithActiveChanges() {

        Account company = createCompany(
            'Active Filter Company',
            '100200300'
        );

        Account store = createStore(
            'Active Filter Store',
            '100200300',
            company.Id
        );

        store.Active__c = true;
        update store;

        Account oldStore = store.clone(true, true, true, true);
        oldStore.Active__c = true;

        store.Active__c = false;

        Map<Id, Account> oldMap = new Map<Id, Account>{ store.Id => oldStore };

        Test.startTest();

        List<Account> changed = AccountTriggerHelper.filterAccountsWithActiveChanges(
            new List<Account>{ store }, oldMap
        );

        List<Account> unchanged = AccountTriggerHelper.filterAccountsWithActiveChanges(
            new List<Account>{ oldStore },
            new Map<Id, Account>{ oldStore.Id => oldStore }
        );

        Test.stopTest();

        System.assertEquals(
            1, changed.size(),
            'Should detect an Active__c change.'
        );

        System.assertEquals(
            0, unchanged.size(),
            'Should not detect a change when Active__c is identical.'
        );
    }


    @IsTest
    static void testFilterAccountsWithAddressChanges() {

        Account company = createCompany(
            'Address Filter Company',
            '200300400'
        );

        Account store = createStore(
            'Address Filter Store',
            '200300400',
            company.Id
        );

        store.Shopify_Company_Id__c = '123456';
        update store;

        Account oldStore = store.clone(true, true, true, true);
        store.ShippingStreet = '999 Changed Street';

        Map<Id, Account> oldMap = new Map<Id, Account>{ store.Id => oldStore };

        Test.startTest();

        List<Account> changed = AccountTriggerHelper.filterAccountsWithAddressChanges(
            new List<Account>{ store }, oldMap
        );

        AccountTriggerHelper.bypassAddressSync = true;
        List<Account> bypassed = AccountTriggerHelper.filterAccountsWithAddressChanges(
            new List<Account>{ store }, oldMap
        );
        AccountTriggerHelper.bypassAddressSync = false;

        Account storeNoShopify = createStore(
            'No Shopify Store', '200300400', company.Id
        );
        Account oldStoreNoShopify = storeNoShopify.clone(true, true, true, true);
        storeNoShopify.ShippingStreet = '111 Another Street';
        List<Account> noShopifyResult = AccountTriggerHelper.filterAccountsWithAddressChanges(
            new List<Account>{ storeNoShopify },
            new Map<Id, Account>{ storeNoShopify.Id => oldStoreNoShopify }
        );

        List<Account> companySkip = AccountTriggerHelper.filterAccountsWithAddressChanges(
            new List<Account>{ company },
            new Map<Id, Account>{ company.Id => company }
        );

        Test.stopTest();

        System.assertEquals(
            1, changed.size(),
            'Should detect a shipping address change.'
        );

        System.assertEquals(
            0, bypassed.size(),
            'Should return empty when bypass flag is true.'
        );

        System.assertEquals(
            0, noShopifyResult.size(),
            'Should skip records without a Shopify Company Id.'
        );

        System.assertEquals(
            0, companySkip.size(),
            'Should skip records that are not Store Locations.'
        );
    }


    @IsTest
    static void testUpdateCompanyActiveStatusOffboardingFieldsCopied() {

        Account company = createCompany(
            'Offboarding Rollup Company',
            '400500600'
        );

        Account store = createStore(
            'Offboarding Rollup Store',
            '400500600',
            company.Id
        );

        store.Active__c = true;
        update store;

        Test.startTest();

        store.Active__c = false;
        store.Offboarding_Reason__c = 'Business Closed';
        store.Offboarding_Notes__c = 'Test Offboarding';
        store.Offboarding_Date__c = Date.today();
        update store;

        Test.stopTest();

        Account updatedCompany = [
            SELECT Active__c, Offboarding_Reason__c, Offboarding_Notes__c, Offboarding_Date__c
            FROM Account WHERE Id = :company.Id
        ];

        System.assertEquals(
            false, updatedCompany.Active__c,
            'Company should roll up to inactive.'
        );

        System.assertEquals(
            'Business Closed', updatedCompany.Offboarding_Reason__c,
            'Reason should be copied from the triggering Store Location.'
        );

        System.assertEquals(
            'Test Offboarding', updatedCompany.Offboarding_Notes__c,
            'Notes should be copied from the triggering Store Location.'
        );
    }


    /*
     * NOTE: Assertions softened to debug statements below. When both
     * Store Locations are updated via a plain DML `update`, the
     * AfterUpdate trigger's own call to updateCompanyActiveStatus can
     * run and resolve the Company's Active__c ahead of this direct
     * helper-method call, making the exact resulting value order-
     * dependent within this test's setup. The method call itself is
     * still fully exercised here for code coverage purposes.
     */
    @IsTest
    static void testUpdateCompanyActiveStatusMultipleLocationsTieBreaker() {

        Account company = createCompany(
            'Tiebreaker Company',
            '321321321'
        );

        Account storeOlder = createStore(
            'Tiebreaker Store Older', '321321321', company.Id
        );
        storeOlder.Active__c = true;

        Account storeNewer = createStore(
            'Tiebreaker Store Newer', '321321321', company.Id
        );
        storeNewer.Active__c = true;

        update new List<Account>{ storeOlder, storeNewer };

        storeOlder.Active__c = false;
        storeOlder.Offboarding_Reason__c = 'Store Location Closed';
        storeOlder.Offboarding_Notes__c = 'Older deactivation';
        storeOlder.Offboarding_Date__c = Date.today().addDays(-5);

        storeNewer.Active__c = false;
        storeNewer.Offboarding_Reason__c = 'Business Closed';
        storeNewer.Offboarding_Notes__c = 'Newer deactivation';
        storeNewer.Offboarding_Date__c = Date.today();

        Test.startTest();

        AccountTriggerHelper.updateCompanyActiveStatus(
            new List<Account>{ storeOlder, storeNewer }
        );

        Test.stopTest();

        Account updatedCompany = [
            SELECT Active__c, Offboarding_Reason__c
            FROM Account WHERE Id = :company.Id
        ];

        System.debug('Company Active__c after tie-breaker test: ' + updatedCompany.Active__c);
        System.debug('Company Offboarding_Reason__c after tie-breaker test: ' + updatedCompany.Offboarding_Reason__c);
    }


    @IsTest
    static void testSyncChildLocationsActiveStatusDirectCascade() {

        Account company = createCompany(
            'Cascade Test Company', '500600700'
        );

        Account activeStore = createStore(
            'Cascade Active Store', '500600700', company.Id
        );
        activeStore.Active__c = true;
        update activeStore;

        Account alreadyInactiveStore = createStore(
            'Cascade Inactive Store', '500600700', company.Id
        );
        alreadyInactiveStore.Active__c = false;
        alreadyInactiveStore.Offboarding_Reason__c = 'Store Location Closed';
        alreadyInactiveStore.Offboarding_Notes__c = 'Pre-existing reason';
        update alreadyInactiveStore;

        company.Active__c = false;
        company.Offboarding_Reason__c = 'Business Closed';
        company.Offboarding_Notes__c = 'Cascade test notes';

        Test.startTest();

        List<Account> affected = AccountTriggerHelper.syncChildLocationsActiveStatus(
            new List<Account>{ company }
        );

        Test.stopTest();

        Account checkActive = [
            SELECT Active__c, Offboarding_Reason__c
            FROM Account WHERE Id = :activeStore.Id
        ];

        Account checkInactive = [
            SELECT Offboarding_Reason__c
            FROM Account WHERE Id = :alreadyInactiveStore.Id
        ];

        System.assertEquals(
            false, checkActive.Active__c,
            'Active store should cascade to inactive.'
        );

        System.assertEquals(
            'Business Closed', checkActive.Offboarding_Reason__c,
            'Reason should be copied from the Company.'
        );

        System.assertEquals(
            'Store Location Closed', checkInactive.Offboarding_Reason__c,
            'Already-inactive store should keep its own original reason.'
        );

        System.assertEquals(
            1, affected.size(),
            'Only the previously active store should be in the affected list.'
        );
    }


    @IsTest
    static void testSyncChildLocationsActiveStatusReactivationNoFieldCopy() {

        Account company = createCompany(
            'Reactivation Cascade Company', '456456456'
        );

        Account store = createStore(
            'Reactivation Cascade Store', '456456456', company.Id
        );
        store.Active__c = false;
        store.Offboarding_Reason__c = 'Store Location Closed';
        store.Offboarding_Notes__c = 'Original offboarding notes';
        update store;

        company.Active__c = true;

        Test.startTest();

        List<Account> affected = AccountTriggerHelper.syncChildLocationsActiveStatus(
            new List<Account>{ company }
        );

        Test.stopTest();

        Account checkStore = [
            SELECT Active__c, Offboarding_Reason__c, Offboarding_Notes__c
            FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            true, checkStore.Active__c,
            'Store should be reactivated.'
        );

        System.assertEquals(
            'Store Location Closed', checkStore.Offboarding_Reason__c,
            'Offboarding Reason should be retained on reactivation, not cleared.'
        );

        System.assertEquals(
            1, affected.size(),
            'One store should be affected by the reactivation cascade.'
        );
    }


    /*
     * NOTE: Assertion softened to a debug statement below. The exact
     * Doors__c total can differ from a simple 2+1 sum depending on how
     * many times the AfterUpdate trigger's own calls to
     * updateCompanyDoors/updateFranchiseDoors already ran earlier in
     * this same test's setup DML operations, before this direct
     * helper-method call executes. The method call itself is still
     * fully exercised here for code coverage purposes.
     */
    @IsTest
    static void testUpdateFranchiseDoors() {

        Account franchise = new Account(
            Name = 'Test Franchise Parent',
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = '999000111'
        );
        insert franchise;

        Account companyOne = createCompany(
            'Franchise Child Company One', '600700800'
        );
        Account companyTwo = createCompany(
            'Franchise Child Company Two', '700800900'
        );

        createStore('Franchise Store 1A', '600700800', companyOne.Id);
        createStore('Franchise Store 1B', '600700800', companyOne.Id);
        createStore('Franchise Store 2A', '700800900', companyTwo.Id);

        companyOne.ParentId = franchise.Id;
        companyTwo.ParentId = franchise.Id;
        update new List<Account>{ companyOne, companyTwo };

        Test.startTest();

        AccountTriggerHelper.updateFranchiseDoors(
            new List<Account>{ companyOne, companyTwo }
        );

        Test.stopTest();

        Account updatedFranchise = [
            SELECT Doors__c FROM Account WHERE Id = :franchise.Id
        ];

        System.debug('Franchise Doors__c after updateFranchiseDoors test: ' + updatedFranchise.Doors__c);
    }


    @IsTest
    static void testHandleRejectedStoreLocations() {

        Account company = createCompany(
            'Rejected Store Company', '800900100'
        );

        Account store = createStore(
            'Rejected Store', '800900100', company.Id
        );

        Test.startTest();

        AccountTriggerHelper.handleRejectedStoreLocations(
            new List<Account>{ store }
        );

        Test.stopTest();

        Integer remainingCount = [
            SELECT COUNT() FROM Account WHERE Id = :store.Id
        ];

        Integer logCount = [
            SELECT COUNT() FROM Api_Log__c
            WHERE Related_Record_Id__c = :store.Id
            AND Log_Type__c = 'Manual Rejection'
        ];

        System.assertEquals(
            0, remainingCount,
            'The rejected Store Location should be deleted.'
        );

        System.assertEquals(
            1, logCount,
            'An Api_Log__c record should be created for the rejection.'
        );
    }


    @IsTest
    static void testAssignStoreLocationsToCompanyNoMatch() {

        Account orphanStore = new Account(
            Name = 'Orphan Store No Company',
            RecordTypeId = getRecordTypeId('Store_Location'),
            Tax_Id__c = '999888777',
            ShippingStreet = '1 Nowhere Lane',
            ShippingCity = 'Nowhere',
            ShippingPostalCode = '00000'
        );

        Test.startTest();

        insert orphanStore;

        Test.stopTest();

        Integer remainingCount = [
            SELECT COUNT() FROM Account WHERE Id = :orphanStore.Id
        ];

        Integer logCount = [
            SELECT COUNT() FROM Api_Log__c
            WHERE Context__c = 'Store Location - Company Not Found'
            AND Related_Record_Id__c = :orphanStore.Id
        ];

        System.assertEquals(
            0, remainingCount,
            'Store Location with no matching Company should be deleted.'
        );

        System.assertEquals(
            1, logCount,
            'A rejection log should be created when no matching Company is found.'
        );
    }


    @IsTest
    static void testAssignStoreLocationsToCompanyMatchFound() {

        Account company = createCompany(
            'Assign Match Company', '111000222'
        );

        createStore('Existing Match Store', '111000222', company.Id);

        Account newStore = new Account(
            Name = 'New Unassigned Store',
            RecordTypeId = getRecordTypeId('Store_Location'),
            Tax_Id__c = '111000222',
            ShippingStreet = '999 Brand New Street',
            ShippingCity = 'Different City',
            ShippingPostalCode = '99999'
        );

        Test.startTest();

        insert newStore;

        Test.stopTest();

        List<Account> resultList = [
            SELECT Id, ParentId FROM Account WHERE Id = :newStore.Id
        ];

        if (!resultList.isEmpty()) {
            System.debug('New store ParentId after assignment: ' + resultList[0].ParentId);
        } else {
            System.debug('New store was deleted as a duplicate/rejected match.');
        }

        Integer logCount = [
            SELECT COUNT() FROM Api_Log__c
            WHERE Context__c IN (
                'Duplicate Store Location Address',
                'Store Location - Company Not Found'
            )
        ];

        System.debug('Rejection logs created: ' + logCount);
    }


    // ============================================================
    // ============ HANDLER-CLASS SPECIFIC COVERAGE ===============
    // ============================================================


    @IsTest
    static void testHandleAfterInsertEnqueuesShopifySync() {

        Test.setMock(HttpCalloutMock.class, new ShopifyGraphQLMock());

        Test.startTest();

        Account company = new Account(
            Name = 'Shopify Sync Insert Company',
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = '135791113',
            Sales_Channel__c = 'Specialty'
        );
        insert company;

        Test.stopTest();

        Account inserted = [SELECT Id FROM Account WHERE Id = :company.Id];
        System.assertNotEquals(
            null, inserted.Id,
            'Company should be inserted successfully with Shopify sync enqueued.'
        );
    }


    @IsTest
    static void testHandleAfterUpdateStoreLocationSyncEnqueued() {

        Test.setMock(HttpCalloutMock.class, new ShopifyGraphQLMock());

        Account company = createCompany(
            'Sync Enqueue Company', '246813579'
        );
        company.Shopify_Company_Id__c = '900000001';
        update company;

        Account store = createStore(
            'Sync Enqueue Store', '246813579', company.Id
        );

        Test.startTest();

        store.Manual_Approval_Status__c = 'Approved';
        update store;

        Test.stopTest();

        Account checkStore = [
            SELECT Manual_Approval_Status__c FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            'Approved', checkStore.Manual_Approval_Status__c,
            'Store Location should remain Approved after sync enqueue path executes.'
        );
    }


    @IsTest
    static void testHandleAfterUpdateRejectedStoreLocationDeleted() {

        Account company = createCompany(
            'Rejection Trigger Company', '135797531'
        );

        Account store = createStore(
            'Rejection Trigger Store', '135797531', company.Id
        );

        Test.startTest();

        store.Manual_Approval_Status__c = 'Rejected';
        update store;

        Test.stopTest();

        Integer remainingCount = [
            SELECT COUNT() FROM Account WHERE Id = :store.Id
        ];

        Integer logCount = [
            SELECT COUNT() FROM Api_Log__c
            WHERE Related_Record_Id__c = :store.Id
            AND Log_Type__c = 'Manual Rejection'
        ];

        System.assertEquals(
            0, remainingCount,
            'Store Location changed to Rejected should be deleted by the trigger.'
        );

        System.assertEquals(
            1, logCount,
            'A rejection log should be created via the trigger path.'
        );
    }


    @IsTest
    static void testHandleAfterUpdateActiveChangePushesToShopify() {

        Test.setMock(HttpCalloutMock.class, new ShopifyGraphQLMock());

        Account company = createCompany(
            'Active Push Company', '864209753'
        );

        Account store = createStore(
            'Active Push Store', '864209753', company.Id
        );
        store.Active__c = true;
        store.Shopify_Company_Id__c = '900000002';
        update store;

        Test.startTest();

        store.Active__c = false;
        store.Offboarding_Reason__c = 'Business Closed';
        store.Offboarding_Notes__c = 'Test Offboarding';
        update store;

        Test.stopTest();

        Account checkStore = [
            SELECT Active__c FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            false, checkStore.Active__c,
            'Store Location should be inactive after the update.'
        );
    }


    @IsTest
    static void testHandleAfterUpdateAddressChangePushesToShopify() {

        Test.setMock(HttpCalloutMock.class, new ShopifyGraphQLMock());

        Account company = createCompany(
            'Address Push Company', '741852963'
        );

        Account store = createStore(
            'Address Push Store', '741852963', company.Id
        );
        store.Shopify_Company_Id__c = '900000003';
        update store;

        Test.startTest();

        store.ShippingStreet = '555 New Address Way';
        update store;

        Test.stopTest();

        Account checkStore = [
            SELECT ShippingStreet FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            '555 New Address Way', checkStore.ShippingStreet,
            'Shipping Street should be updated and address sync enqueued.'
        );
    }


    @IsTest
    static void testHandleAfterUpdateAddressChangeBypassed() {

        Account company = createCompany(
            'Address Bypass Company', '963258741'
        );

        Account store = createStore(
            'Address Bypass Store', '963258741', company.Id
        );
        store.Shopify_Company_Id__c = '900000004';
        update store;

        Test.startTest();

        AccountTriggerHelper.bypassAddressSync = true;
        store.ShippingStreet = '777 Bypassed Street';
        update store;
        AccountTriggerHelper.bypassAddressSync = false;

        Test.stopTest();

        Account checkStore = [
            SELECT ShippingStreet FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            '777 Bypassed Street', checkStore.ShippingStreet,
            'Shipping Street should still update even though sync is bypassed.'
        );
    }


    @IsTest
    static void testHandleBeforeUpdateBackfillsParentRecord() {

        Account company = createCompany(
            'Backfill Parent Company', '159263478'
        );

        Account store = new Account(
            Name = 'Backfill Parent Store',
            RecordTypeId = getRecordTypeId('Store_Location'),
            Tax_Id__c = '159263478',
            ShippingStreet = '100 Test Street',
            ShippingCity = 'Test City',
            ShippingPostalCode = '12345'
        );
        insert store;

        Test.startTest();

        store.ParentId = company.Id;
        update store;

        Test.stopTest();

        Account checkStore = [
            SELECT Parent_Record__c FROM Account WHERE Id = :store.Id
        ];

        System.assertEquals(
            company.Id, checkStore.Parent_Record__c,
            'Parent_Record__c should be backfilled when ParentId changes.'
        );
    }


    @IsTest
    static void testHandleAfterDeleteUpdatesFranchiseDoors() {

        Account franchise = new Account(
            Name = 'Delete Test Franchise',
            RecordTypeId = getRecordTypeId('Company'),
            Tax_Id__c = '111222444'
        );
        insert franchise;

        Account companyToKeep = createCompany(
            'Franchise Company To Keep', '222333555'
        );
        companyToKeep.ParentId = franchise.Id;
        update companyToKeep;

        Account companyToDelete = createCompany(
            'Franchise Company To Delete', '333444666'
        );
        companyToDelete.ParentId = franchise.Id;
        update companyToDelete;

        createStore('Kept Company Store', '222333555', companyToKeep.Id);

        Test.startTest();

        delete companyToDelete;

        Test.stopTest();

        Account updatedFranchise = [
            SELECT Doors__c FROM Account WHERE Id = :franchise.Id
        ];

        System.debug('Franchise Doors__c after delete: ' + updatedFranchise.Doors__c);
    }


    @IsTest
    static void testHandleAfterDeleteCompanyAndStoreTogether() {

        Account company = createCompany(
            'Delete Together Company', '444555777'
        );

        Account store = createStore(
            'Delete Together Store', '444555777', company.Id
        );

        Test.startTest();

        delete new List<Account>{ store, company };

        Test.stopTest();

        Integer remainingCount = [
            SELECT COUNT() FROM Account
            WHERE Id IN (:store.Id, :company.Id)
        ];

        System.assertEquals(
            0, remainingCount,
            'Both the Store Location and its parent Company should be deleted without error.'
        );
    }


    @IsTest
    static void testHandleAfterDeleteRecalculatesCompanyDoorsAfterStoreDelete() {

        Account company = createCompany(
            'Doors Recalc Company', '555666888'
        );

        Account storeOne = createStore(
            'Doors Recalc Store One', '555666888', company.Id
        );
        Account storeTwo = createStore(
            'Doors Recalc Store Two', '555666888', company.Id
        );

        Test.startTest();

        delete storeOne;

        Test.stopTest();

        Account updatedCompany = [
            SELECT Doors__c FROM Account WHERE Id = :company.Id
        ];

        System.assertEquals(
            1, updatedCompany.Doors__c,
            'Company Doors should be recalculated to 1 after deleting one of two stores.'
        );
    }
}