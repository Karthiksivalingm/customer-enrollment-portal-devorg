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