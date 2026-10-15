@isTest
public class AppointmentRequestedSubscriberTest {

    /*
     * Get a non-Agent Contact Record Type to avoid Agent-specific
     * automation during test execution.
     */
    private static Id getContactRecordTypeId() {

        Schema.RecordTypeInfo rtInfo =
            Schema.SObjectType.Contact
                .getRecordTypeInfosByName()
                .get('Agency Director');

        System.assertNotEquals(
            null,
            rtInfo,
            'Agency Director Contact Record Type must exist.'
        );

        return rtInfo.getRecordTypeId();
    }


    @testSetup
    static void setupData() {

        // Agency
        Account acc = new Account(
            Name = 'Appointment Test Agency 001'
        );
        insert acc;


        // Contact
        // Bypass_VR__c sidesteps the org validation rule
        // "Require_Green_Onboarding_Semaphore" on Appointment__c. That rule's
        // formula is NOT(ISPICKVAL(Status__c, "Request")) — note it checks for
        // the picklist value "Request", while the subscriber trigger (and this
        // test's own assertions) use "Requested". Because those never match,
        // the rule always falls through to requiring Agent__r.Overall_Semaphore__c
        // = 'Green', which a freshly-inserted test Contact will never have
        // (it's driven by several *_Complete__c checkboxes). Bypass_VR__c is the
        // rule's built-in escape hatch for exactly this situation.
        Contact con = new Contact(
            RecordTypeId = getContactRecordTypeId(),
            LastName = 'Appointment Test Agent 001',
            AccountId = acc.Id,
            Email = 'appointment.agent.001@test.com',
            NPN__c = '92000001',
            Agent_Status__c = 'Onboarding',
            Bypass_VR__c = true
        );
        insert con;


        // Carrier
        Carrier__c carrier = new Carrier__c(
            Name = 'Aetna Appointment Test 001',
            Supported_Lines_of_Business__c = 'Medicare'
        );
        insert carrier;
    }


    /*
     * Test 1:
     * Verify that an Appointment is created correctly.
     */
    @isTest
    static void testAppointmentCreated() {

        Contact con = [
            SELECT Id, AccountId
            FROM Contact
            LIMIT 1
        ];

        Carrier__c carrier = [
            SELECT Id, Name
            FROM Carrier__c
            LIMIT 1
        ];


        Appointment_Requested__e evt =
            new Appointment_Requested__e(
                Contact_ID__c = con.Id,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'TX;FL'
            );


        Test.startTest();

        Database.SaveResult result =
            EventBus.publish(evt);

        System.assertEquals(
            true,
            result.isSuccess(),
            'Appointment Requested event should be published successfully.'
        );

        Test.getEventBus().deliver();

        Test.stopTest();


        List<Appointment__c> apps = [
            SELECT Id,
                   Agent__c,
                   Agency__c,
                   Carrier__c,
                   Line_of_Business__c,
                   State_s__c,
                   Status__c,
                   Requested_Date__c
            FROM Appointment__c
            WHERE Agent__c = :con.Id
            AND Carrier__c = :carrier.Id
        ];


        System.assertEquals(
            1,
            apps.size(),
            'Exactly one Appointment should be created.'
        );


        Appointment__c app = apps[0];

        System.assertEquals(
            con.Id,
            app.Agent__c,
            'Appointment Agent should match the Contact.'
        );

        System.assertEquals(
            con.AccountId,
            app.Agency__c,
            'Appointment Agency should match the Contact Account.'
        );

        System.assertEquals(
            carrier.Id,
            app.Carrier__c,
            'Appointment Carrier should match the event Carrier.'
        );

        System.assertEquals(
            'Medicare',
            app.Line_of_Business__c,
            'Line of Business should be Medicare.'
        );

        /*
         * Multi-select picklist values can be stored in sorted order.
         */
        System.assertEquals(
            'FL;TX',
            app.State_s__c,
            'States should contain FL and TX.'
        );

        System.assertEquals(
            'Requested',
            app.Status__c,
            'Appointment Status should be Requested.'
        );

        System.assertEquals(
            Date.today(),
            app.Requested_Date__c,
            'Requested Date should be today.'
        );


        // Verify Desired Carriers JSON was updated
        Contact updatedContact = [
            SELECT Desired_Carriers__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assert(
            updatedContact.Desired_Carriers__c.contains(carrier.Id),
            'Desired Carriers should contain the Carrier Id.'
        );

        System.assert(
            updatedContact.Desired_Carriers__c.contains(carrier.Name),
            'Desired Carriers should contain the Carrier Name.'
        );
    }


    /*
     * Test 2:
     * Duplicate Contact + Carrier events in the same transaction
     * should create only one Appointment.
     */
    @isTest
    static void testDuplicateEventsIgnored() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Carrier__c carrier = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ];


        Appointment_Requested__e firstEvent =
            new Appointment_Requested__e(
                Contact_ID__c = con.Id,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'CA'
            );


        Appointment_Requested__e secondEvent =
            new Appointment_Requested__e(
                Contact_ID__c = con.Id,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'CA'
            );


        Test.startTest();

        List<Database.SaveResult> results =
            EventBus.publish(
                new List<Appointment_Requested__e>{
                    firstEvent,
                    secondEvent
                }
            );


        for (Database.SaveResult result : results) {
            System.assertEquals(
                true,
                result.isSuccess(),
                'Appointment Requested event should be published successfully.'
            );
        }


