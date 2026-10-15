@isTest
public class TestOpportunityCheatsheet {

    // The Opportunity_PriceBookMatch validation rule requires Agency/Accelerated/CS_Upsell
    // Opportunities (created after 2026-04-15) to carry a matching, specific Price Book. The
    // "Cross_Sell" Record Type is not covered by that rule at all, so test Opportunities use it
    // to avoid needing to set up a Pricebook2Id just to satisfy an unrelated business rule.
    private static Id getSafeOpportunityRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Opportunity' AND IsActive = true AND DeveloperName = 'Cross_Sell'
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

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
        dummy_opportunity.RecordTypeId = getSafeOpportunityRecordTypeId();
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

    static testMethod void testMissingOpportunityId() {
        Test.setCurrentPage(Page.OpportunityCheatsheet);
        ApexPages.currentPage().getParameters().remove('id');

        OpportunityCheatsheetController ctrl = new OpportunityCheatsheetController();

        System.assertEquals(null, ctrl.opportunity, 'opportunity should be null when no id is provided.');
        System.assert(ApexPages.hasMessages(), 'A page message should be added when no id is provided.');
        System.assert(
            ApexPages.getMessages()[0].getSummary().containsIgnoreCase('No Opportunity Id was provided'),
            'Message should explain the missing id: ' + ApexPages.getMessages()[0].getSummary()
        );

        // Every getter should handle a null opportunity gracefully instead of throwing.
        System.assertEquals(null, ctrl.getActivityHistories());
        System.assertEquals(null, ctrl.getOpenActivities());
        System.assertEquals(null, ctrl.getOpportunityStageHistories());
        System.assertEquals(true, ctrl.getNoteList().isEmpty());
        System.assertEquals(null, ctrl.getCarrier());
        System.assertEquals(true, ctrl.getRelatedContactList().isEmpty());
        System.assertEquals(true, ctrl.getCampaignHistories().isEmpty());
    }

    static testMethod void testInvalidOpportunityId() {
        Test.setCurrentPage(Page.OpportunityCheatsheet);
        // Well-formed Opportunity Id that does not correspond to any real record.
        ApexPages.currentPage().getParameters().put('id', '006000000000000AAA');

        OpportunityCheatsheetController ctrl = new OpportunityCheatsheetController();

        System.assertEquals(null, ctrl.opportunity, 'opportunity should be null when the id does not match any record.');
        System.assert(ApexPages.hasMessages(), 'A page message should be added when the Opportunity cannot be loaded.');
        System.assert(
            ApexPages.getMessages()[0].getSummary().containsIgnoreCase('Unable to load'),
            'Message should explain the load failure: ' + ApexPages.getMessages()[0].getSummary()
        );
    }

    static testMethod void testNoAccount() {
        Opportunity noAccountOpp = new Opportunity(
            Name = 'QA-NoAccount-Opp',
            RecordTypeId = getSafeOpportunityRecordTypeId(),
            StageName = 'Open',
            CloseDate = Date.today().addDays(30)
        );
        insert noAccountOpp;

        Test.setCurrentPage(Page.OpportunityCheatsheet);
        ApexPages.currentPage().getParameters().put('id', noAccountOpp.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        OpportunityCheatsheetController ctrl = new OpportunityCheatsheetController();

        System.assertNotEquals(null, ctrl.opportunity, 'opportunity should still load even with no Account.');
        System.assertNotEquals(null, ctrl.account, 'account should be a placeholder object, not null, when there is no related Account.');
        System.assertEquals(null, ctrl.account.Id, 'account placeholder should have no Id.');
        System.assertEquals(null, ctrl.getCarrier(), 'getCarrier() should return null when there is no Account.');
        System.assertEquals(null, ctrl.getMarketplaceStats(), 'getMarketplaceStats() should not throw when there is no Account/BillingState.');

        // save() must not attempt DML on the placeholder Account (which has no Id).
        ctrl.save();
        System.assert(!ApexPages.hasMessages(), 'save() should succeed even with no Account/Contact linked: ' +
            (ApexPages.hasMessages() ? ApexPages.getMessages()[0].getSummary() : ''));
    }

    static testMethod void testNoContactRole() {
        Carrier__c carrier = new Carrier__c(Name = 'QA-NoRole-Carrier');
        insert carrier;

        Account acct = new Account(Name = 'QA-NoRole-Account', Carrier__c = carrier.Id);
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'QA-NoRole-Opp',
            AccountId = acct.Id,
            RecordTypeId = getSafeOpportunityRecordTypeId(),
            StageName = 'Open',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.setCurrentPage(Page.OpportunityCheatsheet);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        OpportunityCheatsheetController ctrl = new OpportunityCheatsheetController();

        System.assertNotEquals(null, ctrl.contact, 'contact should be a placeholder object, not null, when there is no related Contact Role.');
        System.assertEquals(null, ctrl.contact.Id, 'contact placeholder should have no Id.');
        System.assertNotEquals(null, ctrl.getCarrier(), 'getCarrier() should still resolve via the Account even with no Contact Role.');

        // save() must not attempt DML on the placeholder Contact (which has no Id).
        ctrl.save();
        System.assert(!ApexPages.hasMessages(), 'save() should succeed even with no Contact Role: ' +
            (ApexPages.hasMessages() ? ApexPages.getMessages()[0].getSummary() : ''));
    }
}