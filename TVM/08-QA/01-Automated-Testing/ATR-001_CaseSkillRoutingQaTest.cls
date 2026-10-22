/**
 * ATR-001 — QA test for case skill-based routing (Case_Skill_Mapping_for_same_request_types).
 * Run only as a validate-only deployment (RunSpecifiedTests). Nothing is saved in the org.
 * Test IDs match ATR-001 and MTC-001 (TC-001-xx).
 */
@IsTest
private class CaseSkillRoutingQaTest {

    private static final String CATEGORY = 'General Support';

    private static Id masterRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Master_Record_Type').getRecordTypeId();
    }

    private static Case newCase(String subcategory, String request) {
        return new Case(
            RecordTypeId = masterRecordTypeId(),
            Subject = 'QA skill routing ' + subcategory + ' / ' + request,
            Origin = 'Web',
            Case_Category__c = CATEGORY,
            Case_Subcategory__c = subcategory,
            Case_Request__c = request
        );
    }

    private static String skillOf(Id caseId) {
        return [SELECT Routing_Skill__c FROM Case WHERE Id = :caseId].Routing_Skill__c;
    }

    // TC-001-01 Inventory + Other -> Inventory
    @IsTest static void tc01_inventoryOther() {
        Case c = newCase('Inventory', 'Other');
        insert c;
        System.assertEquals('Inventory', skillOf(c.Id), 'TC-001-01');
    }

    // TC-001-02 Inventory + VDV Issue -> Inventory
    @IsTest static void tc02_inventoryVdvIssue() {
        Case c = newCase('Inventory', 'VDV Issue');
        insert c;
        System.assertEquals('Inventory', skillOf(c.Id), 'TC-001-02');
    }

    // TC-001-03 Onboarding + Other -> General
    @IsTest static void tc03_onboardingOther() {
        Case c = newCase('Onboarding', 'Other');
        insert c;
        System.assertEquals('General', skillOf(c.Id), 'TC-001-03');
    }

    // TC-001-04 Websites - Apollo Apps + VDV Issue -> General
    @IsTest static void tc04_apolloAppsVdvIssue() {
        Case c = newCase('Websites - Apollo Apps', 'VDV Issue');
        insert c;
        System.assertEquals('General', skillOf(c.Id), 'TC-001-04');
    }

    // TC-001-05 Unmapped combinations -> no Routing Skill
    @IsTest static void tc05_unmappedCombinations() {
        Case a = newCase('Inventory', 'Feed Export Issue');
        Case b = newCase('Websites - Apollo Apps', 'VDV Setup');
        insert new List<Case>{ a, b };
        System.assertEquals(null, skillOf(a.Id), 'TC-001-05 Inventory / Feed Export Issue');
        System.assertEquals(null, skillOf(b.Id), 'TC-001-05 Websites - Apollo Apps / VDV Setup');
    }

    // TC-001-06 Update an unmapped case to a mapped combination -> skill set on update
    @IsTest static void tc06_updateToMapped() {
        Case c = newCase('Inventory', 'Feed Export Issue');
        insert c;
        System.assertEquals(null, skillOf(c.Id), 'TC-001-06 before update');
        c.Case_Subcategory__c = 'Onboarding';
        c.Case_Request__c = 'Other';
        update c;
        System.assertEquals('General', skillOf(c.Id), 'TC-001-06 after update');
    }

    // TC-001-07 Change a mapped case to an unmapped combination -> previous skill is kept
    @IsTest static void tc07_changeToUnmappedKeepsSkill() {
        Case c = newCase('Inventory', 'Other');
        insert c;
        System.assertEquals('Inventory', skillOf(c.Id), 'TC-001-07 before update');
        c.Case_Request__c = 'Feed Export Issue';
        update c;
        System.assertEquals('Inventory', skillOf(c.Id), 'TC-001-07 after update (flow does not clear the skill)');
    }

    // TC-001-08 Bulk: 200 cases, 50 of each mapped combination
    @IsTest static void tc08_bulk200() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 50; i++) {
            cases.add(newCase('Inventory', 'Other'));
            cases.add(newCase('Inventory', 'VDV Issue'));
            cases.add(newCase('Onboarding', 'Other'));
            cases.add(newCase('Websites - Apollo Apps', 'VDV Issue'));
        }
        Test.startTest();
        insert cases;
        Test.stopTest();
        Map<String, Integer> counts = new Map<String, Integer>{ 'Inventory' => 0, 'General' => 0 };
        Integer wrong = 0;
        for (Case c : [SELECT Case_Subcategory__c, Case_Request__c, Routing_Skill__c FROM Case WHERE Id IN :cases]) {
            String expected = (c.Case_Subcategory__c == 'Inventory') ? 'Inventory' : 'General';
            if (c.Routing_Skill__c != expected) wrong++;
            if (counts.containsKey(c.Routing_Skill__c)) counts.put(c.Routing_Skill__c, counts.get(c.Routing_Skill__c) + 1);
        }
        System.assertEquals(0, wrong, 'TC-001-08 wrong skills');
        System.assertEquals(100, counts.get('Inventory'), 'TC-001-08 Inventory count');
        System.assertEquals(100, counts.get('General'), 'TC-001-08 General count');
    }

    // TC-001-09 Case created by a General Support agent -> skill set the same way
    @IsTest static void tc09_runAsGeneralSupportAgent() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'General Support' LIMIT 1];
        String uniq = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User agent = new User(
            ProfileId = p.Id, LastName = 'QA Skill Agent', Alias = 'qaskill',
            Email = 'qa.skill.agent@example.invalid', Username = 'qa.skill.agent.' + uniq + '@example.invalid',
            TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert agent;
        Case c = newCase('Onboarding', 'Other');
        System.runAs(agent) {
            insert c;
        }
        System.assertEquals('General', skillOf(c.Id), 'TC-001-09');
    }

    // TC-001-10 The skills used for routing exist in the org
    @IsTest static void tc10_skillsExist() {
        Set<String> names = new Set<String>();
        for (Skill s : [SELECT DeveloperName FROM Skill WHERE DeveloperName IN ('General', 'Inventory')]) {
            names.add(s.DeveloperName);
        }
        System.assert(names.contains('General'), 'TC-001-10 General skill');
        System.assert(names.contains('Inventory'), 'TC-001-10 Inventory skill');
    }
}
