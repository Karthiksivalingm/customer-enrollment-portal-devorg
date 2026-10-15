public with sharing class ContactBioPDFController {
    
    @AuraEnabled(cacheable=true)
    public static Contact getContactDetails(Id contactId) {
        return [
            SELECT Id, Name, Title, Phone, Email, Email_Office__c, MobilePhone, Email_2__c,
                   Company__c, Contact__c, Admin_Phone__c, Admin_Email__c,
                   Professional_Personal_Backgrounds__c, Instagram_Following__c,
                   Instagram_Handle__c, Social_Media_Insta__c, Social_Media_Twitter__c,
                   LinkedIn__c, Tiktok__c, Facebook__c, Snap__c, Website1__c,
                   Marital_Status__c, Spouse_Name__c,Area_of_interest__c,
                   Connection__c, CONNECTION_NOTES__c,Category__c, Sector__c,
                   RecordTypeId, RecordType.Name, Deceased__c, Region__c,
                   Contact_Type__c, Edit__c, Protocol_tier__c, Birthdate
            FROM Contact
            WHERE Id = :contactId
        ];
    }
    
    // Fetch Event Guest List (aligned with Event History related list)
    @AuraEnabled(cacheable=true)
    public static List<Invitation__c> getEventGuestList(String contactId) {
        try {
            return [
                SELECT Id, Name, Date__c
                FROM Invitation__c
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving guest list: ' + e.getMessage());
        }
    }
    
    // Fetch Related Visits to Doha
    @AuraEnabled(cacheable=true)
    public static List<Visit_to_Doha__c> getVisitsToDoha(String contactId) {
        try {
            return [
                SELECT Id, Name
                FROM Visit_to_Doha__c
                WHERE Contact__c = :contactId
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving visits: ' + e.getMessage());
        }
    }
    
    // Fetch Gifts
    @AuraEnabled(cacheable=true)
    public static List<Gift_and_Donation__c> getGifts(String contactId) {
        try {
            return [
                SELECT Id, Name, RecordType.Name, Occasion_Purpose_Other__c
                FROM Gift_and_Donation__c
                WHERE Person_Accounts__c = :contactId
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving gifts: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void generatePdfAndAttach(Id contactId, String base64Content, String fileName) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Content);
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = contactId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

}