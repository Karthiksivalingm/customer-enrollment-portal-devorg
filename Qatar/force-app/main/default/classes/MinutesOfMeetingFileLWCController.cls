/**
 * Handles uploading and retrieving "Minutes of Meeting" files on Event records.
 * Agenda files continue to use the standard Files related list untouched —
 * this class only ever tags/reads files with Document_Category__c = 'Minutes of Meeting'.
 */
public with sharing class MinutesOfMeetingFileLWCController {

    private static final String CATEGORY = 'Minutes of Meeting';

    /**
     * Called right after lightning-file-upload finishes uploading.
     * Stamps the newly created ContentVersion as a Minutes of Meeting file.
     * (Kept for compatibility — not used by the current direct-upload flow below,
     * but harmless to leave in if anything else still calls it.)
     */
    @AuraEnabled
    public static void tagAsMinutesOfMeeting(String contentDocumentId) {
        List<ContentVersion> versions = [
            SELECT Id, Document_Category__c
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            WITH USER_MODE
            LIMIT 1
        ];

        if (versions.isEmpty()) {
            throw new AuraHandledException('Could not find uploaded file to tag.');
        }

        ContentVersion cv = versions[0];
        cv.Document_Category__c = CATEGORY;

        try {
            update cv;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to save file category: ' + e.getMessage());
        }
    }

    /**
     * Uploads a file directly (base64) and tags it as Minutes of Meeting in one step.
     * Intended for typical meeting-minutes documents; not chunked, so very large
     * files (roughly beyond 4-5MB) should use a different upload path.
     */
    @AuraEnabled
public static Id uploadMinutesOfMeetingFile(Id recordId, String fileName, String base64Data) {
    ContentVersion cv = new ContentVersion();
    cv.Title = fileName;
    cv.PathOnClient = fileName;
    cv.VersionData = EncodingUtil.base64Decode(base64Data);
    cv.Document_Category__c = 'Minutes of Meeting';
    cv.FirstPublishLocationId = recordId;

    try {
        insert cv;
    } catch (DmlException e) {
        throw new AuraHandledException('Unable to upload file: ' + e.getMessage());
    }

    return [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
        WITH USER_MODE
    ].ContentDocumentId;
}

    /**
     * Returns only the Minutes of Meeting files linked to the given Event.
     */
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getMinutesOfMeetingFiles(Id recordId) {
        // ContentDocumentLink can't be used as a semi-join subquery, so this
        // has to be its own query rather than nested inside the next one.
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            WITH USER_MODE
        ]) {
            contentDocIds.add(cdl.ContentDocumentId);
        }

        if (contentDocIds.isEmpty()) {
            return new List<ContentVersion>();
        }

        return [
            SELECT Id, Title, FileExtension, ContentDocumentId, ContentSize, CreatedDate, CreatedBy.Name
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = true
            AND Document_Category__c = :CATEGORY
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }
}