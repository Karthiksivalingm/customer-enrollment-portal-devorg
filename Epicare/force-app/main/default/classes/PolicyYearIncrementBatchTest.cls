/**
 * PolicyYearIncrementBatchTest
 * ------------------------------------------------------------------
 * SCHEMA ASSUMPTIONS ON SUPPORTING OBJECTS (please correct if any
 * insert below throws a validation error — these are inferred from
 * this org's other test classes and execution-log runs, not from any
 * visibility into Contact/Carrier__c/Commission_Record__c validation
 * rules themselves):
 *
 *   - Upline_Policy__c has a Flow ("Upline Policy Key Auto-Populate")
 *     that derives Upline_Policy_Key__c from other fields on the
 *     record (confirmed via execution log — left blank, every policy
 *     resolves to the same key and collides with DUPLICATE_VALUE on a
 *     second insert). createPolicy()/createInactivePolicy() below
 *     give each policy its own Carrier__c to differentiate the
 *     derived key. If the real key is built from a different field
 *     (e.g. Agent__c or a Policy Number), swap that in instead.
 *   - Upline_Policy__c.Status__c's non-"Active" value is looked up
 *     dynamically from the picklist's own metadata (getNonActiveStatusValue())
 *     rather than hardcoded, since "Inactive" turned out not to be a
 *     valid value in this org's restricted picklist.
 *   - Commission_Record__c requires Agent__c and Payment_Batch__c
 *     (this mirrors what was needed for Commission_Record__c inserts
 *     elsewhere in this org) in addition to Upline_Policy__c and
 *     Status__c = 'Paid', which are the fields this batch actually
 *     queries on.
 *   - Commission_Record__c.Status__c is also a restricted picklist,
 *     same as Upline_Policy__c.Status__c above — 'Pending' is not a
 *     valid value (confirmed via execution log:
 *     INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST). The non-'Paid' value
 *     used for "not yet paid" test records is looked up dynamically
 *     from the picklist metadata (getNonPaidCommissionStatusValue())
 *     instead of hardcoded.
 *   - The shared agent Contact requires NPN__c
 *     (FIELD_CUSTOM_VALIDATION_EXCEPTION: "NPN is required for all
 *     agents" — confirmed via execution log) plus Agent_Status__c /
 *     Insurance_Types__c, matching the agent setup already used in
 *     this org's other test classes.
 *
 * BATCH/SCHEDULER BEHAVIOR — CONFIRMED AGAINST SOURCE:
 * With PolicyYearIncrementBatch and PolicyYearIncrementScheduler now
 * in hand (rather than inferred from execution logs alone), the
 * following are confirmed, not assumed:
 *   - start() queries Upline_Policy__c WHERE Status__c = 'Active'
 *     only — no other status filter, so any non-"Active" value is
 *     excluded regardless of what it actually is.
 *   - execute() counts Commission_Record__c via a GROUP BY aggregate
 *     restricted to Status__c = 'Paid'; policies with zero matching
 *     rows simply never appear in the aggregate map (handled via
 *     containsKey(), not a zero default row).
 *   - Both Policy_Year__c and Last_Paid_Count_Snapshot__c are read
 *     with a null-safe ternary defaulting to 0 before any arithmetic.
 *   - yearsToAdd = (currentPaidCount - snapshot) / 12 using Apex's
 *     integer division (floor). The snapshot only advances by
 *     yearsToAdd * 12 — i.e. whole consumed windows — never by the
 *     raw paid count, which is what keeps partial progress and
 *     repeated runs safe (see tests 2, 3, and 7 below).
 *   - PolicyYearIncrementScheduler.execute() calls
 *     Database.executeBatch(new PolicyYearIncrementBatch(), 200)
 *     directly with no other logic, so calling
 *     .execute(null) synchronously (test 12b) is a faithful,
 *     side-effect-equivalent way to drive the batch to completion.
 *
 * TESTING NOTE ON Schedulable + Batchable: Test.stopTest() runs a
 * System.schedule()'d job synchronously, but a Database.executeBatch()
 * call made from inside that already-synchronously-running scheduled
 * job is NOT itself flushed in the same pass (confirmed via execution
 * log — the batch gets constructed but never actually runs). Testing
 * the schedule registration (CronTrigger) and testing the batch's
 * effect are therefore split into two tests below: one calls
 * System.schedule() and checks CronTrigger; the other calls
 * PolicyYearIncrementScheduler().execute(null) directly — an ordinary
 * synchronous method call — so its own Database.executeBatch() is the
 * top-level async operation and gets flushed correctly.
 */
