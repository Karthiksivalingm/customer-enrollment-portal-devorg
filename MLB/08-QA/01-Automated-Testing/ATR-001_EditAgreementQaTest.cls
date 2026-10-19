@IsTest
private class EditAgreementQaTest {

    private static final String MA_RULE = 'Membership Agreement records can\'t be edited manually';
    private static final String OPP_RULE = 'Agreement details can\'t be edited manually';

    private static User salesManager() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Marlins Sales Leadership' AND IsActive = true AND UserRole.DeveloperName = 'Sales_Managers' LIMIT 1];
    }

    private static Opportunity newOpp(Id ownerId, String agreementType) {
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Ticket_Sales').getRecordTypeId();
        Opportunity o = new Opportunity(RecordTypeId = rt, Name = 'QA Edit Agreement ' + agreementType, StageName = 'Qualification',
            CloseDate = Date.today(), Agreement_Type__c = agreementType, Parking_Passes__c = 11, Term_Length__c = '2',
            Amount_allocated_to_Flex__c = 100, Total_Due_Today__c = 50, Total_Paid_to_Date__c = 0);
        if (ownerId != null) { o.OwnerId = ownerId; }
        insert as system o;
        return o;
    }

    private static List<Membership_Agreement__c> newRows(Id oppId, Integer n) {
        List<Membership_Agreement__c> rows = new List<Membership_Agreement__c>();
        for (Integer i = 0; i < n; i++) {
            rows.add(new Membership_Agreement__c(Opportunity_LUR__c = oppId, Qty_Seats__c = 1, Location_Seat__c = String.valueOf(i + 1), Paid_to_Date__c = 0));
        }
        insert as system rows;
        return rows;
    }

    private static String firstError(Database.SaveResult r) { return r.isSuccess() ? '' : r.getErrors()[0].getMessage(); }

    // TC-014-01 creating Membership Agreement rows is not blocked (Create Agreement path)
    @IsTest static void tc01_createRowsAllowed() {
        Opportunity o = newOpp(null, 'Membership');
        newRows(o.Id, 3);
        System.assertEquals(3, [SELECT COUNT() FROM Membership_Agreement__c WHERE Opportunity_LUR__c = :o.Id WITH SYSTEM_MODE]);
    }

    // TC-014-02 System Administrator cannot edit a Membership Agreement row manually
    @IsTest static void tc02_adminManualRowEditBlocked() {
        Opportunity o = newOpp(null, 'Membership');
        Membership_Agreement__c row = newRows(o.Id, 1)[0];
        row.Qty_Seats__c = 5;
        Database.SaveResult r = Database.update(row, false, AccessLevel.SYSTEM_MODE);
        System.assert(!r.isSuccess(), 'admin manual edit must be blocked');
        System.assert(firstError(r).contains(MA_RULE), firstError(r));
    }

    // TC-014-03 Sales Manager cannot edit a Membership Agreement row manually
    @IsTest static void tc03_salesManagerManualRowEditBlocked() {
        User u = salesManager();
        Opportunity o = newOpp(u.Id, 'Membership');
        Membership_Agreement__c row = newRows(o.Id, 1)[0];
        Database.SaveResult r;
        System.runAs(u) {
            Membership_Agreement__c mine = [SELECT Id, Qty_Seats__c FROM Membership_Agreement__c WHERE Id = :row.Id];
            mine.Qty_Seats__c = 7;
            r = Database.update(mine, false, AccessLevel.USER_MODE);
        }
        System.assert(!r.isSuccess(), 'sales manager manual edit must be blocked');
        System.assert(firstError(r).contains(MA_RULE), firstError(r));
    }

    // TC-014-04 Edit Agreement update (Flow_Update__c ticked) saves, and the box is cleared straight after
    @IsTest static void tc04_flowUpdateSavesAndResets() {
        Opportunity o = newOpp(null, 'Membership');
        Membership_Agreement__c row = newRows(o.Id, 1)[0];
        row.Qty_Seats__c = 4; row.Flow_Update__c = true;
        Test.startTest(); update as system row; Test.stopTest();
        Membership_Agreement__c after = [SELECT Qty_Seats__c, Flow_Update__c FROM Membership_Agreement__c WHERE Id = :row.Id WITH SYSTEM_MODE];
        System.assertEquals(4, after.Qty_Seats__c);
        System.assertEquals(false, after.Flow_Update__c, 'reset flow must untick Flow_Update__c');
    }

    // TC-014-05 after a flow update, the next manual edit is blocked again
    @IsTest static void tc05_manualEditBlockedAfterFlowUpdate() {
        Opportunity o = newOpp(null, 'Membership');
        Membership_Agreement__c row = newRows(o.Id, 1)[0];
        row.Qty_Seats__c = 4; row.Flow_Update__c = true;
        update as system row;
        Membership_Agreement__c again = [SELECT Id, Qty_Seats__c FROM Membership_Agreement__c WHERE Id = :row.Id WITH SYSTEM_MODE];
        again.Qty_Seats__c = 9;
        Database.SaveResult r = Database.update(again, false, AccessLevel.SYSTEM_MODE);
        System.assert(firstError(r).contains(MA_RULE), 'manual edit after flow update must be blocked: ' + firstError(r));
    }

    // TC-014-06 bulk: 200 manual row edits all blocked, 200 flow updates all saved and reset
    @IsTest static void tc06_bulk200() {
        Opportunity o = newOpp(null, 'Membership');
        List<Membership_Agreement__c> rows = newRows(o.Id, 200);
        for (Membership_Agreement__c r : rows) { r.Qty_Seats__c = 2; }
        Integer blocked = 0;
        for (Database.SaveResult s : Database.update(rows, false, AccessLevel.SYSTEM_MODE)) { if (!s.isSuccess()) blocked++; }
        System.assertEquals(200, blocked);
        List<Membership_Agreement__c> viaFlow = [SELECT Id FROM Membership_Agreement__c WHERE Opportunity_LUR__c = :o.Id WITH SYSTEM_MODE];
        for (Membership_Agreement__c r : viaFlow) { r.Qty_Seats__c = 3; r.Flow_Update__c = true; }
        Test.startTest(); update as system viaFlow; Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Membership_Agreement__c WHERE Opportunity_LUR__c = :o.Id AND Qty_Seats__c = 3 AND Flow_Update__c = false WITH SYSTEM_MODE]);
    }

    // TC-014-07 surplus rows can be deleted (row count reduced in Edit Agreement)
    @IsTest static void tc07_deleteSurplusRowsAllowed() {
        Opportunity o = newOpp(null, 'Membership');
        List<Membership_Agreement__c> rows = newRows(o.Id, 3);
        delete as system rows[2];
        System.assertEquals(2, [SELECT COUNT() FROM Membership_Agreement__c WHERE Opportunity_LUR__c = :o.Id WITH SYSTEM_MODE]);
    }

    // TC-014-08 System Administrator cannot change agreement fields on the Opportunity (one field per section)
    @IsTest static void tc08_adminManualOpportunityEditBlocked() {
        Opportunity o = newOpp(null, 'Suite Lease');
        Map<String, Object> changes = new Map<String, Object>{
            'Parking_Passes__c' => 12, 'Term_Length__c' => '3', 'Amount_allocated_to_Flex__c' => 200, 'Total_Due_Today__c' => 75 };
        for (String f : changes.keySet()) {
            Opportunity edit = new Opportunity(Id = o.Id);
            edit.put(f, changes.get(f));
            Database.SaveResult r = Database.update(edit, false, AccessLevel.SYSTEM_MODE);
            System.assert(firstError(r).contains(OPP_RULE), f + ' should be blocked: ' + firstError(r));
        }
    }

    // TC-014-09 Sales Manager cannot change agreement fields on the Opportunity
    @IsTest static void tc09_salesManagerManualOpportunityEditBlocked() {
        User u = salesManager();
        Opportunity o = newOpp(u.Id, 'Suite Lease');
        Database.SaveResult r;
        System.runAs(u) { r = Database.update(new Opportunity(Id = o.Id, Parking_Passes__c = 13), false, AccessLevel.USER_MODE); }
        System.assert(firstError(r).contains(OPP_RULE), firstError(r));
    }

    // TC-014-10 Create / Edit Agreement save (Agreement_Flow_Update__c flipped) changes agreement fields
    @IsTest static void tc10_flowSaveAllowed() {
        Opportunity o = newOpp(null, 'Suite Lease');
        Opportunity cur = [SELECT Agreement_Flow_Update__c FROM Opportunity WHERE Id = :o.Id WITH SYSTEM_MODE];
        update as system new Opportunity(Id = o.Id, Parking_Passes__c = 14, Agreement_Flow_Update__c = !cur.Agreement_Flow_Update__c);
        System.assertEquals(14, [SELECT Parking_Passes__c FROM Opportunity WHERE Id = :o.Id WITH SYSTEM_MODE].Parking_Passes__c);
    }

    // TC-014-11 other Opportunity fields stay editable
    @IsTest static void tc11_nonAgreementFieldsEditable() {
        User u = salesManager();
        Opportunity o = newOpp(u.Id, 'Suite Lease');
        Database.SaveResult r;
        System.runAs(u) { r = Database.update(new Opportunity(Id = o.Id, NextStep = 'QA next step'), false, AccessLevel.USER_MODE); }
        System.assert(r.isSuccess(), 'Next Step should save: ' + firstError(r));
    }

    // TC-014-12 a new Opportunity can be created with agreement values (rule applies to edits only)
    @IsTest static void tc12_newOpportunityAllowed() {
        Opportunity o = newOpp(null, 'Flex');
        System.assertEquals(50, [SELECT Total_Due_Today__c FROM Opportunity WHERE Id = :o.Id WITH SYSTEM_MODE].Total_Due_Today__c);
    }

    // TC-014-13 Paid to Date changed by Edit Agreement saves and is copied to the Opportunity (defect found and fixed during QA)
    @IsTest static void tc13_paidToDateDoesNotTripOpportunityRule() {
        Opportunity o = newOpp(null, 'Membership');
        Membership_Agreement__c row = newRows(o.Id, 1)[0];
        row.Paid_to_Date__c = 500; row.Flow_Update__c = true;
        Database.SaveResult r = Database.update(row, false, AccessLevel.SYSTEM_MODE);
        System.assert(r.isSuccess(), 'row update must not be blocked by the Opportunity rule: ' + firstError(r));
        System.assertEquals(500, [SELECT Total_Paid_to_Date__c FROM Opportunity WHERE Id = :o.Id WITH SYSTEM_MODE].Total_Paid_to_Date__c,
            'Paid to Date must reach the Opportunity without tripping the rule');
    }
}
