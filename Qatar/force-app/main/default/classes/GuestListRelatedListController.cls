public with sharing class GuestListRelatedListController {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getGuestList(Id invitationId, Integer pageSize, Integer offset) {
        Integer ps = pageSize != null ? pageSize : 20;
        Integer os = offset   != null ? offset   : 0;

        Integer totalCount = [
            SELECT COUNT() FROM Guest_List__c WHERE Invitation__c = :invitationId
        ];

        List<Guest_List__c> guests = [
            SELECT
                Id,
                Contact__r.Contact_External_Id__c,
                Title__c,
                Contact__r.Name,
                Contact__r.Title,
                Bio__c,
                Reason_for_Inviting__c,
                Source__c,
                Protocol_Tier__c,
                Guest_Category__c,
                Guest_Sector__c,
                Company__c,
                Background_Check__c,
                RSVP__c,
                Inbound_Date_Time__c,
                Outbound_Date_Time__c,
                Hotel_Name__c,
                X1_of_Invited_Guests__c,
                Relationship_to__c,
                Main_Guest__c,
                Escorted_By__c,
                Escorted_By__r.Name,
                Contact__c,
                (
                    SELECT Id, Name
                    FROM HE_Request__r
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                )
            FROM Guest_List__c
            WHERE Invitation__c = :invitationId
            ORDER BY Contact__r.Name ASC
            LIMIT :ps OFFSET :os
        ];

        Set<Id> contactIds = new Set<Id>();
        for (Guest_List__c g : guests) {
            if (g.Contact__c != null) contactIds.add(g.Contact__c);
        }

        Map<Id, String> photoMap = new Map<Id, String>();
        if (!contactIds.isEmpty()) {
            for (Attachment att : [
                SELECT Id, ParentId, ContentType
                FROM Attachment
                WHERE ParentId IN :contactIds
                AND ContentType IN ('image/jpeg','image/jpg','image/png','image/gif','image/svg+xml')
                ORDER BY CreatedDate DESC
            ]) {
                if (!photoMap.containsKey(att.ParentId)) {
                    photoMap.put(att.ParentId, '/servlet/servlet.FileDownload?file=' + att.Id);
                }
            }
        }

        List<GuestListWrapper> records = new List<GuestListWrapper>();
        Integer idx = os + 1;
        for (Guest_List__c g : guests) {
            GuestListWrapper w    = new GuestListWrapper();
            w.id                  = g.Id;
            w.rowNum              = idx++;
            w.contactId           = g.Contact__c;
            w.contactExternalId   = g.Contact__r != null ? g.Contact__r.Contact_External_Id__c : '';
            w.title               = g.Title__c;
            w.jobTitle            = g.Contact__r != null ? g.Contact__r.Title : '';
            w.contactName         = g.Contact__r != null ? g.Contact__r.Name : '';
            w.contactInitial      = String.isNotBlank(w.contactName) ? w.contactName.substring(0,1).toUpperCase() : '?';
            w.biography           = g.Bio__c != null ? g.Bio__c : '';
            w.reasonForAttendance = g.Reason_for_Inviting__c;
            w.source              = g.Source__c;
            w.protocolTier        = g.Protocol_Tier__c;
            w.guestCategory       = g.Guest_Category__c;
            w.guestSector         = g.Guest_Sector__c;
            w.company             = g.Company__c;
            w.backgroundCheck     = g.Background_Check__c;
            w.rsvp                = g.RSVP__c;
            w.inboundDateTime     = g.Inbound_Date_Time__c;
            w.outboundDateTime    = g.Outbound_Date_Time__c;
            w.hotelName           = g.Hotel_Name__c;
            w.invitedGuest        = g.X1_of_Invited_Guests__c != null ? g.X1_of_Invited_Guests__c : '';
            w.relationshipTo      = g.Relationship_to__c;
            w.mainGuestId         = g.Main_Guest__c;
            w.escortedById        = g.Escorted_By__c;
            w.escortedBy          = g.Escorted_By__r != null ? g.Escorted_By__r.Name : '';
            w.heNote              = (!g.HE_Request__r.isEmpty()) ? g.HE_Request__r[0].Name : '';
            w.photoUrl            = photoMap.containsKey(g.Contact__c) ? photoMap.get(g.Contact__c) : '';
            records.add(w);
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('records',    records);
        result.put('totalCount', totalCount);
        result.put('hasMore',    (os + ps) < totalCount);
        return result;
    }

    @AuraEnabled
    public static void upsertHERequest(Id guestListId, String guestName, String feedbackNote) {
        List<HE_Request__c> existing = [
            SELECT Id, Name FROM HE_Request__c
            WHERE Guest_List__c = :guestListId
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        if (!existing.isEmpty()) {
            existing[0].Name = feedbackNote;
            update existing[0];
        } else {
            insert new HE_Request__c(
                Name          = feedbackNote,
                Guest_List__c = guestListId
            );
        }
    }

    public class GuestListWrapper {
        @AuraEnabled public String   id;
        @AuraEnabled public Integer  rowNum;
        @AuraEnabled public String   contactId;
        @AuraEnabled public String   contactExternalId;
        @AuraEnabled public String   title;
        @AuraEnabled public String   jobTitle;
        @AuraEnabled public String   contactName;
        @AuraEnabled public String   contactInitial;
        @AuraEnabled public String   biography;
        @AuraEnabled public String   reasonForAttendance;
        @AuraEnabled public String   source;
        @AuraEnabled public String   protocolTier;
        @AuraEnabled public String   guestCategory;
        @AuraEnabled public String   guestSector;
        @AuraEnabled public String   company;
        @AuraEnabled public String   backgroundCheck;
        @AuraEnabled public String   rsvp;
        @AuraEnabled public DateTime inboundDateTime;
        @AuraEnabled public DateTime outboundDateTime;
        @AuraEnabled public String   hotelName;
        @AuraEnabled public String   invitedGuest;
        @AuraEnabled public String   relationshipTo;
        @AuraEnabled public String   mainGuestId;
        @AuraEnabled public String   escortedById;
        @AuraEnabled public String   escortedBy;
        @AuraEnabled public String   heNote;
        @AuraEnabled public String   photoUrl;
    }
}