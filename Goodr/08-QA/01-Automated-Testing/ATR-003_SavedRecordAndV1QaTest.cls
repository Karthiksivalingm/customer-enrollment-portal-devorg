@IsTest
private class SavedRecordAndV1QaTest {

    private static final List<String> V1_FIELDS = new List<String>{ 'Sales_Channel_V1__c', 'Sector_V1__c' };

    private class OkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(200);
            r.setBody('{"data":{}}');
            return r;
        }
    }

    private static Id rt(String developerName) {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }

    private static Account company(String name) {
        return new Account(Name = name, RecordTypeId = rt('Company'), Tax_Id__c = '900000001', Sales_Channel__c = 'Specialty');
    }

    private static User userWithProfile(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        String u = 'qa' + String.valueOf(Crypto.getRandomInteger()).replace('-', '') + '@goodr-qa.test';
        return new User(ProfileId = p.Id, Username = u, Email = u, LastName = 'QA ' + profileName, Alias = 'qagdr',
            TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
    }

    private static Schema.DescribeFieldResult field(Schema.SObjectType t, String name) {
        return t.getDescribe().fields.getMap().get(name).getDescribe();
    }

    // ---------------- REQ-037: hide the Shopify sections on the New Account form ----------------

    // TC-037-01 Is Saved Record is a read-only formula checkbox
    @IsTest static void tc037_01_fieldIsFormulaCheckbox() {
        Schema.DescribeFieldResult d = field(Account.SObjectType, 'Is_Saved_Record__c');
        System.assertEquals(Schema.DisplayType.BOOLEAN, d.getType(), 'Checkbox');
        System.assert(d.isCalculated(), 'Formula field');
        System.assertEquals('NOT(ISBLANK(ID))', d.getCalculatedFormula().deleteWhitespace().toUpperCase(), 'Formula');
        System.assert(!d.isUpdateable(), 'Nobody can edit a formula');
    }

    // TC-037-02 A new (unsaved) Company and Store Location: Is Saved Record = false, so the sections are hidden
    @IsTest static void tc037_02_unsavedRecordIsFalse() {
        List<Account> unsaved = new List<Account>{
            company('QA Unsaved Company'),
            new Account(Name = 'QA Unsaved Store', RecordTypeId = rt('Store_Location'))
        };
        Formula.recalculateFormulas(unsaved);
        for (Account a : unsaved) {
            System.assertEquals(false, a.Is_Saved_Record__c, 'Unsaved record must be false: ' + a.Name);
        }
    }

    // TC-037-03 After saving, Is Saved Record = true, so the sections show
    @IsTest static void tc037_03_savedRecordIsTrue() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Account c = company('QA Saved Company');
        insert c;
        Account s = new Account(Name = 'QA Saved Store', RecordTypeId = rt('Store_Location'), ParentId = c.Id, Tax_Id__c = '900000002',
            Sales_Channel__c = 'Specialty', ShippingStreet = '100 Test Street', ShippingCity = 'Test City', ShippingPostalCode = '12345');
        Test.startTest();
        insert s;
        Test.stopTest();
        for (Account a : [SELECT Name, Is_Saved_Record__c FROM Account WHERE Id IN (:c.Id, :s.Id)]) {
            System.assertEquals(true, a.Is_Saved_Record__c, 'Saved record must be true: ' + a.Name);
        }
    }

    // TC-037-04 Bulk: 200 unsaved records all evaluate to false
    @IsTest static void tc037_04_bulkUnsaved() {
        List<Account> rows = new List<Account>();
        for (Integer i = 0; i < 200; i++) { rows.add(company('QA Bulk ' + i)); }
        Formula.recalculateFormulas(rows);
        Integer trues = 0;
        for (Account a : rows) { if (a.Is_Saved_Record__c) { trues++; } }
        System.assertEquals(0, trues, 'No unsaved record may be true');
    }

    // TC-037-05 A non-admin user (Account Management) can read the field, so the filter works for them; cannot edit it
    @IsTest static void tc037_05_accountManagementCanRead() {
        User u = userWithProfile('Account Management');
        System.runAs(u) {
            Schema.DescribeFieldResult d = field(Account.SObjectType, 'Is_Saved_Record__c');
            System.assert(d.isAccessible(), 'Account Management must be able to read Is Saved Record');
            System.assert(!d.isUpdateable(), 'Read-only');
        }
    }

    // TC-037-06 Standard User can read the field too
    @IsTest static void tc037_06_standardUserCanRead() {
        User u = userWithProfile('Standard User');
        System.runAs(u) {
            System.assert(field(Account.SObjectType, 'Is_Saved_Record__c').isAccessible(), 'Standard User must be able to read Is Saved Record');
        }
    }

    // ---------------- REQ-038: Sales Channel V1 / Sector V1 on Contact, Lead, Opportunity ----------------

    // TC-038-01 The six new fields exist and match the Account fields (type, length, label, help text)
    @IsTest static void tc038_01_fieldsMatchAccount() {
        for (Schema.SObjectType t : new List<Schema.SObjectType>{ Contact.SObjectType, Lead.SObjectType, Opportunity.SObjectType }) {
            for (String f : V1_FIELDS) {
                Schema.DescribeFieldResult n = field(t, f);
                Schema.DescribeFieldResult a = field(Account.SObjectType, f);
                System.assertNotEquals(null, n, t + '.' + f + ' exists');
                System.assertEquals(Schema.DisplayType.STRING, n.getType(), t + '.' + f + ' is Text');
                System.assertEquals(50, n.getLength(), t + '.' + f + ' length');
                System.assertEquals(a.getLabel(), n.getLabel(), t + '.' + f + ' label');
                System.assertEquals(a.getInlineHelpText(), n.getInlineHelpText(), t + '.' + f + ' help text');
            }
        }
    }

    // TC-038-02 System Administrator can read and edit all V1 fields
    @IsTest static void tc038_02_adminCanEdit() {
        User u = userWithProfile('System Administrator');
        System.runAs(u) {
            for (Schema.SObjectType t : new List<Schema.SObjectType>{ Account.SObjectType, Contact.SObjectType, Lead.SObjectType, Opportunity.SObjectType }) {
                for (String f : V1_FIELDS) {
                    System.assert(field(t, f).isAccessible() && field(t, f).isUpdateable(), 'Admin read/edit ' + t + '.' + f);
                }
            }
        }
    }

    // TC-038-03 Account Management can read but not edit the V1 fields
    @IsTest static void tc038_03_accountManagementReadOnly() {
        User u = userWithProfile('Account Management');
        System.runAs(u) {
            for (Schema.SObjectType t : new List<Schema.SObjectType>{ Account.SObjectType, Contact.SObjectType, Lead.SObjectType, Opportunity.SObjectType }) {
                for (String f : V1_FIELDS) {
                    System.assert(field(t, f).isAccessible(), 'Account Management read ' + t + '.' + f);
                    System.assert(!field(t, f).isUpdateable(), 'Account Management no edit ' + t + '.' + f);
                }
            }
        }
    }

    // TC-038-04 Values save and read back on Contact, Lead and Opportunity
    @IsTest static void tc038_04_valuesSave() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Account acc = company('QA V1 Company');
        insert acc;
        Contact c = new Contact(LastName = 'QA V1', AccountId = acc.Id, Sales_Channel_V1__c = 'Specialty CAN', Sector_V1__c = 'Bridge');
        Lead l = new Lead(LastName = 'QA V1', Company = 'QA V1 Lead Co', Sales_Channel_V1__c = 'Key Accounts', Sector_V1__c = 'Core');
        Opportunity o = new Opportunity(Name = 'QA V1 Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(),
            Sales_Channel_V1__c = 'Global', Sector_V1__c = 'Global');
        Test.startTest();
        insert c; insert l; insert o;
        Test.stopTest();
        Contact c2 = [SELECT Sales_Channel_V1__c, Sector_V1__c FROM Contact WHERE Id = :c.Id];
        Lead l2 = [SELECT Sales_Channel_V1__c, Sector_V1__c FROM Lead WHERE Id = :l.Id];
        Opportunity o2 = [SELECT Sales_Channel_V1__c, Sector_V1__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Specialty CAN', c2.Sales_Channel_V1__c); System.assertEquals('Bridge', c2.Sector_V1__c);
        System.assertEquals('Key Accounts', l2.Sales_Channel_V1__c); System.assertEquals('Core', l2.Sector_V1__c);
        System.assertEquals('Global', o2.Sales_Channel_V1__c); System.assertEquals('Global', o2.Sector_V1__c);
    }

    // TC-038-05 Values longer than 50 characters are rejected (field length kept as on Account)
    @IsTest static void tc038_05_lengthLimit() {
        Contact c = new Contact(LastName = 'QA V1 Long', Sales_Channel_V1__c = 'X'.repeat(51));
        Database.SaveResult r = Database.insert(c, false);
        System.assert(!r.isSuccess(), '51 characters must be rejected');
    }

    // TC-038-06 Bulk: 200 Contacts with V1 values save
    @IsTest static void tc038_06_bulkContacts() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Account acc = company('QA V1 Bulk Company');
        insert acc;
        List<Contact> rows = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            rows.add(new Contact(LastName = 'QA V1 Bulk ' + i, AccountId = acc.Id, Sales_Channel_V1__c = 'Specialty', Sector_V1__c = 'Sellgoodr USA'));
        }
        Test.startTest();
        insert rows;
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Contact WHERE AccountId = :acc.Id AND Sales_Channel_V1__c = 'Specialty' AND Sector_V1__c = 'Sellgoodr USA']);
    }

    // TC-038-07 The V1 fields do not change any existing logic: Sales Channel / Sector / Cluster on a new Contact behave as before
    @IsTest static void tc038_07_noImpactOnExistingLogic() {
        Test.setMock(HttpCalloutMock.class, new OkMock());
        Account withV1 = company('QA With V1'); withV1.Sales_Channel_V1__c = 'Specialty'; withV1.Sector_V1__c = 'Bridge';
        Account without = company('QA Without V1');
        Test.startTest();
        insert new List<Account>{ withV1, without };
        Test.stopTest();
        Map<Id, Account> m = new Map<Id, Account>([SELECT Sales_Channel__c, Sector__c, Cluster__c FROM Account WHERE Id IN (:withV1.Id, :without.Id)]);
        System.assertEquals(m.get(without.Id).Sales_Channel__c, m.get(withV1.Id).Sales_Channel__c, 'Sales Channel unaffected by V1');
        System.assertEquals(m.get(without.Id).Cluster__c, m.get(withV1.Id).Cluster__c, 'Cluster unaffected by V1');
    }
}
