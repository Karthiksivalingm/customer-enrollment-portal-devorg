public with sharing class SharePointEventFilesController {

    @AuraEnabled(cacheable=true)
    public static List<SharePoint_Event_Files__c> getFiles(Id recordId) {
        // Step 1: Get the Event's lookup to Event File Link
        Event evt = [
            SELECT Id, Event_File_Link__c
            FROM Event
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (evt.Event_File_Link__c == null) {
            return new List<SharePoint_Event_Files__c>();
        }
        // Step 2: Get all SharePoint Event Files under that Event File Link
        // EXCLUDE files marked as Minutes of Meeting
        return [
            SELECT Id, Name, File_Name__c, File_Path__c, Minutesof_Meeting__c
            FROM SharePoint_Event_Files__c
            WHERE Event_File_Link__c = :evt.Event_File_Link__c
            AND Minutesof_Meeting__c = false
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<SharePoint_Event_Files__c> getMeetingMinutesFiles(Id recordId) {
        Event evt = [
            SELECT Id, Event_File_Link__c
            FROM Event
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (evt.Event_File_Link__c == null) {
            return new List<SharePoint_Event_Files__c>();
        }
        return [
            SELECT Id, Name, File_Name__c, File_Path__c, Minutesof_Meeting__c
            FROM SharePoint_Event_Files__c
            WHERE Event_File_Link__c = :evt.Event_File_Link__c
            AND Minutesof_Meeting__c = true
            ORDER BY CreatedDate DESC
        ];
    }
}