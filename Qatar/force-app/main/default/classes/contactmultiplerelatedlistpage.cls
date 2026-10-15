public class contactmultiplerelatedlistpage {
    private final Contact con;
    public List<ContentDocumentLink> bioContentDocumentLinks { get; set; }
    public List<ContentDocumentLink> itineraryContentDocumentLinks { get; set; }
    public List<ContentDocumentLink> giftContentDocumentLinks { get; set; }
    public List<ContentDocumentLink> meetingMinutesContentDocumentLinks { get; set; }
    
    // Properties for file upload
    public String fileType { get; set; }
    public Blob fileBody { get; set; }
    public String fileName { get; set; }

    // Constructor
    public contactmultiplerelatedlistpage(ApexPages.StandardController stdController) {
        this.con = (Contact)stdController.getRecord();
        System.debug('Initialized controller for Contact: ' + con.Id);
        queryContentDocuments();
    }

    // Method to query content documents by description
    public void queryContentDocuments() {
        bioContentDocumentLinks = getContentDocumentsByDescription('Bios');
        itineraryContentDocumentLinks = getContentDocumentsByDescription('Itineraries');
        giftContentDocumentLinks = getContentDocumentsByDescription('Gifts');
        meetingMinutesContentDocumentLinks = getContentDocumentsByDescription('Meeting Minutes');
    }

    // Helper method to get content documents by description
    private List<ContentDocumentLink> getContentDocumentsByDescription(String description) {
        try {
            return [
                SELECT Id, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, 
                       ContentDocument.LatestPublishedVersion.CreatedDate, ContentDocument.LatestPublishedVersion.CreatedBy.Name,
                       ContentDocument.Description
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :con.Id 
                AND ContentDocument.Description = :description
            ];
        } catch (Exception e) {
            System.debug('Error executing ' + description + ' query: ' + e.getMessage());
            return new List<ContentDocumentLink>();
        }
    }
    
    // Method to handle file upload for Bios
    public PageReference uploadBio() {
        return uploadFile('Bios');
    }
    
    // Method to handle file upload for Itineraries
    public PageReference uploadItineraries() {
        return uploadFile('Itineraries');
    }
    
    // Method to handle file upload for Gifts
    public PageReference uploadGift() {
        return uploadFile('Gifts');
    }
    
    // Method to handle file upload for Meeting Minutes
    public PageReference uploadMeetingminutes() {
        return uploadFile('Meeting Minutes');
    }
    
    // Common method to upload file
    private PageReference uploadFile(String description) {
        if (fileBody != null && fileName != null) {
            try {
                // Create new ContentVersion
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = fileName;
                contentVersion.PathOnClient = fileName;
                contentVersion.VersionData = fileBody;
                contentVersion.Description = description;
                insert contentVersion;

                // Get the Id of the new ContentDocument
                ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.LinkedEntityId = con.Id;
                contentDocumentLink.ContentDocumentId = insertedContentVersion.ContentDocumentId;
                contentDocumentLink.ShareType = 'V'; // Inferred permission
                insert contentDocumentLink;

                // Refresh the lists
                queryContentDocuments();

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'File uploaded successfully'));
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error uploading file: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a file to upload.'));
        }
        return null;
    }
}