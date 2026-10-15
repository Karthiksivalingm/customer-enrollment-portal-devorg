@isTest
public class TestLeadCheatsheet {
    static testMethod void testController() {
		Carrier__c dummy_carrier = new Carrier__c();
		dummy_carrier.Name = 'dummy';
		insert dummy_carrier;
		List<Carrier__c> carriers = [SELECT Id FROM Carrier__c WHERE Name = 'dummy'];
        String dummy_carrier_id = carriers[0].Id;
        
        Lead dummy_lead = new Lead();
        dummy_lead.LastName = 'dummy';
        dummy_lead.Company = 'dummy';
        dummy_lead.Carrier__c = dummy_carrier_id;
        insert dummy_lead;
        List<Lead> leads = [SELECT Id FROM Lead WHERE LastName = 'dummy'];
        String dummy_lead_id = leads[0].Id;
        
        Task task = new Task();
        task.Subject = 'Call';
        task.WhoId = dummy_lead_id;
        insert task;
        
        PageReference pageRef = Page.LeadCheatsheet; 
        Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', dummy_lead_id);
		
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Test.stopTest();
        
        LeadCheatsheetController c = new LeadCheatsheetController();
        c.edit();
        c.cancel();
        c.getMarketplaceStats();
        c.getActivityHistories();
        c.getOpenActivities();
        c.getNoteList();
        c.getCampaignHistories();
        c.getCarrier();
        c.getVplclegs();
    }
    
    static testMethod void testMarketplaceStatsMemoization() {
        Carrier__c carrier = new Carrier__c(Name = 'QA-Scenario5-Carrier');
        insert carrier;

        Lead lead = new Lead(LastName = 'QA-Scenario5-Lead', Company = 'QA Co', State = 'FL', Carrier__c = carrier.Id);
        insert lead;

        PageReference pageRef = Page.LeadCheatsheet;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', lead.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        LeadCheatsheetController ctrl = new LeadCheatsheetController();
        Integer calloutsBefore = Limits.getCallouts();
        JsonParseMarketplaceStats first = ctrl.getMarketplaceStats();
        JsonParseMarketplaceStats second = ctrl.getMarketplaceStats();
        Integer calloutsUsed = Limits.getCallouts() - calloutsBefore;
        Test.stopTest();

        System.assertEquals(1, calloutsUsed, 'getMarketplaceStats() should fire exactly one callout across two calls (memoization)');
        System.assertNotEquals(null, first, 'First call should return parsed stats');
        System.assertEquals(38494, first.consumers.premium, 'Parsed stats should reflect the mocked response body');
        System.assertEquals(first, second, 'Second call should return the cached instance, not re-parse a new one');
    }

    static testMethod void testMissingLeadId() {
        Test.setCurrentPage(Page.LeadCheatsheet);
        ApexPages.currentPage().getParameters().remove('id');

        LeadCheatsheetController ctrl = new LeadCheatsheetController();

        System.assertEquals(null, ctrl.lead, 'lead should be null when no id is provided.');
        System.assert(ApexPages.hasMessages(), 'A page message should be added when no id is provided.');
        System.assert(
            ApexPages.getMessages()[0].getSummary().containsIgnoreCase('No Lead Id was provided'),
            'Message should explain the missing id: ' + ApexPages.getMessages()[0].getSummary()
        );

        // Every getter should handle a null lead gracefully instead of throwing.
        System.assertEquals(null, ctrl.getActivityHistories());
        System.assertEquals(null, ctrl.getOpenActivities());
        System.assertEquals(true, ctrl.getNoteList().isEmpty());
        System.assertEquals(true, ctrl.getCampaignHistories().isEmpty());
        System.assertEquals(null, ctrl.getCarrier());
    }

    static testMethod void testInvalidLeadId() {
        Test.setCurrentPage(Page.LeadCheatsheet);
        // Well-formed Lead Id that does not correspond to any real record.
        ApexPages.currentPage().getParameters().put('id', '00Q000000000000AAA');

        LeadCheatsheetController ctrl = new LeadCheatsheetController();

        System.assertEquals(null, ctrl.lead, 'lead should be null when the id does not match any record.');
        System.assert(ApexPages.hasMessages(), 'A page message should be added when the Lead cannot be loaded.');
        System.assert(
            ApexPages.getMessages()[0].getSummary().containsIgnoreCase('Unable to load'),
            'Message should explain the load failure: ' + ApexPages.getMessages()[0].getSummary()
        );
    }

    static testMethod void testCarrierNullGuard() {
        Lead noCarrierLead = new Lead(LastName = 'QA-NoCarrier-Lead', Company = 'QA Co');
        insert noCarrierLead;

        Test.setCurrentPage(Page.LeadCheatsheet);
        ApexPages.currentPage().getParameters().put('id', noCarrierLead.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        LeadCheatsheetController ctrl = new LeadCheatsheetController();
        System.assertEquals(null, ctrl.getCarrier(), 'getCarrier() should return null when the Lead has no Carrier__c set.');
    }

    static testMethod void testJsonPareMarketplaceStats() {
        String raw_body = '{"consumers": {"premium": 38494, "standard": 17005, "preferred": 27167, "non_standard": 2927}, "share_rate": 1.36, "unsold_leads": 27048, "unsold_consumers": {"premium": 10824, "standard": 5566, "preferred": 9827, "non_standard": 825}}';
        JsonParseMarketplaceStats p = JsonParseMarketplaceStats.parse(raw_body);
        Integer a = p.consumers.premium;
        a = p.consumers.preferred;
        a = p.unsold_consumers.standard;
        a = p.unsold_consumers.non_standard;
        a = p.unsold_leads;
        Double d = p.share_rate;
    }
    
    static testMethod void testWrapperContactTenure() {
        Account a = new Account();
        a.Wizard_Complete_Date__c = datetime.newInstance(2015, 10, 10, 0, 0, 0);
		Contact c = new Contact();
		WrapperContactTenure w = new WrapperContactTenure(c, a);
    }
}