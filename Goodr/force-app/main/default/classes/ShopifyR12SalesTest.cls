@IsTest
public class ShopifyR12SalesTest {

    private static Id companyRtId =
        Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Company')
        .getRecordTypeId();

    private static Id storeRtId =
        Schema.SObjectType.Account
        .getRecordTypeInfosByName()
        .get('Store Location')
        .getRecordTypeId();

    // ═══════════════════════════════════════════════════════════════
    // DATE HELPERS — year over year windows
    //
    // TY YTD = 1 Jan THIS year → today
    // PY YTD = 1 Jan LAST year → same day last year
    //
    // Both helpers use 1 January, which is the inclusive start of
    // each window. That makes them safe whatever date the tests are
    // run on, including 1 January itself.
    //
    // inTY()        → 1 Jan this year  — inside TY YTD only
    // inPY()        → 1 Jan last year  — inside PY YTD only
    // lateLastYear()→ 31 Dec last year — in last year but AFTER the
    //                 year-to-date cut-off, so excluded from PY YTD
    // outsideBoth() → three years ago  — outside both windows
    // ═══════════════════════════════════════════════════════════════

    private static Date inTY() {
        return Date.newInstance(Date.today().year(), 1, 1);
    }

    private static Date inPY() {
        return Date.newInstance(Date.today().year() - 1, 1, 1);
    }

    private static Date lateLastYear() {
        return Date.newInstance(Date.today().year() - 1, 12, 31);
    }

    private static Date outsideBoth() {
        return Date.today().addYears(-3);
    }

    // ═══════════════════════════════════════════════════════════════
    // TEST SETUP
    //
    // Store 1 — TY YTD $1,000 against PY YTD $5,000 → 20% → AT RISK
    // Store 2 — no orders, used as a clean slate by individual tests
    // ═══════════════════════════════════════════════════════════════

