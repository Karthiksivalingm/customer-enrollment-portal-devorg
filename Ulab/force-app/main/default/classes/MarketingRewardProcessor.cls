global class MarketingRewardProcessor implements Database.Batchable<SObject> {

   global Database.QueryLocator start(Database.BatchableContext bc) {

    Date checkDate = Date.newInstance(2026, 3, 31);

    Id recordTypeId = Schema.SObjectType.Marketing_Reward_Association__c
        .getRecordTypeInfosByName()
        .get('Program Association')
        .getRecordTypeId();

    return Database.getQueryLocator([
      SELECT Id, Company__c, Marketing_Program__c,
       Effective_Date__c, End_Date__c,
       Aligner_Price__c, Retainer_Price__c, STL_Price__c,
       IDB_Tray__c, Direct_Print_Aligner__c,
       Custom_Packaging_Price__c, Custom_Packaging_Setup_Price__c,
       Custom_Packaging_Discount__c, Custom_Packaging_Setup_Discount__c,
       uAssist_Initial_Pricing__c, uAssist_Refinement_Pricing__c,
       uAssist_Bracket_Removal_Pricing__c, uAssist_Retainer_Pricing__c,
       Mild_Bundle__c, Moderate_Bundle__c, Comprehensive_Bundle__c,
       OrthoPulse_Unlimited__c,
       uAdjust_10_Bundle__c,
       Finishing_Bundle__c, X2_Retainer_Bundle__c,
       X4_Retainer_Bundle__c, Case_Backstop__c, X8_Retainer_Bundle__c,
       Active__c
    FROM Marketing_Reward_Association__c
    WHERE RecordTypeId = :recordTypeId
     AND Active__c = true 
     AND Effective_Date__c <= :checkDate
      AND (End_Date__c = NULL OR End_Date__c >= :checkDate)
      AND Marketing_Program__r.Name__c NOT IN ('2024 uStart', 'Futures Gold')
      ORDER BY Effective_Date__c DESC
     
    ]);
}

    global void execute(Database.BatchableContext bc,
                        List<Marketing_Reward_Association__c> scope) {

        Date nextEffectiveDate = Date.newInstance(2026, 4, 1);
        Date newEndDate = Date.newInstance(2027, 12, 31);


        List<Marketing_Reward_Association__c> recordsToInsert = new List<Marketing_Reward_Association__c>();

        for (Marketing_Reward_Association__c mra : scope) {

            // Create completely new record
            Marketing_Reward_Association__c newMRA = new Marketing_Reward_Association__c();

            // Copy required relationship fields
            newMRA.Company__c = mra.Company__c;
            newMRA.Marketing_Program__c = mra.Marketing_Program__c;

            // Set new dates
            newMRA.Effective_Date__c = nextEffectiveDate;
            newMRA.End_Date__c = newEndDate;
            

            // Set all pricing fields to NULL
            newMRA.Aligner_Price__c = null;
            newMRA.Retainer_Price__c = null;
            newMRA.STL_Price__c = null;
            newMRA.IDB_Tray__c = null;
            newMRA.Direct_Print_Aligner__c = null;

            newMRA.Custom_Packaging_Price__c = null;
            newMRA.Custom_Packaging_Setup_Price__c = null;
            newMRA.Custom_Packaging_Discount__c = null;
            newMRA.Custom_Packaging_Setup_Discount__c = null;

            newMRA.uAssist_Initial_Pricing__c = null;
            newMRA.uAssist_Refinement_Pricing__c = null;
            newMRA.uAssist_Bracket_Removal_Pricing__c = null;
            newMRA.uAssist_Retainer_Pricing__c = null;

            newMRA.Mild_Bundle__c = null;
            newMRA.Moderate_Bundle__c = null;
            newMRA.Comprehensive_Bundle__c = null;
            newMRA.OrthoPulse_Unlimited__c = null;
            newMRA.uAdjust_10_Bundle__c = null;
            newMRA.Finishing_Bundle__c = null;
            newMRA.X2_Retainer_Bundle__c = null;
            newMRA.X4_Retainer_Bundle__c = null;
            newMRA.Case_Backstop__c = null;
            newMRA.X8_Retainer_Bundle__c = null;

            recordsToInsert.add(newMRA);
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Marketing Reward Batch Completed');
    }
}