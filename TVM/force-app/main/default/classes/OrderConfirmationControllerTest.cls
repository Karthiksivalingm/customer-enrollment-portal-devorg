//Apex class from FND

@isTest
public class OrderConfirmationControllerTest {
     private static String uniqueSuffix() {
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

        
   static Opportunity createTestData() {
        String suf = uniqueSuffix();

        // Fetch active users for Regional Manager and Technician
        User regionalManager = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        User technician = [SELECT Id, Email FROM User WHERE IsActive = true AND Id != :regionalManager.Id LIMIT 1];

        // Create Account
        Account acc = new Account(
            Name = 'Test Dealership ' + suf,
            BillingStreet = '123 Main St',
            BillingCity = 'Los Angeles',
            BillingState = 'CA',
            BillingPostalCode = '90001',
            Quickbase_Record_ID__c = 'QB_' + suf,
            Regional_performance_manager__c = regionalManager.Id,
            Account_Technician__c = technician.Id
        );
        insert acc;

        // Create a Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Title__c = 'Sales Manager',
            AccountId = acc.Id, 
            Contact_Role__c = 'Foundation Contract Signer'
        );
        insert con;
        
        // Assign "Contract Signer" role
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE ContactId = :con.Id LIMIT 1];
        acr.Roles = 'Contract Signer';
        update acr;
        
        // Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = acc.Name,
            AccountId = acc.Id,
            StageName = 'Prospect',
            CloseDate = Date.today(),
            Target_Launch_Month__c = 'March'
        );
        insert opp;
        
        // Create a Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            MRR__c = 50,
            Addendum_Language__c = 'Test Addendum',
            IsActive = true
        );
        insert prod;
        
        // Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id,
            MRR__c = 50,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oli;
        
        return opp;
    }
    
     @isTest
    static void testOrderConfirmationController() {
        Opportunity testOpp = createTestData();
        
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/OrderConfirmation'); 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOpp.Id);
        ApexPages.currentPage().getParameters().put('renderAs', 'PDF');
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
        Integer callouts = Limits.getCallouts();
        
        OrderConfirmationController controller = new OrderConfirmationController();
        Test.stopTest();
        
        // Basic assertion to confirm controller instantiation
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
    }
}