    @TestSetup
    static void setupData() {

        Account companyAcc = new Account(
            Name                  = 'Test Company R12',
            RecordTypeId          = companyRtId,
            Tax_Id__c             = '123456789',
            Shopify_Company_Id__c = 'R12COMPANY001',
            Sales_Channel__c      = 'Specialty'
        );
        insert companyAcc;

        Account storeAcc = new Account(
            Name                       = 'Test Store R12',
            RecordTypeId               = storeRtId,
            ParentId                   = companyAcc.Id,
            Shopify_Company_Id__c      = 'R12STORE001',
            Sales_Channel__c           = 'Specialty',
            Last_Shopify_Order_Date__c = Date.today(),
            ShippingStreet             = '123 Test St',
            ShippingCity               = 'Test City',
            ShippingPostalCode         = '12345',
            ShippingCountry            = 'US',
            Manual_Approval_Status__c  = 'Approved'
        );
        insert storeAcc;

        Account storeAcc2 = new Account(
            Name                       = 'Test Store R12 Empty',
            RecordTypeId               = storeRtId,
            ParentId                   = companyAcc.Id,
            Shopify_Company_Id__c      = 'R12STORE002',
            Sales_Channel__c           = 'Specialty',
            Last_Shopify_Order_Date__c = Date.today(),
            ShippingStreet             = '456 Test St',
            ShippingCity               = 'Test City',
            ShippingPostalCode         = '12345',
            ShippingCountry            = 'US',
            Manual_Approval_Status__c  = 'Approved'
        );
        insert storeAcc2;

        update new Pricebook2(
            Id       = Test.getStandardPricebookId(),
            IsActive = true
        );

        // Store 1: $5,000 last year, only $1,000 this year.
        // 1000 / 5000 = 20%, which is below 50, so AT RISK.
        insert new List<Order>{
            new Order(
                AccountId                     = storeAcc.Id,
                Pricebook2Id                  = Test.getStandardPricebookId(),
                EffectiveDate                 = Date.newInstance(
                                                    Date.today().year() - 1, 1, 1),
                Status                        = 'Draft',
                Name                          = 'SGT-PY-001',
                Shopify_Order_Id__c           = 'gid://shopify/Order/PY001',
                Shopify_Order_Number__c       = 'SGT-PY-001',
                Shopify_Order_Amount__c       = 5000.00,
                Shopify_Payment_Status__c     = 'PAID',
                Shopify_Fulfillment_Status__c = 'FULFILLED'
            ),
            new Order(
                AccountId                     = storeAcc.Id,
                Pricebook2Id                  = Test.getStandardPricebookId(),
                EffectiveDate                 = Date.newInstance(
                                                    Date.today().year(), 1, 1),
                Status                        = 'Draft',
                Name                          = 'SGT-TY-001',
                Shopify_Order_Id__c           = 'gid://shopify/Order/TY001',
                Shopify_Order_Number__c       = 'SGT-TY-001',
                Shopify_Order_Amount__c       = 1000.00,
                Shopify_Payment_Status__c     = 'PAID',
                Shopify_Fulfillment_Status__c = 'FULFILLED'
            )
        };
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════

    private static Account getTestStore() {
        return [
            SELECT Id, Name,
                   Current_Rolling_12_Month_Sales__c,
                   Prior_Rolling_12_Month_Sales__c,
                   R12_Sales_Decline_Ratio__c,
                   R12_Sales_Performance_Percent__c,
                   Shopify_Sales_At_Risk__c,
                   R12_Calculation_Last_Run__c
            FROM Account
            WHERE Name = 'Test Store R12'
            AND RecordTypeId = :storeRtId
            LIMIT 1
        ];
    }

    private static Account getEmptyStore() {
        return [
            SELECT Id, Name,
                   Current_Rolling_12_Month_Sales__c,
                   Prior_Rolling_12_Month_Sales__c,
                   R12_Sales_Decline_Ratio__c,
                   R12_Sales_Performance_Percent__c,
                   Current_YTD_Sales__c,
                   Prior_YTD_Sales__c,
                   Shopify_Sales_At_Risk__c,
                   R12_Calculation_Last_Run__c
            FROM Account
            WHERE Name = 'Test Store R12 Empty'
            AND RecordTypeId = :storeRtId
            LIMIT 1
        ];
    }

    private static Account getCompany() {
        return [
            SELECT Id, Name,
                   Current_Rolling_12_Month_Sales__c,
                   Prior_Rolling_12_Month_Sales__c,
                   R12_Sales_Decline_Ratio__c,
                   R12_Sales_Performance_Percent__c,
                   Shopify_Sales_At_Risk__c,
                   R12_Calculation_Last_Run__c
            FROM Account
            WHERE Name = 'Test Company R12'
            AND RecordTypeId = :companyRtId
            LIMIT 1
        ];
    }

    private static void insertOrder(
        Id accountId,
        Date effectiveDate,
        String name,
        String shopifyId,
        Decimal amount
    ) {
        insert new Order(
            AccountId                     = accountId,
            Pricebook2Id                  = Test.getStandardPricebookId(),
            EffectiveDate                 = effectiveDate,
            Status                        = 'Draft',
            Name                          = name,
            Shopify_Order_Id__c           = shopifyId,
            Shopify_Order_Number__c       = name,
            Shopify_Order_Amount__c       = amount,
            Shopify_Payment_Status__c     = 'PAID',
            Shopify_Fulfillment_Status__c = 'FULFILLED'
        );
    }

    // ═══════════════════════════════════════════════════════════════
    // SERVICE TESTS
    // ═══════════════════════════════════════════════════════════════

    // ── Null and empty input handled gracefully ───────────────────
    @IsTest
    static void testNullInput() {
        Test.startTest();
        ShopifyR12SalesService.calculateR12(null);
        ShopifyR12SalesService.calculateR12(new List<Id>());
        Test.stopTest();
        System.assert(true, 'Null/empty handled gracefully');
    }

    // ── THE KEY TEST: below half of last year → AT RISK ───────────
    // TY YTD $1,000 against PY YTD $5,000 = 20%, below the 50%
    // threshold. This is the case the old calculation could never
    // produce, because its two windows overlapped.
    @IsTest
    static void testBelowHalfOfPriorYear_IsFlagged() {
        Account store = getTestStore();

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getTestStore();

        System.assertEquals(1000.00,
            result.Current_Rolling_12_Month_Sales__c,
            'TY YTD = $1,000');
        System.assertEquals(5000.00,
            result.Prior_Rolling_12_Month_Sales__c,
            'PY YTD = $5,000');
        System.assertEquals(0.2000,
            result.R12_Sales_Decline_Ratio__c,
            'Ratio = 0.2000');
        System.assertEquals(20.00,
            result.R12_Sales_Performance_Percent__c,
            'Percent = 20%');
        System.assertEquals(true,
            result.Shopify_Sales_At_Risk__c,
            'Flagged at risk — below half of last year');
        System.assertNotEquals(null,
            result.R12_Calculation_Last_Run__c,
            'Last run set');
    }

    // ── Boundary: exactly half is NOT flagged ─────────────────────
    // The test is strictly less than 50, matching the client's
    // formula: 2026 YTD < 2025 YTD * 0.5
    @IsTest
    static void testExactlyHalf_NotFlagged() {
        Account store = getEmptyStore();

        insertOrder(store.Id, inPY(), 'SGT-HALF-PY',
            'gid://shopify/Order/HALFPY', 5000.00);
        insertOrder(store.Id, inTY(), 'SGT-HALF-TY',
            'gid://shopify/Order/HALFTY', 2500.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(50.00,
            result.R12_Sales_Performance_Percent__c,
            'Percent = exactly 50%');
        System.assertEquals(false,
            result.Shopify_Sales_At_Risk__c,
            'Exactly 50% is NOT flagged — test is strictly below');
    }

    // ── Just under half IS flagged ────────────────────────────────
    @IsTest
    static void testJustUnderHalf_IsFlagged() {
        Account store = getEmptyStore();

        insertOrder(store.Id, inPY(), 'SGT-UNDER-PY',
            'gid://shopify/Order/UNDERPY', 5000.00);
        insertOrder(store.Id, inTY(), 'SGT-UNDER-TY',
            'gid://shopify/Order/UNDERTY', 2499.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(49.98,
            result.R12_Sales_Performance_Percent__c,
            'Percent = 49.98%');
        System.assertEquals(true,
            result.Shopify_Sales_At_Risk__c,
            'Just under 50% is flagged');
    }

    // ── No sales this year at all → 0% → AT RISK ──────────────────
    // Stopped ordering entirely. The most severe case.
    @IsTest
    static void testNoSalesThisYear_IsFlagged() {
        Account store = getEmptyStore();

        insertOrder(store.Id, inPY(), 'SGT-STOPPED-PY',
            'gid://shopify/Order/STOPPEDPY', 12000.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(0,
            result.Current_Rolling_12_Month_Sales__c,
            'TY YTD = $0');
        System.assertEquals(12000.00,
            result.Prior_Rolling_12_Month_Sales__c,
            'PY YTD = $12,000');
        System.assertEquals(0.00,
            result.R12_Sales_Performance_Percent__c,
            'Percent = 0%');
        System.assertEquals(true,
            result.Shopify_Sales_At_Risk__c,
            'Stopped ordering entirely — flagged');
    }

    // ── Growth is not flagged ─────────────────────────────────────
    @IsTest
    static void testGrowth_NotFlagged() {
        Account store = getEmptyStore();

        insertOrder(store.Id, inPY(), 'SGT-GROW-PY',
            'gid://shopify/Order/GROWPY', 5000.00);
        insertOrder(store.Id, inTY(), 'SGT-GROW-TY',
            'gid://shopify/Order/GROWTY', 10000.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(200.00,
            result.R12_Sales_Performance_Percent__c,
            'Percent = 200%');
        System.assertEquals(2.0000,
            result.R12_Sales_Decline_Ratio__c,
            'Ratio = 2.0000');
        System.assertEquals(false,
            result.Shopify_Sales_At_Risk__c,
            'Growing store not flagged');
    }

    // ── New store: sales this year, none last year ────────────────
    // curr > 0, prior = 0 → ratio 1, percent 100, not flagged
    @IsTest
    static void testNewStoreNoPriorYear_NotFlagged() {
        Account store = getEmptyStore();

        insertOrder(store.Id, inTY(), 'SGT-NEW-TY',
            'gid://shopify/Order/NEWTY', 3000.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(3000.00,
            result.Current_Rolling_12_Month_Sales__c,
            'TY YTD = $3,000');
        System.assertEquals(0,
            result.Prior_Rolling_12_Month_Sales__c,
            'PY YTD = $0');
        System.assertEquals(100.00,
            result.R12_Sales_Performance_Percent__c,
            'curr > 0, prior = 0 → percent = 100%');
        System.assertEquals(1,
            result.R12_Sales_Decline_Ratio__c,
            'curr > 0, prior = 0 → ratio = 1');
        System.assertEquals(false,
            result.Shopify_Sales_At_Risk__c,
            'New store not flagged');
    }

    // ── No orders in either year ──────────────────────────────────
    // Dormant two years running. Not flagged, matching the client's
    // formula, since zero is not less than half of zero.
    @IsTest
    static void testNoOrdersEitherYear_NotFlagged() {
        Account store = getEmptyStore();

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(0,
            result.Current_Rolling_12_Month_Sales__c,
            'TY YTD = 0');
        System.assertEquals(0,
            result.Prior_Rolling_12_Month_Sales__c,
            'PY YTD = 0');
        System.assertEquals(0,
            result.R12_Sales_Decline_Ratio__c,
            'Ratio = 0');
        System.assertEquals(0,
            result.R12_Sales_Performance_Percent__c,
            'Percent = 0%');
        System.assertEquals(false,
            result.Shopify_Sales_At_Risk__c,
            'Dormant both years — not flagged');
    }

    // ── The year-to-date cut-off is respected ─────────────────────
    // An order on 31 Dec last year is in the prior YEAR but after
    // the year-to-date cut-off, so it must NOT count towards PY YTD.
    // This is the client's [YTD Filter] = TRUE condition.
    @IsTest
    static void testLateLastYearOrderExcludedFromPriorYtd() {
        // On 31 Dec the prior YTD window ends on 31 Dec last year, so
        // there is no date in last year after the cut-off to test with.
        Date today = Date.today();
        if (today.month() == 12 && today.day() == 31) return;

        Account store = getEmptyStore();

        insertOrder(store.Id, inPY(), 'SGT-CUT-IN',
            'gid://shopify/Order/CUTIN', 5000.00);
        insertOrder(store.Id, lateLastYear(), 'SGT-CUT-OUT',
            'gid://shopify/Order/CUTOUT', 20000.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        // Asserts the YTD fields: the 31 Dec order is inside the rolling
        // 12 months, so the R12 fields would include it.
        System.assertEquals(5000.00,
            result.Prior_YTD_Sales__c,
            'PY YTD excludes the 31 December order');
        System.assertEquals(0,
            result.Current_YTD_Sales__c,
            'TY YTD = $0 — neither order is in this year');
    }

    // ── Orders outside both windows not counted ───────────────────
    @IsTest
    static void testOrdersOutsideWindowsNotCounted() {
        Account store = getEmptyStore();

        insertOrder(store.Id, outsideBoth(), 'SGT-OLD-001',
            'gid://shopify/Order/OLD001', 50000.00);

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getEmptyStore();

        System.assertEquals(0,
            result.Current_Rolling_12_Month_Sales__c,
            'Old order not in TY YTD');
        System.assertEquals(0,
            result.Prior_Rolling_12_Month_Sales__c,
            'Old order not in PY YTD');
        System.assertEquals(false,
            result.Shopify_Sales_At_Risk__c,
            'Old orders do not flag the account');
    }

    // ── Last run datetime set to today ────────────────────────────
    @IsTest
    static void testLastRunDatetimeIsSet() {
        Account store = getTestStore();

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account result = getTestStore();

        System.assertNotEquals(null,
            result.R12_Calculation_Last_Run__c,
            'R12_Calculation_Last_Run__c should be set');
        System.assertEquals(Date.today(),
            result.R12_Calculation_Last_Run__c.date(),
            'Last run should be today');
    }

    // ── Multiple accounts processed in one call ───────────────────
    @IsTest
    static void testMultipleAccountsProcessed() {
        Account store1 = getTestStore();
        Account store2 = getEmptyStore();

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store1.Id, store2.Id }
        );
        Test.stopTest();

        Account r1 = getTestStore();
        Account r2 = getEmptyStore();

        System.assertEquals(1000.00,
            r1.Current_Rolling_12_Month_Sales__c,
            'Store 1 TY YTD = $1,000');
        System.assertEquals(true,
            r1.Shopify_Sales_At_Risk__c,
            'Store 1 flagged');

        System.assertNotEquals(null,
            r2.R12_Calculation_Last_Run__c,
            'Store 2 last run set');
        System.assertEquals(0,
            r2.Current_Rolling_12_Month_Sales__c,
            'Store 2 TY YTD = $0');
        System.assertEquals(false,
            r2.Shopify_Sales_At_Risk__c,
            'Store 2 not flagged');
    }

    // ── Company rollup populated after store calculation ──────────
    @IsTest
    static void testCompanyRollupPopulated() {
        Account store = getTestStore();

        Test.startTest();
        ShopifyR12SalesService.calculateR12(
            new List<Id>{ store.Id }
        );
        Test.stopTest();

        Account company = getCompany();

        System.assertNotEquals(null,
            company.R12_Calculation_Last_Run__c,
            'Company rollup calculated');
        System.assertEquals(1000.00,
            company.Current_Rolling_12_Month_Sales__c,
            'Company TY YTD rolled up = $1,000');
        System.assertEquals(5000.00,
            company.Prior_Rolling_12_Month_Sales__c,
            'Company PY YTD rolled up = $5,000');
        System.assertEquals(20.00,
            company.R12_Sales_Performance_Percent__c,
            'Company percent = 20%');
        System.assertEquals(true,
            company.Shopify_Sales_At_Risk__c,
            'Company flagged via rollup');
    }

    // ═══════════════════════════════════════════════════════════════
    // BATCH TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void testBatchProcessesAllStoreLocations() {
        Test.startTest();
        Database.executeBatch(new ShopifyR12SalesBatch(), 200);
        Test.stopTest();

        Account store1 = getTestStore();
        Account store2 = getEmptyStore();

        System.assertNotEquals(null,
            store1.R12_Calculation_Last_Run__c,
            'Store 1 calculated');
        System.assertNotEquals(null,
            store2.R12_Calculation_Last_Run__c,
            'Store 2 calculated');
    }

    @IsTest
    static void testBatchCalculatesCorrectValues() {
        Test.startTest();
        Database.executeBatch(new ShopifyR12SalesBatch(), 200);
        Test.stopTest();

        Account store1 = getTestStore();

        System.assertEquals(1000.00,
            store1.Current_Rolling_12_Month_Sales__c,
            'TY YTD = $1,000');
        System.assertEquals(5000.00,
            store1.Prior_Rolling_12_Month_Sales__c,
            'PY YTD = $5,000');
        System.assertEquals(20.00,
            store1.R12_Sales_Performance_Percent__c,
            'Percent = 20%');
        System.assertEquals(true,
            store1.Shopify_Sales_At_Risk__c,
            'Flagged at risk');

        Account store2 = getEmptyStore();
        System.assertEquals(false,
            store2.Shopify_Sales_At_Risk__c,
            'Empty store not flagged');
        System.assertEquals(0,
            store2.R12_Sales_Performance_Percent__c,
            'Empty store percent = 0%');
    }

    @IsTest
    static void testBatchDefaultConstructor() {
        Test.startTest();
        Database.executeBatch(new ShopifyR12SalesBatch());
        Test.stopTest();
        System.assert(true, 'Default constructor works');
    }

    @IsTest
    static void testBatchSchedulable() {
        Test.startTest();
        String jobId = System.schedule(
            'Test R12 Weekly',
            '0 0 23 ? * SUN',
            new ShopifyR12SalesBatch()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId,
            'Scheduler returns job ID');
        System.assertEquals(1,
            [SELECT COUNT() FROM CronTrigger
             WHERE CronJobDetail.Name = 'Test R12 Weekly'],
            'Scheduled job registered');
    }

    @IsTest
    static void testSchedulableExecute() {
        Test.startTest();
        new ShopifyR12SalesBatch().execute(null);
        Test.stopTest();
        System.assert(true, 'Schedulable execute() covered');
    }

    @IsTest
    static void testBatchFinishCountQueries() {
        Test.startTest();
        Database.executeBatch(new ShopifyR12SalesBatch(), 200);
        Test.stopTest();

        Integer flagged = [
            SELECT COUNT() FROM Account
            WHERE Shopify_Sales_At_Risk__c = true
            AND RecordType.Name = 'Store Location'
        ];
        System.assert(flagged >= 1,
            'At least the one at-risk store is counted in finish');
    }

    @IsTest
    static void testBatchCompanyUpdatedViaRollup() {
        Test.startTest();
        Database.executeBatch(new ShopifyR12SalesBatch(), 200);
        Test.stopTest();

        Account company = getCompany();

        System.assertNotEquals(null,
            company.R12_Calculation_Last_Run__c,
            'Company updated via rollup');
        System.assertEquals(1000.00,
            company.Current_Rolling_12_Month_Sales__c,
            'Company TY YTD = $1,000 via rollup');
        System.assertEquals(5000.00,
            company.Prior_Rolling_12_Month_Sales__c,
            'Company PY YTD = $5,000 via rollup');
    }
}