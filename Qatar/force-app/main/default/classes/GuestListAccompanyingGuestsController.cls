/**
 * Backend for the guestListAccompanyingGuests LWC.
 * Lists Guest_List__c child records whose self-lookup Main_Guest__c
 * points back at the parent Guest_List__c record being viewed.
 *
 * NOTE: adjust the field list in getAccompanyingGuests() to match whichever
 * columns you want surfaced in the related list — only Id, Contact__c and
 * Main_Guest__c are relied on structurally.
 */
public with sharing class GuestListAccompanyingGuestsController {

    public class ChildGuestWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String guestTier;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<ChildGuestWrapper> getAccompanyingGuests(Id parentGuestId) {
        List<ChildGuestWrapper> results = new List<ChildGuestWrapper>();

        if (parentGuestId == null) {
            return results;
        }

        List<Guest_List__c> children = [
            SELECT Id, CreatedDate,
                   Contact__c, Contact__r.Name, Contact__r.Email,
                   Guest_Tier_Recommendations__c
            FROM Guest_List__c
            WHERE Main_Guest__c = :parentGuestId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];

        for (Guest_List__c g : children) {
            ChildGuestWrapper w = new ChildGuestWrapper();
            w.id           = g.Id;
            w.contactId    = g.Contact__c;
            w.contactName  = g.Contact__r != null ? g.Contact__r.Name : null;
            w.contactEmail = g.Contact__r != null ? g.Contact__r.Email : null;
            w.guestTier    = g.Guest_Tier_Recommendations__c;
            w.createdDate  = g.CreatedDate;
            results.add(w);
        }

        return results;
    }
}