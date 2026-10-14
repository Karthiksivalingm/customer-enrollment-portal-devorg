@isTest
public class TESTOrderConfirmationSend {

    private class RestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account testAcc = new Account(Name = 'Test');
        insert testAcc;

        Contact testRec = new Contact(
            LastName = 'Chen',
            Email = 'dchen@teamvelocitymarketing.com',
            AccountId = testAcc.Id
        );
        insert testRec;

        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'Test',
            StageName = 'Committed',
            CloseDate = Date.newInstance(1988, 6, 18),
            Order_Confirmation_Subject_Line__c = 'TestSL',
            Dealer_DocuSign_Contact__c = testRec.Id
        );
        insert testOpp;

        // Product with addendum language, so getHasAddendum() checks the line items
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, Addendum_Language__c = 'Test addendum');
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        insert new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
    }

    private static Opportunity getOpp() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    // sendpdf() takes a List<FlowInput> (it is an invocable method called from a Flow)
    private static OrderConfirmationSend.FlowInput buildInput(Id oppId, Boolean isPreview) {
        OrderConfirmationSend.FlowInput input = new OrderConfirmationSend.FlowInput();
        input.oppId = oppId;
        input.emailBody = '<p>Test body</p>';
        input.subject = 'Test Subject';
        input.toAddresses = 'to1@example.com, to2@example.com';
        input.ccAddresses = 'cc@example.com';
        input.bccAddresses = ' [bcc@example.com] ';
        input.isPreview = isPreview;
        return input;
    }

    // Send mode: builds the PDF attachment and sends the email
    @isTest
    static void testSendEmail() {
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Opportunity opp = getOpp();

        Test.startTest();
            List<OrderConfirmationSend.FlowOutput> results =
                OrderConfirmationSend.sendpdf(new List<OrderConfirmationSend.FlowInput>{ buildInput(opp.Id, false) });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One result expected');
        System.assertEquals(null, results[0].contentDocumentId, 'Send mode should not create a preview file');

        Opportunity updated = [SELECT debug__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(updated.debug__c != null && updated.debug__c.contains('Parsed To'),
            'Debug log should be written to the Opportunity');
    }

    // Preview mode: saves the PDF as a File on the Opportunity instead of sending
    @isTest
    static void testPreviewMode() {
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Opportunity opp = getOpp();

        Test.startTest();
            List<OrderConfirmationSend.FlowOutput> results =
                OrderConfirmationSend.sendpdf(new List<OrderConfirmationSend.FlowInput>{ buildInput(opp.Id, true) });
        Test.stopTest();

        System.assertNotEquals(null, results[0].contentDocumentId, 'Preview mode should return the generated file');

        Opportunity updated = [SELECT debug__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(updated.debug__c.contains('PREVIEW MODE'), 'Debug log should show preview mode');
    }

    // Visualforce controller: Id present, line item has addendum language
    @isTest
    static void testControllerWithLineItemAddendum() {
        Opportunity opp = getOpp();
        Test.setCurrentPage(Page.OrderConfirmationPDF);
        ApexPages.currentPage().getParameters().put('Id', opp.Id);

        Test.startTest();
            OrderConfirmationSend ctrl = new OrderConfirmationSend();
        Test.stopTest();

        System.assertEquals(false, ctrl.isError, 'Controller should load the Opportunity');

        // Analytics_Franchise__c is a formula (not writeable), so check against whatever value it calculated
        String franchise = [SELECT Analytics_Franchise__c FROM Opportunity WHERE Id = :opp.Id].Analytics_Franchise__c;
        Set<String> gmFranchises = new Set<String>{'BUICK', 'BUICK GMC', 'CADILLAC', 'CHEVROLET', 'GM', 'GMC'};
        Boolean expectedShowCode = String.isNotBlank(franchise) && gmFranchises.contains(franchise.toUpperCase());
        System.assertEquals(expectedShowCode, ctrl.showOemDealerCode, 'OEM Dealer Code visibility should follow the franchise');
        System.assertEquals('pdf', ctrl.isPDF);
        System.assertEquals(true, ctrl.getHasAddendum(), 'Line item addendum language should count as an addendum');
    }

    // Visualforce controller: special notes on the Opportunity
    @isTest
    static void testControllerWithSpecialNotes() {
        Opportunity opp = getOpp();
        Test.setCurrentPage(Page.OrderConfirmationPDF);
        ApexPages.currentPage().getParameters().put('Id', opp.Id);

        OrderConfirmationSend ctrl = new OrderConfirmationSend();
        ctrl.specialNotes = 'Some special notes';
        System.assertEquals(true, ctrl.getHasAddendum(), 'Special notes should count as an addendum');

        // No notes and no line items -> no addendum
        ctrl.specialNotes = null;
        ctrl.lineItems = new List<OpportunityLineItem>();
        System.assertEquals(false, ctrl.getHasAddendum(), 'No notes and no line items should mean no addendum');
    }

    // Visualforce controller: no Id on the page
    @isTest
    static void testControllerWithoutId() {
        Test.setCurrentPage(Page.OrderConfirmationPDF);

        OrderConfirmationSend ctrl = new OrderConfirmationSend();

        System.assertEquals(true, ctrl.isError, 'Missing Id should set isError');
    }
}