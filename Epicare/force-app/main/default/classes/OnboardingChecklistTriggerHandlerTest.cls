@isTest
public class OnboardingChecklistTriggerHandlerTest {

    @testSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test.contact@example.com',
            NPN__c = 'NPN123456',
            Agent_Status__c = 'Onboarding'
        );
        insert con;
    }

    @isTest
    static void testAfterInsert() {

        Contact con = [SELECT Id FROM Contact LIMIT 1];

        List<Onboarding_Checklist__c> checklist = new List<Onboarding_Checklist__c>{
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'W9',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'ID Front',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'ID Back',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'SSN',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'Banking Info',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'License Verification',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'E O Insurance',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'Background Check',
                Status__c = 'Verified'
            ),
            new Onboarding_Checklist__c(
                Agent__c = con.Id,
                Item_Type__c = 'AML Cert',
                Status__c = 'Verified'
            )
        };

        Test.startTest();
        insert checklist;
        Test.stopTest();

        Contact updatedCon = [
            SELECT Base_Documents_Complete__c,
                   Banking_Complete__c,
                   License_Complete__c,
                   EO_Complete__c,
                   Background_Complete__c,
                   Certification_Complete__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(true, updatedCon.Base_Documents_Complete__c);
        System.assertEquals(true, updatedCon.Banking_Complete__c);
        System.assertEquals(true, updatedCon.License_Complete__c);
        System.assertEquals(true, updatedCon.EO_Complete__c);
        System.assertEquals(true, updatedCon.Background_Complete__c);
        System.assertEquals(true, updatedCon.Certification_Complete__c);
    }

    @isTest
    static void testAfterUpdate() {

        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Onboarding_Checklist__c rec = new Onboarding_Checklist__c(
            Agent__c = con.Id,
            Item_Type__c = 'Banking Info',
            Status__c = 'Submitted' // Valid picklist value
        );

        insert rec;

        Test.startTest();

        rec.Status__c = 'Verified';
        update rec;

        Test.stopTest();

        Contact updatedCon = [
            SELECT Banking_Complete__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(true, updatedCon.Banking_Complete__c);
    }

    @isTest
    static void testAfterDelete() {

        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Onboarding_Checklist__c rec = new Onboarding_Checklist__c(
            Agent__c = con.Id,
            Item_Type__c = 'License Verification',
            Status__c = 'Verified'
        );

        insert rec;

        Test.startTest();
        delete rec;
        Test.stopTest();

        Contact updatedCon = [
            SELECT License_Complete__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(false, updatedCon.License_Complete__c);
    }

    @isTest
    static void testAfterUndelete() {

        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Onboarding_Checklist__c rec = new Onboarding_Checklist__c(
            Agent__c = con.Id,
            Item_Type__c = 'Background Check',
            Status__c = 'Verified'
        );

        insert rec;
        delete rec;

        Test.startTest();
        undelete rec;
        Test.stopTest();

        Contact updatedCon = [
            SELECT Background_Complete__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(true, updatedCon.Background_Complete__c);
    }

    @isTest
    static void testNoAgent() {

        Onboarding_Checklist__c rec = new Onboarding_Checklist__c(
            Item_Type__c = 'W9',
            Status__c = 'Verified'
        );

        Test.startTest();
        insert rec;
        Test.stopTest();

        System.assert(true);
    }
}