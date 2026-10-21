/**
 * Retailer inactivity warm-off (SellGoodr ToS Section 22).
 * Daily batch: sends 5 emails at 12 / 15 / 17 / 17.5 months after a store's last
 * Shopify order, and at 18 months sets Account.Active__c = false and sends Email 5.
 * Each email = one Shopify_At_Risk_Notice__c per contact; the insert fires the
 * "Send Shopify At Risk Notice" flow, which sends it through SendWarmOffEmail.
 * Settings: Shopify_At_Risk_Config__mdt, record 'Default'.
 * Stores with Exclude_From_Auto_Offboarding__c ticked (on the store or its Company) are skipped.
 * Schedule: daily 5:00 AM (cron 0 0 5 * * ?), after the night order sync.
 */
public class ShopifyAtRiskNoticeBatch
    implements Database.Batchable<SObject>,
               Database.Stateful,
               Schedulable {

    // Stage__c picklist values, one per email
    public static final String STAGE_1 = 'Month 12';
    public static final String STAGE_2 = 'Month 15';
    public static final String STAGE_3 = 'Month 17';
    public static final String STAGE_4 = '15-Day Reminder';
    public static final String STAGE_5 = 'Deactivation';

    // Status__c picklist values
    public static final String ST_PENDING    = 'Pending Send';
    public static final String ST_SENT       = 'Notice Sent';
    public static final String ST_FAILED     = 'Send Failed';
    public static final String ST_RECOVERED  = 'Recovered';
    public static final String ST_DUE        = 'Offboard Due';
    public static final String ST_OFFBOARDED = 'Offboarded';

    // At_Risk_Mode__c values: how the at-risk checkbox gates Emails 1-4
    public static final String MODE_EVERY = 'Every Stage';
    public static final String MODE_ENTRY = 'Entry Only';
    public static final String MODE_OFF   = 'Off';

    private static final Integer MONTHS_STAGE_1 = 12;
    private static final Integer MONTHS_STAGE_2 = 15;
    private static final Integer MONTHS_STAGE_3 = 17;

    private Shopify_At_Risk_Config__mdt cfg;
    private Boolean legacyRun = false;

    // Counters for the legacy single-notice run
    private Integer created    = 0;
    private Integer suppressed = 0;
    private Integer failed     = 0;

    // Counters for the warm-off run, printed in finish()
    private Integer wStores        = 0;
    private Integer wCreated       = 0;
    private Integer wFailed        = 0;
    private Integer wGated         = 0;
    private Integer wNoContacts    = 0;
    private Integer wTasks         = 0;
    private Integer wOffboarded    = 0;
    private Integer wDue           = 0;
    private Integer wPastNoWarning = 0;
    private Integer wReactivated   = 0;

    public ShopifyAtRiskNoticeBatch() {}

    // Tests pass an in-memory config (custom metadata cannot be inserted in tests)
    @TestVisible
    private ShopifyAtRiskNoticeBatch(Shopify_At_Risk_Config__mdt cfg) {
        this.cfg = cfg;
    }

    @TestVisible
    private ShopifyAtRiskNoticeBatch(Shopify_At_Risk_Config__mdt cfg, Boolean legacyRun) {
        this.cfg       = cfg;
        this.legacyRun = legacyRun;
    }

    // Scheduler entry point: starts the warm-off run with 50 stores per chunk
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new ShopifyAtRiskNoticeBatch(), 50);
    }

    // ═════════════════════════════ START ═════════════════════════════
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (cfg == null) {
            cfg = Shopify_At_Risk_Config__mdt.getInstance('Default');
        }
        // Kill switch: config inactive → empty run
        if (cfg == null || !cfg.Active__c) {
            System.debug('At-Risk Notice batch SKIPPED — config inactive');
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = null]);
        }
        return legacyRun ? legacyStart() : warmOffStart();
    }

    // Selects active store locations with no Shopify order for 12+ months.
    // The at-risk flag is not filtered here so Month 18 still runs when it has dropped.
    private Database.QueryLocator warmOffStart() {
        Map<String, Object> binds = new Map<String, Object>{
            'cutoff' => Date.today().addMonths(-MONTHS_STAGE_1)
        };
        String q =
            'SELECT Id, Name, OwnerId, ParentId, Last_Shopify_Order_Date__c, ' +
            '       Shopify_Sales_At_Risk__c, At_Risk_Since__c, ' +
            '       Current_YTD_Sales__c, Prior_YTD_Sales__c, YTD_Performance_Percent__c, ' +
            '       Current_Rolling_12_Month_Sales__c, R12_Sales_Decline_Ratio__c ' +
            'FROM Account ' +
            'WHERE RecordType.DeveloperName = \'Store_Location\' ' +
            'AND ParentId != null ' +
            'AND Active__c = true ' +
            'AND Shopify_Company_Id__c != null ' +
            'AND Last_Shopify_Order_Date__c != null ' +
            'AND Last_Shopify_Order_Date__c <= :cutoff ' +
            // Account manager exception: store or its Company excluded from auto-offboarding
            'AND Exclude_From_Auto_Offboarding__c = false ' +
            'AND Parent.Exclude_From_Auto_Offboarding__c = false';

        // Sandbox only: limits the run to test stores (blank in production)
        if (String.isNotBlank(cfg.Test_Store_Name_Filter__c)) {
            q += ' AND Name LIKE :nameFilter';
            binds.put('nameFilter', cfg.Test_Store_Name_Filter__c);
        }
        System.debug('Warm-off run started: ' + DateTime.now());
        return Database.getQueryLocatorWithBinds(q, binds, AccessLevel.SYSTEM_MODE);
    }

    // Legacy run (only when Legacy_Notice_Enabled__c): one row per contact of an at-risk store
    private Database.QueryLocator legacyStart() {
        System.debug('Legacy At-Risk Notice run started: ' + DateTime.now());
        String q =
            'SELECT Id, AccountId, ContactId, Account.At_Risk_Since__c, ' +
            '       Account.Current_YTD_Sales__c, Account.Prior_YTD_Sales__c, ' +
            '       Account.YTD_Performance_Percent__c, ' +
            '       Account.Current_Rolling_12_Month_Sales__c, Account.R12_Sales_Decline_Ratio__c ' +
            'FROM AccountContactRelation ' +
            'WHERE Account.Shopify_Sales_At_Risk__c = true ' +
            'AND Account.RecordType.DeveloperName = \'Store_Location\' ' +
            'AND Account.ParentId != null ' +
            'AND Account.At_Risk_Since__c != null ' +
            'AND Account.Exclude_From_Auto_Offboarding__c = false ' +
            'AND Account.Parent.Exclude_From_Auto_Offboarding__c = false ' +
            'AND IsActive = true ' +
            'AND Contact.Email != null' +
            consentFilter();
        return Database.getQueryLocatorWithBinds(q, new Map<String, Object>(), AccessLevel.SYSTEM_MODE);
    }

    // ═════════════════════════════ EXECUTE ═════════════════════════════
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (legacyRun) {
            List<AccountContactRelation> rows = new List<AccountContactRelation>();
            for (SObject o : scope) rows.add((AccountContactRelation) o);
            legacyExecute(rows);
        } else {
            List<Account> stores = new List<Account>();
            for (SObject o : scope) stores.add((Account) o);
            warmOffExecute(stores);
        }
    }

    // Warm-off stage engine: for each store, works out the one email due today and sends it
    @TestVisible
    private void warmOffExecute(List<Account> stores) {
        Date    today       = Date.today();
        Integer deactMonths = intOr(cfg.Deactivation_Months__c, 18);
        String  mode        = String.isBlank(cfg.At_Risk_Mode__c) ? MODE_EVERY : cfg.At_Risk_Mode__c;

        Map<Id, Account> storeById = new Map<Id, Account>(stores);
        wStores += stores.size();

        // 1. Load what each store has already received in its CURRENT series
        //    (series = notices with the same last order date as the store)
        Map<Id, SeriesState> state = new Map<Id, SeriesState>();
        for (Account s : stores) state.put(s.Id, new SeriesState());

        for (Shopify_At_Risk_Notice__c n : [
            SELECT Id, Store_Account__c, Stage__c, Status__c, Email_Sent__c,
                   Notice_Date__c, Notice_Key__c, Last_Order_Date_At_Notice__c
            FROM Shopify_At_Risk_Notice__c
            WHERE Store_Account__c IN :storeById.keySet()
            AND Stage__c != null
        ]) {
            Account s = storeById.get(n.Store_Account__c);
            if (n.Last_Order_Date_At_Notice__c != s.Last_Shopify_Order_Date__c) continue;  // older series

            SeriesState st = state.get(s.Id);
            st.keys.add(n.Notice_Key__c);

            Boolean sent = n.Email_Sent__c == true || n.Status__c == ST_SENT || n.Status__c == ST_DUE;
            if (!sent) continue;

            st.sentStages.add(n.Stage__c);
            st.sentNotices.add(n);
            if (n.Stage__c == STAGE_3 && n.Notice_Date__c != null &&
                (st.finalWarningDate == null || n.Notice_Date__c < st.finalWarningDate)) {
                st.finalWarningDate = n.Notice_Date__c;
            }
        }

        // 2. Decide the next stage per store; every date = last order + N months
        Map<Id, String> stageFor     = new Map<Id, String>();
        Map<Id, Date>   deactDateFor = new Map<Id, Date>();
        List<Account>   due          = new List<Account>();

        for (Account s : stores) {
            SeriesState st       = state.get(s.Id);
            Date        last     = s.Last_Shopify_Order_Date__c;
            Date        policy   = last.addMonths(deactMonths);                   // deactivation date
            Date        email4At = last.addMonths(MONTHS_STAGE_3).addDays(15);    // 17.5 months
            Boolean     sent3    = st.sentStages.contains(STAGE_3);
            Boolean     sent4    = st.sentStages.contains(STAGE_4);
            String      stage    = null;

            // Store was reactivated by hand after Email 5 without a new order: leave it alone
            if (st.sentStages.contains(STAGE_5)) {
                wReactivated++;
                continue;
            }

            if (today >= policy) {
                // 18 months reached: offboard only if the Email 3 warning was actually sent
                if (sent3) due.add(s);
                else       wPastNoWarning++;       // never warned (go-live backlog): hold
                continue;
            } else if (today >= email4At) {
                if (!sent3)      stage = STAGE_3;  // late joiner gets the warning first
                else if (!sent4) stage = STAGE_4;
            } else if (today >= last.addMonths(MONTHS_STAGE_3)) {
                if (!sent3) stage = STAGE_3;
            } else if (today >= last.addMonths(MONTHS_STAGE_2)) {
                if (!st.sentStages.contains(STAGE_2)) stage = STAGE_2;
            } else if (!st.sentStages.contains(STAGE_1)) {
                stage = STAGE_1;
            }

            if (stage == null) continue;

            // Client condition "AND at risk = True" for Emails 1-4 (see At_Risk_Mode__c)
            if (!passesGate(mode, s.Shopify_Sales_At_Risk__c, st)) {
                wGated++;
                continue;
            }
            stageFor.put(s.Id, stage);
            deactDateFor.put(s.Id, policy);
        }

        // 3. Month 18: Auto Offboard on → deactivate + queue Email 5; off → mark notices Offboard Due
        if (!due.isEmpty()) {
            if (cfg.Auto_Offboard__c) {
                for (Id sid : warmOffOffboard(due, state)) {
                    stageFor.put(sid, STAGE_5);
                    deactDateFor.put(sid, today);
                }
            } else {
                List<Shopify_At_Risk_Notice__c> dueUpdates = new List<Shopify_At_Risk_Notice__c>();
                for (Account s : due) {
                    for (Shopify_At_Risk_Notice__c n : state.get(s.Id).sentNotices) {
                        if (n.Status__c != ST_DUE) {
                            dueUpdates.add(new Shopify_At_Risk_Notice__c(Id = n.Id, Status__c = ST_DUE));
                        }
                    }
                }
                if (!dueUpdates.isEmpty()) Database.update(dueUpdates, false);
                wDue += due.size();
            }
        }

        if (stageFor.isEmpty()) return;

        // 4. Recipients: contacts linked to the store through AccountContactRelation
        String q =
            'SELECT AccountId, ContactId FROM AccountContactRelation ' +
            'WHERE AccountId IN :storeIds AND IsActive = true AND Contact.Email != null' +
            consentFilter();
        List<AccountContactRelation> acrs = Database.queryWithBinds(
            q, new Map<String, Object>{ 'storeIds' => stageFor.keySet() }, AccessLevel.SYSTEM_MODE
        );

        // Build one notice per contact; the key stops the same email being sent twice
        List<Shopify_At_Risk_Notice__c> toInsert = new List<Shopify_At_Risk_Notice__c>();
        Set<Id> withContact = new Set<Id>();

        for (AccountContactRelation r : acrs) {
            Account s     = storeById.get(r.AccountId);
            String  stage = stageFor.get(r.AccountId);
            String  key   = String.valueOf(r.ContactId) + '-' + String.valueOf(r.AccountId) + '-' +
                            stage + '-' + String.valueOf(s.Last_Shopify_Order_Date__c);

            withContact.add(r.AccountId);
            SeriesState st = state.get(r.AccountId);
            if (st.keys.contains(key)) continue;
            st.keys.add(key);

            toInsert.add(new Shopify_At_Risk_Notice__c(
                Store_Account__c             = r.AccountId,
                Contact__c                   = r.ContactId,
                Stage__c                     = stage,
                Status__c                    = ST_PENDING,
                Notice_Key__c                = key,
                At_Risk_Since__c             = s.At_Risk_Since__c,
                Last_Order_Date_At_Notice__c = s.Last_Shopify_Order_Date__c,
                Months_Inactive_At_Notice__c = monthsInactive(s.Last_Shopify_Order_Date__c, today),
                Deactivation_Date__c         = deactDateFor.get(r.AccountId),
                // Sales snapshot frozen at the time of the email
                YTD_Sales_At_Notice__c           = s.Current_YTD_Sales__c,
                Prior_YTD_Sales_At_Notice__c     = s.Prior_YTD_Sales__c,
                Performance_Percent_At_Notice__c = s.YTD_Performance_Percent__c,
                R12_Sales_At_Notice__c           = s.Current_Rolling_12_Month_Sales__c,
                Decline_Ratio_At_Notice__c       = s.R12_Sales_Decline_Ratio__c
            ));
        }

        for (Id sid : stageFor.keySet()) {
            if (!withContact.contains(sid)) {
                wNoContacts++;
                System.debug('No reachable contact: store ' + sid + ' at ' + stageFor.get(sid));
            }
        }
        if (toInsert.isEmpty()) return;

        // Insert fires the send flow, which emails each notice in this same transaction
        Set<Id> stage3Stores = new Set<Id>();
        Database.SaveResult[] res = Database.insert(toInsert, false);
        for (Integer i = 0; i < res.size(); i++) {
            if (res[i].isSuccess()) {
                wCreated++;
                if (toInsert[i].Stage__c == STAGE_3) stage3Stores.add(toInsert[i].Store_Account__c);
            } else {
                wFailed++;
                System.debug('Warm-off notice insert failed: ' + res[i].getErrors()[0].getMessage());
            }
        }

        // 5. Month 17: task for the store owner to contact the retailer ("Email + Rep Task")
        List<Task> tasks = new List<Task>();
        for (Id sid : stage3Stores) {
            Account s = storeById.get(sid);
            tasks.add(new Task(
                WhatId       = sid,
                OwnerId      = s.OwnerId,
                Subject      = 'Retailer inactivity: 30-day deactivation warning sent',
                Priority     = 'High',
                Status       = 'Not Started',
                ActivityDate = today.addDays(7),
                Description  = s.Name + ' has not ordered since ' + s.Last_Shopify_Order_Date__c.format() +
                               '. Email 3 (30-day warning) was sent today. Scheduled deactivation: ' +
                               deactDateFor.get(sid).format() + '. Please reach out before that date.'
            ));
        }
        if (!tasks.isEmpty()) {
            for (Database.SaveResult r : Database.insert(tasks, false)) {
                if (r.isSuccess()) wTasks++;
                else System.debug('Task insert failed: ' + r.getErrors()[0].getMessage());
            }
        }
    }

    // Legacy run: one "Shopify At Risk Notice" per contact per at-risk episode (no offboarding)
    @TestVisible
    private void legacyExecute(List<AccountContactRelation> scope) {
        // Key = contact + store + episode start date, so each episode is notified once
        Map<String, AccountContactRelation> byKey = new Map<String, AccountContactRelation>();
        for (AccountContactRelation r : scope) {
            byKey.put(String.valueOf(r.ContactId) + '-' + String.valueOf(r.AccountId) + '-' +
                      String.valueOf(r.Account.At_Risk_Since__c), r);
        }

        Set<String> existing = new Set<String>();
        for (Shopify_At_Risk_Notice__c n : [
            SELECT Notice_Key__c FROM Shopify_At_Risk_Notice__c WHERE Notice_Key__c IN :byKey.keySet()
        ]) {
            existing.add(n.Notice_Key__c);
        }

        List<Shopify_At_Risk_Notice__c> toInsert = new List<Shopify_At_Risk_Notice__c>();
        for (String key : byKey.keySet()) {
            if (existing.contains(key)) { suppressed++; continue; }
            AccountContactRelation r = byKey.get(key);
            toInsert.add(new Shopify_At_Risk_Notice__c(
                Store_Account__c                 = r.AccountId,
                Contact__c                       = r.ContactId,
                At_Risk_Since__c                 = r.Account.At_Risk_Since__c,
                Status__c                        = ST_PENDING,
                Notice_Key__c                    = key,
                YTD_Sales_At_Notice__c           = r.Account.Current_YTD_Sales__c,
                Prior_YTD_Sales_At_Notice__c     = r.Account.Prior_YTD_Sales__c,
                Performance_Percent_At_Notice__c = r.Account.YTD_Performance_Percent__c,
                R12_Sales_At_Notice__c           = r.Account.Current_Rolling_12_Month_Sales__c,
                Decline_Ratio_At_Notice__c       = r.Account.R12_Sales_Decline_Ratio__c
            ));
        }
        if (toInsert.isEmpty()) return;

        for (Database.SaveResult sr : Database.insert(toInsert, false)) {
            if (sr.isSuccess()) {
                created++;
            } else {
                failed++;
                System.debug('Notice insert failed: ' + sr.getErrors()[0].getMessage());
            }
        }
    }

    // ═════════════════════════════ FINISH ═════════════════════════════
    // Closes notices org-wide: Recovered when the store ordered again, Offboarded when it is inactive
    public void finish(Database.BatchableContext bc) {
        if (legacyRun) {
            System.debug('Legacy At-Risk Notice run complete | Created: ' + created +
                         ' | Suppressed: ' + suppressed + ' | Failed: ' + failed);
            return;
        }
        if (cfg == null || !cfg.Active__c) return;

        Date today = Date.today();
        Map<Id, Shopify_At_Risk_Notice__c> updates = new Map<Id, Shopify_At_Risk_Notice__c>();
        Integer cRecovered  = 0;
        Integer cOffboarded = 0;

        // Pass 1: old single notices → Recovered when the store is no longer at risk
        for (Shopify_At_Risk_Notice__c n : [
            SELECT Id FROM Shopify_At_Risk_Notice__c
            WHERE Status__c IN ('Pending Send', 'Notice Sent', 'Offboard Due')
            AND Stage__c = null
            AND Store_Account__r.Shopify_Sales_At_Risk__c = false
            AND Store_Account__r.Active__c = true
            LIMIT 10000
        ]) {
            updates.put(n.Id, new Shopify_At_Risk_Notice__c(
                Id = n.Id, Status__c = ST_RECOVERED, Recovered_Date__c = today));
            cRecovered++;
        }

        // Pass 2: warm-off notices → Recovered when the store has ordered since the notice
        Set<String> openStaged = new Set<String>{ ST_PENDING, ST_SENT, ST_DUE, ST_FAILED };
        for (Shopify_At_Risk_Notice__c n : [
            SELECT Id, Last_Order_Date_At_Notice__c, Store_Account__r.Last_Shopify_Order_Date__c
            FROM Shopify_At_Risk_Notice__c
            WHERE Status__c IN :openStaged
            AND Stage__c != null
            AND Store_Account__r.Active__c = true
            LIMIT 10000
        ]) {
            if (updates.containsKey(n.Id)) continue;
            Date storeLast = n.Store_Account__r.Last_Shopify_Order_Date__c;
            if (storeLast != null && n.Last_Order_Date_At_Notice__c != null &&
                storeLast > n.Last_Order_Date_At_Notice__c) {
                updates.put(n.Id, new Shopify_At_Risk_Notice__c(
                    Id = n.Id, Status__c = ST_RECOVERED, Recovered_Date__c = today));
                cRecovered++;
            }
        }

        // Pass 3: any open notice on an inactive store → Offboarded (batch or manual deactivation)
        for (Shopify_At_Risk_Notice__c n : [
            SELECT Id FROM Shopify_At_Risk_Notice__c
            WHERE Status__c IN ('Pending Send', 'Notice Sent', 'Offboard Due')
            AND Store_Account__r.Active__c = false
            LIMIT 10000
        ]) {
            if (updates.containsKey(n.Id)) continue;
            updates.put(n.Id, new Shopify_At_Risk_Notice__c(Id = n.Id, Status__c = ST_OFFBOARDED));
            cOffboarded++;
        }

        // One update for all passes. Each row is a fresh record (Id + changed fields only):
        // re-using the queried rows also sent their Store_Account__c lookup, which Salesforce rejected
        Integer updated = 0;
        if (!updates.isEmpty()) {
            for (Database.SaveResult sr : Database.update(updates.values(), false)) {
                if (sr.isSuccess()) updated++;
                else System.debug('Notice status update failed: ' + sr.getErrors()[0].getMessage());
            }
        }

        System.debug(
            'At-Risk Notice batch complete (warm-off run)' +
            ' | Stores evaluated: '               + wStores        +
            ' | Warm-off created: '               + wCreated       +
            ' | Warm-off insert failed: '         + wFailed        +
            ' | Held by at-risk gate: '           + wGated         +
            ' | Stores w/o contact: '             + wNoContacts    +
            ' | Rep tasks: '                      + wTasks         +
            ' | Warm-off offboarded: '            + wOffboarded    +
            ' | Warm-off due (auto off): '        + wDue           +
            ' | Past 18m, never warned (held): '  + wPastNoWarning +
            ' | Reactivated after Email 5 (skipped): ' + wReactivated +
            ' | Recovered: '                      + cRecovered     +
            ' | Swept to Offboarded: '            + cOffboarded    +
            ' | Updated OK: '                     + updated + ' of ' + updates.size()
        );

        // Optional legacy run creates the old single notice (Legacy_Notice_Enabled__c)
        if (cfg.Legacy_Notice_Enabled__c && !Test.isRunningTest()) {
            Database.executeBatch(new ShopifyAtRiskNoticeBatch(cfg, true), 200);
        }
    }

    // ═════════════════════════════ HELPERS ═════════════════════════════

    // Optional recipient filters from config: retailer opt-in and bounced emails
    private String consentFilter() {
        String f = '';
        if (cfg.Require_Opt_In__c)  f += ' AND Account.Retailer_Communication_Opt_In__c = true';
        if (cfg.Exclude_Bounced__c) f += ' AND Contact.IsEmailBounced = false';
        return f;
    }

    // Deactivates stores in two updates: A sets Active__c = false (the existing offboarding
    // flow stamps the running user), B re-stamps Offboarded By with the configured owner
    private Set<Id> warmOffOffboard(List<Account> due, Map<Id, SeriesState> state) {
        Id ownerId;
        if (String.isNotBlank(cfg.Offboard_Owner_Username__c)) {
            List<User> owners = [
                SELECT Id FROM User
                WHERE Username = :cfg.Offboard_Owner_Username__c AND IsActive = true LIMIT 1
            ];
            if (!owners.isEmpty()) ownerId = owners[0].Id;
        }

        // Phase A: switch off Shopify ordering and record the reason
        List<Account> accs = new List<Account>();
        for (Account s : due) {
            accs.add(new Account(
                Id                    = s.Id,
                Active__c             = false,
                Offboarding_Reason__c = cfg.Offboard_Reason__c,
                Offboarding_Notes__c  = ('Offboarded under Section 22 of the SellGoodr Terms of Service: ' +
                                         '18 months without a purchase. Last Shopify order ' +
                                         s.Last_Shopify_Order_Date__c.format() + '; final warning sent ' +
                                         state.get(s.Id).finalWarningDate.format() + '.').left(255)
            ));
        }

        Set<Id> disabled = new Set<Id>();
        Database.SaveResult[] res = Database.update(accs, false);
        for (Integer i = 0; i < res.size(); i++) {
            if (res[i].isSuccess()) disabled.add(accs[i].Id);
            else System.debug('Warm-off offboarding failed for ' + accs[i].Id + ': ' +
                              res[i].getErrors()[0].getMessage());
        }
        wOffboarded += disabled.size();

        // Phase B: without touching Active__c, so the offboarding flow does not fire again
        if (ownerId != null && !disabled.isEmpty()) {
            List<Account> reown = new List<Account>();
            for (Id accId : disabled) {
                reown.add(new Account(Id = accId, Offboarded_By__c = ownerId, Offboarding_Date__c = Date.today()));
            }
            Database.update(reown, false);
        }
        return disabled;
    }

    // Every Stage: flag needed at each stage | Entry Only: needed to start | Off: ignored
    private static Boolean passesGate(String mode, Boolean flagged, SeriesState st) {
        if (flagged == true || mode == MODE_OFF) return true;
        if (mode == MODE_ENTRY) return !st.sentStages.isEmpty();
        return false;
    }

    private static Decimal monthsInactive(Date lastOrder, Date today) {
        return (Decimal.valueOf(lastOrder.daysBetween(today)) / 30.4375).setScale(1);
    }

    private static Integer intOr(Decimal v, Integer dflt) {
        return v == null ? dflt : v.intValue();
    }

    // What one store's current series has already received
    public class SeriesState {
        public Set<String> keys       = new Set<String>();
        public Set<String> sentStages = new Set<String>();
        public List<Shopify_At_Risk_Notice__c> sentNotices = new List<Shopify_At_Risk_Notice__c>();
        public Date finalWarningDate;
    }
}