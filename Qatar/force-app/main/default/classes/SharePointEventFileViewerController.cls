public with sharing class SharePointEventFileViewerController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getEventFileDetails(Id recordId) {
        SharePoint_Event_Files__c record = [
            SELECT File_Path__c, File_Name__c
            FROM SharePoint_Event_Files__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        Map<String, String> result = new Map<String, String>();
        result.put('filePath', record.File_Path__c);
        result.put('fileName', record.File_Name__c);
        return result;
    }
}