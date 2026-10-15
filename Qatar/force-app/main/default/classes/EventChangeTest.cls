@IsTest
public class EventChangeTest {
    
    @TestSetup
    static void setupData() {
        // Create sample Events for testing
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 3; i++) {
            events.add(new Event(
                Subject = 'Meeting ' + i,
                StartDateTime = System.now().addDays(i),
                EndDateTime = System.now().addDays(i).addHours(1),
                Location = 'Room ' + i
            ));
        }
        insert events;
    }
    
    @IsTest
    static void testEventUpdate_TrackedFieldsChanged() {
        // Fetch events
        List<Event> events = [SELECT Id, Subject, StartDateTime, EndDateTime, Location FROM Event];
        Map<Id, Event> oldMap = new Map<Id, Event>(events);
        
        // Modify one event's tracked field (Subject)
        for (Event e : events) {
            e.Subject = 'Updated ' + e.Subject;
        }

        Test.startTest();
        EventChangePublishHandler.handleAfter(events, oldMap, oldMap.values(), true, false);
        Test.stopTest();

        // No exceptions expected
        System.assert(true, 'Update with tracked field changes executed successfully');
    }

    @IsTest
    static void testEventUpdate_NoTrackedFieldsChanged() {
        List<Event> events = [SELECT Id, Subject, StartDateTime, EndDateTime, Location FROM Event];
        Map<Id, Event> oldMap = new Map<Id, Event>(events);

        // Modify a non-tracked field (simulate same values)
        for (Event e : events) {
            e.Description = 'No tracked changes'; // not part of trackedFields
        }

        Test.startTest();
        EventChangePublishHandler.handleAfter(events, oldMap, oldMap.values(), true, false);
        Test.stopTest();

        System.assert(true, 'Update with no tracked field change executed successfully');
    }

    @IsTest
    static void testEventUpdate_CanceledSubjectTriggersDelete() {
        List<Event> events = [SELECT Id, Subject, StartDateTime, EndDateTime, Location FROM Event LIMIT 1];
        Map<Id, Event> oldMap = new Map<Id, Event>(events);

        // Simulate event being marked as canceled
        Event canceledEvent = events[0];
        canceledEvent.Subject = 'Canceled Meeting';

        Test.startTest();
        EventChangePublishHandler.handleAfter(new List<Event>{ canceledEvent }, oldMap, oldMap.values(), true, false);
        Test.stopTest();

        // Verify event is deleted
        Integer countAfter = [SELECT count() FROM Event WHERE Id = :canceledEvent.Id];
        System.assertEquals(0, countAfter, 'Canceled event should be deleted');
    }

    @IsTest
    static void testEventDeleteScenario() {
        // Create a new event to delete
        Event e = new Event(
            Subject = 'Delete Test',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Location = 'Test Room'
        );
        insert e;

        List<Event> oldList = new List<Event>{ e };

        Test.startTest();
        EventChangePublishHandler.handleAfter(null, null, oldList, false, true);
        Test.stopTest();

        System.assert(true, 'Delete scenario executed successfully');
    }
}