        Test.getEventBus().deliver();

        Test.stopTest();


        Integer countApps = [
            SELECT COUNT()
            FROM Appointment__c
            WHERE Agent__c = :con.Id
            AND Carrier__c = :carrier.Id
        ];


        System.assertEquals(
            1,
            countApps,
            'Duplicate Contact + Carrier events should create only one Appointment.'
        );
    }


    /*
     * Test 3:
     * Event with missing Contact ID or Carrier ID should be ignored.
     */
    @isTest
    static void testNullValuesIgnored() {

        Test.startTest();

        Appointment_Requested__e evt =
            new Appointment_Requested__e(
                Contact_ID__c = null,
                Carrier_ID__c = null,
                States__c = 'TX'
            );


        Database.SaveResult result =
            EventBus.publish(evt);


        System.assertEquals(
            true,
            result.isSuccess(),
            'Event should be published successfully.'
        );


        Test.getEventBus().deliver();

        Test.stopTest();


        Integer countApps = [
            SELECT COUNT()
            FROM Appointment__c
        ];


        System.assertEquals(
            0,
            countApps,
            'No Appointment should be created when Contact or Carrier is missing.'
        );
    }


    /*
     * Test 4:
     * Valid Carrier + invalid Contact should not create Appointment.
     */
    @isTest
    static void testContactNotFound() {

        Carrier__c carrier = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ];


        // Valid Contact Id format but does not exist.
        Id fakeContactId = '003000000000001AAA';


        Appointment_Requested__e evt =
            new Appointment_Requested__e(
                Contact_ID__c = fakeContactId,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'NY'
            );


        Test.startTest();

        Database.SaveResult result =
            EventBus.publish(evt);


        System.assertEquals(
            true,
            result.isSuccess(),
            'Event should be published successfully.'
        );


        Test.getEventBus().deliver();

        Test.stopTest();


        Integer countApps = [
            SELECT COUNT()
            FROM Appointment__c
        ];


        System.assertEquals(
            0,
            countApps,
            'No Appointment should be created when Contact does not exist.'
        );
    }


    /*
     * Test 5:
     * Two different Contacts with the same Carrier
     * should create two separate Appointments.
     */
    @isTest
    static void testMultipleDifferentAppointments() {

        Account acc2 = new Account(
            Name = 'Appointment Test Agency 002'
        );
        insert acc2;


        // Bypass_VR__c is required here too — this Contact is inserted fresh
        // in this test method (not via @testSetup), so it needs the same
        // validation-rule bypass as the agent created in setupData().
        Contact con2 = new Contact(
            RecordTypeId = getContactRecordTypeId(),
            LastName = 'Appointment Test Agent 002',
            AccountId = acc2.Id,
            Email = 'appointment.agent.002@test.com',
            NPN__c = '92000002',
            Agent_Status__c = 'Onboarding',
            Bypass_VR__c = true
        );
        insert con2;


        Contact con1 = [
            SELECT Id, AccountId
            FROM Contact
            LIMIT 1
        ];


        Carrier__c carrier = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ];


        /*
         * Publish both events together.
         * This ensures the subscriber receives both events
         * in the same Platform Event delivery.
         */
        Appointment_Requested__e event1 =
            new Appointment_Requested__e(
                Contact_ID__c = con1.Id,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'TX'
            );


        Appointment_Requested__e event2 =
            new Appointment_Requested__e(
                Contact_ID__c = con2.Id,
                Carrier_ID__c = carrier.Id,
                LOB__c = 'Medicare',
                States__c = 'FL'
            );


        Test.startTest();

        List<Database.SaveResult> results =
            EventBus.publish(
                new List<Appointment_Requested__e>{
                    event1,
                    event2
                }
            );


        System.assertEquals(
            2,
            results.size(),
            'Two events should be published.'
        );


        for (Database.SaveResult result : results) {
            System.assertEquals(
                true,
                result.isSuccess(),
                'Both Appointment Requested events should be published successfully.'
            );
        }


        Test.getEventBus().deliver();

        Test.stopTest();


        /*
         * Query only Appointments created for the two
         * Contacts used by this test.
         */
        List<Appointment__c> appointments = [
            SELECT Id,
                   Agent__c,
                   Agency__c,
                   Carrier__c,
                   Line_of_Business__c,
                   State_s__c,
                   Status__c
            FROM Appointment__c
            WHERE Agent__c IN :new Set<Id>{
                con1.Id,
                con2.Id
            }
        ];


        System.assertEquals(
            2,
            appointments.size(),
            'Two different Contacts should create two Appointments.'
        );


        Set<Id> appointmentContactIds = new Set<Id>();

        for (Appointment__c app : appointments) {

            appointmentContactIds.add(app.Agent__c);

            System.assertEquals(
                carrier.Id,
                app.Carrier__c,
                'Both Appointments should use the requested Carrier.'
            );

            System.assertEquals(
                'Medicare',
                app.Line_of_Business__c,
                'Both Appointments should have Medicare as the LOB.'
            );

            System.assertEquals(
                'Requested',
                app.Status__c,
                'Both Appointments should have Requested status.'
            );
        }


        System.assert(
            appointmentContactIds.contains(con1.Id),
            'An Appointment should exist for the first Contact.'
        );

        System.assert(
            appointmentContactIds.contains(con2.Id),
            'An Appointment should exist for the second Contact.'
        );
    }
}