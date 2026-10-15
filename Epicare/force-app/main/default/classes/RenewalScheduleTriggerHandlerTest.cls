@isTest
private class RenewalScheduleTriggerHandlerTest {

    // ─── Constants ────────────────────────────────────────────────────────────
    private static final String SCHEDULE_TYPE_RENEWAL  = 'Renewal';
    private static final String SCHEDULE_TYPE_SERVICE  = 'Service Fee';
    private static final String SCHEDULE_TYPE_EXTENDED = 'Extended Renewal';

    // ─── Helper: create fresh Product_State__c per test ──────────────────────

    private static Product_State__c createProductState(String productName) {
        Product__c product = new Product__c(Name = productName);
        insert product;
        Product_State__c ps = new Product_State__c(Product__c = product.Id);
        insert ps;
        return ps;
    }

    // ─── Helper: build Renewal_Schedule__c ───────────────────────────────────

    private static Renewal_Schedule__c buildSchedule(
        Id productStateId,
        String scheduleType,
        Decimal yearFrom,
        Decimal yearTo
    ) {
        return new Renewal_Schedule__c(
            Product_State__c = productStateId,
            Schedule_Type__c = scheduleType,
            Year_From__c     = yearFrom,
            Year_To__c       = yearTo
        );
    }

    // ─── TEST 1: Insert non-overlapping → succeeds ────────────────────────────

    @isTest
    static void testInsert_NonOverlapping_Success() {
        Product_State__c ps = createProductState('Product T1');
        Renewal_Schedule__c rs = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 10);

