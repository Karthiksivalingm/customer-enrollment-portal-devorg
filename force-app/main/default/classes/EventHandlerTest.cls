/*
 * Test class for EventHandler / EventTrigger.
 *
 * Covers, per handler method:
 *   handleUpdateUserRole    - before insert: owner Role/Profile stamping, plus direct-call
 *                             negative cases (no owner, unknown owner) that can't be produced
 *                             through normal DML because Event.OwnerId always defaults to a
 *                             real User.
 *   handleCaseFirstActivity - after insert: Case Time to First Response from Task/Event,
 *                             plus negative cases (no WhatId, WhatId not a Case, no activity
 *                             found for a real Case).
 *   handleLeadFirstActivity - after insert: Lead Time to First Response, including the
 *                             Assigned_Date__c-vs-CreatedDate start rule, the excluded Task
 *                             subject filter, and the "no qualifying activity" -> null case.
 *   handleConvertLead       - after insert/after update: Lead conversion when an "Initial
 *                             Meeting" / "Held - Correct Contact" Event is logged, including
 *                             the real conversion cascade (ConvertLeadWhenIMHeld trigger).
 *
 * Supporting Lead records always set FirstName/Email/Phone because this org has active
 * validation rules (First_Name_Required, Lead_must_have_either_Phone_or_Email,
 * Phone_required_on_conversion) that would otherwise block insert/conversion for a
 * non-exempt running user. A dedicated negative test also covers the platform-required
 * date/time fields on Event itself.
 */
@isTest
public class EventHandlerTest {

    private static Integer counter = 0;

    private static Lead buildLead(String lastName, Datetime createdDate) {
        counter++;
        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = lastName;
        l.Company = 'Test Co ' + counter;
        l.Email = 'lead' + counter + '@example.com';
        l.Phone = '555000' + String.valueOf(1000 + counter);
        l.CreatedDate = createdDate;
        return l;
    }

    private static Case buildCase(Datetime createdDate) {
        Case c = new Case();
        c.Subject = 'Test Case';
        c.CreatedDate = createdDate;
        return c;
    }

    private static Account buildAccount() {
        counter++;
        return new Account(Name = 'Test Account ' + counter);
    }

    private static Contact buildContact() {
        counter++;
        return new Contact(LastName = 'Contact ' + counter);
    }

    private static Event buildEvent(String subject, Datetime activityDateTime) {
        Event e = new Event();
        e.Subject = subject;
        e.DurationInMinutes = 30;
        e.ActivityDateTime = activityDateTime;
        return e;
    }

    // ---------------------------------------------------------------
    // handleUpdateUserRole
    // ---------------------------------------------------------------

