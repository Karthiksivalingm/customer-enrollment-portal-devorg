/**
 * Supports the in-portal PDF fill-and-save flow.
 *
 *  - getPdfForFilling: hands the generated fillable PDF's bytes to the
 *    portalFormFiller LWC so it can render the form fields for editing.
 *  - saveFilledPdf: takes the completed PDF back from that LWC and stores
 *    it as a File on the record, then (optionally) flips the tracking
 *    field's status.
 *
 * Adjust the two SOQL filters below to match how your generated PDFs are
 * actually named/tagged - they're written to work with the existing
 * pattern in this component (Title containing the form's field API name).
 */
public with sharing class PortalFormFillerService {

    @AuraEnabled
    public static String getPdfForFilling(Id recordId, String fieldApiName) {
        try {
            if (recordId == null || String.isBlank(fieldApiName)) {
                throw new AuraHandledException('Missing recordId or field.');
            }

            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ];

            if (links.isEmpty()) {
                throw new AuraHandledException(
                    'No document found yet for this form. Ask your case worker to resend it.'
                );
            }

            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink l : links) {
                docIds.add(l.ContentDocumentId);
            }

            // Most recent PDF whose title references this form field -
            // update this filter if your generated files are tagged
            // differently (e.g. a custom field instead of Title matching).
            List<ContentVersion> versions = [
                SELECT VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
                AND FileExtension = 'pdf'
                AND Title LIKE :('%' + fieldApiName + '%')
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (versions.isEmpty()) {
                throw new AuraHandledException(
                    'No fillable PDF found for this form yet.'
                );
            }

            return EncodingUtil.base64Encode(versions[0].VersionData);

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading PDF: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveFilledPdf(
        Id recordId,
        String fieldApiName,
        String formLabel,
        String base64Pdf
    ) {
        try {
            if (recordId == null || String.isBlank(fieldApiName) || String.isBlank(base64Pdf)) {
                throw new AuraHandledException('Missing required parameters.');
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = formLabel + ' - Completed';
            cv.PathOnClient = formLabel + '_' + fieldApiName + '_completed.pdf';
            cv.VersionData = EncodingUtil.base64Decode(base64Pdf);
            insert cv;

            Id contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            ].ContentDocumentId;

            insert new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = recordId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );

            // Best-effort status update on the tracking field, matching
            // how the rest of this component updates status elsewhere.
            // Wrapped so a schema mismatch never blocks the file save.
            try {
                SObjectType targetType = recordId.getSObjectType();
                if (targetType.getDescribe().fields.getMap().containsKey(fieldApiName)) {
                    SObject record = targetType.newSObject(recordId);
                    record.put(fieldApiName, 'Completed');
                    update record;
                }
            } catch (Exception statusEx) {
                System.debug('Could not update status field: ' + statusEx.getMessage());
            }

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving completed PDF: ' + e.getMessage());
        }
    }
}