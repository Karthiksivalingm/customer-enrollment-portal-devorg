/**
 * Tests for MraEffectiveDateBatch and MraEffectiveDateScheduler.
 *
 * Assumptions (adjust if your org differs):
 *  - Company__c is a lookup to Account.
 *  - The Marketing_Reward_Association__c trigger calls MRASendToBoomi.validate
 *    on before insert / before update. Test data is built so it passes those
 *    rules, and one test deliberately fails them to cover the batch's
 *    partial-save error branch.
 *  - Add any other required MRA fields in newMra().
 */
@IsTest
private class MraEffectiveDateBatchTest {

    private static final Id PROG_RT_ID =
        Schema.SObjectType.Marketing_Reward_Association__c
            .getRecordTypeInfosByDeveloperName()
            .get('Program_Association')
            .getRecordTypeId();

    /* =====================================================
     * Helpers
     * ===================================================== */

    /*
     * The MRA validation rule only allows MRAs on Companies whose status
     * is "uLab Account".
     *
     * Set COMPANY_STATUS_FIELD to the Account field API name used in that
     * validation rule (e.g. 'Company_Status__c' or 'Type'). If left null,
     * the test auto-detects the first Account picklist field that has a
     * "uLab Account" value.
     */
    private static final String COMPANY_STATUS_FIELD = null;
    private static final String COMPANY_STATUS_VALUE = 'uLab Account';

    private static String companyStatusField {
        get {
            if (companyStatusField == null) {
                companyStatusField = COMPANY_STATUS_FIELD != null
                    ? COMPANY_STATUS_FIELD
                    : findStatusField();
            }
            return companyStatusField;
        }
        set;
    }

