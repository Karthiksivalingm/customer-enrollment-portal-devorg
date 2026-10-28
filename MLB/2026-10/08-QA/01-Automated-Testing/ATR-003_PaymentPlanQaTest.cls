@IsTest
private class PaymentPlanQaTest {

    private static final String LOCK_RULE = 'Agreement details can\'t be edited manually';
    private static final String NUMERIC_RULE = 'Payment Amount can contain numbers only';

    private static User salesManager() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Marlins Sales Leadership' AND IsActive = true AND UserRole.DeveloperName = 'Sales_Managers' LIMIT 1];
    }

    private static List<Opportunity> newOpps(Id ownerId, Integer n) {
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Ticket_Sales').getRecordTypeId();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < n; i++) {
            Opportunity o = new Opportunity(RecordTypeId = rt, Name = 'QA Payment Plan ' + i, StageName = 'Qualification',
                CloseDate = Date.today(), Agreement_Type__c = 'Suite Lease', This_Season_Total_Amount__c = 1111,
                Year_1_License_Fee__c = 1111, Year_2_License_Fee__c = 1144);
            if (ownerId != null) { o.OwnerId = ownerId; }
            opps.add(o);
        }
        insert as system opps;
        return opps;
    }

    // a save as the Agreement Flow does it: flips the marker so the lock rule lets it through
    private static Opportunity flowSave(Id oppId) {
        Opportunity cur = [SELECT Agreement_Flow_Update__c FROM Opportunity WHERE Id = :oppId];
        return new Opportunity(Id = oppId, Agreement_Flow_Update__c = !cur.Agreement_Flow_Update__c);
    }

    private static String firstError(Database.SaveResult r) { return r.isSuccess() ? '' : r.getErrors()[0].getMessage(); }

    @IsTest static void licenseFeesCanBeEditedManually() {
        User u = salesManager();
        Opportunity o = newOpps(u.Id, 1)[0];
        Database.SaveResult r;
        System.runAs(u) {
            r = Database.update(new Opportunity(Id = o.Id, Year_1_License_Fee__c = 1000, Year_2_License_Fee__c = 1030,
                Year_3_License_Fee__c = 1060, Year_4_License_Fee__c = 1090, Year_5_License_Fee__c = 1120), false, AccessLevel.USER_MODE);
        }
        Assert.isTrue(r.isSuccess(), 'Year 1-5 License Fee must be editable manually: ' + firstError(r));
        Opportunity after = [SELECT Year_1_License_Fee__c, Year_5_License_Fee__c FROM Opportunity WHERE Id = :o.Id];
        Assert.areEqual(1000, after.Year_1_License_Fee__c);
        Assert.areEqual(1120, after.Year_5_License_Fee__c);
    }

    @IsTest static void licenseFeesEditableByAdminToo() {
        Opportunity o = newOpps(null, 1)[0];
        Database.SaveResult r = Database.update(new Opportunity(Id = o.Id, Year_3_License_Fee__c = 5000), false);
        Assert.isTrue(r.isSuccess(), firstError(r));
    }

    @IsTest static void paymentPlanFieldsLockedForManualEdits() {
        Opportunity o = newOpps(null, 1)[0];
        List<Opportunity> edits = new List<Opportunity>{
            new Opportunity(Id = o.Id, Number_of_Payment_Plans__c = '3'),
            new Opportunity(Id = o.Id, Payment_Due_Date_1__c = 'November 2, 2026'),
            new Opportunity(Id = o.Id, Payment_Due_Date_12__c = 'October 2, 2027'),
            new Opportunity(Id = o.Id, Payment_Amount__c = '100')
        };
        for (Opportunity e : edits) {
            Database.SaveResult r = Database.update(e, false);
            Assert.isFalse(r.isSuccess(), 'Manual edit must be blocked: ' + e);
            Assert.isTrue(firstError(r).contains(LOCK_RULE), firstError(r));
        }
    }

    @IsTest static void flowSaveOfFullPlanSucceeds() {
        Opportunity o = newOpps(null, 1)[0];
        Opportunity e = flowSave(o.Id);
        e.Number_of_Payment_Plans__c = '3';
        e.Due_Date__c = Date.today().addDays(5);
        e.Payment_Due_Date_1__c = 'November 2, 2026';
        e.Payment_Due_Date_2__c = 'December 2, 2026';
        e.Payment_Due_Date_3__c = 'January 2, 2027';
        e.Payment_Amount__c = '370.33';
        Database.SaveResult r = Database.update(e, false);
        Assert.isTrue(r.isSuccess(), firstError(r));
        Opportunity after = [SELECT Number_of_Payment_Plans__c, Payment_Amount__c, Payment_Due_Date_3__c FROM Opportunity WHERE Id = :o.Id];
        Assert.areEqual('3', after.Number_of_Payment_Plans__c);
        Assert.areEqual('370.33', after.Payment_Amount__c);
        Assert.areEqual('January 2, 2027', after.Payment_Due_Date_3__c);
    }

    @IsTest static void amountsAcceptNumbersOnly() {
        Opportunity o = newOpps(null, 1)[0];
        Map<String, Boolean> values = new Map<String, Boolean>{
            '1250' => true, '1250.5' => true, '1250.50' => true, '0.99' => true,
            '12a' => false, 'abc' => false, '1,250' => false, '-5' => false, '$100' => false, '1250.505' => false, '12 50' => false
        };
        for (String v : values.keySet()) {
            for (String f : new List<String>{ 'Payment_Amount__c' }) {
                Opportunity e = flowSave(o.Id);
                e.put(f, v);
                Database.SaveResult r = Database.update(e, false);
                if (values.get(v)) {
                    Assert.isTrue(r.isSuccess(), f + ' = ' + v + ' must save: ' + firstError(r));
                } else {
                    Assert.isFalse(r.isSuccess(), f + ' = ' + v + ' must be blocked');
                    Assert.isTrue(firstError(r).contains(NUMERIC_RULE), firstError(r));
                }
            }
        }
    }

    @IsTest static void numberOfPaymentPlansOnlyAllowsListValues() {
        Opportunity o = newOpps(null, 1)[0];
        for (String v : new List<String>{ 'Full', '2', '7', '12' }) {
            Opportunity e = flowSave(o.Id); e.Number_of_Payment_Plans__c = v;
            Database.SaveResult r = Database.update(e, false);
            Assert.isTrue(r.isSuccess(), v + ': ' + firstError(r));
        }
        for (String v : new List<String>{ '0', '1', '13', 'Half' }) {
            Opportunity e = flowSave(o.Id); e.Number_of_Payment_Plans__c = v;
            Database.SaveResult r = Database.update(e, false);
            Assert.isFalse(r.isSuccess(), v + ' must be rejected');
        }
    }

    @IsTest static void bulk200() {
        List<Opportunity> opps = newOpps(null, 200);
        Map<Id, Opportunity> cur = new Map<Id, Opportunity>([SELECT Id, Agreement_Flow_Update__c FROM Opportunity WHERE Id IN :opps]);
        List<Opportunity> good = new List<Opportunity>();
        List<Opportunity> bad = new List<Opportunity>();
        List<Opportunity> manualFee = new List<Opportunity>();
        for (Opportunity o : opps) {
            good.add(new Opportunity(Id = o.Id, Agreement_Flow_Update__c = !cur.get(o.Id).Agreement_Flow_Update__c, Number_of_Payment_Plans__c = '12', Payment_Amount__c = '92.58'));
            bad.add(new Opportunity(Id = o.Id, Payment_Amount__c = 'x'));
            manualFee.add(new Opportunity(Id = o.Id, Year_4_License_Fee__c = 1200));
        }
        Test.startTest();
        List<Database.SaveResult> rg = Database.update(good, false);
        List<Database.SaveResult> rb = Database.update(bad, false);
        List<Database.SaveResult> rm = Database.update(manualFee, false);
        Test.stopTest();
        Integer ok = 0, blocked = 0, fee = 0;
        for (Database.SaveResult r : rg) { if (r.isSuccess()) ok++; }
        for (Database.SaveResult r : rb) { if (!r.isSuccess()) blocked++; }
        for (Database.SaveResult r : rm) { if (r.isSuccess()) fee++; }
        Assert.areEqual(200, ok, 'flow-style saves');
        Assert.areEqual(200, blocked, 'manual payment edits blocked');
        Assert.areEqual(200, fee, 'manual license fee edits allowed');
    }

    // REQ-020: Person Accounts can be saved with the two new Type values
    @IsTest static void personAccountTypeValues() {
        Id rt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        User u = salesManager();
        List<Account> accts = new List<Account>{
            new Account(RecordTypeId = rt, LastName = 'QA Person FB', Type = 'Food and Beverage', OwnerId = u.Id),
            new Account(RecordTypeId = rt, LastName = 'QA Person NP', Type = 'Non-Profit', OwnerId = u.Id)
        };
        List<Database.SaveResult> rs;
        System.runAs(u) { rs = Database.insert(accts, false); }
        for (Database.SaveResult r : rs) { Assert.isTrue(r.isSuccess(), firstError(r)); }
        Map<String, Integer> byType = new Map<String, Integer>();
        for (Account a : [SELECT Type FROM Account WHERE Id IN :accts AND IsPersonAccount = true]) { byType.put(a.Type, 1); }
        Assert.isTrue(byType.containsKey('Food and Beverage') && byType.containsKey('Non-Profit'), 'both values saved on Person Accounts');
    }
}