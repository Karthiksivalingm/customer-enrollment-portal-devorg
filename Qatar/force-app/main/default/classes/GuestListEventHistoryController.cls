public class GuestListEventHistoryController {
    public Guest_List__c currentGuestList { get; set; }
    public List<Guest_List__c> guestHistoryList { get; set; }

    public GuestListEventHistoryController(ApexPages.StandardController stdController) {
        Id guestListId = stdController.getId();
        
        // Safely assign currentGuestList
        List<Guest_List__c> results = [
            SELECT Id, Name, Contact__c 
            FROM Guest_List__c 
            WHERE Id = :guestListId 
            LIMIT 1
        ];

        if (!results.isEmpty()) {
            currentGuestList = results[0];
        } else {
            currentGuestList = new Guest_List__c();
            guestHistoryList = new List<Guest_List__c>();
            return;
        }

        // Check if the Guest Name (Contact lookup) is available
        if (currentGuestList.Contact__c != null) {
            guestHistoryList = [
                SELECT Name, Invitation__c, Date__c, Attended__c, 
                       Type_of_Participation__c, RSVP__c, Invitation_Sent__c, 
                       Save_the_date_sent__c
                FROM Guest_List__c
                WHERE Contact__c = :currentGuestList.Contact__c
                ORDER BY Date__c DESC
            ];
        } else {
            guestHistoryList = new List<Guest_List__c>();
        }
    }
}