public with sharing class SharePointGiftDonationViewerController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getGiftDonationFileDetails(Id recordId) {
        SharePoint_Gifts_Donation__c fileRecord = [
            SELECT File_Path__c, File_Name__c
            FROM SharePoint_Gifts_Donation__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        Map<String, String> result = new Map<String, String>();
        result.put('filePath', fileRecord.File_Path__c);
        result.put('fileName', fileRecord.File_Name__c);

        return result;
    }
}