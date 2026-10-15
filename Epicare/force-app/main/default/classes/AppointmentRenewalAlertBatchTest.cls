@IsTest
private class AppointmentRenewalAlertBatchTest {

    private static Id getAgentRecordTypeId() {

        Map<String, Schema.RecordTypeInfo> recordTypes =
            Schema.SObjectType.Contact
                .getRecordTypeInfosByDeveloperName();

        if (recordTypes.containsKey('Agent')) {
            return recordTypes.get('Agent').getRecordTypeId();
        }

        return null;
    }

    private static Appointment__c createAppointment(
        Integer renewalDays,
        String statusVal
    ) {

        Account acc = new Account(
            Name = 'Test Agency ' + String.valueOf(renewalDays)
        );
        insert acc;

        Contact agent = new Contact(
            LastName = 'Test Agent ' + String.valueOf(renewalDays),
            Email = 'agent' + String.valueOf(renewalDays) + '@test.com',
            AccountId = acc.Id,

            // Valid 10-digit NPN.
            NPN__c = String.valueOf(1000000000 + renewalDays),

            // Required while creating an Agent.
            Agent_Status__c = 'Onboarding',

            // Bypasses Appointment onboarding validation rule.
            Bypass_VR__c = true
        );

        Id agentRtId = getAgentRecordTypeId();

        if (agentRtId != null) {
            agent.RecordTypeId = agentRtId;
        }

        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier ' + String.valueOf(renewalDays),
            Supported_Lines_of_Business__c = 'Medicare',
            Supports_Medicare__c = true
        );
        insert carrier;

        Appointment__c appt = new Appointment__c(
            Agent__c = agent.Id,
            Agency__c = acc.Id,
            Carrier__c = carrier.Id,
            State_s__c = 'AK',
            Line_Of_Business__c = 'Medicare',
            Status__c = statusVal,
            Renewal_Date__c = Date.today().addDays(renewalDays)
        );
        insert appt;

        return appt;
    }

    @IsTest
    static void testBatchProcessesEligibleAppointment() {

        // Only one eligible appointment is created.
        createAppointment(30, 'Active');

        Test.startTest();

        Id batchJobId = Database.executeBatch(
            new AppointmentRenewalAlertBatch(),
            200
        );

        Test.stopTest();

        AsyncApexJob batchJob = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :batchJobId
        ];

        System.assertEquals(
            'Completed',
            batchJob.Status,
            'Batch must complete successfully.'
        );

        System.assertEquals(
            0,
            batchJob.NumberOfErrors,
            'Batch should not contain errors.'
        );

        System.assertEquals(
            1,
            batchJob.JobItemsProcessed,
            'One eligible appointment must be processed.'
        );
    }

    @IsTest
    static void testBatchIgnoresAppointmentBeyond90Days() {

        createAppointment(120, 'Active');

        Test.startTest();

        Id batchJobId = Database.executeBatch(
            new AppointmentRenewalAlertBatch(),
            200
        );

        Test.stopTest();

        AsyncApexJob batchJob = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :batchJobId
        ];

        System.assertEquals(
            'Completed',
            batchJob.Status
        );

        System.assertEquals(
            0,
            batchJob.NumberOfErrors
        );

        System.assertEquals(
            0,
            batchJob.JobItemsProcessed,
            'An appointment beyond 90 days must not be processed.'
        );
    }

    @IsTest
    static void testBatchIgnoresInactiveAppointment() {

        createAppointment(30, 'Inactive');

        Test.startTest();

        Id batchJobId = Database.executeBatch(
            new AppointmentRenewalAlertBatch(),
            200
        );

        Test.stopTest();

        AsyncApexJob batchJob = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :batchJobId
        ];

        System.assertEquals(
            'Completed',
            batchJob.Status
        );

        System.assertEquals(
            0,
            batchJob.NumberOfErrors
        );

        System.assertEquals(
            0,
            batchJob.JobItemsProcessed,
            'Inactive appointments must not be processed.'
        );
    }

    @IsTest
    static void testScheduler() {

        createAppointment(15, 'Active');

        Test.startTest();

        String jobId = System.schedule(
            'Appointment Renewal Scheduler Test',
            '0 0 0 1 1 ? 2099',
            new AppointmentRenewalAlertScheduler()
        );

        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'The scheduler must create a job Id.'
        );
    }
}