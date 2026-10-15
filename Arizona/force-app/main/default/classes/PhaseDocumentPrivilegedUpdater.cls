/**
 * PhaseDocumentPrivilegedUpdater
 *
 * A separate, narrowly-scoped `without sharing` class whose only job is
 * flipping one of the Phase Document Tracker's status fields on a
 * Contact to 'Pending'. It exists as its own TOP-LEVEL class (rather
 * than an inner class of PhaseDocumentTrackerController) because Apex
 * does not allow `static` methods on inner/nested classes - only on
 * top-level ones. Trying to nest this as an inner class produces the
 * compile error: "static can only be used on methods of a top level type".
 *
 * WHY `without sharing`: Experience Cloud portal users are typically
 * granted only READ sharing access to their own Contact record, not
 * Edit. PhaseDocumentTrackerController.markDocumentPending() needs this
 * one field-flip to succeed regardless, so the DML here intentionally
 * bypasses record-level sharing.
 *
 * SECURITY: this class is NOT itself an entry point (no @AuraEnabled
 * methods) - it can only be reached through
 * PhaseDocumentTrackerController.markDocumentPending(), which already:
 *   1. Validates fieldApiName against a fixed allow-list of known
 *      status fields, and
 *   2. Confirms contactId matches the CURRENT LOGGED-IN USER'S OWN
 *      Contact (validateContactOwnership()).
 * Do not call setFieldToPending() from anywhere else without
 * re-implementing those same two checks first - this class trusts its
 * caller completely, by design, since it has no sharing/FLS enforcement
 * of its own.
 */
public without sharing class PhaseDocumentPrivilegedUpdater {

    public static void setFieldToPending(String contactId, String fieldApiName) {
        Contact con = new Contact(Id = contactId);
        con.put(fieldApiName, 'Pending');
        update con;
    }
    /**
 * Deletes a ContentDocument, bypassing sharing - needed because portal
 * users get INSUFFICIENT_ACCESS_OR_READONLY trying to delete a file
 * even when its ContentDocumentLink.Visibility is 'AllUsers' (that
 * setting grants read access, not delete rights). Called only after
 * PhaseDocumentTrackerController.deleteUploadedDocument() has already
 * confirmed the file is genuinely linked to the caller's own Contact.
 */
public static void deleteContentDocumentPrivileged(Id contentDocumentId) {
    delete new ContentDocument(Id = contentDocumentId);
}
}