@IsTest
private class PolicyYearIncrementBatchTest {

    /*
     * ============================================================
     * TEST DATA HELPERS
     * ============================================================
     */

    private static Contact sharedAgent;
    private static Payment_Batch__c sharedPaymentBatch;

    @TestSetup
    static void setupData() {

        // NPN__c is required for all agent Contacts in this org
        // (FIELD_CUSTOM_VALIDATION_EXCEPTION: "NPN is required for all
        // agents"), and Agent_Status__c / Insurance_Types__c mirror the
        // agent Contact setup already working elsewhere in this org's
        // test classes. DMLOptions bypasses the duplicate-rule block
        // seen on Contact inserts in those same classes.
        Contact agent = new Contact(
            LastName            = 'Policy Year Test Agent',
            Email               = 'policy.year.test.agent@test.com',
            NPN__c              = '99000001',
            Agent_Status__c     = 'Onboarding',
            Insurance_Types__c  = 'Life'
        );
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.insert(agent, dml);

        Payment_Batch__c batch = new Payment_Batch__c(
            Status__c          = 'Draft',
            Payment_Period__c  = '2026-08'
        );
        insert batch;
    }

    private static Contact getSharedAgent() {
        if (sharedAgent == null) {
            sharedAgent = [SELECT Id FROM Contact LIMIT 1];
        }
        return sharedAgent;
    }

    private static Payment_Batch__c getSharedPaymentBatch() {
        if (sharedPaymentBatch == null) {
            sharedPaymentBatch = [SELECT Id FROM Payment_Batch__c LIMIT 1];
        }
        return sharedPaymentBatch;
    }

    // A "Upline Policy Key Auto-Populate" Flow derives
    // Upline_Policy_Key__c from other fields on the record (confirmed
    // via execution log). Left blank, every test policy resolves to
    // the same key ("_"), and a second insert in the same test method
    // collides with DUPLICATE_VALUE. Giving each policy its own
    // Carrier__c (a field already used elsewhere on Commission_Record__c
    // and Appointment__c in this org) is enough to differentiate the
    // derived key. If Upline_Policy__c actually keys off a different
    // field (e.g. Agent__c or a Policy Number), add that here instead.
    private static Integer policyCounter = 0;

    private static Carrier__c createUniqueCarrier() {
        policyCounter++;
        Carrier__c carrier = new Carrier__c(
            Name                             = 'Policy Year Test Carrier ' + policyCounter,
            Supported_Lines_of_Business__c   = 'Life'
        );
        insert carrier;
        return carrier;
    }

    // Looks up a real, active, non-"Active" value from the actual
    // Status__c picklist metadata rather than guessing a literal
    // string — "Inactive" turned out not to be a valid value in this
    // org's restricted picklist (INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST,
    // confirmed via execution log).
    private static String getNonActiveStatusValue() {
        Schema.DescribeFieldResult statusFieldDescribe =
            Upline_Policy__c.Status__c.getDescribe();

        for (
            Schema.PicklistEntry entry :
            statusFieldDescribe.getPicklistValues()
        ) {
            if (entry.isActive() && entry.getValue() != 'Active') {
                return entry.getValue();
            }
        }
        System.assert(
            false,
            'Expected at least one active, non-"Active" value on ' +
            'Upline_Policy__c.Status__c.'
        );
        return null;
    }

    // Same restricted-picklist situation as Upline_Policy__c.Status__c
    // above, discovered the same way (confirmed via execution log:
    // INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, "bad value for restricted
    // picklist field: Pending: [Status__c]"). 'Pending' is not a valid
    // value in this org's restricted Commission_Record__c.Status__c
    // picklist, so the non-'Paid' value used for "not yet paid" test
    // records is looked up dynamically instead of hardcoded.
    private static String getNonPaidCommissionStatusValue() {
        Schema.DescribeFieldResult statusFieldDescribe =
            Commission_Record__c.Status__c.getDescribe();

        for (
            Schema.PicklistEntry entry :
            statusFieldDescribe.getPicklistValues()
        ) {
            if (entry.isActive() && entry.getValue() != 'Paid') {
                return entry.getValue();
            }
        }
        System.assert(
            false,
            'Expected at least one active, non-"Paid" value on ' +
            'Commission_Record__c.Status__c.'
        );
        return null;
    }

