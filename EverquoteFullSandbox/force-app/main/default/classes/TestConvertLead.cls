@isTest
public class TestConvertLead {
    static testMethod void test(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Carrier__c dummy_carrier = new Carrier__c();
        dummy_carrier.Name = 'dummy';
        insert dummy_carrier;
        
        List<Carrier__c> carriers = [SELECT Id FROM Carrier__c WHERE Name = 'dummy'];
        String dummy_carrier_id = carriers[0].Id;
        
        Lead dummy_lead = new Lead();
        dummy_lead.LastName = 'dummy';
        dummy_lead.Company = 'dummy';
        dummy_lead.LeadSource = 'Referral';
        dummy_lead.Carrier__c = dummy_carrier_id;
        insert dummy_lead;
        
        List<Lead> leads = [SELECT Id FROM Lead WHERE LastName = 'dummy'];
        String dummy_lead_id = leads[0].Id;
               
        Event dummy_event = new Event();
        dummy_event.Subject = 'Initial Meeting';
        dummy_event.Meeting_Result__c = 'Held - Correct Contact';
        dummy_event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        dummy_event.DurationInMinutes = 60;
        dummy_event.WhoId = dummy_lead_id;
        insert dummy_event;
    }
}