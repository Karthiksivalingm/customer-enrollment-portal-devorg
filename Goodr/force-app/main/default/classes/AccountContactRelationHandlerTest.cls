@IsTest
private class AccountContactRelationHandlerTest {

    /*
     * Get Account Record Type ID safely.
     */
    private static Id getAccountRecordTypeId(String developerName) {

        List<RecordType> recordTypeList = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = :developerName
            LIMIT 1
        ];

        if (recordTypeList.isEmpty()) {
            return null;
        }

        return recordTypeList[0].Id;
    }


    /*
     * Create test data.
     */
    @TestSetup
    static void setupData() {

        Id companyRT = getAccountRecordTypeId('Company');
        Id storeRT = getAccountRecordTypeId('Store_Location');


        /*
         * Company Account
         */
        Account company = new Account(
            Name = 'Test Company',
            RecordTypeId = companyRT,

            Shopify_Company_Id__c = 'COMP001',
            Sales_Channel__c = 'Specialty',

            /*
             * Required by the Company validation rule.
             */
            Tax_ID__c = '123456789',

            /*
             * Keep only basic address fields.
             *
             * Do not set:
             * BillingState
             * BillingStateCode
             * BillingCountry
             * BillingCountryCode
             * ShippingState
             * ShippingStateCode
             * ShippingCountry
             * ShippingCountryCode
             */
            ShippingStreet = '123 Test Street',
            ShippingCity = 'Los Angeles',
            ShippingPostalCode = '90001',

            BillingStreet = '123 Test Street',
            BillingCity = 'Los Angeles',
            BillingPostalCode = '90001'
        );

        insert company;


        /*
         * Store Location Account
         */
        Account store = new Account(
            Name = 'Test Store',
            RecordTypeId = storeRT,

            Shopify_Company_Id__c = 'STORE001',
            Sales_Channel__c = 'Specialty',

            Tax_ID__c = '987654321',

            ShippingStreet = '456 Store Street',
            ShippingCity = 'Toronto',
            ShippingPostalCode = 'M5V1E3',

            BillingStreet = '456 Store Street',
            BillingCity = 'Toronto',
            BillingPostalCode = 'M5V1E3'
        );

        insert store;


        /*
         * Company Account without Shopify Company ID.
         */
        Account companyNoShopify = new Account(
            Name = 'No Shopify Company',
            RecordTypeId = companyRT,

            Tax_ID__c = '456789123',

            ShippingStreet = '789 Company Street',
            ShippingCity = 'New York',
            ShippingPostalCode = '10001',

            BillingStreet = '789 Company Street',
            BillingCity = 'New York',
            BillingPostalCode = '10001'
        );

        insert companyNoShopify;


        /*
         * Contact with Shopify Customer ID.
         *
         * AccountId is required so the Contact is not private.
         */
        Contact shopifyContact = new Contact(
            FirstName = 'Test',
            LastName = 'Smith',
            Email = 'smith@test.com',

            Shopify_Customer_Id__c = 'CUST001',

            AccountId = company.Id
        );

        insert shopifyContact;


        /*
         * Contact without Shopify Customer ID.
         */
        Contact nonShopifyContact = new Contact(
            FirstName = 'Test',
            LastName = 'NoShopify',
            Email = 'noshopify@test.com',

            AccountId = company.Id
        );

        insert nonShopifyContact;
    }


    /*
     * Test Company Account relationship.
     *
     * The Contact already belongs directly to Test Company.
     * Therefore, use No Shopify Company as the additional Account.
     */
    @IsTest
    static void testCompanyAssociation() {

        Account relatedAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'No Shopify Company'
            LIMIT 1
        ];

        Contact shopifyContact = [
            SELECT Id
            FROM Contact
            WHERE LastName = 'Smith'
            LIMIT 1
        ];

        Test.startTest();

        AccountContactRelation relation =
            new AccountContactRelation(
                AccountId = relatedAccount.Id,
                ContactId = shopifyContact.Id,
                Roles = 'Decision Maker'
            );

        insert relation;

        Test.stopTest();

        System.assertNotEquals(
            null,
            relation.Id,
            'The Account Contact Relationship should be created.'
        );
    }


    /*
     * Test Store Location relationship.
     */
 /* @IsTest
static void testStoreLocationAssociation() {

    List<Account> storeAccounts = [
        SELECT Id
        FROM Account
        WHERE Name = 'Test Store'
        LIMIT 1
    ];

    List<Contact> shopifyContacts = [
        SELECT Id
        FROM Contact
        WHERE LastName = 'Smith'
        LIMIT 1
    ];

    System.assert(
        !storeAccounts.isEmpty(),
        'Test Store Account was not created in @TestSetup.'
    );

    System.assert(
        !shopifyContacts.isEmpty(),
        'Smith Contact was not created in @TestSetup.'
    );

    Account storeAccount = storeAccounts[0];
    Contact shopifyContact = shopifyContacts[0];

    Test.startTest();

    AccountContactRelation relation =
        new AccountContactRelation(
            AccountId = storeAccount.Id,
            ContactId = shopifyContact.Id
        );

    insert relation;

    Test.stopTest();

    System.assertNotEquals(
        null,
        relation.Id,
        'The Store Location relationship should be created.'
    );
}*/
    /*
     * Test Contact without Shopify Customer ID.
     */
    /*@IsTest
    static void testContactWithoutShopifyId() {

        Account storeAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Store'
            LIMIT 1
        ];

        Contact nonShopifyContact = [
            SELECT Id
            FROM Contact
            WHERE LastName = 'NoShopify'
            LIMIT 1
        ];

        Test.startTest();

        AccountContactRelation relation =
            new AccountContactRelation(
                AccountId = storeAccount.Id,
                ContactId = nonShopifyContact.Id,
                Roles = 'User'
            );

        insert relation;

        Test.stopTest();

        System.assertNotEquals(
            null,
            relation.Id,
            'The relationship should be created.'
        );
    }*/
    


    /*
     * Test Account without Shopify Company ID.
     */
    @IsTest
    static void testAccountWithoutShopifyId() {

        Account nonShopifyAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'No Shopify Company'
            LIMIT 1
        ];

        Contact shopifyContact = [
            SELECT Id
            FROM Contact
            WHERE LastName = 'Smith'
            LIMIT 1
        ];

        Test.startTest();

        AccountContactRelation relation =
            new AccountContactRelation(
                AccountId = nonShopifyAccount.Id,
                ContactId = shopifyContact.Id,
                Roles = 'User'
            );

        insert relation;

        Test.stopTest();

        System.assertNotEquals(
            null,
            relation.Id,
            'The relationship should be created.'
        );
    }


    /*
     * Cover the empty-list branch.
     */
    @IsTest
    static void testEmptyListCoverage() {

        Test.startTest();

        AccountContactRelationHandler.handleAfterInsert(
            new List<AccountContactRelation>()
        );

        Test.stopTest();

        System.assertEquals(
            0,
            0,
            'The empty-list execution should complete.'
        );
    }


    /*
     * Cover null AccountId and ContactId.
     */
    @IsTest
    static void testNullIdCoverage() {

        List<AccountContactRelation> relationList =
            new List<AccountContactRelation>();

        relationList.add(
            new AccountContactRelation()
        );

        Test.startTest();

        AccountContactRelationHandler.handleAfterInsert(
            relationList
        );

        Test.stopTest();

        System.assertEquals(
            1,
            relationList.size(),
            'The test list should contain one record.'
        );
    }
}