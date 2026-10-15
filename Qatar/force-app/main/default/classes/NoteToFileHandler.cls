public class NoteToFileHandler implements Queueable, Database.AllowsCallouts {

    private List<String> contentDocIds;
    private List<String> linkedEntityIds;

    public NoteToFileHandler(List<String> contentDocIds, List<String> linkedEntityIds) {
        this.contentDocIds   = contentDocIds;
        this.linkedEntityIds = linkedEntityIds;
    }

    public void execute(QueueableContext context) {
        for (Integer i = 0; i < contentDocIds.size(); i++) {
            String contentDocumentId = contentDocIds[i];
            String linkedEntityId    = linkedEntityIds[i];

            List<ContentVersion> versions = [
                SELECT Id, Title, VersionData, FileType, CreatedById, CreatedDate
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                AND IsLatest = true
                LIMIT 1
            ];

            if (versions.isEmpty() || versions[0].FileType != 'SNOTE') {
                continue;
            }

            ContentVersion noteCV = versions[0];

            // Get Event name
            String eventName = 'Unknown Event';
            try {
                SObject linkedRecord = Database.query(
                    'SELECT Id, Subject FROM Event WHERE Id = :linkedEntityId LIMIT 1'
                );
                if (linkedRecord != null) {
                    eventName = (String) linkedRecord.get('Subject');
                }
            } catch (Exception e) {
                eventName = noteCV.Title;
            }

            // Get Created By name
            String createdByName = '';
            try {
                User u = [SELECT Name FROM User WHERE Id = :noteCV.CreatedById LIMIT 1];
                createdByName = u.Name;
            } catch (Exception e) {
                createdByName = '';
            }

            // Format date
            String noteDate = DateTime.valueOf(noteCV.CreatedDate)
                .format('MMMM dd, yyyy hh:mm a');

            PageReference pdfPage = Page.NotePDFTemplate;
            pdfPage.getParameters().put('cvId',       noteCV.Id);
            pdfPage.getParameters().put('eventName',  eventName);
            pdfPage.getParameters().put('createdBy',  createdByName);
            pdfPage.getParameters().put('noteDate',   noteDate);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('PDF Test Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            String pdfTitle = 'HE Notes - ' + eventName;

            ContentVersion pdfCV = new ContentVersion();
            pdfCV.Title                  = pdfTitle;
            pdfCV.PathOnClient           = pdfTitle + '.pdf';
            pdfCV.VersionData            = pdfBlob;
            pdfCV.FirstPublishLocationId = linkedEntityId;
            insert pdfCV;
        }
    }
}