    private static String findStatusField() {
        for (Schema.SObjectField f : Schema.SObjectType.Account.fields.getMap().values()) {
            Schema.DescribeFieldResult d = f.getDescribe();
            if (d.getType() != Schema.DisplayType.PICKLIST || !d.isUpdateable()) {
                continue;
            }
            for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                if (pe.isActive() && pe.getValue() == COMPANY_STATUS_VALUE) {
                    return d.getName();
                }
            }
        }
        throw new IllegalArgumentException(
            'No Account picklist field with value "' + COMPANY_STATUS_VALUE +
            '" found. Set COMPANY_STATUS_FIELD in MraEffectiveDateBatchTest.');
    }

    private static Account newCompany(String name) {
        Account acc = new Account(Name = name);
        acc.put(companyStatusField, COMPANY_STATUS_VALUE);
        return acc;
    }

    private static Account insertCompany(String name) {
        Account acc = newCompany(name);
        insert acc;
        return acc;
    }

    /*
     * The MRA validation rule requires a Marketing Reward to be selected.
     *
     * Set MARKETING_REWARD_FIELD to the MRA lookup field API name used in
     * that validation rule (e.g. 'Marketing_Reward__c'). If left null, the
     * test auto-detects the MRA lookup that points to an object whose name
     * contains "Marketing_Reward".
     *
     * If the Marketing Reward object has its own required fields or
     * validation rules, set them in newMarketingReward().
     */
    private static final String MARKETING_REWARD_FIELD = 'Marketing_Program__c';

    // Used for Marketing_Reward__c.Name__c, which feeds MRA.Program_Name__c.
    // Follows the real naming pattern (e.g. "uPP 3 Star - 2022"); must contain
    // 'uPP' or 'New' for RewardAssociationTrigger's start-date logic.
    private static final String PROGRAM_NAME =
        'uPP 3 Star - ' + String.valueOf(Date.today().year());

    /*
     * Record type of the Marketing Rewards used by real Program Associations.
     * The Marketing_Program__c lookup filter only accepts rewards of this type.
     * Set REWARD_RECORD_TYPE_DEVNAME (Object Manager > Marketing Reward >
     * Record Types) to avoid relying on the Id below.
     */
    private static final String REWARD_RECORD_TYPE_DEVNAME = 'Marketing_Program';
    private static final Id KNOWN_REWARD_RECORD_TYPE_ID = '0126g000000bO6PAAU';

    private static Id rewardRecordTypeId(Schema.SObjectType rewardType) {
        Schema.DescribeSObjectResult d = rewardType.getDescribe();
        if (REWARD_RECORD_TYPE_DEVNAME != null) {
            return d.getRecordTypeInfosByDeveloperName()
                .get(REWARD_RECORD_TYPE_DEVNAME)
                .getRecordTypeId();
        }
        return d.getRecordTypeInfosById().containsKey(KNOWN_REWARD_RECORD_TYPE_ID)
            ? KNOWN_REWARD_RECORD_TYPE_ID
            : null;
    }

    private static Id rewardIdCache;

    private static Schema.DescribeFieldResult rewardLookup {
        get {
            if (rewardLookup == null) {
                rewardLookup = findRewardLookup();
            }
            return rewardLookup;
        }
        set;
    }

    private static Schema.DescribeFieldResult findRewardLookup() {
        Map<String, Schema.SObjectField> mraFields =
            Schema.SObjectType.Marketing_Reward_Association__c.fields.getMap();

        if (MARKETING_REWARD_FIELD != null) {
            return mraFields.get(MARKETING_REWARD_FIELD).getDescribe();
        }

        for (Schema.SObjectField f : mraFields.values()) {
            Schema.DescribeFieldResult d = f.getDescribe();
            if (d.getType() != Schema.DisplayType.REFERENCE || !d.isCreateable()) {
                continue;
            }
            for (Schema.SObjectType target : d.getReferenceTo()) {
                String objName = target.getDescribe().getName();
                if (objName.containsIgnoreCase('Marketing_Reward')
                    && objName != 'Marketing_Reward_Association__c') {
                    return d;
                }
            }
        }
        throw new IllegalArgumentException(
            'No Marketing Reward lookup found on Marketing_Reward_Association__c. ' +
            'Set MARKETING_REWARD_FIELD in MraEffectiveDateBatchTest.');
    }

    private static SObject newMarketingReward() {
        Schema.SObjectType rewardType = rewardLookup.getReferenceTo()[0];
        SObject reward = rewardType.newSObject();

        Id rewardRtId = rewardRecordTypeId(rewardType);
        if (rewardRtId != null) {
            reward.put('RecordTypeId', rewardRtId);
        }

        Map<String, Schema.SObjectField> rewardFields =
            rewardType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult nameField = rewardFields.get('Name').getDescribe();
        if (nameField.isCreateable() && !nameField.isAutoNumber()) {
            reward.put('Name', PROGRAM_NAME);
        }

        // MRA.Program_Name__c is the formula Marketing_Program__r.Name__c,
        // and RewardAssociationTrigger calls .contains() on it without a null check.
        reward.put('Name__c', PROGRAM_NAME);

        // The Marketing_Program__c lookup filter only accepts live rewards.
        // Status__c is a formula (not writable), so make the reward live
        // through its date range instead.
        putDate(reward, 'Start_Date__c', Date.today().addDays(-30));
        putDate(reward, 'End_Date__c',   Date.today().addDays(365));

        // TODO: set any other required fields / values the MRA rule treats as "relevant"

        return reward;
    }

    private static void putDate(SObject rec, String fieldName, Date value) {
        Schema.DisplayType t = rec.getSObjectType().getDescribe()
            .fields.getMap().get(fieldName).getDescribe().getType();
        if (t == Schema.DisplayType.DATETIME) {
            rec.put(fieldName, Datetime.newInstance(value, Time.newInstance(0, 0, 0, 0)));
        } else {
            rec.put(fieldName, value);
        }
    }

    private static Id getRewardId() {
        if (rewardIdCache == null) {
            SObject reward = newMarketingReward();
            insert reward;
            rewardIdCache = reward.Id;
        }
        return rewardIdCache;
    }

    private static Marketing_Reward_Association__c newMra(
        Id companyId,
        Date effectiveDate,
        Date endDate,
        Boolean sendToBoomi
    ) {
        Marketing_Reward_Association__c mra = new Marketing_Reward_Association__c(
            RecordTypeId      = PROG_RT_ID,
            Company__c        = companyId,
            Effective_Date__c = effectiveDate,
            End_Date__c       = endDate,
            Send_to_Boomi__c  = sendToBoomi
            // TODO: add any other required fields here
        );
        mra.put(rewardLookup.getName(), getRewardId());

        // RewardAssociationTrigger calls Program_Name__c.contains(...) with no
        // null check. Set it directly if it's an editable field; if it's a
        // formula, it's fed from the Marketing Reward (see newMarketingReward).
        Schema.DescribeFieldResult progName =
            Schema.SObjectType.Marketing_Reward_Association__c.fields.Program_Name__c;
        if (progName.isCreateable()) {
            mra.put('Program_Name__c', PROGRAM_NAME);
        }
        return mra;
    }

    private static void runBatch() {
        Test.startTest();
        Database.executeBatch(new MraEffectiveDateBatch(), 200);
        Test.stopTest();
    }

    private static Boolean flagOf(Id mraId) {
        return [
            SELECT Send_to_Boomi__c
            FROM Marketing_Reward_Association__c
            WHERE Id = :mraId
        ].Send_to_Boomi__c;
    }

    /* =====================================================
     * Batch - happy paths
     * ===================================================== */

    @IsTest
    static void effectiveToday_openEnded_isFlagged() {
        Account co = insertCompany('Open Ended Co');
        Marketing_Reward_Association__c mra = newMra(co.Id, Date.today(), null, false);
        insert mra;

        runBatch();

        Assert.isTrue(flagOf(mra.Id),
            'Open-ended record effective today should be flagged.');
    }

    @IsTest
    static void effectiveToday_futureEndDate_isFlagged() {
        Account co = insertCompany('Future End Co');
        Marketing_Reward_Association__c mra =
            newMra(co.Id, Date.today(), Date.today().addDays(30), false);
        insert mra;

        runBatch();

        Assert.isTrue(flagOf(mra.Id),
            'Record effective today with a future End Date should be flagged.');
    }

    @IsTest
    static void effectiveToday_endsToday_isFlagged() {
        Account co = insertCompany('Ends Today Co');
        Marketing_Reward_Association__c mra =
            newMra(co.Id, Date.today(), Date.today(), false);
        insert mra;

        runBatch();

        Assert.isTrue(flagOf(mra.Id),
            'End Date = today is still active (boundary) and should be flagged.');
    }

    @IsTest
    static void bulk_200Records_allFlagged() {
        List<Account> companies = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            companies.add(newCompany('Bulk Co ' + i));
        }
        insert companies;

        List<Marketing_Reward_Association__c> mras = new List<Marketing_Reward_Association__c>();
        for (Account co : companies) {
            mras.add(newMra(co.Id, Date.today(), null, false));
        }
        insert mras;

        runBatch();

        Integer flagged = [
            SELECT COUNT()
            FROM Marketing_Reward_Association__c
            WHERE Id IN :mras AND Send_to_Boomi__c = true
        ];
        Assert.areEqual(200, flagged, 'All 200 records should be flagged.');
    }

    /* =====================================================
     * Batch - records the query should ignore
     * ===================================================== */

    @IsTest
    static void notEffectiveToday_isIgnored() {
        Account coPast   = insertCompany('Past Co');
        Account coFuture = insertCompany('Future Co');

        Marketing_Reward_Association__c pastMra =
            newMra(coPast.Id, Date.today().addDays(-1), null, false);
        Marketing_Reward_Association__c futureMra =
            newMra(coFuture.Id, Date.today().addDays(1), null, false);
        insert new List<Marketing_Reward_Association__c>{ pastMra, futureMra };

        runBatch();

        Assert.isFalse(flagOf(pastMra.Id),
            'Record that started yesterday is not picked up by the batch.');
        Assert.isFalse(flagOf(futureMra.Id),
            'Record starting tomorrow must not be flagged.');
    }

    /* =====================================================
     * Batch - one-per-Company rule
     * ===================================================== */

    @IsTest
    static void companyAlreadyClaimed_isSkipped() {
        /*
         * The "Copy pricing fields on MRA record from MR record on Effective
         * date" flow switches Send to Boomi on itself when a record with
         * today's Effective Date is saved, which collides with MRASendToBoomi
         * Rule 1 when the Company is already claimed. So the newcomer is saved
         * with a future Effective Date and handed straight to execute(): the
         * batch only checks whether the Company is already claimed.
         */
        Account co = insertCompany('Claimed Co');

        // Already flagged, active since last week (passes MRASendToBoomi rules)
        Marketing_Reward_Association__c existing =
            newMra(co.Id, Date.today().addDays(-7), null, true);
        insert existing;

        Marketing_Reward_Association__c newcomer =
            newMra(co.Id, Date.today().addDays(5), null, false);
        insert newcomer;

        List<Marketing_Reward_Association__c> scope = [
            SELECT Id, Company__c, Send_to_Boomi__c, Effective_Date__c, End_Date__c
            FROM Marketing_Reward_Association__c
            WHERE Id = :newcomer.Id
        ];

        Test.startTest();
        new MraEffectiveDateBatch().execute(null, scope);
        Test.stopTest();

        Assert.isTrue(flagOf(existing.Id), 'Existing flagged record stays flagged.');
        Assert.isFalse(flagOf(newcomer.Id),
            'Company already has a flagged record, so the new one is skipped.');
    }

    @IsTest
    static void sameCompanyTwiceInScope_onlyOneUpdated() {
        /*
         * RewardAssociationTrigger rejects an update when the Company already
         * has another active Program Association, so two real active records
         * on one Company can't be used here. Instead the same record is passed
         * twice in the scope: the batch's in-scope dedup must drop the second
         * copy, otherwise Database.update throws "Duplicate id in list".
         */
        Account co = insertCompany('Twin Co');
        Marketing_Reward_Association__c mra = newMra(co.Id, Date.today(), null, false);
        insert mra;

        Marketing_Reward_Association__c row = [
            SELECT Id, Company__c, Send_to_Boomi__c, Effective_Date__c, End_Date__c
            FROM Marketing_Reward_Association__c
            WHERE Id = :mra.Id
        ];
        List<Marketing_Reward_Association__c> scope =
            new List<Marketing_Reward_Association__c>{ row, row.clone(true) };

        Test.startTest();
        new MraEffectiveDateBatch().execute(null, scope);
        Test.stopTest();

        Assert.isTrue(flagOf(mra.Id),
            'The first record for the Company is flagged and the duplicate is skipped.');
    }

    /* =====================================================
     * Batch - failed update is logged, not thrown
     * ===================================================== */

    @IsTest
    static void failedUpdate_isHandledWithoutException() {
        Account co = insertCompany('Stale Scope Co');

        // Not active yet, so MRASendToBoomi Rule 2 will reject the update.
        Marketing_Reward_Association__c mra =
            newMra(co.Id, Date.today().addDays(5), null, false);
        insert mra;

        List<Marketing_Reward_Association__c> scope = [
            SELECT Id, Company__c, Send_to_Boomi__c, Effective_Date__c, End_Date__c
            FROM Marketing_Reward_Association__c
            WHERE Id = :mra.Id
        ];

        Test.startTest();
        new MraEffectiveDateBatch().execute(null, scope);
        Test.stopTest();

        Assert.isFalse(flagOf(mra.Id),
            'Validation should reject the update; the batch must swallow the error.');
    }

    /* =====================================================
     * Scheduler
     * ===================================================== */

    @IsTest
    static void scheduler_registersJob() {
        String cron = '0 0 1 * * ?'; // 01:00 every day

        Test.startTest();
        String jobId = System.schedule(
            'MraEffectiveDateScheduler Test', cron, new MraEffectiveDateScheduler());

        CronTrigger ct = [
            SELECT CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Test.stopTest();

        Assert.areEqual(cron, ct.CronExpression, 'Cron expression should match.');
        Assert.areEqual(0, ct.TimesTriggered, 'Job should not have fired yet.');
        Assert.isNotNull(ct.NextFireTime, 'Next fire time should be set.');
    }

    @IsTest
    static void scheduler_execute_runsBatch() {
        Account co = insertCompany('Scheduler Co');
        Marketing_Reward_Association__c mra = newMra(co.Id, Date.today(), null, false);
        insert mra;

        Test.startTest();
        new MraEffectiveDateScheduler().execute(null);
        Test.stopTest();

        Assert.isTrue(flagOf(mra.Id),
            'Scheduler should launch the batch, which flags the record.');
    }
}