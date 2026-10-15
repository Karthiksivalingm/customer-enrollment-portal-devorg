@isTest
public class ContactInsuranceHandlerTest {

    @testSetup
    static void setupData() {
        insert new Account(Name = 'Test Account');
    }

    @isTest
    static void testAfterInsert() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test.contact@example.com',
            NPN__c = 'NPN123456',
            Agent_Status__c = 'Onboarding',
            Insurance_Types__c = 'Life;Supplementary'
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        List<Certification__c> certs = [
            SELECT Insurance_Type__c
            FROM Certification__c
            WHERE Agent__c = :con.Id
        ];

        List<Onboarding_Checklist__c> checks = [
            SELECT Insurance_Type__c
            FROM Onboarding_Checklist__c
            WHERE Agent__c = :con.Id
        ];

        System.assert(certs.size() > 0);
        System.assert(checks.size() > 0);
    }

    @isTest
    static void testAfterUpdate_AddInsurance() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact con = new Contact(
            FirstName = 'Update',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'update.contact@example.com',
            NPN__c = 'NPN234567',
            Agent_Status__c = 'Onboarding',
            Insurance_Types__c = 'Life'
        );
        insert con;

        Test.startTest();

        con.Insurance_Types__c = 'Life;Supplementary;ACA';
        update con;

        Test.stopTest();

        List<Certification__c> certs = [
            SELECT Insurance_Type__c
            FROM Certification__c
            WHERE Agent__c = :con.Id
        ];

        List<Onboarding_Checklist__c> checks = [
            SELECT Insurance_Type__c
            FROM Onboarding_Checklist__c
            WHERE Agent__c = :con.Id
        ];

        Boolean certFound = false;
        for (Certification__c c : certs) {
            if (c.Insurance_Type__c == 'ACA') {
                certFound = true;
                break;
            }
        }

        Boolean checkFound = false;
        for (Onboarding_Checklist__c c : checks) {
            if (c.Insurance_Type__c == 'ACA') {
                checkFound = true;
                break;
            }
        }

        System.assert(certFound);
        System.assert(checkFound);
    }

    @isTest
    static void testAfterUpdate_RemoveInsurance() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact con = new Contact(
            FirstName = 'Delete',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'delete.contact@example.com',
            NPN__c = 'NPN345678',
            Agent_Status__c = 'Onboarding',
            Insurance_Types__c = 'Life;Supplementary;ACA'
        );
        insert con;

        Test.startTest();

        con.Insurance_Types__c = 'Life';
        update con;

        Test.stopTest();

        List<Certification__c> certs = [
            SELECT Insurance_Type__c
            FROM Certification__c
            WHERE Agent__c = :con.Id
        ];

        List<Onboarding_Checklist__c> checks = [
            SELECT Insurance_Type__c
            FROM Onboarding_Checklist__c
            WHERE Agent__c = :con.Id
        ];

        Boolean lifeCert = false;
        for (Certification__c c : certs) {
            if (c.Insurance_Type__c == 'Life') {
                lifeCert = true;
                break;
            }
        }

        Boolean lifeCheck = false;
        for (Onboarding_Checklist__c c : checks) {
            if (c.Insurance_Type__c == 'Life') {
                lifeCheck = true;
                break;
            }
        }

        System.assert(lifeCert);
        System.assert(lifeCheck);
    }

    @isTest
    static void testBlankInsuranceTypes() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact con = new Contact(
            FirstName = 'Blank',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'blank.contact@example.com',
            NPN__c = 'NPN456789',
            Agent_Status__c = 'Onboarding'
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Integer certCount = [
            SELECT COUNT()
            FROM Certification__c
            WHERE Agent__c = :con.Id
        ];

        Integer checkCount = [
            SELECT COUNT()
            FROM Onboarding_Checklist__c
            WHERE Agent__c = :con.Id
        ];

        System.assertEquals(0, certCount);
        System.assertEquals(0, checkCount);
    }
}