/**
 * Copies certificate files uploaded through the Upload Certificate component onto the Contact
 * as classic Attachments named "[Category] Title.ext".
 *
 * The Vendor Activation Agreement template attaches "Document from Master Object > Attachments",
 * so only certificates reach the agreement. Files added directly to the Contact's Files are
 * not copied and are never attached.
 *
 * A new upload replaces the earlier certificate attachment of the same category.
 * The copy runs in a Queueable so larger files fit within the asynchronous heap limit.
 */
public without sharing class CertificateAttachmentService {

    public class Request {
        @InvocableVariable(label='Contact Id' required=true)
        public Id contactId;
        @InvocableVariable(label='Content Version Ids' required=true)
        public List<String> contentVersionIds;
        @InvocableVariable(label='Certificate Category' required=true)
        public String category;
    }

    @InvocableMethod(label='Copy certificate files to Contact attachments'
        description='Saves uploaded certificate files as Contact attachments so only certificates are added to the agreement.')
    public static void copyToAttachments(List<Request> requests) {
        List<Request> work = new List<Request>();
        for (Request r : requests) {
            if (r != null && r.contactId != null && r.contentVersionIds != null && !r.contentVersionIds.isEmpty() && String.isNotBlank(r.category)) {
                work.add(r);
            }
        }
        if (!work.isEmpty()) {
            System.enqueueJob(new CopyJob(work));
        }
    }

    /** One-time backfill: copy the latest categorised certificate files already on these Contacts. */
    public static void backfill(Set<Id> contactIds) {
        Map<String, Request> byKey = new Map<String, Request>();
        for (ContentDocumentLink l : [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId,
                       ContentDocument.LatestPublishedVersion.Certificate_Category__c
                FROM ContentDocumentLink WHERE LinkedEntityId IN :contactIds WITH SYSTEM_MODE]) {
            String category = l.ContentDocument.LatestPublishedVersion.Certificate_Category__c;
            if (String.isBlank(category)) { continue; }
            String key = l.LinkedEntityId + '|' + category;
            Request r = byKey.get(key);
            if (r == null) {
                r = new Request();
                r.contactId = l.LinkedEntityId;
                r.category = category;
                r.contentVersionIds = new List<String>();
                byKey.put(key, r);
            }
            r.contentVersionIds.add(l.ContentDocument.LatestPublishedVersionId);
        }
        copyNow(byKey.values());
    }

    public class CopyJob implements Queueable {
        private final List<Request> requests;
        public CopyJob(List<Request> requests) { this.requests = requests; }
        public void execute(QueueableContext context) { copyNow(requests); }
    }

    @TestVisible
    private static String prefix(String category) { return '[' + category + '] '; }

    private static void copyNow(List<Request> requests) {
        Set<Id> versionIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<String> keys = new Set<String>();
        for (Request r : requests) {
            contactIds.add(r.contactId);
            keys.add(r.contactId + '|' + r.category);
            for (String v : r.contentVersionIds) { versionIds.add((Id) v); }
        }
        Map<Id, ContentVersion> versions = new Map<Id, ContentVersion>([
            SELECT Id, Title, FileExtension, VersionData FROM ContentVersion WHERE Id IN :versionIds WITH SYSTEM_MODE]);

        // replace the earlier certificate attachment of the same category
        List<Attachment> toDelete = new List<Attachment>();
        for (Attachment a : [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId IN :contactIds WITH SYSTEM_MODE]) {
            for (Request r : requests) {
                if (a.ParentId == r.contactId && a.Name.startsWith(prefix(r.category))) { toDelete.add(a); break; }
            }
        }

        List<Attachment> toInsert = new List<Attachment>();
        for (Request r : requests) {
            for (String v : r.contentVersionIds) {
                ContentVersion cv = versions.get((Id) v);
                if (cv == null) { continue; }
                String ext = String.isBlank(cv.FileExtension) ? '' : '.' + cv.FileExtension;
                toInsert.add(new Attachment(ParentId = r.contactId, Name = (prefix(r.category) + cv.Title + ext).left(255), Body = cv.VersionData));
            }
        }
        if (!toDelete.isEmpty()) { delete as system toDelete; }
        if (!toInsert.isEmpty()) { insert as system toInsert; }
    }
}
