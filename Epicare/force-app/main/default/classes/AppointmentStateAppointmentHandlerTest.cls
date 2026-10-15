@IsTest
private class AppointmentStateAppointmentHandlerTest {

    private static final String STATE_1 = 'CA';
    private static final String STATE_2 = 'TX';
    private static final String STATE_3 = 'FL';
    private static final String LOB = 'Medicare';
    private static final String STATUS = 'On Agent Side';

    @TestSetup
    static void setupTestData() {

        Account agency = new Account(
            Name = 'Test Agency'
        );
        insert agency;

        Contact agent = new Contact(
            LastName = 'Test Agent',
            AccountId = agency.Id,
            Email = 'testagent@example.com',
            NPN__c = '1234567890',
            Agent_Status__c = 'Onboarding',
            Insurance_Types__c = 'Medicare',

            // Bypasses Appointment onboarding validation rule.
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare'
        );
        insert carrier;
    }

    private static Appointment__c buildAppointment(
        String states
    ) {
        Account agency = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        Contact agent = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Carrier__c carrier = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ];

        return new Appointment__c(
            State_s__c = states,
            Line_of_Business__c = LOB,
            Agent__c = agent.Id,
            Carrier__c = carrier.Id,
            Agency__c = agency.Id
        );
    }

    private static Appointment__c createAppointment(
        String states
    ) {
        Appointment__c appointment = buildAppointment(states);
        insert appointment;
        return appointment;
    }

    /*
     * Calls handler update logic directly.
     * This avoids unrelated Appointment "Ready to Sell" validation
     * that runs during update DML in the org.
     */
    private static void processStateChange(
        Id appointmentId,
        String oldStates,
        String newStates
    ) {
        Appointment__c updatedAppointment = new Appointment__c(
            Id = appointmentId,
            State_s__c = newStates
        );

        Map<Id, Appointment__c> oldMap =
            new Map<Id, Appointment__c>{
                appointmentId => new Appointment__c(
                    Id = appointmentId,
                    State_s__c = oldStates
                )
            };

        AppointmentStateAppointmentHandler.createStateAppointments(
            new List<Appointment__c>{ updatedAppointment },
            oldMap
        );
    }

    @IsTest
    static void testInsert_SingleState_CreatesOneStateAppointment() {

        Test.startTest();
        Appointment__c app = createAppointment(STATE_1);
        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT Id, State__c, State_Status__c, Appointment__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            1,
            results.size(),
            'Expected one State Appointment record.'
        );

        System.assertEquals(
            STATE_1,
            results[0].State__c
        );

        System.assertEquals(
            STATUS,
            results[0].State_Status__c
        );
    }

    @IsTest
    static void testInsert_MultipleStates_CreatesMultipleStateAppointments() {

        Test.startTest();

        Appointment__c app = createAppointment(
            STATE_1 + ';' + STATE_2 + ';' + STATE_3
        );

        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT State__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            3,
            results.size(),
            'Expected three State Appointment records.'
        );

        Set<String> expectedStates =
            new Set<String>{ STATE_1, STATE_2, STATE_3 };

        for (State_Appointment__c result : results) {
            System.assert(
                expectedStates.contains(result.State__c),
                'Unexpected state: ' + result.State__c
            );
        }
    }

    @IsTest
    static void testInsert_StatesWithSpaces_TrimsCorrectly() {

        Test.startTest();

        Appointment__c app = createAppointment(
            ' ' + STATE_1 + ' ; ' + STATE_2 + ' '
        );

        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT State__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            2,
            results.size(),
            'Expected two trimmed State Appointment records.'
        );

        Set<String> expectedStates =
            new Set<String>{ STATE_1, STATE_2 };

        for (State_Appointment__c result : results) {
            System.assert(
                expectedStates.contains(result.State__c),
                'Unexpected state: ' + result.State__c
            );
        }
    }

    @IsTest
    static void testInsert_EmptySegment_SkipsBlankSegment() {

        Test.startTest();

        Appointment__c app = createAppointment(
            STATE_1 + ';;' + STATE_2
        );

        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT State__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            2,
            results.size(),
            'Blank state segment must be skipped.'
        );
    }

    @IsTest
    static void testUpdate_StateChanges_CreatesNewStateAppointment() {

        Appointment__c app = createAppointment(STATE_1);

        Test.startTest();

        processStateChange(
            app.Id,
            STATE_1,
            STATE_1 + ';' + STATE_2
        );

        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT State__c
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            2,
            results.size(),
            'Expected records for CA and TX.'
        );

        Set<String> expectedStates =
            new Set<String>{ STATE_1, STATE_2 };

        for (State_Appointment__c result : results) {
            System.assert(
                expectedStates.contains(result.State__c),
                'Unexpected state: ' + result.State__c
            );
        }
    }

    @IsTest
    static void testUpdate_StateUnchanged_NoNewRecordsCreated() {

        Appointment__c app = createAppointment(STATE_1);

        Integer countBefore = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        Test.startTest();

        processStateChange(
            app.Id,
            STATE_1,
            STATE_1
        );

        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            countBefore,
            countAfter,
            'No State Appointment should be created for an unchanged state.'
        );
    }

    @IsTest
    static void testUpdate_DuplicateState_NotInsertedAgain() {

        Appointment__c app = createAppointment(STATE_1);

        insert new State_Appointment__c(
            Appointment__c = app.Id,
            State__c = STATE_2,
            State_Status__c = STATUS
        );

        Test.startTest();

        processStateChange(
            app.Id,
            STATE_1,
            STATE_1 + ';' + STATE_2
        );

        Test.stopTest();

        List<State_Appointment__c> results = [
            SELECT Id
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
            AND State__c = :STATE_2
        ];

        System.assertEquals(
            1,
            results.size(),
            'TX must not be inserted more than once.'
        );
    }

    @IsTest
    static void testUpdate_DifferentState_CreatesNewStateAppointment() {

        Appointment__c app = createAppointment(STATE_1);

        Integer countBefore = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        Test.startTest();

        processStateChange(
            app.Id,
            STATE_1,
            STATE_2
        );

        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
        ];

        System.assertEquals(
            countBefore + 1,
            countAfter,
            'One State Appointment record should be created for TX.'
        );

        Integer txCount = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c = :app.Id
            AND State__c = :STATE_2
        ];

        System.assertEquals(
            1,
            txCount,
            'Expected one State Appointment record for TX.'
        );
    }

    @IsTest
    static void testBulkInsert_200Records_AllStateAppointmentsCreated() {

        Account agency = [SELECT Id FROM Account LIMIT 1];
        Contact agent = [SELECT Id FROM Contact LIMIT 1];
        Carrier__c carrier = [SELECT Id FROM Carrier__c LIMIT 1];

        List<Appointment__c> apps = new List<Appointment__c>();

        for (Integer i = 0; i < 200; i++) {
            apps.add(
                new Appointment__c(
                    State_s__c = STATE_1 + ';' + STATE_2,
                    Line_of_Business__c = LOB,
                    Agent__c = agent.Id,
                    Carrier__c = carrier.Id,
                    Agency__c = agency.Id
                )
            );
        }

        Test.startTest();
        insert apps;
        Test.stopTest();

        Integer stateAppointmentCount = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c IN :apps
        ];

        System.assertEquals(
            400,
            stateAppointmentCount,
            'Expected 400 State Appointment records.'
        );
    }

    @IsTest
    static void testBulkUpdate_200Records_OnlyNewStatesInserted() {

        Account agency = [SELECT Id FROM Account LIMIT 1];
        Contact agent = [SELECT Id FROM Contact LIMIT 1];
        Carrier__c carrier = [SELECT Id FROM Carrier__c LIMIT 1];

        List<Appointment__c> apps = new List<Appointment__c>();

        for (Integer i = 0; i < 200; i++) {
            apps.add(
                new Appointment__c(
                    State_s__c = STATE_1,
                    Line_of_Business__c = LOB,
                    Agent__c = agent.Id,
                    Carrier__c = carrier.Id,
                    Agency__c = agency.Id
                )
            );
        }

        insert apps;

        List<Appointment__c> updatedApps =
            new List<Appointment__c>();

        Map<Id, Appointment__c> oldMap =
            new Map<Id, Appointment__c>();

        for (Appointment__c app : apps) {

            updatedApps.add(
                new Appointment__c(
                    Id = app.Id,
                    State_s__c = STATE_1 + ';' + STATE_3
                )
            );

            oldMap.put(
                app.Id,
                new Appointment__c(
                    Id = app.Id,
                    State_s__c = STATE_1
                )
            );
        }

        Test.startTest();

        AppointmentStateAppointmentHandler.createStateAppointments(
            updatedApps,
            oldMap
        );

        Test.stopTest();

        Integer floridaCount = [
            SELECT COUNT()
            FROM State_Appointment__c
            WHERE Appointment__c IN :apps
            AND State__c = :STATE_3
        ];

        System.assertEquals(
            200,
            floridaCount,
            'Expected 200 FL State Appointment records after bulk update.'
        );
    }
}