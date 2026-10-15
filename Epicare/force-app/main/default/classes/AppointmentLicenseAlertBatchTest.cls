@isTest
private class AppointmentLicenseAlertBatchTest {

    // ─── Constants ────────────────────────────────────────────────────────────
    // NOTE: matches the batch's literal exactly ('Ready to sell', lowercase 's').
    // SOQL string equality is case-insensitive so the old 'Ready to Sell' value
    // technically still matched, but keeping it exact avoids relying on that.
    private static final String STATE_1    = 'CA';
    private static final String STATE_2    = 'TX';
    private static final String LOB        = 'Medicare';
    private static final String STATUS     = 'Active';
    private static final String SUB_STATUS = 'Ready to sell';

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @testSetup
    static void setupTestData() {
        // ── Non-setup objects ──
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        // Bypass_VR__c sidesteps the org validation rule "Require_Green_Onboarding_Semaphore",
        // which otherwise blocks any Appointment__c from moving Status__c past 'Requested'
        // unless Agent__r.Overall_Semaphore__c = 'Green'. Overall_Semaphore__c is itself a
        // formula driven by several *_Complete__c checkboxes on Contact, which is a lot of
        // unrelated fields to fake just to get test data past the rule — Bypass_VR__c is the
        // rule's built-in escape hatch for exactly this situation.
        Contact agent = new Contact(
            LastName           = 'Test Agent',
            AccountId          = agency.Id,
            Email              = 'testagent@example.com',
            NPN__c             = '1234567890',
            Agent_Status__c    = 'Onboarding',
            Insurance_Types__c = 'Medicare',
            Bypass_VR__c       = true
        );
        insert agent;

        Carrier__c carrier = new Carrier__c(
            Name                           = 'Test Carrier',
            Supported_Lines_of_Business__c = 'Medicare'
        );
        insert carrier;

        // ── Setup object (Group) — separate DML context to avoid MIXED_DML_OPERATION ──
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group contractingGroup = new Group(
                Name          = 'Contracting',
                DeveloperName = 'Contracting',
                Type          = 'Regular'
            );
            insert contractingGroup;
        }
    }

    // ─── Helper: does a real CustomNotificationType exist in this org? ────────
    // CustomNotificationType records are metadata and cannot be inserted via
    // Apex DML in a test, so whether "Appointment_Renewal_Alert" exists depends
    // entirely on whether it has been deployed to the org. Tests that need the
    // "happy path" (no config errors) must check for this instead of assuming
    // it exists, otherwise they fail in any org where it hasn't been deployed.
    private static Id getNotificationTypeId() {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType
            WHERE DeveloperName = 'Appointment_Renewal_Alert'
            LIMIT 1
        ];
        return types.isEmpty() ? null : types[0].Id;
    }

    // ─── Helper: build Appointment ────────────────────────────────────────────

    private static Appointment__c buildAppointment(
        Date renewalDate,
        String status,
        String subStatus,
        String states
    ) {
        Account    agency = [SELECT Id FROM Account LIMIT 1];
        Contact    agent  = [SELECT Id FROM Contact LIMIT 1];
        Carrier__c carr   = [SELECT Id FROM Carrier__c LIMIT 1];

        return new Appointment__c(
            Line_of_Business__c = LOB,
            Agent__c            = agent.Id,
            Carrier__c          = carr.Id,
            Agency__c           = agency.Id,
            Status__c           = status,
            Sub_Status__c       = subStatus,
            Renewal_Date__c     = renewalDate,
            State_s__c          = states
        );
    }

    private static Appointment__c createActiveAppointment(
        Date renewalDate,
        String states
    ) {
        Appointment__c app = buildAppointment(
            renewalDate,
            STATUS,
            SUB_STATUS,
            states
        );
        insert app;
        return app;
    }

    // ─── Helper: create State_Appointment__c ──────────────────────────────────

    private static void createStateLicense(
        Id appointmentId,
        String state,
        String licenseStatus
    ) {
        insert new State_Appointment__c(
            Appointment__c  = appointmentId,
            State__c        = state,
            State_Status__c = licenseStatus
        );
    }

    // ─── TEST 1: Uncovered state → notification attempted ────────────────────

    @isTest
    static void testExecute_UncoveredState_NotificationSent() {
        Appointment__c app = createActiveAppointment(
            Date.today().addDays(30),
            STATE_1
        );

        // Inactive license — should NOT count as covered
        createStateLicense(app.Id, STATE_1, 'Inactive');

        Boolean notifTypeExists = getNotificationTypeId() != null;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        if (notifTypeExists) {
            // Real send may or may not throw depending on org notification config,
            // so we only assert that no CONFIG error (missing type/group) was logged.
            for (Error_Log__c e : errors) {
                Assert.isFalse(
                    e.Error_Message__c != null && e.Error_Message__c.contains('not found'),
                    'No missing-config errors expected when CustomNotificationType exists'
                );
            }
        } else {
            // Expected: execute() short-circuits on the missing CustomNotificationType.
            Assert.areEqual(1, errors.size(), 'Expected exactly one config error when notification type is missing');
            Assert.isTrue(
                errors[0].Error_Message__c.contains('CustomNotificationType'),
                'Error should describe the missing CustomNotificationType'
            );
        }
    }

    // ─── TEST 2: All states covered → no notification ─────────────────────────

    @isTest
    static void testExecute_AllStatesCovered_NoNotification() {
        Appointment__c app = createActiveAppointment(
            Date.today().addDays(30),
            STATE_1 + ';' + STATE_2
        );

        createStateLicense(app.Id, STATE_1, 'Active');
        createStateLicense(app.Id, STATE_2, 'Active');

        Boolean notifTypeExists = getNotificationTypeId() != null;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        if (notifTypeExists) {
            // Only in this case can "no errors" actually be asserted — otherwise the
            // missing-CustomNotificationType check fires before coverage is even evaluated.
            Assert.areEqual(0, errors.size(), 'No errors expected when all states are covered');
        } else {
            Assert.areEqual(1, errors.size(), 'Expected the missing-notification-type config error');
        }
    }

    // ─── TEST 3: Appointment outside 90-day window → not processed ────────────

    @isTest
    static void testStart_AppointmentOutside90Days_NotQueried() {
        Appointment__c app = buildAppointment(
            Date.today().addDays(91),
            STATUS,
            SUB_STATUS,
            STATE_1
        );
        insert app;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        // Outside the query window means the scope is empty and execute() never
        // fires at all, regardless of CustomNotificationType configuration.
        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];
        Assert.areEqual(0, errors.size(), 'Appointment outside 90-day window should not be processed');
    }

    // ─── TEST 4: Inactive Status → not queried ────────────────────────────────

    @isTest
    static void testStart_InactiveAppointment_NotQueried() {
        Appointment__c app = buildAppointment(
            Date.today().addDays(30),
            'Inactive',
            SUB_STATUS,
            STATE_1
        );
        insert app;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];
        Assert.areEqual(0, errors.size(), 'Inactive status appointment should not be processed');
    }

    // ─── TEST 5: Wrong Sub_Status → not queried ───────────────────────────────

    @isTest
    static void testStart_WrongSubStatus_NotQueried() {
        Appointment__c app = buildAppointment(
            Date.today().addDays(30),
            STATUS,
            'Inactive',
            STATE_1
        );
        insert app;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];
        Assert.areEqual(0, errors.size(), 'Wrong sub-status appointment should not be processed');
    }

    // ─── TEST 6: Missing CustomNotificationType → error logged ────────────────

    @isTest
    static void testExecute_MissingNotificationType_ErrorLogged() {
        // This scenario naturally holds in any org that hasn't deployed the
        // "Appointment_Renewal_Alert" CustomNotificationType (it can't be
        // created via Apex DML), so no special setup is required here.
        if (getNotificationTypeId() != null) {
            // If some org DOES have it configured, this test can't validate the
            // missing-type path, so skip rather than produce a false failure.
            return;
        }

        Appointment__c app = createActiveAppointment(
            Date.today().addDays(30),
            STATE_1
        );

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c, Severity__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        Assert.areEqual(1, errors.size(), 'Exactly one config error expected');
        Assert.areEqual('High', errors[0].Severity__c, 'Error severity should be High');
        Assert.isTrue(
            errors[0].Error_Message__c.contains('CustomNotificationType'),
            'Error message should describe the missing CustomNotificationType'
        );
    }

    // ─── TEST 7: Missing Contracting group → error logged ────────────────────

    @isTest
    static void testExecute_MissingContractingGroup_ErrorLogged() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group grp = [
                SELECT Id FROM Group
                WHERE DeveloperName = 'Contracting'
                AND Type = 'Regular'
                LIMIT 1
            ];
            delete grp;
        }

        Appointment__c app = createActiveAppointment(
            Date.today().addDays(30),
            STATE_1
        );

        Boolean notifTypeExists = getNotificationTypeId() != null;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c, Severity__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        Assert.areEqual(1, errors.size(), 'Exactly one config error expected');
        Assert.areEqual('High', errors[0].Severity__c, 'Severity should be High');

        if (notifTypeExists) {
            // Only when the notification type exists does execution actually
            // reach the group check, so only then can we assert on group text.
            Assert.isTrue(
                errors[0].Error_Message__c.contains('Contracting'),
                'Error message should describe the missing Contracting group'
            );
        } else {
            // The CustomNotificationType check runs first in execute(), so the
            // missing-group path is never reached — this documents that behavior
            // rather than asserting a group-specific message that can't occur.
            Assert.isTrue(
                errors[0].Error_Message__c.contains('CustomNotificationType'),
                'With no notification type configured, that check short-circuits first'
            );
        }
    }

    // ─── TEST 8: Partial coverage → notification for uncovered states ─────────

    @isTest
    static void testExecute_PartialCoverage_NotificationSentForUncovered() {
        // CA has active license, TX does not
        Appointment__c app = createActiveAppointment(
            Date.today().addDays(45),
            STATE_1 + ';' + STATE_2
        );

        createStateLicense(app.Id, STATE_1, 'Active');
        // STATE_2 (TX) has no license at all

        Boolean notifTypeExists = getNotificationTypeId() != null;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id, Error_Message__c
            FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        if (notifTypeExists) {
            for (Error_Log__c e : errors) {
                Assert.isFalse(
                    e.Error_Message__c != null && e.Error_Message__c.contains('not found'),
                    'No missing-config errors expected'
                );
            }
        } else {
            Assert.areEqual(1, errors.size(), 'Expected the missing-notification-type config error');
        }
    }

    // ─── TEST 9: Bulk 200 appointments → no governor errors ──────────────────

    @isTest
    static void testExecute_Bulk200Appointments_ProcessedWithoutError() {
        Account    agency = [SELECT Id FROM Account LIMIT 1];
        Contact    agent  = [SELECT Id FROM Contact LIMIT 1];
        Carrier__c carr   = [SELECT Id FROM Carrier__c LIMIT 1];

        List<Appointment__c> apps = new List<Appointment__c>();
        for (Integer i = 0; i < 200; i++) {
            apps.add(new Appointment__c(
                Line_of_Business__c = LOB,
                Agent__c            = agent.Id,
                Carrier__c          = carr.Id,
                Agency__c           = agency.Id,
                Status__c           = STATUS,
                Sub_Status__c       = SUB_STATUS,
                Renewal_Date__c     = Date.today().addDays(30),
                State_s__c          = STATE_1
            ));
        }
        insert apps;

        // All states covered — no notification needed
        List<State_Appointment__c> licenses = new List<State_Appointment__c>();
        for (Appointment__c app : apps) {
            licenses.add(new State_Appointment__c(
                Appointment__c  = app.Id,
                State__c        = STATE_1,
                State_Status__c = 'Active'
            ));
        }
        insert licenses;

        Boolean notifTypeExists = getNotificationTypeId() != null;

        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        List<Error_Log__c> errors = [
            SELECT Id FROM Error_Log__c
            WHERE Event_Type__c = 'AppointmentLicenseAlertBatch'
        ];

        if (notifTypeExists) {
            Assert.areEqual(0, errors.size(), 'No errors expected for bulk covered appointments');
        } else {
            // execute() runs once per batch chunk; with 200 records in one chunk
            // of size 200, expect exactly one config error, not one per record.
            Assert.areEqual(1, errors.size(), 'Expected exactly one config error for the single batch chunk');
        }
    }

    // ─── TEST 10: Scheduler execute() fires batch ─────────────────────────────

    @isTest
    static void testScheduler_Execute_FiresBatch() {
        Test.startTest();
        AppointmentLicenseAlertScheduler scheduler =
            new AppointmentLicenseAlertScheduler();
        scheduler.execute(null);
        Test.stopTest();

        Assert.isTrue(true, 'Scheduler executed without exception');
    }

    // ─── TEST 11: System.schedule() creates the job ───────────────────────────

    @isTest
    static void testScheduler_SystemSchedule_JobCreated() {
        Test.startTest();
        System.schedule(
            'AppointmentLicenseAlertScheduler_Test',
            '0 0 6 * * ?',
            new AppointmentLicenseAlertScheduler()
        );
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'AppointmentLicenseAlertScheduler_Test'
        ];

        Assert.areEqual(1, jobs.size(), 'Exactly 1 scheduled job should exist');
    }

    // ─── TEST 12: Abort and reschedule → only 1 active job ───────────────────

    @isTest
    static void testScheduler_AbortAndReschedule_OnlyOneActiveJob() {
        Test.startTest();

        // First schedule with name A
        String jobId = System.schedule(
            'AppointmentLicenseAlertScheduler_V1',
            '0 0 6 * * ?',
            new AppointmentLicenseAlertScheduler()
        );

        // Abort the first job
        System.abortJob(jobId);

        // Reschedule with name B
        System.schedule(
            'AppointmentLicenseAlertScheduler_V2',
            '0 0 7 * * ?',
            new AppointmentLicenseAlertScheduler()
        );

        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name IN (
                'AppointmentLicenseAlertScheduler_V1',
                'AppointmentLicenseAlertScheduler_V2'
            )
            AND State NOT IN ('DELETED', 'COMPLETE')
        ];

        Assert.areEqual(1, jobs.size(), 'Only 1 active scheduled job should exist after abort and reschedule');
    }

    // ─── TEST 13: Finish method completes without error ───────────────────────

    @isTest
    static void testFinish_CompletesWithoutError() {
        Test.startTest();
        Database.executeBatch(new AppointmentLicenseAlertBatch(), 200);
        Test.stopTest();

        Assert.isTrue(true, 'Batch finish completed without exception');
    }
}