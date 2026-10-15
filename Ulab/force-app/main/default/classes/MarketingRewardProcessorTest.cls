@isTest
public class MarketingRewardProcessorTest {

    @testSetup
    static void setupData() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Company',
            Account_Status__c = 'uLab Account'
        );
        insert acc;

        // Create Marketing Program (Required for relationship)
        Marketing_Reward__c program = new Marketing_Reward__c(
            Name__c = 'Test Program'
        );
        insert program;

        // Get Record Type
        Id recordTypeId = Schema.SObjectType.Marketing_Reward_Association__c
            .getRecordTypeInfosByName()
            .get('Program Association')
            .getRecordTypeId();

        // Create MRA record
        // Do NOT set Program_Name__c (Auto Number)
        // Do NOT set Active__c (Formula)

        Marketing_Reward_Association__c mra = new Marketing_Reward_Association__c(
            RecordTypeId = recordTypeId,
            Company__c = acc.Id,
            Marketing_Program__c = program.Id,

            // Important: Make formula Active__c evaluate TRUE
            Effective_Date__c = Date.today().addDays(-5),
            End_Date__c = Date.today().addDays(30)
        );

        insert mra;
    }

    // Test Batch Execution
    @isTest
    static void testBatchExecution() {

        Test.startTest();

        MarketingRewardProcessor batch = new MarketingRewardProcessor();
        Database.executeBatch(batch, 1);

        Test.stopTest();

        // Verify new record created
        List<Marketing_Reward_Association__c> newRecords = [
            SELECT Id, Effective_Date__c, End_Date__c,
                   Aligner_Price__c, Retainer_Price__c
            FROM Marketing_Reward_Association__c
            WHERE Effective_Date__c = :Date.newInstance(2026, 4, 1)
        ];

        System.assertEquals(1, newRecords.size(), 'One new record should be created');

        Marketing_Reward_Association__c created = newRecords[0];

        System.assertEquals(Date.newInstance(2026, 4, 1), created.Effective_Date__c);
        System.assertEquals(Date.newInstance(2027, 12, 31), created.End_Date__c);

        // Pricing fields should be null
        System.assertEquals(null, created.Aligner_Price__c);
        System.assertEquals(null, created.Retainer_Price__c);
    }

}