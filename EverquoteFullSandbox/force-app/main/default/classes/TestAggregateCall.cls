@isTest
public class TestAggregateCall {
    static testMethod void test(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead dummy_lead = new Lead();
        dummy_lead.LastName = 'dummy';
        dummy_lead.Company = 'dummy';
        insert dummy_lead;
        
        List<Lead> leads = [SELECT Id FROM Lead WHERE LastName = 'dummy'];
        String dummy_lead_id = leads[0].Id;
        
        Task first_task = new Task();
        first_task.CallType = 'Inbound';
        first_task.CallDurationInSeconds = 1;
        first_task.WhoId = dummy_lead_id;
        first_task.Subject = 'Call';
        first_task.ActivityDate = date.newInstance(2015, 11, 11);
        insert first_task;
        
        Task second_task = new Task();
        second_task.CallType = 'Inbound';
        second_task.CallDurationInSeconds = 1;
        second_task.WhoId = dummy_lead_id;
        second_task.Subject = 'Follow Up';
        second_task.CallDisposition = 'Spoke to Decision Maker';
        second_task.ActivityDate = date.newInstance(2015, 12, 12);
        insert second_task;
        
        Task third_task = new Task();
        third_task.CallType = 'Inbound';
        third_task.CallDurationInSeconds = 1;
        third_task.WhoId = dummy_lead_id;
        third_task.Subject = 'Follow Up';
        third_task.CallDisposition = 'Spoke to Decision Maker';
        third_task.ActivityDate = date.newInstance(2016, 12, 12);
        insert third_task;
        
        Event dummy_event = new Event();
        dummy_event.Subject = 'Follow Up';
        dummy_event.ActivityDateTime = datetime.newInstance(2020, 10, 10, 0, 0, 0);
        dummy_event.DurationInMinutes = 60;
        dummy_event.WhoId = dummy_lead_id;
        insert dummy_event;

        delete first_task;
        delete second_task;
        
        dummy_event.DurationInMinutes = 120;
        update dummy_event;
        delete dummy_event;
    }
}