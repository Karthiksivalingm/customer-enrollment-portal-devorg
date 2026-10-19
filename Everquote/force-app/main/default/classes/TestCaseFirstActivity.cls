/*
 * Test case for trigger EventCaseFirstActivity and TaskCaseFirstActivity
 */
@isTest
public class TestCaseFirstActivity {
	static testMethod void addNewTaskNoCase(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create a task not associated with any case
        Task task = new Task();
        task.Subject = 'Call';
        insert task;
    } 
    
    static testMethod void addNewEventNoCase(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create an event not associated with any case
        Event event = new Event();
        event.Subject = 'Follow Up';
        event.DurationInMinutes = 60;
        event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert event;
    }
   
    static testMethod void addNewTaskAndEventToCase(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create an event then a task then an event associated with a case
        Case dummy_case = new Case();
        insert dummy_case;
        List<Case> cases = [SELECT Id FROM Case];
        String dummy_case_id = cases[0].Id;
        
        Event event = new Event();
        event.WhatId = dummy_case_id;
        event.Subject = 'Follow Up';
        event.DurationInMinutes = 60;
        event.CreatedDate = datetime.newInstance(2014, 10, 10, 0, 0, 0);
        event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert event;
        
        Task task = new Task();
        task.Subject = 'Call';
        task.WhatId = dummy_case_id;
        task.CreatedDate = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert task;
        
        Event event2 = new Event();
        event2.WhatId = dummy_case_id;
        event2.Subject = 'Follow Up';
        event2.DurationInMinutes = 60;
        event2.CreatedDate = datetime.newInstance(2014, 10, 10, 0, 0, 0);
        event2.ActivityDateTime = datetime.newInstance(2016, 10, 10, 0, 0, 0);
        insert event2;
    }
}