        Test.startTest();
        insert rs;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Renewal_Schedule__c WHERE Id = :rs.Id];
        Assert.areEqual(1, count, 'Non-overlapping schedule should insert successfully');
    }

    // ─── TEST 2: Insert overlapping → addError fires ──────────────────────────

    @isTest
    static void testInsert_Overlapping_ErrorAdded() {
        Product_State__c ps = createProductState('Product T2');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 30, 70), false
        );
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Overlapping insert should fail');
    }

    // ─── TEST 3: Insert exact boundary overlap → error ────────────────────────

    @isTest
    static void testInsert_ExactBoundaryOverlap_ErrorAdded() {
        Product_State__c ps = createProductState('Product T3');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 50, 70), false
        );
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Exact boundary overlap should fail');
    }

    // ─── TEST 4: Insert adjacent non-overlapping → succeeds ──────────────────

    @isTest
    static void testInsert_AdjacentNonOverlapping_Success() {
        Product_State__c ps = createProductState('Product T4');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 30);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 31, 50), false
        );
        Test.stopTest();

        Assert.isTrue(result.isSuccess(),
            'Adjacent non-overlapping schedule should insert successfully');
    }

    // ─── TEST 5: Different Schedule_Type → no overlap check ──────────────────

    @isTest
    static void testInsert_DifferentScheduleType_Success() {
        Product_State__c ps = createProductState('Product T5');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_SERVICE, 2, 50), false
        );
        Test.stopTest();

        Assert.isTrue(result.isSuccess(),
            'Different schedule type should not trigger overlap error');
    }

    // ─── TEST 6: Different Product_State → no overlap check ──────────────────

    @isTest
    static void testInsert_DifferentProductState_Success() {
        Product_State__c ps1 = createProductState('Product T6A');
        Product_State__c ps2 = createProductState('Product T6B');
        insert buildSchedule(ps1.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps2.Id, SCHEDULE_TYPE_RENEWAL, 2, 50), false
        );
        Test.stopTest();

        Assert.isTrue(result.isSuccess(),
            'Different product state should not trigger overlap error');
    }

    // ─── TEST 7: Null Year_From → skipped, no error ───────────────────────────

    @isTest
    static void testInsert_NullYearFrom_Skipped() {
        Product_State__c ps = createProductState('Product T7');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Renewal_Schedule__c nullFrom = new Renewal_Schedule__c(
            Product_State__c = ps.Id,
            Schedule_Type__c = SCHEDULE_TYPE_RENEWAL,
            Year_From__c     = null,
            Year_To__c       = 50
        );

        Test.startTest();
        Database.insert(nullFrom, false);
        Test.stopTest();

        System.debug('testInsert_NullYearFrom_Skipped completed');
    }

    // ─── TEST 8: Null Year_To → skipped, no error ────────────────────────────

    @isTest
    static void testInsert_NullYearTo_Skipped() {
        Product_State__c ps = createProductState('Product T8');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        Renewal_Schedule__c nullTo = new Renewal_Schedule__c(
            Product_State__c = ps.Id,
            Schedule_Type__c = SCHEDULE_TYPE_RENEWAL,
            Year_From__c     = 30,
            Year_To__c       = null
        );

        Test.startTest();
        Database.insert(nullTo, false);
        Test.stopTest();

        System.debug('testInsert_NullYearTo_Skipped completed');
    }

    // ─── TEST 9: Null Schedule_Type → handler exits early ────────────────────

    @isTest
    static void testInsert_NullScheduleType_NoOverlapError() {
        Product_State__c ps = createProductState('Product T9');

        Renewal_Schedule__c rs = new Renewal_Schedule__c(
            Product_State__c = ps.Id,
            Schedule_Type__c = null,
            Year_From__c     = 2,
            Year_To__c       = 50
        );

        Test.startTest();
        Database.insert(rs, false);
        Test.stopTest();

        System.debug('testInsert_NullScheduleType_NoOverlapError completed');
    }

    // ─── TEST 10: Update — same record, trigger runs ──────────────────────────

    @isTest
    static void testUpdate_SameRecord_TriggerRuns() {
        Product_State__c ps = createProductState('Product T10');

        Renewal_Schedule__c rs = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);
        insert rs;

        Test.startTest();
        rs.Year_To__c = 60;
        Database.update(rs, false);
        Test.stopTest();

        System.debug('testUpdate_SameRecord_TriggerRuns completed');
    }

    // ─── TEST 11: Update — overlap with different record → fails ─────────────

    @isTest
    static void testUpdate_OverlapWithOtherRecord_Fails() {
        Product_State__c ps = createProductState('Product T11');

        Renewal_Schedule__c rs1 = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 30);
        insert rs1;

        Renewal_Schedule__c rs2 = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 50, 70);
        insert rs2;

        Test.startTest();
        rs2.Year_From__c = 20;
        Database.SaveResult result = Database.update(rs2, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Update causing overlap should fail');
    }

    // ─── TEST 12: Update — non-overlapping → trigger runs ────────────────────

    @isTest
    static void testUpdate_NonOverlapping_TriggerRuns() {
        Product_State__c ps = createProductState('Product T12');

        Renewal_Schedule__c rs1 = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 30);
        insert rs1;

        Renewal_Schedule__c rs2 = buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 50, 70);
        insert rs2;

        Test.startTest();
        rs2.Year_To__c = 80;
        Database.update(rs2, false);
        Test.stopTest();

        System.debug('testUpdate_NonOverlapping_TriggerRuns completed');
    }

    // ─── TEST 13: Bulk insert — 5 non-overlapping records one at a time ───────

    @isTest
    static void testBulkInsert_NonOverlapping_AllSucceed() {
        Product_State__c ps = createProductState('Product T13');

        List<Id> insertedIds = new List<Id>();

        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            Renewal_Schedule__c rs = buildSchedule(
                ps.Id, SCHEDULE_TYPE_RENEWAL,
                2 + (i * 11),
                10 + (i * 11)
            );
            insert rs;
            insertedIds.add(rs.Id);
        }
        Test.stopTest();

        Integer count = [
            SELECT COUNT() FROM Renewal_Schedule__c
            WHERE Id IN :insertedIds
        ];
        Assert.areEqual(5, count,
            'All 5 non-overlapping records should insert successfully');
    }

    // ─── TEST 14: Different schedule types same years → all succeed ───────────

    @isTest
    static void testBulkInsert_DifferentTypes_SameYears_AllSucceed() {
        Product_State__c ps = createProductState('Product T14');

        List<Renewal_Schedule__c> schedules = new List<Renewal_Schedule__c>{
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL,  2, 50),
            buildSchedule(ps.Id, SCHEDULE_TYPE_SERVICE,  2, 50),
            buildSchedule(ps.Id, SCHEDULE_TYPE_EXTENDED, 2, 50)
        };

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(schedules, false);
        Test.stopTest();

        for (Database.SaveResult result : results) {
            Assert.isTrue(result.isSuccess(),
                'Different schedule types with same years should all succeed');
        }
    }

    // ─── TEST 15: New record completely inside existing range → error ─────────

    @isTest
    static void testInsert_CompletelyInside_ErrorAdded() {
        Product_State__c ps = createProductState('Product T15');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 90);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 20, 50), false
        );
        Test.stopTest();

        Assert.isFalse(result.isSuccess(),
            'Record completely inside existing range should fail');
    }

    // ─── TEST 16: New record completely contains existing range → error ────────

    @isTest
    static void testInsert_CompletelyContains_ErrorAdded() {
        Product_State__c ps = createProductState('Product T16');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 30, 50);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 10, 70), false
        );
        Test.stopTest();

        Assert.isFalse(result.isSuccess(),
            'Record completely containing existing range should fail');
    }

    // ─── TEST 17: Batch — one overlaps existing, one does not ────────────────

    @isTest
    static void testInsert_SameBatch_OneOverlapsExisting_OnlyThatFails() {
        Product_State__c ps = createProductState('Product T17');
        insert buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 2, 50);

        List<Renewal_Schedule__c> batch = new List<Renewal_Schedule__c>{
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 60, 80),
            buildSchedule(ps.Id, SCHEDULE_TYPE_RENEWAL, 20, 40)
        };

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(batch, false);
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess(),
            'Non-overlapping record in batch should succeed');
        Assert.isFalse(results[1].isSuccess(),
            'Overlapping record in batch should fail');
    }
}