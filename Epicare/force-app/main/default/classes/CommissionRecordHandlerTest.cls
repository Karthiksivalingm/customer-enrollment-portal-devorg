@IsTest
private class CommissionRecordHandlerTest {

    private static final String STATUS_RECONCILED = 'Reconciled';
    private static final String STATUS_ESTIMATED = 'Estimated';

    private static final String EX_UNDERPAID = 'Underpaid';
    private static final String EX_OVERPAID = 'Overpaid';

    private static Id agencyId;
    private static Id agentId;
    private static Id carrierId;
    private static Id directAppointmentId;
    private static Id pendingAppointmentId;

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
            Bypass_VR__c = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare'
        );
        insert carrier;

        Appointment__c directAppointment = new Appointment__c(
            Agent__c = agent.Id,
            Carrier__c = carrier.Id,
            Agency__c = agency.Id,
            Line_of_Business__c = 'Medicare',
            State_s__c = 'CA',
            Payment_Flow__c = 'Carrier_Direct'
        );
        insert directAppointment;

        Appointment__c pendingAppointment = new Appointment__c(
            Agent__c = agent.Id,
            Carrier__c = carrier.Id,
            Agency__c = agency.Id,
            Line_of_Business__c = 'Medicare',
            State_s__c = 'CA',
            Payment_Flow__c = 'Pending'
        );
        insert pendingAppointment;
    }

    private static void loadIds() {

        if (agentId != null) {
            return;
        }

        agencyId = [
            SELECT Id
            FROM Account
            LIMIT 1
        ].Id;

        agentId = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ].Id;

        carrierId = [
            SELECT Id
            FROM Carrier__c
            LIMIT 1
        ].Id;

        directAppointmentId = [
            SELECT Id
            FROM Appointment__c
            WHERE Payment_Flow__c = 'Carrier_Direct'
            LIMIT 1
        ].Id;

        pendingAppointmentId = [
            SELECT Id
            FROM Appointment__c
            WHERE Payment_Flow__c = 'Pending'
            LIMIT 1
        ].Id;
    }

    private static Id getDirectAppointmentId() {
        loadIds();
        return directAppointmentId;
    }

    private static Id getPendingAppointmentId() {
        loadIds();
        return pendingAppointmentId;
    }

    private static Commission_Record__c buildCommissionRecord(
        String status,
        String policyNumber,
        String paymentPeriod,
        Decimal grossAmount,
        Id appointmentId,
        String paymentFlow
    ) {
        loadIds();

        return new Commission_Record__c(
            Status__c = status,
            Policy_Number__c = policyNumber,
            Payment_Period__c = paymentPeriod,
            Gross_Amount__c = grossAmount,
            Admin_Fee__c = 0,
            Chargeback_Amount__c = 0,
            Agent__c = agentId,
            Carrier__c = carrierId,
            Agency__c = agencyId,
            LOB__c = 'Medicare',
            Compensation_Type__c = 'New Business',
            Source__c = 'Manual',
            Effective_Date__c = Date.today(),
            Payment_Date__c = Date.today(),
            Appointment__c = appointmentId,
            Payment_Flow__c = paymentFlow
        );
    }

    private static void insertUsingHandler(
        List<Commission_Record__c> records
    ) {
        CommissionRecordHandler.handleBeforeInsert(records);

        insert records;

        CommissionRecordHandler.handleAfterInsert(records);
    }

    @IsTest
    static void testBeforeInsert_StampsDirectPaymentFlow() {

        Commission_Record__c cr = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_STAMP_DIRECT',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            null
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ cr }
        );

        Test.stopTest();

        Commission_Record__c savedRecord = [
            SELECT Payment_Flow__c
            FROM Commission_Record__c
            WHERE Id = :cr.Id
        ];

        System.assertEquals(
            'Carrier_Direct',
            savedRecord.Payment_Flow__c,
            'Payment Flow must be stamped from the related Appointment.'
        );
    }

    @IsTest
    static void testBeforeInsert_StampsPendingPaymentFlow() {

        Commission_Record__c cr = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_STAMP_PENDING',
            '2024-01',
            100.00,
            getPendingAppointmentId(),
            null
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ cr }
        );

        Test.stopTest();

        Commission_Record__c savedRecord = [
            SELECT Payment_Flow__c
            FROM Commission_Record__c
            WHERE Id = :cr.Id
        ];

        System.assertEquals(
            'Pending',
            savedRecord.Payment_Flow__c,
            'Pending Payment Flow must be stamped from the related Appointment.'
        );
    }

    @IsTest
    static void testAfterInsert_WithinTolerance_ReconcilesEstimated() {

        Commission_Record__c estimated = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_TOLERANCE',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );
        insertUsingHandler(
            new List<Commission_Record__c>{ estimated }
        );

        Commission_Record__c reconciled = buildCommissionRecord(
            STATUS_RECONCILED,
            'POL_TOLERANCE',
            '2024-01',
            100.30,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ reconciled }
        );

        Test.stopTest();

        Commission_Record__c updatedEstimated = [
            SELECT Status__c
            FROM Commission_Record__c
            WHERE Id = :estimated.Id
        ];

        System.assertEquals(
            STATUS_RECONCILED,
            updatedEstimated.Status__c,
            'Estimated record must be Reconciled within tolerance.'
        );
    }

    @IsTest
    static void testAfterInsert_UnderpaidException() {

        Commission_Record__c estimated = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_UNDERPAID',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );
        insertUsingHandler(
            new List<Commission_Record__c>{ estimated }
        );

        Commission_Record__c reconciled = buildCommissionRecord(
            STATUS_RECONCILED,
            'POL_UNDERPAID',
            '2024-01',
            90.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ reconciled }
        );

        Test.stopTest();

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c
            FROM Commission_Exception__c
            WHERE Commission_Record__c = :reconciled.Id
        ];

        System.assertEquals(
            1,
            exceptions.size(),
            'One Underpaid exception must be created.'
        );

        System.assertEquals(
            EX_UNDERPAID,
            exceptions[0].Exception_Type__c
        );
    }

    @IsTest
    static void testAfterInsert_OverpaidException() {

        Commission_Record__c estimated = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_OVERPAID',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );
        insertUsingHandler(
            new List<Commission_Record__c>{ estimated }
        );

        Commission_Record__c reconciled = buildCommissionRecord(
            STATUS_RECONCILED,
            'POL_OVERPAID',
            '2024-01',
            115.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ reconciled }
        );

        Test.stopTest();

        List<Commission_Exception__c> exceptions = [
            SELECT Id, Exception_Type__c
            FROM Commission_Exception__c
            WHERE Commission_Record__c = :reconciled.Id
        ];

        System.assertEquals(
            1,
            exceptions.size(),
            'One Overpaid exception must be created.'
        );

        System.assertEquals(
            EX_OVERPAID,
            exceptions[0].Exception_Type__c
        );
    }

    @IsTest
    static void testAfterInsert_UnknownPolicy_RecordInsertsSuccessfully() {

        Commission_Record__c reconciled = buildCommissionRecord(
            STATUS_RECONCILED,
            'POL_UNKNOWN_POLICY',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ reconciled }
        );

        Test.stopTest();

        Integer recordCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Id = :reconciled.Id
        ];

        System.assertEquals(
            1,
            recordCount,
            'The Unknown Policy Commission Record must insert successfully.'
        );
    }

    @IsTest
    static void testAfterInsert_ExactTolerance_ReconcilesEstimated() {

        Commission_Record__c estimated = buildCommissionRecord(
            STATUS_ESTIMATED,
            'POL_EXACT_TOLERANCE',
            '2024-01',
            100.00,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );
        insertUsingHandler(
            new List<Commission_Record__c>{ estimated }
        );

        Commission_Record__c reconciled = buildCommissionRecord(
            STATUS_RECONCILED,
            'POL_EXACT_TOLERANCE',
            '2024-01',
            100.50,
            getDirectAppointmentId(),
            'Carrier_Direct'
        );

        Test.startTest();

        insertUsingHandler(
            new List<Commission_Record__c>{ reconciled }
        );

        Test.stopTest();

        Commission_Record__c updatedEstimated = [
            SELECT Status__c
            FROM Commission_Record__c
            WHERE Id = :estimated.Id
        ];

        System.assertEquals(
            STATUS_RECONCILED,
            updatedEstimated.Status__c,
            'Estimated record must be Reconciled at the exact $0.50 tolerance.'
        );
    }

    @IsTest
    static void testBulkInsert_200CommissionRecords() {

        List<Commission_Record__c> records =
            new List<Commission_Record__c>();

        for (Integer i = 0; i < 200; i++) {
            records.add(
                buildCommissionRecord(
                    STATUS_ESTIMATED,
                    'POL_BULK_' + i,
                    '2024-01',
                    100.00,
                    getDirectAppointmentId(),
                    null
                )
            );
        }

        Test.startTest();

        insertUsingHandler(records);

        Test.stopTest();

        Integer recordCount = [
            SELECT COUNT()
            FROM Commission_Record__c
            WHERE Policy_Number__c LIKE 'POL_BULK_%'
        ];

        System.assertEquals(
            200,
            recordCount,
            'All 200 Commission Records must be inserted.'
        );
    }
}