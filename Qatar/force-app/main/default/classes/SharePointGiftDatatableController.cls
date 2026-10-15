public with sharing  class SharePointGiftDatatableController {

   @AuraEnabled(cacheable=true)
    public static List<SharePoint_Gifts_Donation__c> getSharePointGiftsDonationFiles(Id parentRecordId) {
        return [
            SELECT Id, Name, File_Name__c, File_Path__c
            FROM SharePoint_Gifts_Donation__c
            WHERE Id != null
            ORDER BY CreatedDate DESC
        ];
    }
}