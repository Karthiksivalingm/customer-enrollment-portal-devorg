public with sharing class SharePointTableController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSharePointFiles(Id parentRecordId) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();

        if (parentRecordId == null) {
            for (SharePoint_Event_Files__c record : [
                SELECT Id, Name, File_Name__c, File_Path__c,
                       Start_Date_Time__c, End_Date_Time__c, Subject__c
                FROM SharePoint_Event_Files__c
                ORDER BY CreatedDate DESC
                LIMIT 200
            ]) {
                resultList.add(new Map<String, Object>{
                    'Id' => record.Id,
                    'Name' => record.Name,
                    'File_Name__c' => record.File_Name__c,
                    'File_Path__c' => record.File_Path__c,
                    'Start_Date_Time__c' => record.Start_Date_Time__c,
                    'End_Date_Time__c' => record.End_Date_Time__c,
                    'Subject__c' => record.Subject__c
                });
            }
            return resultList;
        }

        String objectName = '';
        if ([SELECT Id FROM Guest_List__c WHERE Id = :parentRecordId LIMIT 1].size() > 0) {
            objectName = 'Guest_List__c';
        } else if ([SELECT Id FROM Event_File_Link__c WHERE Id = :parentRecordId LIMIT 1].size() > 0) {
            objectName = 'Event_File_Link__c';
        } else if ([SELECT Id FROM Gift_and_Donation__c WHERE Id = :parentRecordId LIMIT 1].size() > 0) {
            objectName = 'Gift_and_Donation__c';
        }

        if (String.isBlank(objectName)) return resultList;

        if (objectName == 'Event_File_Link__c') {
            for (SharePoint_Event_Files__c record : [
                SELECT Id, Name, File_Name__c, File_Path__c,
                       Start_Date_Time__c, End_Date_Time__c, Subject__c
                FROM SharePoint_Event_Files__c
                WHERE Event_File_Link__c = :parentRecordId
                ORDER BY CreatedDate DESC LIMIT 200
            ]) {
                resultList.add(new Map<String, Object>{
                    'Id' => record.Id,
                    'Name' => record.Name,
                    'File_Name__c' => record.File_Name__c,
                    'File_Path__c' => record.File_Path__c,
                    'Start_Date_Time__c' => record.Start_Date_Time__c,
                    'End_Date_Time__c' => record.End_Date_Time__c,
                    'Subject__c' => record.Subject__c
                });
            }
        } else if (objectName == 'Guest_List__c') {
            for (Share_Point_Files__c record : [
                SELECT Id, Name, File_Name__c, File_Path__c
                FROM Share_Point_Files__c
                WHERE Guest_List__c = :parentRecordId
                ORDER BY CreatedDate DESC LIMIT 200
            ]) {
                resultList.add(new Map<String, Object>{
                    'Id' => record.Id,
                    'Name' => record.Name,
                    'File_Name__c' => record.File_Name__c,
                    'File_Path__c' => record.File_Path__c
                });
            }
        } else if (objectName == 'Gift_and_Donation__c') {
            for (SharePoint_Gifts_Donation__c record : [
                SELECT Id, Name, File_Name__c, File_Path__c
                FROM SharePoint_Gifts_Donation__c
                WHERE Gift_and_Donation__c = :parentRecordId
                ORDER BY CreatedDate DESC LIMIT 200
            ]) {
                resultList.add(new Map<String, Object>{
                    'Id' => record.Id,
                    'Name' => record.Name,
                    'File_Name__c' => record.File_Name__c,
                    'File_Path__c' => record.File_Path__c
                });
            }
        }

        return resultList;
    }
}