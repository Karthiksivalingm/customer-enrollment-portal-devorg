public with sharing class SharePointFileViewerController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFileDetails(Id recordId, String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API Name is required.');
        }

        String soql = 'SELECT File_Name__c, File_Path__c FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
        SObject record = Database.query(soql);

        Map<String, String> result = new Map<String, String>();
        result.put('fileName', (String)record.get('File_Name__c'));
        result.put('filePath', (String)record.get('File_Path__c'));
        return result;
    }
}