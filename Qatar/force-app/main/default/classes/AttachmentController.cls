public with sharing class AttachmentController {
    @AuraEnabled(cacheable=true)
    public static String getAttachmentUrl(Id parentId) {
        Attachment att = [
            SELECT Id 
            FROM Attachment 
            WHERE ParentId = :parentId 
                  AND ContentType IN ('image/png','image/jpeg','image/gif')
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        if (att != null) {
            return '/servlet/servlet.FileDownload?file=' + att.Id;
        }
        return null;
    }
}