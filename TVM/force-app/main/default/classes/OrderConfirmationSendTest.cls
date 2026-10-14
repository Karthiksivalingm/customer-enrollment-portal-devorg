@isTest
private class OrderConfirmationSendTest {

    private static void setupLineItems(Id oppId, Boolean withAddendum) {
        Product2 prod = new Product2(
            Name = 'Test Product', 
            Addendum_Language__c = withAddendum ? 'Test Addendum Language' : '',
            IsActive = true
        );
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 1000.00, 
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppId,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 1000.00,
            MRR__c = 1000.00
            // Removed Contract_Product_Name__c as it is a non-writable formula field
        );
        insert oli;
    }

    @isTest
    static void testConstructorAndEdgeCases() {
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id
        );
        insert testOpp;
        setupLineItems(testOpp.Id, true);

        PageReference pageRef = Page.OrderConfirmationPDF; 
        Test.setCurrentPage(pageRef);
        
        // Path 1: Valid ID
        ApexPages.currentPage().getParameters().put('Id', testOpp.Id);
        OrderConfirmationSend controller = new OrderConfirmationSend();
        System.assertEquals(false, controller.isError);
        System.assertEquals('pdf', controller.isPDF);

        // Path 2: Blank ID to cover the error return block
        ApexPages.currentPage().getParameters().put('Id', '');
        OrderConfirmationSend errorController = new OrderConfirmationSend();
        System.assertEquals(true, errorController.isError);
    }

    @isTest
    static void testAddendumLogic() {
        Account testAcc = new Account(Name = 'Test Addendum Acc');
        insert testAcc;
        Opportunity opp = new Opportunity(Name = 'Test Addendum Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAcc.Id);
        insert opp;

        ApexPages.currentPage().getParameters().put('Id', opp.Id);
        OrderConfirmationSend controller = new OrderConfirmationSend();
        
        // Scenario A: Blank
        System.assertEquals(false, controller.getHasAddendum());

        // Scenario B: Special Notes populated via Addendum field
        opp.Addendum__c = 'Special Notes';
        update opp;
        
        // Re-instantiate to trigger the constructor query again
        OrderConfirmationSend controllerWithNotes = new OrderConfirmationSend();
        System.assertEquals(true, controllerWithNotes.getHasAddendum());
        
        // Scenario C: Line Item Addendum populated
        opp.Addendum__c = null;
        update opp;
        
        setupLineItems(opp.Id, true);
        
        OrderConfirmationSend controllerWithLineItem = new OrderConfirmationSend();
        System.assertEquals(true, controllerWithLineItem.getHasAddendum());
    }

    @isTest
    static void testSendPdfAndEmailParsing() {
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Opportunity standardOpp = new Opportunity(Name = 'Standard Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAcc.Id);
        insert standardOpp;

        OrderConfirmationSend.FlowInput input = new OrderConfirmationSend.FlowInput();
        input.oppId = standardOpp.Id;
        input.emailBody = 'Test Body';
        input.subject = 'Test Subject';
        // Updated test string to use commas, as parseEmailAddresses splits by comma
        input.toAddresses = ' test1@tvm.com, (test2@tvm.com), [test3@tvm.com] '; 
        input.ccAddresses = 'testcc@tvm.com'; 

        Test.startTest();
        OrderConfirmationSend.sendpdf(new List<OrderConfirmationSend.FlowInput>{input});
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, debug__c FROM Opportunity WHERE Id = :standardOpp.Id];
        System.assert(updatedOpp.debug__c.contains('--- PDF GENERATION TELEMETRY ---'));
    }
    
    @isTest
    static void testPreviewMode() {
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Opportunity standardOpp = new Opportunity(Name = 'Standard Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = testAcc.Id);
        insert standardOpp;

        OrderConfirmationSend.FlowInput input = new OrderConfirmationSend.FlowInput();
        input.oppId = standardOpp.Id;
        input.emailBody = 'Test Body';
        input.subject = 'Test Subject';
        input.toAddresses = 'test1@tvm.com';
        input.isPreview = true; // Trigger the preview logic block

        Test.startTest();
        List<OrderConfirmationSend.FlowOutput> results = OrderConfirmationSend.sendpdf(new List<OrderConfirmationSend.FlowInput>{input});
        Test.stopTest();

        // Verify the output and that a ContentVersion was generated
        System.assertEquals(1, results.size(), 'Should return one FlowOutput record');
        System.assertNotEquals(null, results[0].contentDocumentId, 'ContentDocumentId should be populated in Preview mode');
    }
}