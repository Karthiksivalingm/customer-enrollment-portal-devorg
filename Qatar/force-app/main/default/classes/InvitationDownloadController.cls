public class InvitationDownloadController {
    public Invitation__c invitation { get; set; }
    public List<GuestDetail> guestDetails { get; set; }

    public InvitationDownloadController() {
        Id invitationId = ApexPages.currentPage().getParameters().get('invitationId');
        if (invitationId != null) {
            invitation = [SELECT Name FROM Invitation__c WHERE Id = :invitationId LIMIT 1];

            List<Guest_List__c> guestList = [
                SELECT Contact__r.Name, Contact__r.Title, 
                       Contact__r.Professional_Personal_Backgrounds__c, 
                       Contact__r.Instagram_Handle__c 
                FROM Guest_List__c 
                WHERE Invitation__c = :invitationId
                ORDER BY CreatedDate ASC
            ];

            guestDetails = new List<GuestDetail>();

            for (Guest_List__c gl : guestList) {
                if (gl.Contact__r == null) continue;

                GuestDetail gd = new GuestDetail();
                gd.contact = gl.Contact__r;

                List<Attachment> attachments = [
                    SELECT Id FROM Attachment WHERE ParentId = :gl.Contact__r.Id LIMIT 1
                ];
                if (!attachments.isEmpty()) {
                    gd.attachment = attachments[0];
                }

                guestDetails.add(gd);
            }
        } else {
            guestDetails = new List<GuestDetail>();
        }
    }

    public class GuestDetail {
        public Contact contact { get; set; }
        public Attachment attachment { get; set; }
    }
}