public without sharing class NotePDFController {

    public String title       { get; set; }
    public String content     { get; set; }
    public String noteDate    { get; set; }
    public String createdBy   { get; set; }

    public NotePDFController() {
        String cvId      = ApexPages.currentPage().getParameters().get('cvId');
        String eventName = ApexPages.currentPage().getParameters().get('eventName');
        String createdBy = ApexPages.currentPage().getParameters().get('createdBy');
        String noteDate  = ApexPages.currentPage().getParameters().get('noteDate');

        this.title     = String.isNotBlank(eventName) ? eventName : 'Untitled';
        this.createdBy = String.isNotBlank(createdBy) ? createdBy : '';
        this.noteDate  = String.isNotBlank(noteDate)  ? noteDate  : String.valueOf(Date.today());
        this.content   = '';

        if (String.isNotBlank(cvId)) {
            try {
                ContentVersion cv = [
                    SELECT Id, VersionData
                    FROM ContentVersion
                    WHERE Id = :cvId
                    LIMIT 1
                ];
                this.content = cv.VersionData.toString();
            } catch (Exception e) {
                this.content = '<p>Error: ' + e.getMessage() + '</p>';
            }
        }
    }
}