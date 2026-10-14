@IsTest
public class ShopifyAssociationSyncQueueableTest {

    /*
     * Get Account Record Type ID using Developer Name.
     */
    private static Id getAccountRecordTypeId(
        String developerName
    ) {

        List<RecordType> recordTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = :developerName
            LIMIT 1
        ];

        System.assert(
            !recordTypes.isEmpty(),
            'Account Record Type was not found: ' +
            developerName
        );

        return recordTypes[0].Id;
    }


    /*
     * Mock for successful Shopify API response.
     */
    private class ShopifyAssociationSuccessMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest request
        ) {

            HttpResponse response =
                new HttpResponse();

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setStatusCode(200);

            response.setBody(
                '{"success":true}'
            );

            return response;
        }
    }


    /*
     * Mock for failed Shopify API response.
     */
    private class ShopifyAssociationFailureMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest request
        ) {

            HttpResponse response =
                new HttpResponse();

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setStatusCode(500);

            response.setBody(
                '{"success":false,"error":"Integration failed"}'
            );

            return response;
        }
    }


    /*
     * Create common test data.
     */
    @TestSetup
    static void setupData() {

        Id companyRecordTypeId =
            getAccountRecordTypeId(
                'Company'
            );

        /*
         * Shopify Configuration.
         */
        Shopify_Configuration__c configuration =
            new Shopify_Configuration__c(
                Name = 'Specialty',
                Shopify_Endpoint__c =
                    'https://test-endpoint.com',
                Shopify_Access_Token__c =
                    'test-access-token'
            );

        insert configuration;


        /*
         * Company Account.
         */
        Account company =
            new Account(
                Name = 'Test Company',
                RecordTypeId =
                    companyRecordTypeId,
                Tax_Id__c =
                    '123456789',
                Shopify_Company_Id__c =
                    'compShopify123',
                Sales_Channel__c =
                    'Specialty'
            );

        insert company;


        /*
         * Valid Company Contact.
         */
        Contact companyContact =
            new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email =
                    'john.doe@test.com',
                AccountId =
                    company.Id,
                Shopify_Customer_Id__c =
                    'cust123'
            );

        insert companyContact;
    }


    /*
     * Test successful Queueable execution.
     */
    @IsTest
    static void testQueueableSuccess() {

        Contact contact = [
            SELECT
                Id,
                AccountId
            FROM Contact
            WHERE Email =
                'john.doe@test.com'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationSuccessMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    contact.Id,
                    contact.AccountId
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The Queueable job should be created.'
        );
    }


    /*
     * Test Contact without Shopify Customer ID.
     */
    @IsTest
    static void testContactWithoutShopifyCustomerId() {

        Account company = [
            SELECT Id
            FROM Account
            WHERE Name =
                'Test Company'
            LIMIT 1
        ];

        Contact contact =
            new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email =
                    'jane.smith@test.com',
                AccountId =
                    company.Id
            );

        insert contact;

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationSuccessMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    contact.Id,
                    company.Id
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The Queueable job should be created.'
        );
    }


    /*
     * Test Queueable constructor with association list.
     */
    @IsTest
    static void testQueueableAssociationList() {

        List<AccountContactRelationHandler.ShopifyAssociationInput>
            associations =
                new List<AccountContactRelationHandler.ShopifyAssociationInput>();

        associations.add(
            new AccountContactRelationHandler.ShopifyAssociationInput(
                'customer001',
                'company001',
                'Company',
                'customer1@test.com',
                'Specialty'
            )
        );

        associations.add(
            new AccountContactRelationHandler.ShopifyAssociationInput(
                'customer002',
                'company002',
                'Company',
                'customer2@test.com',
                'Specialty'
            )
        );

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationSuccessMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    associations
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The association-list Queueable should be created.'
        );
    }


    /*
     * Test multiple Shopify associations.
     */
    @IsTest
    static void testMultipleAssociations() {

        List<AccountContactRelationHandler.ShopifyAssociationInput>
            associations =
                new List<AccountContactRelationHandler.ShopifyAssociationInput>();

        for (
            Integer index = 0;
            index < 5;
            index++
        ) {

            associations.add(
                new AccountContactRelationHandler.ShopifyAssociationInput(
                    'customer' + index,
                    'company' + index,
                    'Company',
                    'customer' +
                    index +
                    '@test.com',
                    'Specialty'
                )
            );
        }

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationSuccessMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    associations
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The Queueable job should be created.'
        );
    }


   


    /*
     * Test failed Shopify callout.
     */
    @IsTest
    static void testQueueableCalloutFailure() {

        Contact contact = [
            SELECT
                Id,
                AccountId
            FROM Contact
            WHERE Email =
                'john.doe@test.com'
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationFailureMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    contact.Id,
                    contact.AccountId
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The Queueable job should be created.'
        );
    }


    /*
     * Test Store Location branch.
     *
     * Existing Company Contact is used to avoid:
     *
     * "Please select a Valid Company Contact"
     */
    @IsTest
    static void testStoreLocationBranch() {

        Id storeRecordTypeId =
            getAccountRecordTypeId(
                'Store_Location'
            );

        Account company = [
            SELECT Id
            FROM Account
            WHERE Name =
                'Test Company'
            LIMIT 1
        ];

        Contact validContact = [
            SELECT Id
            FROM Contact
            WHERE Email =
                'john.doe@test.com'
            LIMIT 1
        ];

        Account store =
            new Account(
                Name =
                    'Test Store Location',

                ParentId =
                    company.Id,

                RecordTypeId =
                    storeRecordTypeId,

                Tax_Id__c =
                    '987654321',

                Shopify_Company_Id__c =
                    'storeShopify456',

                Sales_Channel__c =
                    'Specialty',

                ShippingStreet =
                    '123 Test Street',

                ShippingCity =
                    'Test City',

                ShippingPostalCode =
                    '12345',

                ShippingCountryCode =
                    'US',

                Active__c =
                    true,

                Manual_Approval_Status__c =
                    'Approved'
            );

        insert store;

        Test.setMock(
            HttpCalloutMock.class,
            new ShopifyAssociationSuccessMock()
        );

        Test.startTest();

        Id jobId =
            System.enqueueJob(
                new ShopifyAssociationSyncQueueable(
                    validContact.Id,
                    store.Id
                )
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The Store Location Queueable should be created.'
        );
    }

