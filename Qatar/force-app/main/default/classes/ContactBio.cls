public class ContactBio {
    public Contact Con { get; set; }
    public Attachment Attach { get; set; }
    public Id ConId { get; set; }
    public List<String> ParagraphChunks { get; set; }

    public ContactBio() {
        ConId = ApexPages.currentPage().getParameters().get('id');
        ParagraphChunks = new List<String>();

        if (ConId != null) {
            List<Contact> matches = [
                SELECT Id, Name, Title, Birthdate, Phone, Instagram_Handle__c,
                       Professional_Personal_Backgrounds__c, Email, OtherPhone,
                       Email_Office__c, CreatedDate, Salutation, Company__c
                FROM Contact
                WHERE Id = :ConId
                LIMIT 1
            ];
            Con = matches.isEmpty() ? null : matches[0];

            if (Con != null && !String.isBlank(Con.Name)) {
                String safeName = Con.Name.replaceAll('[^a-zA-Z0-9 ]', '');
                ApexPages.currentPage().getHeaders().put(
                    'Content-Disposition', 
                    'inline; filename=Bio - ' + safeName + '.pdf'
                );
            }

            List<Attachment> attachments = [
                SELECT Id, Name, LastModifiedDate, ContentType 
                FROM Attachment 
                WHERE ParentId = :ConId 
                AND ContentType IN ('image/png', 'image/jpeg', 'image/gif','image/jpg') 
                ORDER BY LastModifiedDate DESC 
                LIMIT 1
            ];
            if (!attachments.isEmpty()) {
                Attach = attachments[0];
            }

            if (Con != null && !String.isBlank(Con.Professional_Personal_Backgrounds__c)) {
                String[] paragraphs = Con.Professional_Personal_Backgrounds__c.split('\n');
                String currentChunk = '';
                Integer chunkLimit = 2000;

                for (String para : paragraphs) {
                    if ((currentChunk.length() + para.length()) > chunkLimit) {
                        ParagraphChunks.add(currentChunk);
                        currentChunk = para + '\n';
                    } else {
                        currentChunk += para + '\n';
                    }
                }

                if (!String.isBlank(currentChunk)) {
                    ParagraphChunks.add(currentChunk);
                }
            }
        }
    }

    public Boolean getIsBiographyEmpty() {
        return Con == null || String.isBlank(Con.Professional_Personal_Backgrounds__c);
    }

    public Boolean getIsBioEmpty() {
        return getIsBiographyEmpty();
    }

    public String getPageRenderAs() {
        if (Con == null || String.isBlank(Con.Professional_Personal_Backgrounds__c)) {
            return ''; // renders as HTML → shows error UI
        }
        return 'pdf'; // renders as PDF
    }
}