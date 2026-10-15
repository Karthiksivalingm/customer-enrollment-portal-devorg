public with sharing class FileController {
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getFiles(Id recordId) {
        List<FileWrapper> results = new List<FileWrapper>();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileExtension,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        for (ContentDocumentLink link : links) {
            String ext = link.ContentDocument.FileExtension != null 
                ? link.ContentDocument.FileExtension.toLowerCase() 
                : '';
            if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
                results.add(new FileWrapper(
                    link.ContentDocument.Title,
                    '/sfc/servlet.shepherd/version/download/' + link.ContentDocument.LatestPublishedVersionId
                ));
            }
        }
        return results;
    }

    public class FileWrapper {
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String url {get;set;}

        public FileWrapper(String t, String u) {
            title = t;
            url = u;
        }
    }
}