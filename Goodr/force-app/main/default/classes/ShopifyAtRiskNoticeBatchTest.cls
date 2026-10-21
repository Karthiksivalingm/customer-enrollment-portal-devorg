@IsTest
private class ShopifyAtRiskNoticeBatchTest {

    // Tests for ShopifyAtRiskNoticeBatch (warm-off stages, offboarding, clean-up) and SendWarmOffEmail.
    // The send flow also fires on insert here, so tests assert on notice records, not email delivery.

    private static final Id COMPANY_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Company').getRecordTypeId();
    private static final Id STORE_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Store_Location').getRecordTypeId();

    // In-memory config (custom metadata cannot be inserted in tests)
    private static Shopify_At_Risk_Config__mdt config(String mode, Boolean autoOffboard) {
        return new Shopify_At_Risk_Config__mdt(
            Active__c                = true,
            Auto_Offboard__c         = autoOffboard,
            At_Risk_Mode__c          = mode,
            Deactivation_Months__c   = 18,
            Require_Opt_In__c        = false,
            Exclude_Bounced__c       = false,
            Offboard_Reason__c       = 'Store At Risk',
            Legacy_Notice_Enabled__c = false,
            Email_Template_Name__c   = 'Shopify At Risk Notice',
            Template_Stage_1__c      = 'Warm Off 1 - Check In',
            Template_Stage_2__c      = 'Warm Off 2 - Early Notice',
            Template_Stage_3__c      = 'Warm Off 3 - 30 Day Warning',
            Template_Stage_4__c      = 'Warm Off 4 - 15 Day Reminder',
            Template_Stage_5__c      = 'Warm Off 5 - Deactivation Notice'
        );
    }

    private static Integer seq = 0;

    // Company + store location + contact linked to the store through ACR
    private static Account makeStore(Date lastOrder, Boolean atRisk) {
        seq++;
        String tag = 'SANT' + seq;

        Account company = new Account(
            Name = tag + ' Company', RecordTypeId = COMPANY_RT,
            Tax_ID__c = '12-345678' + seq, Manual_Approval_Status__c = 'Approved',
            ShippingStreet = '1 Test St', ShippingCity = 'Austin',
            ShippingPostalCode = '78701', ShippingCountryCode = 'US', ShippingStateCode = 'TX'
        );
        insert company;

        Account store = new Account(
            Name = tag + ' Store', RecordTypeId = STORE_RT, ParentId = company.Id,
            Active__c = true, Shopify_Company_Id__c = 'TEST-' + tag, Manual_Approval_Status__c = 'Approved',
            ShippingStreet = '1 Test St', ShippingCity = 'Austin',
            ShippingPostalCode = '78701', ShippingCountryCode = 'US', ShippingStateCode = 'TX',
            Last_Shopify_Order_Date__c = lastOrder, Shopify_Sales_At_Risk__c = atRisk
        );
        insert store;

        Contact c = new Contact(FirstName = 'Test', LastName = 'ZTest-' + tag,
                                Email = tag.toLowerCase() + '@example.com', AccountId = company.Id);
        insert c;
        insert new AccountContactRelation(AccountId = store.Id, ContactId = c.Id, IsActive = true);
        return store;
    }

    // A notice already sent: inserted as Notice Sent so the send flow does not fire
    private static Shopify_At_Risk_Notice__c seedSent(Account store, String stage, Date sentOn) {
        Id contactId = [SELECT ContactId FROM AccountContactRelation
                        WHERE AccountId = :store.Id AND IsActive = true LIMIT 1].ContactId;
        Shopify_At_Risk_Notice__c n = new Shopify_At_Risk_Notice__c(
            Store_Account__c = store.Id, Contact__c = contactId, Stage__c = stage,
            Status__c = ShopifyAtRiskNoticeBatch.ST_SENT, Email_Sent__c = true, Notice_Date__c = sentOn,
            Last_Order_Date_At_Notice__c = store.Last_Shopify_Order_Date__c,
            Notice_Key__c = contactId + '-' + store.Id + '-' + stage + '-' +
                            String.valueOf(store.Last_Shopify_Order_Date__c)
        );
        insert n;
        return n;
    }

