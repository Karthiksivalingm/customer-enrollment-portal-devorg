public with sharing class TechReviewController {

   /* @AuraEnabled
    public static void updateComments(Id recordId, String comments) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required');
        }

        uLab_Order__c rec = [
            SELECT Id, uAssist_Comments__c
            FROM uLab_Order__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        rec.uAssist_Comments__c = comments;
        update rec;
    }*/
}