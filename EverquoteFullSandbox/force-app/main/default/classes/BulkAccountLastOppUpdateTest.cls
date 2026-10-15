@isTest
private class BulkAccountLastOppUpdateTest {

    private static final String AGENCY_PRICEBOOK_NAME = 'Agency Price Book';

    @TestSetup
    static void createTestData() {
        // The "Agency" Opportunity record type has org automation (e.g. a record-triggered flow
        // that force-assigns a hardcoded, org-specific Pricebook2 Id) that cannot resolve correctly
        // inside the data isolation of a test context, so Opportunity_PriceBookMatch's Agency branch
        // can never be satisfied here. The "Agency_CS_Upsell" record type isn't targeted by that
        // automation and isn't matched by any Opportunity_PriceBookMatch branch, so it's used instead
        // - the batch class under test doesn't filter or behave differently based on RecordType.
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Agency_CS_Upsell').getRecordTypeId();

        Pricebook2 agencyPricebook = new Pricebook2(Name = AGENCY_PRICEBOOK_NAME, IsActive = true);
        insert agencyPricebook;

        Carrier__c carrier = new Carrier__c(Name = 'Test Carrier');
        insert carrier;

        Account closedLostAccount = new Account(
            Name = 'Closed Lost Test Account',
            Carrier__c = carrier.Id,
            Last_Opportunity_was_Close_Lost__c = false
        );
        Account openAccount = new Account(
            Name = 'Open Opportunity Test Account',
            Carrier__c = carrier.Id,
            Last_Opportunity_was_Close_Lost__c = false
        );
        insert new List<Account>{ closedLostAccount, openAccount };

        insert new List<Opportunity>{
            newAgencyOpportunity('Closed Lost Test Opportunity', closedLostAccount.Id, oppRecordTypeId, agencyPricebook.Id),
            newAgencyOpportunity('Open Test Opportunity', openAccount.Id, oppRecordTypeId, agencyPricebook.Id)
        };
    }

    private static Opportunity newAgencyOpportunity(String oppName, Id accountId, Id recordTypeId, Id pricebookId) {
        return new Opportunity(
            Name = oppName,
            AccountId = accountId,
            RecordTypeId = recordTypeId,
            Pricebook2Id = pricebookId,
            StageName = 'Open',
            CloseDate = System.today().addMonths(1),
            LeadSource = 'Outbound Call'
        );
    }

    @isTest
    static void execute_flagsAccountWhoseMostRecentOpportunityIsClosedLost() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Closed Lost Test Account' LIMIT 1];
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        opp.StageName = 'Closed Lost';
        update opp;

        Test.startTest();
        Database.executeBatch(new BulkAccountLastOppUpdate(), 5);
        Test.stopTest();

        Account result = [SELECT Last_Opportunity_was_Close_Lost__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            true,
            result.Last_Opportunity_was_Close_Lost__c,
            'Account whose most recent Opportunity is Closed Lost should be flagged true.'
        );
    }

    @isTest
    static void execute_leavesAccountUnflaggedWhenMostRecentOpportunityIsOpen() {
        Account acc = [SELECT Id, Last_Opportunity_was_Close_Lost__c FROM Account WHERE Name = 'Open Opportunity Test Account' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new BulkAccountLastOppUpdate(), 5);
        Test.stopTest();

        Account result = [SELECT Last_Opportunity_was_Close_Lost__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            false,
            result.Last_Opportunity_was_Close_Lost__c,
            'Account whose most recent Opportunity is still open should not be flagged.'
        );
    }

    @isTest
    static void start_excludesAccountsAlreadyFlaggedClosedLost() {
        Account alreadyFlagged = new Account(
            Name = 'Already Flagged Account',
            Last_Opportunity_was_Close_Lost__c = true
        );
        insert alreadyFlagged;

        Test.startTest();
        Database.executeBatch(new BulkAccountLastOppUpdate(), 5);
        Test.stopTest();

        Account result = [SELECT Last_Opportunity_was_Close_Lost__c FROM Account WHERE Id = :alreadyFlagged.Id];
        System.assertEquals(
            true,
            result.Last_Opportunity_was_Close_Lost__c,
            'Batch start query only selects Accounts where Last_Opportunity_was_Close_Lost__c = false, so this record should be untouched.'
        );
    }
}