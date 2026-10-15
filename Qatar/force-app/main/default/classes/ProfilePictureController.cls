public with sharing class ProfilePictureController {
    
    @AuraEnabled
    public static Attachment getProfilePicture(Id parentId) {
        return [
            SELECT Id, Name, LastModifiedDate, ContentType 
            FROM Attachment 
            WHERE ParentId = :parentId 
            AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/jpg','image/webp') 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static String getProfilePictureBase64(Id parentId) {
        List<Attachment> attachments = [
            SELECT Id, Body, ContentType, BodyLength
            FROM Attachment 
            WHERE ParentId = :parentId 
            AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/jpg')
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        
        if (!attachments.isEmpty()) {
            if (attachments[0].BodyLength > 2000000) {
                throw new AuraHandledException('Image too large to edit. Max size is 2MB.');
            }
            String base64 = EncodingUtil.base64Encode(attachments[0].Body);
            return 'data:' + attachments[0].ContentType + ';base64,' + base64;
        }
        return null;
    }
    
    @AuraEnabled
    public static Id saveAttachment(Id parentId, String fileName, String base64Data, String contentType) {
        // Check if image already exists — update instead of insert
        List<Attachment> existing = [
            SELECT Id FROM Attachment 
            WHERE ParentId = :parentId 
            AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/jpg')
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        Attachment attachment;

        if (!existing.isEmpty()) {
            // Update existing — no duplicate
            attachment = existing[0];
            attachment.body = EncodingUtil.base64Decode(base64Data);
            attachment.name = fileName;
            attachment.contentType = contentType;
            update attachment;
        } else {
            // First time — insert new
            attachment = new Attachment();
            attachment.parentId = parentId;
            attachment.body = EncodingUtil.base64Decode(base64Data);
            attachment.name = fileName;
            attachment.contentType = contentType;
            insert attachment;
        }

        return attachment.id;
    }

    @AuraEnabled
    public static void deleteAttachment(Id parentId) {
        List<Attachment> attachments = [
            SELECT Id FROM Attachment 
            WHERE ParentId = :parentId 
            AND ContentType IN ('image/png', 'image/jpeg', 'image/gif', 'image/jpg','image/webp')
            ORDER BY LastModifiedDate DESC
        ];
        if (!attachments.isEmpty()) {
            delete attachments;
        }
    }
}