public with sharing class PurchaseOrderFilesController {

    public class FileWrapper {
        @AuraEnabled public Id       contentDocumentId;
        @AuraEnabled public Id       contentVersionId;   // ← needed for bulk zip download
        @AuraEnabled public String   title;
        @AuraEnabled public String   fileExtension;
        @AuraEnabled public String   fileType;
        @AuraEnabled public Integer  contentSize;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public String   ownerName;
        @AuraEnabled public String   documentType;
        @AuraEnabled public String   downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getPurchaseOrderFiles(Id recordId, Boolean filterByType) {
        List<FileWrapper> results = new List<FileWrapper>();
        Set<Id> linkedDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            WITH USER_MODE
        ]) {
            linkedDocumentIds.add(cdl.ContentDocumentId);
        }
        if (linkedDocumentIds.isEmpty()) return results;
        Map<Id, String> documentTypeByDocId  = new Map<Id, String>();
        Map<Id, Id>     versionIdByDocId      = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Document_Type__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :linkedDocumentIds
              AND IsLatest = true
            WITH USER_MODE
        ]) {
            documentTypeByDocId.put(cv.ContentDocumentId, cv.Document_Type__c);
            versionIdByDocId.put(cv.ContentDocumentId, cv.Id);
        }
        Set<Id> docIdsToShow = new Set<Id>();
        for (Id docId : linkedDocumentIds) {
            String docType = documentTypeByDocId.get(docId);
            if (filterByType != true || docType == 'Purchase Order') {
                docIdsToShow.add(docId);
            }
        }
        if (docIdsToShow.isEmpty()) return results;
        for (ContentDocument doc : [
            SELECT Id, Title, FileExtension, FileType, ContentSize,
                   LastModifiedDate, Owner.Name
            FROM ContentDocument
            WHERE Id IN :docIdsToShow
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
        ]) {
            FileWrapper fw        = new FileWrapper();
            fw.contentDocumentId  = doc.Id;
            fw.contentVersionId   = versionIdByDocId.get(doc.Id);
            fw.title              = doc.Title;
            fw.fileExtension      = doc.FileExtension;
            fw.fileType           = doc.FileType;
            fw.contentSize        = doc.ContentSize;
            fw.lastModifiedDate   = doc.LastModifiedDate;
            fw.ownerName          = doc.Owner?.Name;
            fw.documentType       = documentTypeByDocId.get(doc.Id);
            fw.downloadUrl        = '/sfc/servlet.shepherd/document/download/' + doc.Id;
            results.add(fw);
        }
        return results;
    }

    // ── Uploads a new file and tags it as a Purchase Order ────────────────────
    @AuraEnabled
    public static Id uploadFile(String base64Data, String fileName, Id recordId) {
        if (String.isBlank(base64Data) || String.isBlank(fileName) || recordId == null) {
            return null;
        }

        ContentVersion cv = new ContentVersion(
            Title            = fileName,
            PathOnClient     = fileName,
            VersionData      = EncodingUtil.base64Decode(base64Data),
            Document_Type__c = 'Purchase Order'
        );
        insert cv;

        ContentVersion insertedVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            WITH USER_MODE
            LIMIT 1
        ];

        insert new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId    = recordId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        return insertedVersion.ContentDocumentId;
    }

    // ── Bulk-tags existing files as Purchase Order ─────────────────────────────
    @AuraEnabled
    public static void tagFilesAsPurchaseOrder(List<Id> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return;
        }

        List<ContentVersion> versions = [
            SELECT Id, Document_Type__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
              AND IsLatest = true
            WITH USER_MODE
        ];

        if (versions.isEmpty()) {
            return;
        }

        for (ContentVersion cv : versions) {
            cv.Document_Type__c = 'Purchase Order';
        }

        update versions;
    }

    @AuraEnabled
    public static void togglePurchaseOrder(Id contentDocumentId, Boolean isChecked) {
        if (contentDocumentId == null) return;
        List<ContentVersion> versions = [
            SELECT Id, Document_Type__c
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
              AND IsLatest = true
            WITH USER_MODE
            LIMIT 1
        ];
        if (versions.isEmpty()) return;
        versions[0].Document_Type__c = isChecked ? 'Purchase Order' : null;
        update versions[0];
    }

    @AuraEnabled
    public static void deleteFile(Id contentDocumentId) {
        List<ContentDocument> docs = [
            SELECT Id FROM ContentDocument
            WHERE Id = :contentDocumentId
            WITH USER_MODE
        ];
        if (!docs.isEmpty()) delete docs;
    }
}