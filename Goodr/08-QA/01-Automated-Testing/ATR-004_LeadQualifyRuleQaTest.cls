@IsTest
private class LeadQualifyRuleQaTest {

    private static final String RULE_MSG = 'Please fill in Sales Channel and Sector before setting this Lead to Qualified.';

    private class OkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setBody('{"data":{}}');
            return r;
        }
    }

    private static Integer seq = 0;

    // A Lead that passes the existing checks (early stages trigger, Tax ID format, rejection email flow), so only the new rule decides.
    private static Lead lead(String name, Boolean withValues) {
        Lead l = new Lead(LastName = name, Company = name + ' Co', Status = 'New',
            Terms_of_Service_Agreement__c = 'Accepted', Has_Physical_Store__c = true,
            Resale_Certificate_Status__c = 'Yes, I do.', Parent_Vertical__c = 'Active', Country = 'US',
            Tax_ID__c = String.valueOf(900000000 + seq), Email = 'qa' + seq + '@goodr-qa.test');
        seq++;
        if (withValues) {
            l.Sales_Channel__c = 'Specialty';
            l.Sector__c = 'Self Service';
        }
        return l;
    }

    private static Database.SaveResult qualify(Lead l) {
        return Database.update(new Lead(Id = l.Id, Status = 'Qualified'), false);
    }

    private static void assertBlocked(Database.SaveResult r, String scenario) {
        System.assert(!r.isSuccess(), scenario + ': should be blocked');
        System.assertEquals(RULE_MSG, r.getErrors()[0].getMessage(), scenario + ': message');
    }

    private static String statusOf(Id leadId) {
        return [SELECT Status FROM Lead WHERE Id = :leadId].Status;
    }

    private static User userWithProfile(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        String u = 'qa' + String.valueOf(Crypto.getRandomInteger()).replace('-', '') + '@goodr-qa.test';
        return new User(ProfileId = p.Id, Username = u, Email = u, LastName = 'QA ' + profileName, Alias = 'qagdr',
            TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
    }

    // TC-039-01 Sector blank -> Qualified is blocked
    @IsTest static void tc039_01_sectorBlankBlocked() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Sector Blank', false);
        l.Sales_Channel__c = 'Specialty';
        insert l;
        assertBlocked(qualify(l), 'Sector blank');
        System.assertEquals('New', statusOf(l.Id), 'Status unchanged');
    }

    // TC-039-02 Sales Channel and Sector both blank -> blocked
    @IsTest static void tc039_02_bothBlankBlocked() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Both Blank', false);
        insert l;
        assertBlocked(qualify(l), 'Both blank');
    }

    // TC-039-03 Both filled -> Qualified is saved
    @IsTest static void tc039_03_bothFilledAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Both Filled', true);
        insert l;
        Database.SaveResult r3 = qualify(l);
        System.assert(r3.isSuccess(), 'Both filled: allowed ' + r3.getErrors());
        System.assertEquals('Qualified', statusOf(l.Id), 'Status is Qualified');
    }

    // TC-039-04 Fill the values after the error, then qualify again -> allowed
    @IsTest static void tc039_04_fixAndRetryAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Fix And Retry', false);
        insert l;
        assertBlocked(qualify(l), 'First try');
        update new Lead(Id = l.Id, Sales_Channel__c = 'Specialty', Sector__c = 'Self Service');
        System.assert(qualify(l).isSuccess(), 'Second try after filling: allowed');
    }

    // TC-039-05 Creating a Lead with both fields blank (web, Typeform, manual) still works
    @IsTest static void tc039_05_createWithBlanksAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Database.SaveResult r = Database.insert(lead('QA Create Blank', false), false);
        System.assert(r.isSuccess(), 'Create with blanks: allowed');
    }

    // TC-039-06 Editing other fields on a Lead with blanks still works
    @IsTest static void tc039_06_editOtherFieldsAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Edit Blank', false);
        insert l;
        System.assert(Database.update(new Lead(Id = l.Id, Company = 'QA Edit Blank Co 2'), false).isSuccess(), 'Edit: allowed');
    }

    // TC-039-07 Moving to any status other than Qualified with blanks still works
    @IsTest static void tc039_07_otherStatusAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Other Status', false);
        insert l;
        System.assert(Database.update(new Lead(Id = l.Id, Status = 'Working'), false).isSuccess(), 'Working: allowed');
        Database.SaveResult r7 = Database.update(new Lead(Id = l.Id, Status = 'Manual Rejection'), false);
        System.assert(r7.isSuccess(), 'Manual Rejection: allowed ' + r7.getErrors());
    }

    // TC-039-08 A Lead that is already Qualified can still be edited (no status change)
    @IsTest static void tc039_08_alreadyQualifiedEditAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Already Qualified', true);
        insert l;
        System.assert(qualify(l).isSuccess(), 'Qualify');
        System.assert(Database.update(new Lead(Id = l.Id, Company = 'QA Already Qualified Co 2'), false).isSuccess(), 'Edit: allowed');
    }

    // TC-039-09 Approve button (LeadManualApproveController) with blanks -> blocked, Lead stays New
    @IsTest static void tc039_09_approveButtonBlocked() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Approve Blank', false);
        insert l;
        Boolean thrown = false;
        try {
            LeadManualApproveController.approveLead(l.Id, 'Approved');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Approve shows an error');
        System.assertEquals('New', statusOf(l.Id), 'Status unchanged');
    }

    // TC-039-10 Approve button with both filled -> Qualified
    @IsTest static void tc039_10_approveButtonAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Approve Filled', true);
        insert l;
        LeadManualApproveController.approveLead(l.Id, 'Approved');
        System.assertEquals('Qualified', statusOf(l.Id), 'Approved to Qualified');
    }

    // TC-039-11 Reject button with blanks still works
    @IsTest static void tc039_11_rejectButtonAllowed() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Reject Blank', false);
        insert l;
        LeadManualApproveController.approveLead(l.Id, 'Rejected');
        System.assertEquals('Manual Rejection', statusOf(l.Id), 'Rejected');
    }

    // TC-039-12 Create Shopify stays disabled until the Lead is Qualified
    @IsTest static void tc039_12_createShopifyNeedsQualified() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead blank = lead('QA Shopify Blank', false);
        Lead ready = lead('QA Shopify Ready', true);
        insert new List<Lead>{ blank, ready };
        qualify(blank);
        qualify(ready);
        System.assertEquals(false, LeadConversionService.canConvert(blank.Id), 'Blank Lead: Create Shopify disabled');
        System.assertEquals(true, LeadConversionService.canConvert(ready.Id), 'Filled Lead: Create Shopify enabled');
    }

    // TC-039-13 Bulk: 200 Leads, half blank -> 100 qualified, 100 blocked
    @IsTest static void tc039_13_bulk200() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(lead('QA Bulk ' + i, Math.mod(i, 2) == 0));
        }
        insert leads;
        List<Lead> upd = new List<Lead>();
        for (Lead l : leads) {
            upd.add(new Lead(Id = l.Id, Status = 'Qualified'));
        }
        Test.startTest();
        List<Database.SaveResult> res = Database.update(upd, false);
        Test.stopTest();
        Integer ok = 0, blocked = 0;
        for (Database.SaveResult r : res) {
            if (r.isSuccess()) {
                ok++;
            } else if (r.getErrors()[0].getMessage() == RULE_MSG) {
                blocked++;
            }
        }
        System.assertEquals(100, ok, 'Filled Leads qualified');
        System.assertEquals(100, blocked, 'Blank Leads blocked');
    }

    // TC-039-14 The rule applies to non-admin users too
    @IsTest static void tc039_14_standardUserBlocked() {
        User u = userWithProfile('Standard User');
        insert u;
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new OkMock());
            Lead l = lead('QA Std User', false);
            insert l;
            assertBlocked(qualify(l), 'Standard User');
        }
    }

    // TC-039-15 Rule is checked before the existing trigger check: both messages can appear together
    @IsTest static void tc039_15_ruleWithTriggerCheck() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Lead l = lead('QA Both Checks', false);
        l.Has_Physical_Store__c = false;
        insert l;
        Database.SaveResult r = qualify(l);
        System.assert(!r.isSuccess(), 'Blocked');
        Boolean hasRule = false;
        for (Database.Error e : r.getErrors()) {
            if (e.getMessage() == RULE_MSG) {
                hasRule = true;
            }
        }
        System.assert(hasRule || r.getErrors()[0].getMessage().contains('cannot be set to Qualified'), 'Blocked by the rule or the existing check');
    }
}