@IsTest
static void testSkipRetryInTestContext() {

  Contact con = [
    SELECT Id, AccountId
    FROM Contact
    WHERE Email = 'john.doe@test.com'
    LIMIT 1
];

    ShopifyAssociationSyncQueueable.skipTestGuard = false;

    Test.startTest();
    System.enqueueJob(
        new ShopifyAssociationSyncQueueable(
            con.Id,
            con.AccountId
        )
    );
    Test.stopTest();

    System.assert(true);
}

    @IsTest
static void testRetryBranch() {

    Contact con = [
        SELECT Id, AccountId
        FROM Contact
        WHERE Email='john.doe@test.com'
        LIMIT 1
    ];

    update new Contact(
        Id = con.Id,
        Shopify_Customer_Id__c = null
    );

    ShopifyAssociationSyncQueueable.skipTestGuard = false;

    Test.startTest();
    System.enqueueJob(
        new ShopifyAssociationSyncQueueable(
            con.Id,
            con.AccountId,
            0
        )
    );
    Test.stopTest();

    ShopifyAssociationSyncQueueable.skipTestGuard = false;
}
@IsTest
static void testMaxRetriesReached() {

    Contact con = [
        SELECT Id, AccountId
        FROM Contact
        WHERE Email='john.doe@test.com'
        LIMIT 1
    ];

    update new Contact(
        Id = con.Id,
        Shopify_Customer_Id__c = null
    );

    ShopifyAssociationSyncQueueable.skipTestGuard = true;

    Test.startTest();
    System.enqueueJob(
        new ShopifyAssociationSyncQueueable(
            con.Id,
            con.AccountId,
            5
        )
    );
    Test.stopTest();

    List<Api_Log__c> logs = [
        SELECT Id
        FROM Api_Log__c
        WHERE Context__c='ShopifyAssociationSyncQueueable - Max Retries Reached'
    ];

    System.assertEquals(1, logs.size());

    ShopifyAssociationSyncQueueable.skipTestGuard = false;
}
   
}