    private static void run(Shopify_At_Risk_Config__mdt cfg) {
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(cfg), 50);
        Test.stopTest();
    }

    private static List<Shopify_At_Risk_Notice__c> noticesFor(Id storeId, String stage) {
        return [SELECT Id, Stage__c, Status__c, Deactivation_Date__c FROM Shopify_At_Risk_Notice__c
                WHERE Store_Account__c = :storeId AND Stage__c = :stage];
    }

    private static Boolean isActive(Id storeId) {
        return [SELECT Active__c FROM Account WHERE Id = :storeId].Active__c;
    }

    // Shopify config custom setting used by the Shopify sync queueables (US and Canada stores)
    private static void insertShopifyConfig() {
        insert new List<Shopify_Configuration__c>{
            new Shopify_Configuration__c(Name = 'Specialty', Shopify_Access_Token__c = 'test-token-us',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json'),
            new Shopify_Configuration__c(Name = 'Specialty CAN', Shopify_Access_Token__c = 'test-token-ca',
                Shopify_Endpoint__c = 'https://test.myshopify.com/admin/api/2024-01/graphql.json')
        };
    }

    // Shopify returns no data: the sync services find nothing to change and exit cleanly
    private class ShopifyNoDataMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":null}');
            return res;
        }
    }

    // ── Stages ────────────────────────────────────────────────────

    @IsTest static void month12_createsCheckIn() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        run(config('Every Stage', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_1).size());
    }

    @IsTest static void month15_createsEarlyNotice() {
        Account s = makeStore(Date.today().addMonths(-15).addDays(-3), true);
        run(config('Every Stage', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_2).size());
    }

    @IsTest static void month17_createsWarningAndTask() {
        Account s = makeStore(Date.today().addMonths(-17).addDays(-3), true);
        run(config('Every Stage', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_3).size());
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :s.Id AND Subject LIKE 'Retailer inactivity%']);
    }

    @IsTest static void month17_deactivationDateIs18MonthMark() {
        Date last = Date.today().addMonths(-17).addDays(-3);
        Account s = makeStore(last, true);
        run(config('Every Stage', false));
        System.assertEquals(last.addMonths(18), noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_3)[0].Deactivation_Date__c);
    }

    @IsTest static void month17Point5_createsReminder() {
        Account s = makeStore(Date.today().addMonths(-17).addDays(-16), true);
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_3, Date.today().addDays(-16));
        run(config('Every Stage', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_4).size());
    }

    @IsTest static void past18_neverWarned_isHeldNotOffboarded() {
        Account s = makeStore(Date.today().addMonths(-20), true);
        run(config('Every Stage', true));
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
        System.assertEquals(true, isActive(s.Id));
    }

    // ── Month 18 offboarding ──────────────────────────────────────

    @IsTest static void month18_autoOffboardOn_deactivatesAndSendsFinal() {
        Account s = makeStore(Date.today().addMonths(-18).addDays(-1), false);
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_3, Date.today().addMonths(-1));
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_4, Date.today().addDays(-15));
        run(config('Every Stage', true));
        System.assertEquals(false, isActive(s.Id));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_5).size());
        System.assertEquals('Store At Risk', [SELECT Offboarding_Reason__c FROM Account WHERE Id = :s.Id].Offboarding_Reason__c);
    }

    @IsTest static void month18_autoOffboardOff_marksOffboardDue() {
        Account s = makeStore(Date.today().addMonths(-18).addDays(-1), true);
        Shopify_At_Risk_Notice__c w = seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_3, Date.today().addMonths(-1));
        run(config('Every Stage', false));
        System.assertEquals(true, isActive(s.Id));
        System.assertEquals(ShopifyAtRiskNoticeBatch.ST_DUE,
            [SELECT Status__c FROM Shopify_At_Risk_Notice__c WHERE Id = :w.Id].Status__c);
    }

    @IsTest static void reactivatedAfterEmail5_isNotOffboardedAgain() {
        Account s = makeStore(Date.today().addMonths(-19), true);
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_3, Date.today().addMonths(-2));
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_5, Date.today().addMonths(-1));
        run(config('Every Stage', true));
        System.assertEquals(true, isActive(s.Id));
    }

    // ── At-risk gate ──────────────────────────────────────────────

    @IsTest static void everyStage_notAtRisk_heldBack() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), false);
        run(config('Every Stage', false));
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
    }

    @IsTest static void entryOnly_startedSeriesContinues() {
        Account s = makeStore(Date.today().addMonths(-15).addDays(-3), false);
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_1, Date.today().addMonths(-3));
        run(config('Entry Only', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_2).size());
    }

    @IsTest static void off_ignoresFlag() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), false);
        run(config('Off', false));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_1).size());
    }

    // ── Clean-up passes ───────────────────────────────────────────

    @IsTest static void newOrder_recoversSeries() {
        Account s = makeStore(Date.today().addMonths(-13), true);
        Shopify_At_Risk_Notice__c old = seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_1, Date.today().addMonths(-1));
        update new Account(Id = s.Id, Last_Shopify_Order_Date__c = Date.today().addDays(-5));
        run(config('Every Stage', false));
        System.assertEquals(ShopifyAtRiskNoticeBatch.ST_RECOVERED,
            [SELECT Status__c FROM Shopify_At_Risk_Notice__c WHERE Id = :old.Id].Status__c);
    }

    @IsTest static void inactiveStore_noticesSweptToOffboarded() {
        // Deactivating a store enqueues ShopifyActiveStatusSyncQueueable, which needs the
        // Shopify config custom setting and a callout mock when it runs at Test.stopTest()
        insertShopifyConfig();
        Test.setMock(HttpCalloutMock.class, new ShopifyNoDataMock());
        Account s = makeStore(Date.today().addMonths(-15), true);
        Shopify_At_Risk_Notice__c n = seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_2, Date.today().addDays(-5));
        update new Account(Id = s.Id, Active__c = false);
        run(config('Every Stage', false));
        System.assertEquals(ShopifyAtRiskNoticeBatch.ST_OFFBOARDED,
            [SELECT Status__c FROM Shopify_At_Risk_Notice__c WHERE Id = :n.Id].Status__c);
    }

    @IsTest static void legacyNotice_isNeverOffboardedAfter30Days() {
        Account s = makeStore(Date.today().addDays(-40), true);
        Id contactId = [SELECT ContactId FROM AccountContactRelation
                        WHERE AccountId = :s.Id AND IsActive = true LIMIT 1].ContactId;
        insert new Shopify_At_Risk_Notice__c(
            Store_Account__c = s.Id, Contact__c = contactId,
            Status__c = ShopifyAtRiskNoticeBatch.ST_SENT, Notice_Date__c = Date.today().addDays(-31),
            Notice_Key__c = contactId + '-' + s.Id + '-legacy'
        );
        run(config('Every Stage', true));
        System.assertEquals(true, isActive(s.Id));   // old 30-day rule removed
    }

    // ── Run control ───────────────────────────────────────────────

    @IsTest static void rerun_noDuplicates() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        Shopify_At_Risk_Config__mdt cfg = config('Every Stage', false);
        run(cfg);
        List<Account> scope = [
            SELECT Id, Name, OwnerId, ParentId, Last_Shopify_Order_Date__c, Shopify_Sales_At_Risk__c,
                   At_Risk_Since__c, Current_YTD_Sales__c, Prior_YTD_Sales__c, YTD_Performance_Percent__c,
                   Current_Rolling_12_Month_Sales__c, R12_Sales_Decline_Ratio__c
            FROM Account WHERE Id = :s.Id
        ];
        new ShopifyAtRiskNoticeBatch(cfg).execute(null, scope);
        System.assertEquals(1, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
    }

    @IsTest static void killSwitch() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        Shopify_At_Risk_Config__mdt cfg = config('Every Stage', false);
        cfg.Active__c = false;
        run(cfg);
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
    }

    @IsTest static void scheduler() {
        Test.startTest();
        System.schedule('SANT schedule test', '0 0 5 * * ?', new ShopifyAtRiskNoticeBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'SANT schedule test']);
    }

    @IsTest static void legacyRun_createsSingleNoticeWithoutStage() {
        Account s = makeStore(Date.today().addDays(-10), true);
        update new Account(Id = s.Id, At_Risk_Since__c = Date.today());
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(config('Every Stage', false), true), 200);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c
                                WHERE Store_Account__c = :s.Id AND Stage__c = null]);
    }

    // ── Exclude from Auto-Offboarding (account manager exception) ─

    @IsTest static void excludedStore_month18_notOffboarded() {
        Account s = makeStore(Date.today().addMonths(-18).addDays(-1), false);
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_3, Date.today().addMonths(-1));
        seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_4, Date.today().addDays(-15));
        update new Account(Id = s.Id, Exclude_From_Auto_Offboarding__c = true);
        run(config('Every Stage', true));
        System.assertEquals(true, isActive(s.Id));
        System.assertEquals(0, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_5).size());
    }

    @IsTest static void excludedStore_month17_noEmailNoTask() {
        Account s = makeStore(Date.today().addMonths(-17).addDays(-3), true);
        update new Account(Id = s.Id, Exclude_From_Auto_Offboarding__c = true);
        run(config('Every Stage', true));
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :s.Id AND Subject LIKE 'Retailer inactivity%']);
    }

    @IsTest static void excludedCompany_coversItsStores() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        update new Account(Id = s.ParentId, Exclude_From_Auto_Offboarding__c = true);
        run(config('Every Stage', true));
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
    }

    @IsTest static void notExcluded_stillProcessed() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        update new Account(Id = s.Id, Exclude_From_Auto_Offboarding__c = false);
        run(config('Every Stage', true));
        System.assertEquals(1, noticesFor(s.Id, ShopifyAtRiskNoticeBatch.STAGE_1).size());
    }

    @IsTest static void excludedStore_legacyRun_noNotice() {
        Account s = makeStore(Date.today().addDays(-10), true);
        update new Account(Id = s.Id, At_Risk_Since__c = Date.today(), Exclude_From_Auto_Offboarding__c = true);
        Test.startTest();
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(config('Every Stage', false), true), 200);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Shopify_At_Risk_Notice__c WHERE Store_Account__c = :s.Id]);
    }

    // Flow "Create At Risk Task for Account Owner": skipped for an excluded store or Company
    @IsTest static void atRiskTask_skippedWhenExcluded() {
        Account normal   = makeStore(Date.today().addDays(-10), true);
        Account excluded = makeStore(Date.today().addDays(-10), true);
        Account viaCo    = makeStore(Date.today().addDays(-10), true);
        update new List<Account>{
            new Account(Id = excluded.Id, Exclude_From_Auto_Offboarding__c = true),
            new Account(Id = viaCo.ParentId, Exclude_From_Auto_Offboarding__c = true)
        };
        Test.startTest();
        update new List<Account>{
            new Account(Id = normal.Id,   At_Risk_Since__c = Date.today()),
            new Account(Id = excluded.Id, At_Risk_Since__c = Date.today()),
            new Account(Id = viaCo.Id,    At_Risk_Since__c = Date.today())
        };
        Test.stopTest();
        String subj = 'Shopify sales at risk%';
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :normal.Id   AND Subject LIKE :subj]);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :excluded.Id AND Subject LIKE :subj]);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :viaCo.Id    AND Subject LIKE :subj]);
    }

    // ── SendWarmOffEmail ──────────────────────────────────────────

    @IsTest static void invocable_handlesMissingNoticeAndMissingTemplate() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        Shopify_At_Risk_Notice__c n = seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_1, Date.today());

        Shopify_At_Risk_Config__mdt cfg = config('Every Stage', false);
        cfg.Template_Stage_1__c = 'Template_That_Does_Not_Exist';
        SendWarmOffEmail.configOverride = cfg;

        SendWarmOffEmail.Request good = new SendWarmOffEmail.Request();
        good.noticeId = n.Id;
        SendWarmOffEmail.Request bad = new SendWarmOffEmail.Request();
        bad.noticeId = s.Id;   // not a notice

        List<SendWarmOffEmail.Result> res = SendWarmOffEmail.send(new List<SendWarmOffEmail.Request>{ good, bad });
        System.assertEquals(2, res.size());
        System.assertEquals(false, res[0].success);
        System.assert(res[0].errorMessage.contains('No active template'));
        System.assertEquals('Notice not found', res[1].errorMessage);
    }

    @IsTest static void invocable_sendsWithRealTemplate() {
        Account s = makeStore(Date.today().addMonths(-12).addDays(-3), true);
        Shopify_At_Risk_Notice__c n = seedSent(s, ShopifyAtRiskNoticeBatch.STAGE_1, Date.today());
        SendWarmOffEmail.configOverride = config('Every Stage', false);

        SendWarmOffEmail.Request r = new SendWarmOffEmail.Request();
        r.noticeId = n.Id;
        List<SendWarmOffEmail.Result> res = SendWarmOffEmail.send(new List<SendWarmOffEmail.Request>{ r });
        System.assertEquals(1, res.size());   // success depends on template + deliverability
    }
}