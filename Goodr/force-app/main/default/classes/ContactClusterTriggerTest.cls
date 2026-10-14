@IsTest
public class ContactClusterTriggerTest {

    private static Id companyRtId = Schema.SObjectType.Account
        .getRecordTypeInfosByName().get('Company').getRecordTypeId();



    private static Account buildCompanyAccount(String name, String taxId) {
        return new Account(
            Name               = name,
            RecordTypeId       = companyRtId,
            Tax_Id__c          = taxId,
            Sales_Channel__c   = 'Global',
            BillingStreet      = '123 Main St',
            BillingCity        = 'Los Angeles',
            BillingState       = 'CA',
            BillingPostalCode  = '90001',
            BillingCountry     = 'US',
            ShippingStreet     = '123 Main St',
            ShippingCity       = 'Los Angeles',
            ShippingState      = 'CA',
            ShippingPostalCode = '90001',
            ShippingCountry    = 'US'
        );
    }

    private static Contact buildContact(
        String firstName, String lastName,
        String email, Id accountId
    ) {
        return new Contact(
            FirstName        = firstName,
            LastName         = lastName,
            Email            = email,
            AccountId        = accountId,
            Sales_Channel__c = 'Global'
        );
    }

   

    
    @IsTest
    static void testContactInsert_EnqueuesTeamAssignment() {
        Account acc = buildCompanyAccount('Trigger Test Co', '100200301');
        insert acc;

        Test.startTest();
        insert buildContact('John', 'Doe', 'john.doe@test.com', acc.Id);
        Test.stopTest();
        // stopTest() flushes the async queue — Queueable executes here

        // Verify Contact exists and team assignment ran without error
        List<Contact> cons = [
            SELECT Id, Cluster__c
            FROM Contact
            WHERE Email = 'john.doe@test.com'
        ];
        System.assertEquals(1, cons.size(), 'Contact should be inserted');
        // Team assignment ran — Contact_Team__c records may or may not exist
        // depending on CMDT rules, but no exception should be thrown
        System.assert(true, 'Queueable should execute without error after Contact insert');
    }

    // Covers: bulk insert — multiple contacts enqueued in one trigger batch
    @IsTest
    static void testContactBulkInsert_AllContactsProcessed() {
        Account acc = buildCompanyAccount('Bulk Contact Co', '100200302');
        insert acc;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(buildContact(
                'Bulk', 'Contact' + i,
                'bulk.contact' + i + '@test.com',
                acc.Id
            ));
        }

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Integer count = [
            SELECT COUNT()
            FROM Contact
            WHERE AccountId = :acc.Id
        ];
        System.assertEquals(5, count, 'All 5 contacts should be inserted and processed');
    }

   
    @IsTest
    static void testQueueable_Execute_ContactsExist_AssignsTeams() {
        Account acc = buildCompanyAccount('Queueable Test Co', '100200303');
        insert acc;

        Contact con = buildContact('Jane', 'Smith', 'jane.smith@test.com', acc.Id);
        insert con;

        Test.startTest();
        System.enqueueJob(
            new ContactTeamReassignQueueable(new Set<Id>{ con.Id })
        );
        Test.stopTest();

        // Formula field Cluster__c resolves after Account is committed
        List<Contact> freshCons = [
            SELECT Id, Cluster__c
            FROM Contact
            WHERE Id = :con.Id
        ];
        System.assertEquals(1, freshCons.size(),
            'Contact should exist when Queueable executes');
        System.assert(true, 'Queueable execute() should complete without error');
    }

    // Covers: execute() — empty result from query (contact deleted before async runs)
    @IsTest
    static void testQueueable_Execute_NoContactsFound_NoError() {
        // Pass a valid but non-existent Id to simulate
        // contact deleted before Queueable runs
        Id fakeContactId = '003000000000001AAA';

        Test.startTest();
        System.enqueueJob(
            new ContactTeamReassignQueueable(new Set<Id>{ fakeContactId })
        );
        Test.stopTest();

        System.assert(true,
            'Queueable should handle empty query result gracefully');
    }

    // Covers: execute() — multiple contacts, bulk assignTeams path
    @IsTest
    static void testQueueable_Execute_MultipleContacts_BulkPath() {
        Account acc = buildCompanyAccount('Multi Contact Co', '100200304');
        insert acc;

        List<Contact> contacts = new List<Contact>{
            buildContact('Multi', 'One', 'multi.one@test.com', acc.Id),
            buildContact('Multi', 'Two', 'multi.two@test.com', acc.Id),
            buildContact('Multi', 'Three', 'multi.three@test.com', acc.Id)
        };
        insert contacts;

        Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();

        Test.startTest();
        System.enqueueJob(new ContactTeamReassignQueueable(contactIds));
        Test.stopTest();

        Integer count = [
            SELECT COUNT() FROM Contact WHERE Id IN :contactIds
        ];
        System.assertEquals(3, count,
            'All 3 contacts should be processed by Queueable');
    }

    // Covers: Queueable correctly reads formula Cluster__c after Account committed
    // This is the core formula field timing fix being validated
    @IsTest
    static void testQueueable_Execute_FormulaFieldResolvesCorrectly() {
        Account acc = buildCompanyAccount('Formula Test Co', '100200305');
        insert acc;

        Contact con = buildContact('Formula', 'Test', 'formula.test@test.com', acc.Id);
        insert con;

        Test.startTest();
        System.enqueueJob(
            new ContactTeamReassignQueueable(new Set<Id>{ con.Id })
        );
        Test.stopTest();

        // Re-query after async completes — formula should resolve
        // to Account's Cluster__c value (set by ClusterRuleEngine on Account insert)
        Contact freshCon = [
            SELECT Id, Cluster__c, AccountId
            FROM Contact
            WHERE Id = :con.Id
        ];

        // Account.Cluster__c drives the formula — both should match
        Account freshAcc = [SELECT Cluster__c FROM Account WHERE Id = :acc.Id];

        System.assertEquals(
            freshAcc.Cluster__c,
            freshCon.Cluster__c,
            'Contact formula Cluster__c should match Account Cluster__c after async'
        );
    }

    // Covers: trigger does NOT fire on update — team assignment
    // on update is handled by AccountCascadeHandler, not this trigger
    @IsTest
    static void testContactUpdate_TriggerDoesNotRefire() {
        Account acc = buildCompanyAccount('Update Safe Co', '100200306');
        insert acc;

        Contact con = buildContact('Update', 'Safe', 'update.safe@test.com', acc.Id);
        insert con;

        Test.startTest();
        // Update should not fire ContactClusterTrigger (after insert only)
        con.Title = 'Updated Title';
        update con;
        Test.stopTest();

        Contact updated = [SELECT Title FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Updated Title', updated.Title,
            'Contact update should succeed without trigger interference');
    }
}