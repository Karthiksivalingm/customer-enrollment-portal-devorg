//DEPRECATED
@isTest
public class ShopifyIntegrationServiceTest {
    
    /*public class MockHttpResponseGenerator implements HttpCalloutMock {
        private String responseType;
        
        public MockHttpResponseGenerator(String responseType) {
            this.responseType = responseType;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String body = req.getBody();
            
            if (body.contains('companies(first: 1')) {
                if (responseType == 'companyExists') {
                    res.setBody('{"data":{"companies":{"edges":[{"node":{"id":"gid://shopify/Company/123","name":"Test Company"}}]}}}');
                } else if (responseType == 'companyNotExists') {
                    res.setBody('{"data":{"companies":{"edges":[]}}}');
                }
            } else if (body.contains('companyCreate')) {
                res.setBody('{"data":{"companyCreate":{"company":{"id":"gid://shopify/Company/123","name":"Test Company","mainContact":{"id":"gid://shopify/CompanyContact/456","customer":{"id":"gid://shopify/Customer/789","email":"test@example.com"}}},"userErrors":[]}}}');
            } else if (body.contains('companyContactCreate')) {
                res.setBody('{"data":{"companyContactCreate":{"companyContact":{"id":"gid://shopify/CompanyContact/456","company":{"id":"gid://shopify/Company/123","name":"Test Company"},"customer":{"id":"gid://shopify/Customer/789","firstName":"John","lastName":"Doe","email":"test@example.com"}},"userErrors":[]}}}');
            }
            
            return res;
        }
    }
    
    @TestSetup
    static void setupTestData() {
        Shopify_Config__c config = new Shopify_Config__c();
        config.Shopify_Access_Token__c = 'test_access_token';
        insert config;
        
        Id companyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
        Id storeRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Store Location').getRecordTypeId();

        Account companyAccount = new Account(
            Name = 'Test Company Account',
            RecordTypeId = companyRecordTypeId,
            ShippingStreet = '123 Main St',
            ShippingCity = 'Anytown',
            ShippingState = 'California',
            ShippingPostalCode = '12345',
            ShippingCountry = 'US',
            Tax_Id__c = '1234567890'
        );
        insert companyAccount;

        Account storeAccount = new Account(
            Name = 'Test Store',
            RecordTypeId = storeRecordTypeId,
            ParentId = companyAccount.Id,
            BillingStreet = '456 Store Ave',
            BillingCity = 'Storeville',
            BillingState = 'California',
            BillingPostalCode = '67890',
            BillingCountry = 'US'
        );
        insert storeAccount;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '555-1234',
            AccountId = storeAccount.Id,
            MailingStreet = '456 Oak Ave',
            MailingCity = 'Testville',
            MailingState = 'California',
            MailingPostalCode = '54321',
            MailingCountry = 'US'
        );
        insert testContact;
    }
    
    @isTest
    static void testSendContactToShopify_CompanyNotExists() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('companyNotExists'));
        
        ShopifyIntegrationService.sendContactToShopify(new List<Id>{testContact.Id});
        
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, Shopify_Customer_Id__c, HIC_ShopifySync__Shopify_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('789', updatedContact.Shopify_Customer_Id__c, 'Shopify Customer ID should be set');
        System.assertEquals('789', updatedContact.HIC_ShopifySync__Shopify_Id__c, 'HIC Shopify Sync ID should be set');
    }
    
    @isTest
    static void testSendContactToShopify_CompanyExists() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('companyExists'));
        
        ShopifyIntegrationService.sendContactToShopify(new List<Id>{testContact.Id});
        
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, Shopify_Customer_Id__c, HIC_ShopifySync__Shopify_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('789', updatedContact.Shopify_Customer_Id__c, 'Shopify Customer ID should be set');
        System.assertEquals('789', updatedContact.HIC_ShopifySync__Shopify_Id__c, 'HIC Shopify Sync ID should be set');
    }
    
    @isTest
    static void testSendContactToShopify_WithExistingShopifyId() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        testContact.HIC_ShopifySync__Shopify_Id__c = 'existing_id';
        update testContact;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('companyNotExists'));
        
        ShopifyIntegrationService.sendContactToShopify(new List<Id>{testContact.Id});
        
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, Shopify_Customer_Id__c, HIC_ShopifySync__Shopify_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('789', updatedContact.HIC_ShopifySync__Shopify_Id__c, 'HIC Shopify Sync ID should be updated');
    }
    
    @isTest
    static void testSendContactToShopify_EmptyContactList() {
        Test.startTest();
        
        try {
            ShopifyIntegrationService.sendContactToShopify(new List<Id>());
            System.assert(false, 'Should throw exception for empty list');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for empty contact list');
        }
        
        Test.stopTest();
    }*/
    
    /*@isTest
    static void testSendContactToShopify_NullValues() {
        
        Account testAccountWithNulls = new Account(
            Name = 'Test Company No Address'
        );
        insert testAccountWithNulls;
        
        Contact testContactWithNulls = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            AccountId = testAccountWithNulls.Id
        );
        insert testContactWithNulls;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('companyNotExists'));
        
        ShopifyIntegrationService.sendContactToShopify(new List<Id>{testContactWithNulls.Id});
        
        Test.stopTest();
        
        Contact updatedContact = [SELECT Id, Shopify_Customer_Id__c FROM Contact WHERE Id = :testContactWithNulls.Id];
        System.assertEquals('789', updatedContact.Shopify_Customer_Id__c, 'Should handle null values gracefully');
    }*/
}