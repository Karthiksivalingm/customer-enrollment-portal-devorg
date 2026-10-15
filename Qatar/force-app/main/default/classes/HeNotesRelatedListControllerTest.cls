@isTest
private class HeNotesRelatedListControllerTest {

    @TestSetup
    static void setupData() {
        Event evt = new Event(
            Subject = 'Test Event Subject',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            DurationInMinutes = 60
        );
        insert evt;

        List<HE_Notes__c> notes = new List<HE_Notes__c>();
        for (Integer i = 0; i < 3; i++) {
            notes.add(new HE_Notes__c(
                Event_Id__c = evt.Id,
                HE_Request__c = 'Request ' + i,
                HE_Request_Status__c = 'Done',
                Feedback__c = 'Feedback ' + i
            ));
        }
        insert notes;
    }

    @isTest
    static void testGetNotesByEvent_WithNotes() {
        Event evt = [SELECT Id FROM Event LIMIT 1];

        Test.startTest();
        List<HE_Notes__c> result = HeNotesRelatedListController.getNotesByEvent(evt.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Expected 3 notes for the event');
    }

    @isTest
    static void testGetNotesByEvent_NoNotes() {
        Event evtNoNotes = new Event(
            Subject = 'No Notes Event',
            StartDateTime = System.now().addDays(2),
            EndDateTime = System.now().addDays(2).addHours(1),
            DurationInMinutes = 60
        );
        insert evtNoNotes;

        Test.startTest();
        List<HE_Notes__c> result = HeNotesRelatedListController.getNotesByEvent(evtNoNotes.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Expected no notes for this event');
    }

    @isTest
    static void testGetEventSubject() {
        Event evt = [SELECT Id, Subject FROM Event LIMIT 1];

        Test.startTest();
        Event result = HeNotesRelatedListController.getEventSubject(evt.Id);
        Test.stopTest();

        System.assertEquals(evt.Id, result.Id, 'Event Id should match');
        System.assertEquals('Test Event Subject', result.Subject, 'Subject should match');
    }
}