    private static Upline_Policy__c createPolicy(
        Decimal policyYear,
        Decimal snapshot
    ) {
        Upline_Policy__c policy = new Upline_Policy__c(
            Status__c                    = 'Active',
            Policy_Year__c                = policyYear,
            Last_Paid_Count_Snapshot__c   = snapshot,
            Carrier__c                    = createUniqueCarrier().Id
        );
        insert policy;
        return policy;
    }

    private static Upline_Policy__c createInactivePolicy(
        Decimal policyYear,
        Decimal snapshot
    ) {
        Upline_Policy__c policy = new Upline_Policy__c(
            Status__c                    = getNonActiveStatusValue(),
            Policy_Year__c                = policyYear,
            Last_Paid_Count_Snapshot__c   = snapshot,
            Carrier__c                    = createUniqueCarrier().Id
        );
        insert policy;
        return policy;
    }

    private static void createPaidCommissionRecords(
        Id policyId,
        Integer count
    ) {
        List<Commission_Record__c> records = new List<Commission_Record__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(new Commission_Record__c(
                Agent__c          = getSharedAgent().Id,
                Payment_Batch__c  = getSharedPaymentBatch().Id,
                Upline_Policy__c  = policyId,
                Status__c         = 'Paid'
            ));
        }
        if (!records.isEmpty()) {
            insert records;
        }
    }

    private static void createUnpaidCommissionRecords(
        Id policyId,
        Integer count
    ) {
        List<Commission_Record__c> records = new List<Commission_Record__c>();
        for (Integer i = 0; i < count; i++) {
            records.add(new Commission_Record__c(
                Agent__c          = getSharedAgent().Id,
                Payment_Batch__c  = getSharedPaymentBatch().Id,
                Upline_Policy__c  = policyId,
                Status__c         = getNonPaidCommissionStatusValue()
            ));
        }
        if (!records.isEmpty()) {
            insert records;
        }
    }

    private static Upline_Policy__c requery(Id policyId) {
        return [
            SELECT Id, Policy_Year__c, Last_Paid_Count_Snapshot__c, Status__c
            FROM Upline_Policy__c
            WHERE Id = :policyId
        ];
    }

    /*
     * ============================================================
     * 1. EXACTLY 12 NEW PAID RECORDS -> ONE YEAR INCREMENT
     * ============================================================
     */
    @IsTest
    static void testExactlyTwelveNewPaidRecordsAddsOneYear() {

        Upline_Policy__c policy = createPolicy(5, 0);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            6,
            updated.Policy_Year__c.intValue(),
            'Policy_Year__c should advance by exactly 1.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should advance by exactly 12 (one full window).'
        );
    }

    /*
     * ============================================================
     * 2. PARTIAL PROGRESS PAST 12 IS NOT LOST OR DOUBLE-COUNTED
     * ============================================================
     * 23 paid records / 12 = 1 (floor), with 11 left over. The
     * snapshot should only advance by 12 (one consumed window), not
     * jump all the way to 23 — otherwise the leftover 11 would be
     * silently lost and never count toward the next year.
     */
    @IsTest
    static void testPartialProgressPastTwelveIsPreserved() {

        Upline_Policy__c policy = createPolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 23);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            1,
            updated.Policy_Year__c.intValue(),
            'Only one full 12-record window has been consumed.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should advance by exactly one window (12), leaving 11 unconsumed.'
        );
    }

    /*
     * ============================================================
     * 3. MULTIPLE FULL WINDOWS IN A SINGLE RUN
     * ============================================================
     * 25 paid records / 12 = 2 (floor). Both years should apply at
     * once, and the snapshot should advance by 24 (two windows), not
     * 25 — leaving exactly 1 unconsumed record.
     */
    @IsTest
    static void testMultipleFullWindowsInOneRun() {

        Upline_Policy__c policy = createPolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 25);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            2,
            updated.Policy_Year__c.intValue(),
            'Two full 12-record windows should be consumed in one run.'
        );

        System.assertEquals(
            24,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should advance by exactly 24 (two windows), leaving 1 unconsumed.'
        );
    }

    /*
     * ============================================================
     * 4. FEWER THAN 12 NEW PAID RECORDS -> NO CHANGE
     * ============================================================
     */
    @IsTest
    static void testBelowThresholdMakesNoChange() {

        Upline_Policy__c policy = createPolicy(3, 0);

        createPaidCommissionRecords(policy.Id, 11);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            3,
            updated.Policy_Year__c.intValue(),
            'Policy_Year__c should be untouched below the 12-record threshold.'
        );

        System.assertEquals(
            0,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should be untouched below the 12-record threshold.'
        );
    }

    /*
     * ============================================================
     * 5. NO PAID COMMISSION RECORDS AT ALL -> NO CHANGE
     * ============================================================
     * Covers the branch where the policy doesn't appear in the
     * aggregate result map at all (paidCountByPolicy.containsKey()
     * is false), as distinct from "some but not enough" above.
     */
    @IsTest
    static void testNoPaidRecordsMakesNoChange() {

        Upline_Policy__c policy = createPolicy(1, 0);

        // No Commission_Record__c rows created at all for this policy.

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            1,
            updated.Policy_Year__c.intValue(),
            'Policy_Year__c should be untouched with zero paid records.'
        );

        System.assertEquals(
            0,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should be untouched with zero paid records.'
        );
    }

    /*
     * ============================================================
     * 6. ALREADY CAUGHT UP -> NO CHANGE (IDEMPOTENCY, SINGLE RUN)
     * ============================================================
     * Snapshot already equals the current paid count, so there's
     * nothing new to consume even though 12 Paid records exist.
     */
    @IsTest
    static void testSnapshotAlreadyCaughtUpMakesNoChange() {

        Upline_Policy__c policy = createPolicy(4, 12);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            4,
            updated.Policy_Year__c.intValue(),
            'Policy_Year__c should be untouched once the snapshot has caught up.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Snapshot should remain unchanged once caught up.'
        );
    }

    /*
     * ============================================================
     * 7. IDEMPOTENCY ACROSS TWO RUNS
     * ============================================================
     * Running the batch twice in a row with no new
     * Commission_Record__c rows created in between should be a
     * complete no-op on the second run — this is the "safe to run
     * daily" guarantee called out in the class header.
     *
     * Both executeBatch() calls are issued inside a single
     * Test.startTest()/Test.stopTest() window (Apex only allows one
     * such window per test method) rather than checking state between
     * two separately-flushed runs. Since a buggy, non-idempotent
     * implementation would double-count and land on Policy_Year__c =
     * 2 here instead of 1, asserting the final state after both runs
     * still proves the second run did nothing.
     */
    @IsTest
    static void testSecondRunWithNoNewRecordsIsANoOp() {

        Upline_Policy__c policy = createPolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            1,
            updated.Policy_Year__c.intValue(),
            'Running the batch twice in a row with no new paid records in ' +
            'between should still land on exactly 1 year advanced, not 2 — ' +
            'the second run must be a complete no-op.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'The snapshot should not move on the second, no-op run.'
        );
    }

    /*
     * ============================================================
     * 8. NULL Policy_Year__c AND Last_Paid_Count_Snapshot__c
     * ============================================================
     * Both fields should be treated as 0 when null, per the ternary
     * guards in the batch — this is the more realistic starting
     * state for a brand-new policy that's never been processed.
     */
    @IsTest
    static void testNullStartingFieldsAreTreatedAsZero() {

        Upline_Policy__c policy = createPolicy(null, null);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            1,
            updated.Policy_Year__c.intValue(),
            'Null Policy_Year__c should be treated as 0 before adding.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'Null Last_Paid_Count_Snapshot__c should be treated as 0 before adding.'
        );
    }

    /*
     * ============================================================
     * 9. INACTIVE POLICIES ARE EXCLUDED
     * ============================================================
     */
    @IsTest
    static void testInactivePolicyIsNotProcessed() {

        Upline_Policy__c policy = createInactivePolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            0,
            updated.Policy_Year__c.intValue(),
            'A non-Active policy should never be picked up by the batch query.'
        );

        System.assertEquals(
            0,
            updated.Last_Paid_Count_Snapshot__c.intValue(),
            'A non-Active policy should never be picked up by the batch query.'
        );
    }

    /*
     * ============================================================
     * 10. NON-PAID COMMISSION RECORDS DON'T COUNT
     * ============================================================
     */
    @IsTest
    static void testNonPaidCommissionRecordsAreNotCounted() {

        Upline_Policy__c policy = createPolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 5);
        createUnpaidCommissionRecords(policy.Id, 20);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            0,
            updated.Policy_Year__c.intValue(),
            'Only Status__c = \'Paid\' records should count toward the window, ' +
            'regardless of how many non-Paid records exist.'
        );

        System.assertEquals(
            0,
            updated.Last_Paid_Count_Snapshot__c.intValue()
        );
    }

    /*
     * ============================================================
     * 11. BULK: MULTIPLE POLICIES WITH DIFFERENT OUTCOMES IN ONE RUN
     * ============================================================
     * Verifies the batch's per-policy aggregate map doesn't cross-
     * contaminate between records in the same execute() scope.
     */
    @IsTest
    static void testBulkMultiplePoliciesWithMixedOutcomes() {

        Upline_Policy__c reachesOneYear   = createPolicy(0, 0);
        Upline_Policy__c reachesTwoYears  = createPolicy(0, 0);
        Upline_Policy__c belowThreshold   = createPolicy(0, 0);
        Upline_Policy__c alreadyCaughtUp  = createPolicy(2, 12);
        Upline_Policy__c inactiveIgnored  = createInactivePolicy(0, 0);

        createPaidCommissionRecords(reachesOneYear.Id, 12);
        createPaidCommissionRecords(reachesTwoYears.Id, 24);
        createPaidCommissionRecords(belowThreshold.Id, 7);
        createPaidCommissionRecords(alreadyCaughtUp.Id, 12);
        createPaidCommissionRecords(inactiveIgnored.Id, 12);

        Test.startTest();
        Database.executeBatch(new PolicyYearIncrementBatch(), 200);
        Test.stopTest();

        System.assertEquals(
            1,
            requery(reachesOneYear.Id).Policy_Year__c.intValue()
        );

        System.assertEquals(
            2,
            requery(reachesTwoYears.Id).Policy_Year__c.intValue()
        );

        System.assertEquals(
            0,
            requery(belowThreshold.Id).Policy_Year__c.intValue()
        );

        System.assertEquals(
            2,
            requery(alreadyCaughtUp.Id).Policy_Year__c.intValue()
        );

        System.assertEquals(
            0,
            requery(inactiveIgnored.Id).Policy_Year__c.intValue()
        );
    }

    /*
     * ============================================================
     * 12a. SCHEDULER: REGISTERS WITH THE EXPECTED CRON EXPRESSION
     * ============================================================
     * Verifies System.schedule() itself, independent of the batch it
     * eventually kicks off — see 12b below for why those two things
     * need separate tests here.
     */
    @IsTest
    static void testSchedulerRegistersWithExpectedCron() {

        Test.startTest();

        String jobId = System.schedule(
            'Policy Year Increment Test',
            '0 0 0 15 3 ? 2099',
            new PolicyYearIncrementScheduler()
        );

        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(
            '0 0 0 15 3 ? 2099',
            ct.CronExpression,
            'The scheduled job should be registered with the expected CRON expression.'
        );
    }

    /*
     * ============================================================
     * 12b. SCHEDULER: execute() ACTUALLY RUNS THE BATCH TO COMPLETION
     * ============================================================
     * Test.stopTest() does run a System.schedule()'d job synchronously
     * (confirmed via execution log — PolicyYearIncrementScheduler's
     * execute() does fire), but the Database.executeBatch() call made
     * FROM INSIDE that already-synchronously-flushing scheduled job
     * does not itself get flushed in the same pass: the log shows
     * PolicyYearIncrementBatch getting constructed but its start()/
     * execute() never actually running. Calling
     * PolicyYearIncrementScheduler.execute(null) directly here — a
     * perfectly ordinary synchronous method call, nothing async or
     * restricted about it — makes the Database.executeBatch() call
     * the top-level async operation instead of a nested one, so this
     * test's own Test.stopTest() flushes it properly, matching every
     * other direct-executeBatch test above.
     */
    @IsTest
    static void testSchedulerExecuteRunsBatchToCompletion() {

        Upline_Policy__c policy = createPolicy(0, 0);

        createPaidCommissionRecords(policy.Id, 12);

        Test.startTest();

        new PolicyYearIncrementScheduler().execute(null);

        Test.stopTest();

        Upline_Policy__c updated = requery(policy.Id);

        System.assertEquals(
            1,
            updated.Policy_Year__c.intValue(),
            'PolicyYearIncrementScheduler.execute() should kick off the batch ' +
            'and it should run to completion, advancing the policy year.'
        );

        System.assertEquals(
            12,
            updated.Last_Paid_Count_Snapshot__c.intValue()
        );
    }
}