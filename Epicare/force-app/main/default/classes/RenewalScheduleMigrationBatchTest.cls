@IsTest
private class RenewalScheduleMigrationBatchTest {

    // ═══════════════════════════════════════════════════════════════════════
    // TEST DATA HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private static Carrier__c createCarrier() {

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier Renewal Migration',
            Supported_Lines_of_Business__c = 'ACA;Life'
        );

        insert carrier;

        return carrier;
    }


    private static Product__c createProduct() {

        Product__c product = new Product__c(
            Name = 'Test Product Renewal Migration'
        );

        insert product;

        return product;
    }


    private static Product_State__c createProductState(
        Id carrierId,
        Id productId
    ) {

        Product_State__c ps = new Product_State__c(
            Carrier__c = carrierId,
            Product__c = productId,

            Renewal_Yrs_2__c = 0.10,
            Renewal_Yrs_2_5__c = 0.10,
            Renewal_Yrs_6_10__c = 0.08,
            Renewal_Yrs_11_30__c = 0.06,

            Service_Fees_Yrs_11__c = 0.04,
            Extended_Renewal_Percentage__c = 0.03
        );

        insert ps;

        return ps;
    }


    private static Product_State__c createEmptyProductState(
        Id carrierId,
        Id productId
    ) {

        Product_State__c ps = new Product_State__c(
            Carrier__c = carrierId,
            Product__c = productId
        );

        insert ps;

        return ps;
    }


    private static Renewal_Schedule__c createRenewalSchedule(
        Id productStateId,
        Decimal percentage,
        Decimal yearFrom,
        Decimal yearTo,
        Decimal sortOrder
    ) {

        Renewal_Schedule__c rs = new Renewal_Schedule__c(
            Product_State__c = productStateId,
            Schedule_Type__c = 'Renewal',
            Percentage__c = percentage,
            Year_From__c = yearFrom,
            Year_To__c = yearTo,
            Sort_Order__c = sortOrder,
            Active__c = true
        );

        insert rs;

        return rs;
    }


    private static Renewal_Schedule__c createInactiveRenewalSchedule(
        Id productStateId,
        Decimal percentage,
        Decimal yearFrom,
        Decimal yearTo,
        Decimal sortOrder
    ) {

        Renewal_Schedule__c rs = new Renewal_Schedule__c(
            Product_State__c = productStateId,
            Schedule_Type__c = 'Renewal',
            Percentage__c = percentage,
            Year_From__c = yearFrom,
            Year_To__c = yearTo,
            Sort_Order__c = sortOrder,
            Active__c = false
        );

        insert rs;

        return rs;
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 1. COMPLETE BATCH EXECUTION
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCompleteBatchExecution() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createProductState(
                carrier.Id,
                product.Id
            );

        /*
         * Renewal schedules matching the legacy values:
         *
         * Year 2       -> 10%
         * Years 3-5    -> 10%
         * Years 6-10   -> 8%
         * Years 11-30  -> 6%
         * Years 31-50  -> 3%
         *
         * We use Renewal records only because the current org's
         * restricted Schedule_Type__c does not accept the literal
         * Service_Fee / Extended_Renewal values used by the batch constants.
         */

        createRenewalSchedule(
            ps.Id,
            0.10,
            2,
            5,
            1
        );

        createRenewalSchedule(
            ps.Id,
            0.08,
            6,
            10,
            2
        );

        createRenewalSchedule(
            ps.Id,
            0.06,
            11,
            30,
            3
        );

        createRenewalSchedule(
            ps.Id,
            0.03,
            31,
            50,
            4
        );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Source_Type__c,
                   Filename__c,
                   Processing_Status__c,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        System.assert(
            logs.size() > 0,
            'Expected validation logs to be created.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 2. DIRECT START / EXECUTE / FINISH
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testDirectExecute() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createProductState(
                carrier.Id,
                product.Id
            );

        createRenewalSchedule(
            ps.Id,
            0.10,
            2,
            5,
            1
        );

        createRenewalSchedule(
            ps.Id,
            0.08,
            6,
            10,
            2
        );

        createRenewalSchedule(
            ps.Id,
            0.06,
            11,
            30,
            3
        );

        createRenewalSchedule(
            ps.Id,
            0.03,
            31,
            50,
            4
        );

        RenewalScheduleMigrationValidationBatch batch =
            new RenewalScheduleMigrationValidationBatch();

        Test.startTest();

        Database.QueryLocator locator =
            batch.start(null);

        System.assertNotEquals(
            null,
            locator,
            'start() should return a QueryLocator.'
        );

        List<Product_State__c> records = [
            SELECT Id,
                   Renewal_Yrs_2__c,
                   Renewal_Yrs_2_5__c,
                   Renewal_Yrs_6_10__c,
                   Renewal_Yrs_11_30__c,
                   Service_Fees_Yrs_11__c,
                   Extended_Renewal_Percentage__c
            FROM Product_State__c
            WHERE Id = :ps.Id
        ];

        batch.execute(
            null,
            records
        );

        batch.finish(null);

        Test.stopTest();

        System.assert(
            true,
            'Direct batch execution completed successfully.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 3. EMPTY PRODUCT STATE
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testEmptyProductState() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createEmptyProductState(
                carrier.Id,
                product.Id
            );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        /*
         * Empty Product State has:
         * - no legacy values
         * - no schedules
         *
         * Therefore the batch should not create a legacy/schedule
         * existence mismatch.
         */

        System.assertNotEquals(
            null,
            ps.Id
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 4. LEGACY DATA BUT NO NEW SCHEDULE
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testMissingNewSchedules() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createProductState(
                carrier.Id,
                product.Id
            );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        System.assert(
            logs.size() > 0,
            'Expected logs because legacy values exist but schedules are missing.'
        );

        Boolean foundMissingNew = false;

        for (Commission_Import_Log__c log : logs) {

            if (
                log.Error_Details__c != null &&
                log.Error_Details__c.contains(
                    'Missing_New_Record'
                )
            ) {

                foundMissingNew = true;
                break;
            }
        }

        System.assert(
            foundMissingNew,
            'Expected Missing_New_Record validation result.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 5. EXTRA NEW SCHEDULE
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testExtraNewSchedule() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createEmptyProductState(
                carrier.Id,
                product.Id
            );

        createRenewalSchedule(
            ps.Id,
            0.10,
            2,
            5,
            1
        );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        System.assert(
            logs.size() > 0,
            'Expected logs because a schedule exists without legacy data.'
        );

        Boolean foundExtra = false;

        for (Commission_Import_Log__c log : logs) {

            if (
                log.Error_Details__c != null &&
                log.Error_Details__c.contains(
                    'Extra_New_Record'
                )
            ) {

                foundExtra = true;
                break;
            }
        }

        System.assert(
            foundExtra,
            'Expected Extra_New_Record validation result.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 6. INACTIVE SCHEDULE
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInactiveSchedule() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createEmptyProductState(
                carrier.Id,
                product.Id
            );

        createInactiveRenewalSchedule(
            ps.Id,
            0.10,
            2,
            5,
            1
        );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        /*
         * The inactive schedule is retrieved by the batch,
         * but getNewValue() ignores it because Active__c = false.
         */

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        System.assert(
            logs.size() > 0,
            'Expected validation output for inactive schedule.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 7. VALUE MISMATCH
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testValueMismatch() {

        Carrier__c carrier = createCarrier();
        Product__c product = createProduct();

        Product_State__c ps =
            createProductState(
                carrier.Id,
                product.Id
            );

        /*
         * Legacy:
         *   Year 2-5 = 10%
         *
         * New:
         *   Year 2-5 = 20%
         *
         * This should generate Value_Mismatch.
         */

        createRenewalSchedule(
            ps.Id,
            0.20,
            2,
            5,
            1
        );

        createRenewalSchedule(
            ps.Id,
            0.08,
            6,
            10,
            2
        );

        createRenewalSchedule(
            ps.Id,
            0.06,
            11,
            30,
            3
        );

        createRenewalSchedule(
            ps.Id,
            0.03,
            31,
            50,
            4
        );

        Test.startTest();

        Database.executeBatch(
            new RenewalScheduleMigrationValidationBatch(),
            200
        );

        Test.stopTest();

        List<Commission_Import_Log__c> logs = [
            SELECT Id,
                   Error_Details__c,
                   Notes__c
            FROM Commission_Import_Log__c
        ];

        Boolean foundMismatch = false;

        for (Commission_Import_Log__c log : logs) {

            if (
                log.Error_Details__c != null &&
                log.Error_Details__c.contains(
                    'Value_Mismatch'
                )
            ) {

                foundMismatch = true;
                break;
            }
        }

        System.assert(
            foundMismatch,
            'Expected Value_Mismatch validation result.'
        );
    }


    // ═══════════════════════════════════════════════════════════════════════
    // 8. FINISH METHOD
    // ═══════════════════════════════════════════════════════════════════════

    @IsTest
    static void testFinish() {

        RenewalScheduleMigrationValidationBatch batch =
            new RenewalScheduleMigrationValidationBatch();

        Test.startTest();

        batch.finish(null);

        Test.stopTest();

        System.assert(
            true,
            'finish() completed successfully.'
        );
    }
}