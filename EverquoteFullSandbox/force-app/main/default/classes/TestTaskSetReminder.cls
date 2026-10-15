/*
 * Test case for trigger TaskSetReminder
 */
@isTest
public class TestTaskSetReminder {
	static testMethod void addNewTask(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Task task = new Task();
        task.Subject = 'Call';
        insert task;
        task.ReminderDateTime = datetime.newInstance(2015, 11, 11, 0, 0, 0);
        update task;
    }
    
    static testMethod void addNewEvent(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Event event = new Event();
        event.Subject = 'Follow Up';
        event.DurationInMinutes = 60;
        event.ActivityDateTime = datetime.newInstance(2015, 10, 10, 0, 0, 0);
        insert event;
        event.Subject = 'Onsite Visit';
        update event;
    }
}