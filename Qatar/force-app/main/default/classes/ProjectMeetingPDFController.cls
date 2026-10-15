public class ProjectMeetingPDFController {
    public Project_Meeting__c projectMeeting { get; set; }
    public List<Action_Item__c> actionItems { get; set; }
    public List<ContentDocumentLink> attachments { get; set; }
  public List<Meeting_Request__c> meetingRequests { get; set; }
      public List<Minutes_Of_Meeting__c> mom { get; set; }
     public List<Project_Minutes__c> projectminutes{ get; set; }

    public Map<Id, String> fileUrls { get; set; }

    public ProjectMeetingPDFController() {
        Id projectMeetingId = ApexPages.currentPage().getParameters().get('id');
        
        // Query the Project Meeting details
        projectMeeting = [SELECT Category__c, CP_Feedback__c, End_date__c, Owner.Name, 
                          Priority__c, Project_Title__c, Start_date__c, Type__c 
                          FROM Project_Meeting__c 
                          WHERE Id = :projectMeetingId];

        // Query related Action Items
        actionItems = [SELECT Name, Status__c, Due_Date__c,	Action__c,Owner.Name 
                       FROM Action_Item__c 
                       WHERE Project__c = :projectMeetingId];
  // Query related Meeting Requests
        meetingRequests = [SELECT Name, Subject__c, Status__c, Meeting_Type__c, CreatedDate
                           FROM Meeting_Request__c 
                           WHERE Project__c = :projectMeetingId];

        
        // Query related MOM
      projectMinutes = [SELECT Name, OwnerId,Owner.Name,Minutes_Of_Meeting__r.Name  FROM Project_Minutes__c
    WHERE 	Project__c = :projectMeetingId]; 

        
        
        
     // Query Attachments (Notes and Attachments) through ContentDocumentLink
        attachments = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate, 
                       ContentDocument.LatestPublishedVersionId
                       FROM ContentDocumentLink
                       WHERE LinkedEntityId = :projectMeetingId];


      
        
        // Construct file URLs for each attachment
        fileUrls = new Map<Id, String>();
        for(ContentDocumentLink attachment : attachments) {
            String fileUrl = '/sfc/servlet.shepherd/version/download/' + attachment.ContentDocument.LatestPublishedVersionId;
            fileUrls.put(attachment.ContentDocument.LatestPublishedVersionId, fileUrl);
        }
    }
}