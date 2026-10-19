@isTest
public class TestOpportunityCheatsheet {
    static testMethod void testController() {
        Carrier__c dummy_carrier = new Carrier__c();
        dummy_carrier.Name = 'dummy_carrier';
        insert dummy_carrier;
        List<Carrier__c> carriers = [SELECT Id FROM Carrier__c WHERE Name = 'dummy_carrier'];
        String dummy_carrier_id = carriers[0].Id;
        
        Account dummy_account = new Account();
        dummy_account.Carrier__c = dummy_carrier_id;
        dummy_account.Name = 'dummy_account';
        insert dummy_account;
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'dummy_account'];
        String dummy_account_id = accounts[0].Id;
                  
        Opportunity dummy_opportunity = new Opportunity();
        dummy_opportunity.Name = 'dummy_opportunity';
        dummy_opportunity.AccountId = dummy_account_id;
        dummy_opportunity.LeadSource = 'Outbound Call';
        dummy_opportunity.StageName = 'Open';
        dummy_opportunity.CloseDate = Date.newInstance(2010, 1, 1);
        insert dummy_opportunity;
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
        String dummy_opportunity_id = opportunities[0].Id;
        
        Contact dummy_contact = new Contact();
        dummy_contact.LastName = 'dummy_contact';
        dummy_contact.phone = '+12345678900';
        insert dummy_contact;
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Name='dummy_contact'];
        String dummy_contact_id = contacts[0].Id;
        
        OpportunityContactRole dummy_role = new OpportunityContactRole();
        dummy_role.OpportunityId = dummy_opportunity_id;
        dummy_role.ContactId = dummy_contact_id;
        insert dummy_role;
        
        Task task = new Task();
        task.Subject = 'Call';
        task.WhoId = dummy_contact_id;
        task.WhatId = dummy_opportunity_id;
        insert task;
        
        PageReference pageRef = Page.OpportunityCheatsheet; 
        Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id', dummy_opportunity_id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		
        OpportunityCheatsheetController o = new OpportunityCheatsheetController();
        o.edit();
        o.cancel();
        o.getMarketplaceStats();
        o.getActivityHistories();
        o.getOpenActivities();
        o.getNoteList();
        o.getCampaignHistories();
        o.getCarrier();
        o.getVplclegs();
        o.getOpportunityStageHistories();
        o.getRelatedContactList();
        Test.stopTest();
    }
	
}