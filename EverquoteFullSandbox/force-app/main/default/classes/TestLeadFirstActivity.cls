/*
 * Test case for trigger EventLeadFirstActivity and TaskLeadFirstActivity
 */
@isTest
public class TestLeadFirstActivity {
	static testMethod void addNewTaskNoLead(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create a task not associated with any lead
        Task task = new Task();
        task.Subject = 'Call';
        insert task;
    } 
    
    static testMethod void addNewEventNoLead(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create an event not associated with any lead
        Event event = new Event();
        event.Subject = 'Follow Up';
        event.DurationInMinutes = 60;
        event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert event;
    }
   
    static testMethod void addNewTaskAndEventToCase(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create an event then a task then an event associated with a case
        Lead dummy_lead = new Lead();
        dummy_lead.LastName = 'dummy';
        dummy_lead.Company = 'dummy';
        dummy_lead.CreatedDate = datetime.newInstance(2014, 1, 1, 0, 0, 0);
        insert dummy_lead;
        List<Lead> leads = [SELECT Id FROM Lead];
        String dummy_lead_id = leads[0].Id;
        
        Event event = new Event();
        event.WhoId = dummy_lead_id;
        event.Subject = 'Follow Up';
        event.DurationInMinutes = 60;
        event.CreatedDate = datetime.newInstance(2014, 10, 10, 0, 0, 0);
        event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert event;
        
        Task task = new Task();
        task.Subject = 'Call';
        task.WhoId = dummy_lead_id;
        task.CreatedDate = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert task;
        
        Event event2 = new Event();
        event2.WhoId = dummy_lead_id;
        event2.Subject = 'Follow Up';
        event2.DurationInMinutes = 60;
        event2.CreatedDate = datetime.newInstance(2014, 10, 10, 0, 0, 0);
        event2.ActivityDateTime = datetime.newInstance(2016, 10, 10, 0, 0, 0);
        insert event2;
    }
}