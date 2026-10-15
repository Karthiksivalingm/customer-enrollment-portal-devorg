public with sharing class SharePointFileNameViewerController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFileDetails(Id recordId) {
        Share_Point_Files__c fileRecord = [
            SELECT File_Path__c, File_Name__c
            FROM Share_Point_Files__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        Map<String, String> result = new Map<String, String>();
        result.put('filePath', fileRecord.File_Path__c);
        result.put('fileName', fileRecord.File_Name__c);

        return result;
    }
}