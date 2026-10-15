public with sharing class SharePointFileDatatableController {

    @AuraEnabled(cacheable=true)
    public static List<Share_Point_Files__c> getSharePointFiles(Id parentRecordId) {
        // Replace Guest_List__c with your actual lookup field API name
        return [
            SELECT Id, Name, File_Name__c, File_Path__c
            FROM Share_Point_Files__c
            WHERE Guest_List__c = :parentRecordId
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }
}