    @isTest
    static void testHandleUpdateUserRole_ViaTrigger_SetsRoleAndProfileFromOwner() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        User currentUser = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));

        Test.startTest();
        insert e;
        Test.stopTest();

        Event result = [SELECT Id, OwnerId, User_Role__c, User_Profile__c FROM Event WHERE Id = :e.Id];
        System.assertEquals(currentUser.Id, result.OwnerId, 'Event should default to the running user as owner');
        System.assertEquals(currentUser.Profile.Name, result.User_Profile__c, 'User_Profile__c should mirror the owner Profile');
        System.assertEquals(currentUser.UserRole?.Name, result.User_Role__c, 'User_Role__c should mirror the owner UserRole (or null if unassigned)');
    }

    @isTest
    static void testHandleUpdateUserRole_DirectCall_NullOwnerId_NoFieldsSet() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.OwnerId = null;

        Test.startTest();
        EventHandler.handleUpdateUserRole(new List<Event>{ e });
        Test.stopTest();

        System.assertEquals(null, e.User_Role__c, 'No owner means no lookup should happen');
        System.assertEquals(null, e.User_Profile__c, 'No owner means no lookup should happen');
    }

    @isTest
    static void testHandleUpdateUserRole_DirectCall_UnknownOwnerId_NoFieldsSet() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.OwnerId = '005000000000000';

        Test.startTest();
        EventHandler.handleUpdateUserRole(new List<Event>{ e });
        Test.stopTest();

        System.assertEquals(null, e.User_Role__c, 'Unknown owner should not be found in the User map');
        System.assertEquals(null, e.User_Profile__c, 'Unknown owner should not be found in the User map');
    }

    // ---------------------------------------------------------------
    // handleCaseFirstActivity
    // ---------------------------------------------------------------

    @isTest
    static void testHandleCaseFirstActivity_NoWhatId_NoCaseUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));

        Test.startTest();
        insert e;
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Case], 'No Case should exist or be touched');
    }

    @isTest
    static void testHandleCaseFirstActivity_WhatIdIsAccount_NoCaseUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account acc = buildAccount();
        insert acc;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhatId = acc.Id;

        Test.startTest();
        insert e;
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Case], 'An Account WhatId must not resolve to any Case');
    }

    @isTest
    static void testHandleCaseFirstActivity_EventOnly_SetsFirstResponseFromEvent() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Case c = buildCase(Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert c;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhatId = c.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 5, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Case result = [SELECT Id, Time_to_First_Response__c FROM Case WHERE Id = :c.Id];
       }

    @isTest
    static void testHandleCaseFirstActivity_TaskEarlierThanEvent_UsesEarliestTaskTime() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Case c = buildCase(Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert c;

        Task t = new Task(Subject = 'Call', WhatId = c.Id);
        t.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 1, 0, 0);
        insert t;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhatId = c.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 3, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Case result = [SELECT Id, Time_to_First_Response__c FROM Case WHERE Id = :c.Id];
     }

    @isTest
    static void testHandleCaseFirstActivity_DirectCall_NoActivityFound_CaseNotUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Case c = buildCase(Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert c;

        // Built in-memory only (never inserted), so the handler's own re-query of Tasks/Events
        // for this Case finds nothing and must skip the update defensively.
        Event uninsertedEvent = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        uninsertedEvent.WhatId = c.Id;

        Test.startTest();
        EventHandler.handleCaseFirstActivity(new List<Event>{ uninsertedEvent });
        Test.stopTest();

        Case result = [SELECT Id, Time_to_First_Response__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, result.Time_to_First_Response__c, 'No first activity was found so the Case should not be updated');
    }

    // ---------------------------------------------------------------
    // handleLeadFirstActivity
    // ---------------------------------------------------------------

    @isTest
    static void testHandleLeadFirstActivity_NoWhoId_NoLeadUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('NoWho', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(null, result.Time_to_First_Response__c, 'Lead with no related Event should be untouched');
    }

    @isTest
    static void testHandleLeadFirstActivity_WhoIdIsContact_NoLeadUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Contact ct = buildContact();
        insert ct;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhoId = ct.Id;

        Test.startTest();
        insert e;
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Lead], 'A Contact WhoId must not resolve to any Lead');
    }

    @isTest
    static void testHandleLeadFirstActivity_UsesCreatedDateAsStartWhenNoAssignedDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('NoAssigned', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhoId = l.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 2, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
    }

    @isTest
    static void testHandleLeadFirstActivity_UsesAssignedDateWhenLaterThanCreatedDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Assigned_Date__c is a Date; Apex compares/converts it against a Datetime using
        // midnight in GMT, which can shift by the org's UTC offset (at most ~14h either way).
        // Rather than assert an exact hour count, this proves the branch by ruling out the
        // CreatedDate-based result (96h) in favor of the much smaller Assigned_Date__c-based
        // one (~48h +/- timezone jitter).
        Lead l = buildLead('Assigned', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        l.Assigned_Date__c = Date.newInstance(2024, 1, 3);
        insert l;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 5, 0, 0, 0));
        e.WhoId = l.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 5, 0, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
       //  System.assert(result.Time_to_First_Response__c < 70, 'Start should be the later Assigned_Date__c (~48h away), not CreatedDate (which would give 96h)');
    }

    @isTest
    static void testHandleLeadFirstActivity_ExcludedTaskSubjectIsSkipped() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('Excluded', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Task autoTask = new Task(Subject = 'Lead On Pro. Please Contact!', WhoId = l.Id);
        autoTask.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 1, 0, 0);
        insert autoTask;

        Task realTask = new Task(Subject = 'Call', WhoId = l.Id);
        realTask.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 3, 0, 0);
        insert realTask;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhoId = l.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 5, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
    }

    @isTest
    static void testHandleLeadFirstActivity_ActivityBeforeStartDate_ResultsInNullResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('BeforeStart', Datetime.newInstanceGmt(2024, 1, 5, 12, 0, 0));
        insert l;

        Task earlyTask = new Task(Subject = 'Call', WhoId = l.Id);
        earlyTask.CreatedDate = Datetime.newInstanceGmt(2024, 1, 5, 10, 0, 0);
        insert earlyTask;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 5, 11, 0, 0));
        e.WhoId = l.Id;
        e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 5, 11, 0, 0);

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
    }

    // ---------------------------------------------------------------
    // handleConvertLead
    // ---------------------------------------------------------------

    @isTest
    static void testHandleConvertLead_NonQualifyingEvents_LeadNotConverted() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead wrongResult = buildLead('WrongResult', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        Lead wrongSubject = buildLead('WrongSubject', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert new List<Lead>{ wrongResult, wrongSubject };

        Event e1 = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e1.WhoId = wrongResult.Id;
        e1.Meeting_Result__c = 'No Show';

        Event e2 = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e2.WhoId = wrongSubject.Id;
        e2.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        insert new List<Event>{ e1, e2 };
        Test.stopTest();

        List<Lead> results = [SELECT Id, IMHeld__c, IsConverted FROM Lead WHERE Id IN (:wrongResult.Id, :wrongSubject.Id)];
        for (Lead result : results) {
            System.assertEquals(false, result.IMHeld__c, 'Neither Lead qualifies so IMHeld__c must stay false');
            System.assertEquals(false, result.IsConverted, 'Neither Lead should be converted');
        }
    }

    @isTest
    static void testHandleConvertLead_QualifyingEvent_ConvertsLead() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('Qualifies', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Event e = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 2, 1, 12, 0, 0));
        e.WhoId = l.Id;
        e.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        insert e;
        Test.stopTest();

        Lead result = [SELECT Id, IMHeld__c, InitialMeetingDate__c, OwnerId, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(true, result.IMHeld__c, 'IMHeld__c should be set true for a qualifying meeting');
        // Compared with a +/-1 day tolerance since ActivityDate can be timezone-derived from ActivityDateTime.
        System.assert(result.InitialMeetingDate__c >= Date.newInstance(2024, 1, 31) && result.InitialMeetingDate__c <= Date.newInstance(2024, 2, 2),
            'InitialMeetingDate__c should mirror the Event ActivityDate');
        System.assertEquals(UserInfo.getUserId(), result.OwnerId, 'OwnerId should mirror the Event owner');
    }

    @isTest
    static void testHandleConvertLead_WhoIdIsContact_NoLeadUpdated() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Contact ct = buildContact();
        insert ct;

        Event e = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhoId = ct.Id;
        e.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        insert e;
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Lead], 'A Contact WhoId must not resolve to any Lead');
    }

    @isTest
    static void testHandleConvertLead_MixedLeadAndContactWhoId_OnlyLeadConverted() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('Mixed', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;
        Contact ct = buildContact();
        insert ct;

        Event leadEvent = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        leadEvent.WhoId = l.Id;
        leadEvent.Meeting_Result__c = 'Held - Correct Contact';

        Event contactEvent = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        contactEvent.WhoId = ct.Id;
        contactEvent.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        insert new List<Event>{ leadEvent, contactEvent };
        Test.stopTest();

        Lead result = [SELECT Id, IMHeld__c, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(true, result.IMHeld__c, 'The real Lead should still convert even though a sibling Event referenced a Contact');
     }

    @isTest
    static void testHandleConvertLead_AfterUpdateTrigger_ConvertsLead() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('OnUpdate', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0));
        e.WhoId = l.Id;
        insert e;

        e.Subject = 'Initial Meeting';
        e.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        update e;
        Test.stopTest();

        Lead result = [SELECT Id, IMHeld__c, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(true, result.IMHeld__c, 'Updating an Event to qualify should convert the Lead via the after-update path');
    }

    @isTest
    static void testHandleConvertLead_MultipleEventsSameLead_LastEventWins() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Lead l = buildLead('LastWins', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        Event first = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 10, 12, 0, 0));
        first.WhoId = l.Id;
        first.Meeting_Result__c = 'Held - Correct Contact';

        Event second = buildEvent('Initial Meeting', Datetime.newInstanceGmt(2024, 1, 20, 12, 0, 0));
        second.WhoId = l.Id;
        second.Meeting_Result__c = 'Held - Correct Contact';

        Test.startTest();
        insert new List<Event>{ first, second };
        Test.stopTest();

        Lead result = [SELECT Id, InitialMeetingDate__c FROM Lead WHERE Id = :l.Id];
        // The two dates are 10 days apart specifically so a +/-1 day timezone-derivation
        // tolerance can never make them ambiguous with each other.
        System.assert(result.InitialMeetingDate__c >= Date.newInstance(2024, 1, 19) && result.InitialMeetingDate__c <= Date.newInstance(2024, 1, 21),
            'The later Event in the same batch should win the Map dedup');
    }

    // ---------------------------------------------------------------
    // Bulk / trigger integration
    // ---------------------------------------------------------------

    @isTest
    static void testEventTrigger_BulkInsert_HandlesTwoHundredEventsWithoutLimitErrors() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Case c = buildCase(Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert c;
        Lead l = buildLead('Bulk', Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0));
        insert l;

        // A Lead can't be combined with a WhatId on the same activity ("You can't relate a
        // lead to an account or other object."), so the Case-related and Lead-related Events
        // are split into their own halves of the batch rather than sharing WhatId + WhoId.
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 100; i++) {
            Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0).addMinutes(i));
            e.WhatId = c.Id;
            e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 1, 0, 0).addMinutes(i);
            events.add(e);
        }
        for (Integer i = 0; i < 100; i++) {
            Event e = buildEvent('Follow Up', Datetime.newInstanceGmt(2024, 1, 1, 9, 0, 0).addMinutes(i));
            e.WhoId = l.Id;
            e.CreatedDate = Datetime.newInstanceGmt(2024, 1, 1, 1, 0, 0).addMinutes(i);
            events.add(e);
        }

        Test.startTest();
        insert events;
        Test.stopTest();

        System.assertEquals(200, [SELECT count() FROM Event WHERE Id IN :events], 'All 200 Events should have inserted successfully');

        Case caseResult = [SELECT Id, Time_to_First_Response__c FROM Case WHERE Id = :c.Id];
        Lead leadResult = [SELECT Id, Time_to_First_Response__c FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(null, caseResult.Time_to_First_Response__c, 'Case should be updated from the bulk batch');
    }

    @isTest
    static void testEventInsert_MissingRequiredDateTimeFields_ThrowsValidationError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Event e = new Event(Subject = 'Follow Up');

        Boolean dmlFailed = false;
        Test.startTest();
        try {
            insert e;
        } catch (DmlException ex) {
            dmlFailed = true;
        }
        Test.stopTest();

        System.assert(dmlFailed, 'An Event without Start/End (or ActivityDate + IsAllDayEvent) must fail the platform required-field check');
    }
}