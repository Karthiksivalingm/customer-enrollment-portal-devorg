@IsTest
private class ContactTriggerHandlerTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Get Agent Record Type
    // ─────────────────────────────────────────────────────────────────────────

    private static Id getAgentRecordTypeId() {

        Map<String, Schema.RecordTypeInfo> recordTypes =
            Schema.SObjectType.Contact
                .getRecordTypeInfosByDeveloperName();

        if (recordTypes.containsKey('Agent')) {
            return recordTypes.get('Agent').getRecordTypeId();
        }

        return null;
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Create Agent
    // ─────────────────────────────────────────────────────────────────────────

    private static Contact createAgent() {

        Account acc = new Account(
            Name = 'Test Agency ' + String.valueOf(Crypto.getRandomInteger())
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Agent',
            Email = 'agent' +
                    String.valueOf(Crypto.getRandomInteger()) +
                    '@test.com',
            AccountId = acc.Id,
            RecordTypeId = getAgentRecordTypeId(),
            NPN__c = '123456789',
            Agent_Status__c = 'Onboarding',
            Agent_Sub_Type__c = 'Captive',

            Base_Documents_Complete__c = true,
            Banking_Complete__c = true,
            EO_Complete__c = true,
            License_Complete__c = true,
            Certification_Complete__c = true,
            E_O_Termination_Date__c = Date.today().addDays(30),
            Background_Check_Status__c = 'Passed',

            Bypass_VR__c = true
        );

        insert con;

        return con;
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Create Appointment
    // ─────────────────────────────────────────────────────────────────────────

    private static Appointment__c createAppointment(
        Id agentId,
        Id agencyId,
        String statusValue
    ) {

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier ' +
                   String.valueOf(Crypto.getRandomInteger()),
            Supported_Lines_of_Business__c = 'Medicare'
        );

        insert carrier;

        Appointment__c appt = new Appointment__c(
            Agent__c = agentId,
            Agency__c = agencyId,
            Carrier__c = carrier.Id,
            State_s__c = 'AK',
            Line_Of_Business__c = 'Medicare',
            Status__c = statusValue
        );

        insert appt;

        return appt;
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Captive Agent - No Appointments
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testCaptiveAgentNoAppointments() {

        Contact con = createAgent();

        Test.startTest();

        update con;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            updatedCon.Agent_Warning__c
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Captive Agent - One Appointment
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testCaptiveAgentOneAppointment() {

        Contact con = createAgent();

        createAppointment(
            con.Id,
            con.AccountId,
            'Requested'
        );

        Test.startTest();

        update con;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            updatedCon.Agent_Warning__c
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Captive Agent - Multiple Appointments
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testCaptiveAgentMultipleAppointments() {

        Contact con = createAgent();

        createAppointment(
            con.Id,
            con.AccountId,
            'Requested'
        );

        createAppointment(
            con.Id,
            con.AccountId,
            'Requested'
        );

        Test.startTest();

        update con;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertNotEquals(
            null,
            updatedCon.Agent_Warning__c
        );

        System.assert(
            updatedCon.Agent_Warning__c.contains(
                'active appointments'
            )
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Rejected / Terminated Appointments Ignored
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testRejectedAppointmentsIgnored() {

        Contact con = createAgent();

        createAppointment(
            con.Id,
            con.AccountId,
            'Rejected'
        );

        createAppointment(
            con.Id,
            con.AccountId,
            'Terminated'
        );

        Test.startTest();

        update con;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            updatedCon.Agent_Warning__c
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Non-Captive Agent
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testNonCaptiveAgent() {

        Account acc = new Account(
            Name = 'Agency Non Captive'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Non Captive',
            Email = 'noncaptive@test.com',
            AccountId = acc.Id,
            RecordTypeId = getAgentRecordTypeId(),
            NPN__c = '999999999',
            Agent_Status__c = 'Onboarding',
            Agent_Sub_Type__c = 'Independent',
            Bypass_VR__c = true
        );

        Test.startTest();

        insert con;

        Test.stopTest();

        Contact insertedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            insertedCon.Agent_Warning__c
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // Captive → Independent
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testSubtypeChangedFromCaptiveToIndependent() {

        Contact con = createAgent();

        createAppointment(
            con.Id,
            con.AccountId,
            'Requested'
        );

        createAppointment(
            con.Id,
            con.AccountId,
            'Requested'
        );

        con.Agent_Sub_Type__c = 'Independent';

        Test.startTest();

        update con;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Agent_Warning__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            updatedCon.Agent_Warning__c
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // SSN Created
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testSSNCreatedIncident() {

        Account acc = new Account(
            Name = 'SSN Agency'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'SSN Agent',
            Email = 'ssncreated@test.com',
            AccountId = acc.Id,
            RecordTypeId = getAgentRecordTypeId(),
            NPN__c = '111111111',
            Agent_Status__c = 'Onboarding',
            Agent_Sub_Type__c = 'Captive',

            Base_Documents_Complete__c = true,
            Banking_Complete__c = true,
            EO_Complete__c = true,
            License_Complete__c = true,
            Certification_Complete__c = true,
            E_O_Termination_Date__c = Date.today().addDays(30),
            Background_Check_Status__c = 'Passed',

            Bypass_VR__c = true
        );

        Test.startTest();

        insert con;

        // Update SSN after Contact exists.
        // This allows the test to exercise the SSN tracking
        // without making the initial Contact insert carry SSN.
        con.SSN__c = '123456789';

        update con;

        Test.stopTest();

        List<Security_Incident__c> incidents = [
            SELECT Incident_Type__c,
                   Severity__c,
                   Status__c,
                   Detection_Method__c,
                   Affected_Object__c,
                   Affected_Records__c,
                   Description__c
            FROM Security_Incident__c
            WHERE Affected_Object__c = 'Contact'
            ORDER BY CreatedDate DESC
        ];

        System.assertEquals(
            1,
            incidents.size(),
            'One Security Incident should be created when SSN is set.'
        );

        System.assertEquals(
            'PII Exposure',
            incidents[0].Incident_Type__c
        );

        System.assertEquals(
            'Medium',
            incidents[0].Severity__c
        );

        System.assertEquals(
            'Open',
            incidents[0].Status__c
        );

        System.assertEquals(
            'SSN_Access_Trigger',
            incidents[0].Detection_Method__c
        );

        System.assertEquals(
            'Contact',
            incidents[0].Affected_Object__c
        );

        System.assertEquals(
            1,
            incidents[0].Affected_Records__c
        );

        System.assert(
            incidents[0].Description__c != null &&
            incidents[0].Description__c.contains(
                'SSN was modified'
            )
        );
    }


    // ─────────────────────────────────────────────────────────────────────────
    // SSN Modified
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testSSNModifiedIncident() {

        Contact con = createAgent();

        Test.startTest();

        con.SSN__c = '111111111';
        update con;

        con.SSN__c = '999999999';
        update con;

        Test.stopTest();

        List<Security_Incident__c> incidents = [
            SELECT Description__c
            FROM Security_Incident__c
            WHERE Affected_Object__c = 'Contact'
            ORDER BY CreatedDate
        ];

        System.assertEquals(
            2,
            incidents.size(),
            'Two Security Incidents should be created for two SSN changes.'
        );

        for (Security_Incident__c si : incidents) {

            System.assert(
                si.Description__c != null &&
                si.Description__c.contains(
                    'SSN was modified'
                )
            );
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // No SSN - No Incident
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testNoSSN_NoIncidentCreated() {

        Account acc = new Account(
            Name = 'No SSN Agency'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'No SSN',
            Email = 'nossn@test.com',
            AccountId = acc.Id,
            RecordTypeId = getAgentRecordTypeId(),
            NPN__c = '888888888',
            Agent_Status__c = 'Onboarding',
            Agent_Sub_Type__c = 'Captive',
            Bypass_VR__c = true
        );

        Test.startTest();

        insert con;

        Test.stopTest();

        Integer count = [
            SELECT COUNT()
            FROM Security_Incident__c
        ];

        System.assertEquals(
            0,
            count,
            'No Security Incident should be created when SSN is blank.'
        );
    }
}