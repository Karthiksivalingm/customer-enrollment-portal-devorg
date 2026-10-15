/**
 * PerContactDocumentService
 * -----------------------------------------------------------------------
 * Gives each contact their OWN Google Doc copy of a form, instead of
 * every contact editing the same shared master template.
 *
 * NO CUSTOM OBJECT REQUIRED. The mapping of "this contact's copy of this
 * form is this Google Doc Id" is remembered as a small, hidden reference
 * file in standard Salesforce Files - a ContentVersion/ContentDocumentLink
 * on the Contact, titled "<form label> - GDoc Link", whose entire content
 * is just the Google Doc Id as plain text. This uses the exact same
 * ContentVersion/ContentDocumentLink mechanism the rest of this feature
 * already relies on, so no new object, no new field-level-security grants,
 * nothing else to set up in the org - portal users already have whatever
 * access they need for this to work, because it's the same access they
 * already have for every other file this component creates.
 *
 * FormWorkflowService.filesForLabel() knows to skip files with the
 * GDOC_LINK_SUFFIX below, so this reference file never shows up in the
 * "uploaded files" list a contact or owner sees - it's purely internal
 * bookkeeping.
 *
 * Depends on GoogleDriveService, which depends on the Google_Drive_API
 * Named Credential (see PerContactCopy_Setup_Guide.md). If that isn't set
 * up yet, every method here throws - callers catch that and fall back
 * to the previous shared-document behaviour.
 */
public with sharing class PerContactDocumentService {

    /** Exposed so FormWorkflowService can filter this file out of the
     *  "uploaded files" list it shows on each form row. */
    public static final String GDOC_LINK_SUFFIX = ' - GDoc Link';

    public class CopyInfo {
        public String googleDocId;
        public String editUrl;
    }

    /**
     * Returns the existing per-contact copy for (contactId, formLabel) if
     * one was already created, otherwise makes a new one: copies
     * masterGdocId in Google Drive, shares the copy as "anyone - editor",
     * and remembers the mapping as a hidden reference file on the Contact.
     */
    public static CopyInfo getOrCreateCopy(
        Id contactId, String formLabel, String masterGdocId, String recipientName
    ) {
        ContentVersion existing = findGdocLinkVersion(contactId, formLabel);
        if (existing != null && existing.VersionData != null) {
            String existingId = existing.VersionData.toString();
            if (String.isNotBlank(existingId)) {
                return buildCopyInfo(existingId);
            }
        }

        String newTitle = formLabel + ' - ' + recipientName;
        String newFileId = GoogleDriveService.copyFile(masterGdocId, newTitle);
        GoogleDriveService.shareAsEditor(newFileId);

        saveGdocLinkFile(contactId, formLabel, newFileId);

        return buildCopyInfo(newFileId);
    }

    /** Looks up an existing copy without creating one. Returns null if none exists yet. */
    public static CopyInfo findExistingCopy(Id contactId, String formLabel) {
        ContentVersion existing = findGdocLinkVersion(contactId, formLabel);
        if (existing == null || existing.VersionData == null) {
            return null;
        }
        String googleDocId = existing.VersionData.toString();
        return String.isBlank(googleDocId) ? null : buildCopyInfo(googleDocId);
    }

    /**
     * Creates (or overwrites, if one already exists) the hidden reference
     * file that records "<formLabel> on this contact -> this Google Doc Id".
     */
    private static void saveGdocLinkFile(Id contactId, String formLabel, String googleDocId) {
        String title = linkTitle(formLabel);

        ContentVersion cv = new ContentVersion();
        cv.Title          = title;
        cv.PathOnClient   = title + '.txt';
        cv.VersionData    = Blob.valueOf(googleDocId);
        cv.IsMajorVersion = true;

        Id existingDocId = findGdocLinkDocumentId(contactId, formLabel);
        if (existingDocId != null) {
            cv.ContentDocumentId = existingDocId;
        }
        insert cv;

        if (existingDocId == null) {
            Id contentDocId = [
                SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
            ].ContentDocumentId;
            insert new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId    = contactId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
        }
    }

    private static String linkTitle(String formLabel) {
        return formLabel + GDOC_LINK_SUFFIX;
    }

    /** Finds the ContentDocumentId of this contact's reference file for this form, if any. */
    private static Id findGdocLinkDocumentId(Id contactId, String formLabel) {
        String title = linkTitle(formLabel);
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
            ORDER BY ContentDocument.CreatedDate DESC
        ]) {
            if (title.equalsIgnoreCase(link.ContentDocument.Title)) {
                return link.ContentDocumentId;
            }
        }
        return null;
    }

    /** Finds the latest ContentVersion (with its bytes) of this contact's reference file. */
    private static ContentVersion findGdocLinkVersion(Id contactId, String formLabel) {
        Id docId = findGdocLinkDocumentId(contactId, formLabel);
        if (docId == null) {
            return null;
        }
        List<ContentVersion> versions = [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = true
            LIMIT 1
        ];
        return versions.isEmpty() ? null : versions[0];
    }

    private static CopyInfo buildCopyInfo(String googleDocId) {
        CopyInfo info = new CopyInfo();
        info.googleDocId = googleDocId;
        info.editUrl     = 'https://docs.google.com/document/d/' + googleDocId + '/edit';
        return info;
    }
}