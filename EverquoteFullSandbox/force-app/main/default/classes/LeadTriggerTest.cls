@isTest
public class LeadTriggerTest {
	@isTest
    static void testCheckLeadScore() {
        Lead testLead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company',
            Status = 'Lost Reason',
            Lost_Reason__c = 'Recycled',
            Unqualified_Reason__c = 'Consumer',
            LeadSource = 'Web Scrape'
        );
        
        Test.starttest();
        insert testLead1;
        
        List<Lead> updatedLeads = [SELECT Id, mkto71_Lead_Score__c FROM Lead WHERE Id =: testLead1.Id];

        //System.assertEquals(90, updatedLeads[0].mkto71_Lead_Score__c, 'Lead score should be set to 90 for Web Scrape leads');
        Test.stopTest();
    }
    
    @isTest
    static void updateCheckLeadScore() {
        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company',
            Status = 'Lost Reason',
            Lost_Reason__c = 'Recycled',
            Unqualified_Reason__c = 'Consumer',
            LeadSource = 'Other Source'
        );
        insert testLead2;

        testLead2.LeadSource = 'Web Scrape';
        Test.starttest();
        update testLead2;
        Test.stoptest();
    }
}