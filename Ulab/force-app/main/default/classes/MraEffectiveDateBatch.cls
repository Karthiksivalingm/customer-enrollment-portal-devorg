public class MraEffectiveDateBatch implements Database.Batchable<SObject> {

    // Backing field - do NOT reference the getter method from inside itself
    private static Id progRtIdCache;

    private static Id getProgramAssociationRecordTypeId() {
        if (progRtIdCache == null) {
            progRtIdCache =
                Schema.SObjectType.Marketing_Reward_Association__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('Program_Association')
                    .getRecordTypeId();
        }
        return progRtIdCache;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Date today  = Date.today();
        Id progRtId = getProgramAssociationRecordTypeId();

        return Database.getQueryLocator([
            SELECT Id, Company__c, Send_to_Boomi__c,
                   Effective_Date__c, End_Date__c
            FROM   Marketing_Reward_Association__c
            WHERE  RecordTypeId = :progRtId
            AND    Effective_Date__c = :today
            AND    Send_to_Boomi__c = false
            AND    (End_Date__c = NULL OR End_Date__c >= :today)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Marketing_Reward_Association__c> scope) {

        Id progRtId = getProgramAssociationRecordTypeId();

        Set<Id> companyIds = new Set<Id>();
        for (Marketing_Reward_Association__c mra : scope) {
            if (mra.Company__c != null) {
                companyIds.add(mra.Company__c);
            }
        }

        Set<Id> claimedCompanies = new Set<Id>();
        if (!companyIds.isEmpty()) {
            for (Marketing_Reward_Association__c existing : [
                SELECT Company__c
                FROM   Marketing_Reward_Association__c
                WHERE  Company__c IN :companyIds
                AND    RecordTypeId = :progRtId
                AND    Send_to_Boomi__c = true
            ]) {
                claimedCompanies.add(existing.Company__c);
            }
        }

        List<Marketing_Reward_Association__c> toUpdate =
            new List<Marketing_Reward_Association__c>();

        for (Marketing_Reward_Association__c mra : scope) {

            if (mra.Company__c != null) {

                if (claimedCompanies.contains(mra.Company__c)) {
                    System.debug(LoggingLevel.WARN,
                        'MraEffectiveDateBatch skipped ' + mra.Id +
                        ' - Company ' + mra.Company__c +
                        ' already has a Program Association marked Send to Boomi.');
                    continue;
                }

                claimedCompanies.add(mra.Company__c);
            }

            toUpdate.add(new Marketing_Reward_Association__c(
                Id = mra.Id,
                Send_to_Boomi__c = true
            ));
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'MraEffectiveDateBatch failed for ' + toUpdate[i].Id + ': ' +
                        results[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Hook for notification / logging if needed later.
    }
}