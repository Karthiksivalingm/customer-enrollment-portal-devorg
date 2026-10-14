// Apex test class for OrderConfirmationBtnController from FND
@isTest
public class OrderConfirmationBtnControllerTest {

    private static String uniqueSuffix() {
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        return String.valueOf(rnd);
    }

    // Helper method to create test data
    static Opportunity createTestData() {
        String suf = uniqueSuffix();

        // Create Account with dummy Regional Manager and Technician
        User regionalManager = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        User technician = [SELECT Id, Email FROM User WHERE IsActive = true AND Id != :regionalManager.Id LIMIT 1];

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

        // Create Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Title__c = 'Manager',
            AccountId = acc.Id,
            Contact_Role__c = 'Foundation Contract Signer'
        );
        insert con;

        // Assign "Contract Signer" role
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE ContactId = :con.Id LIMIT 1];
        acr.Roles = 'Contract Signer';
        update acr;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = acc.Name,
            AccountId = acc.Id,
            StageName = 'Prospect',
            CloseDate = Date.today(),
            Target_Launch_Month__c = 'March'
        );
        insert opp;

        // Create Product
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

    // Existing test method
    @isTest
    static void testSavePDF() {
        Opportunity testOpp = createTestData();

        Test.startTest();
        PageReference pageRef = Page.OrderConfirmationPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOpp.Id);
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

        ApexPages.StandardController stdController = new ApexPages.StandardController(testOpp);
        OrderConfirmationBtnController controller = new OrderConfirmationBtnController(stdController);

        PageReference result = controller.savePDF();
        Test.stopTest();
    }

    // Additional test method to cover remaining 4%
    @isTest
    static void testFromEmailBranch() {
        Test.startTest();

        // Create test Opportunity
        Opportunity testOpp = createTestData();

        // Add a second Product and OpportunityLineItem to cover for-loop concatenation
        Product2 prod2 = new Product2(
            Name = 'Test Product 2',
            MRR__c = 60,
            Addendum_Language__c = 'Test Addendum 2',
            IsActive = true
        );
        insert prod2;

        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe2;

        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe2.Id,
            Product2Id = prod2.Id,
            MRR__c = 60,
            Quantity = 1,
            UnitPrice = 200
        );
        insert oli2;

        // Set page parameters
        Test.setCurrentPageReference(Page.OrderConfirmationPDF);
        ApexPages.currentPage().getParameters().put('id', testOpp.Id);
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

        // Instantiate controller and call savePDF
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOpp);
        OrderConfirmationBtnController controller = new OrderConfirmationBtnController(stdController);

        // Call savePDF to cover the "fromEmail != ''" branch and else block safely
        PageReference result = controller.savePDF();

        Test.stopTest();
    }
}