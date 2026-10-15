public with sharing class SharePointEventFileDatatableController {

    @AuraEnabled(cacheable=true)
    public static List<SharePoint_Event_Files__c> getSharePointEventFiles(Id parentRecordId) {
        // Replace Event__c with the correct lookup field API name on SharePoint_Event_Files__c
        return [
            SELECT Id, Name, File_Name__c, File_Path__c
            FROM SharePoint_Event_Files__c
            WHERE Event_File_Link__c = :parentRecordId
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }
}