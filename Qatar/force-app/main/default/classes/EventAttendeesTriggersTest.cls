@IsTest
private class EventAttendeesTriggersTest {

    @TestSetup
    static void setupData() {

        List<Contact> contacts = new List<Contact>();

        contacts.add(new Contact(
            LastName = 'John',
            Email = 'john@test.com'
        ));

        contacts.add(new Contact(
            LastName = 'Mary',
            Email = 'mary@test.com'
        ));

        contacts.add(new Contact(
            LastName = 'Optional',
            Email = 'optional@test.com'
        ));

        insert contacts;
    }

    @IsTest
    static void testContactCreatesEventRelation() {

        Event evt = new Event(
            Subject = 'Test Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description =
                'Attendees: john@test.com'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Contact c = [
            SELECT Id
            FROM Contact
            WHERE Email = 'john@test.com'
            LIMIT 1
        ];

        List<EventRelation> rels = [
            SELECT Id,
                   EventId,
                   RelationId,
                   IsInvitee
            FROM EventRelation
            WHERE EventId = :evt.Id
            AND RelationId = :c.Id
        ];

        System.assertEquals(
            1,
            rels.size()
        );

        System.assertEquals(
            true,
            rels[0].IsInvitee
        );
    }

    @IsTest
    static void testExternalAttendeesStored() {

        Event evt = new Event(
            Subject = 'External Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description =
                'external1@gmail.com external2@yahoo.com'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assert(
            updatedEvt.External_Attendees__c
            .contains('external1@gmail.com')
        );

        System.assert(
            updatedEvt.External_Attendees__c
            .contains('external2@yahoo.com')
        );
    }

    @IsTest
    static void testBlankDescription() {

        Event evt = new Event(
            Subject = 'Blank Description',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1)
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assertEquals(
            null,
            updatedEvt.External_Attendees__c
        );
    }

    @IsTest
    static void testOrganizerExcluded() {

        Event evt = new Event(
            Subject = 'Organizer Test',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description =
                'Invited By John ' +
                'john@test.com ' +
                'external@gmail.com'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assert(
            !String.valueOf(
                updatedEvt.External_Attendees__c
            ).contains('john@test.com')
        );
    }

   @IsTest
static void testOptionalAttendeeExcluded() {

    Event evt = new Event(
        Subject = 'Optional Test',
        StartDateTime = System.now(),
        EndDateTime = System.now().addHours(1),
        Description =
            'Optional:\n' +
            'optional@test.com\n' +
            'Attendees:\n' +
            'guest@gmail.com'
    );

    Test.startTest();
    insert evt;
    Test.stopTest();

    Event updatedEvt = [
        SELECT External_Attendees__c
        FROM Event
        WHERE Id = :evt.Id
    ];

    System.assertNotEquals(
        null,
        updatedEvt.External_Attendees__c
    );

    System.assert(
        updatedEvt.External_Attendees__c.contains(
            'guest@gmail.com'
        )
    );

    System.assert(
        !updatedEvt.External_Attendees__c.contains(
            'optional@test.com'
        )
    );
}

    @IsTest
    static void testInternalDomainExcluded() {

        Event evt = new Event(
            Subject = 'Internal Domain',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description =
                'employee@qm.org.qa external@gmail.com'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assert(
            !String.valueOf(
                updatedEvt.External_Attendees__c
            ).contains('employee@qm.org.qa')
        );

        System.assert(
            String.valueOf(
                updatedEvt.External_Attendees__c
            ).contains('external@gmail.com')
        );
    }

    @IsTest
    static void testUpdateEvent() {

        Event evt = new Event(
            Subject = 'Update Test',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'john@test.com'
        );

        insert evt;

        Test.startTest();

        evt.Description =
            'john@test.com external@gmail.com';

        update evt;

        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assert(
            String.valueOf(
                updatedEvt.External_Attendees__c
            ).contains('external@gmail.com')
        );
    }

    @IsTest
    static void testSafeLinksUrlHandling() {

        Event evt = new Event(
            Subject = 'SafeLinks Test',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description =
                '<https://eur04.safelinks.protection.outlook.com>' +
                ' external@gmail.com'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        Event updatedEvt = [
            SELECT External_Attendees__c
            FROM Event
            WHERE Id = :evt.Id
        ];

        System.assert(
            String.valueOf(
                updatedEvt.External_Attendees__c
            ).contains('external@gmail.com')
        );
    }
    
    
}