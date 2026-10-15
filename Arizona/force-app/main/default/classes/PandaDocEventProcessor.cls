// NEW: does the webhook's work (PDF download, file save, Contact status) as a Salesforce user.
// Started by PandaDocWebhookTrigger. The site guest user that receives the webhook cannot access Contacts.
public without sharing class PandaDocEventProcessor implements Queueable, Database.AllowsCallouts {

    // PandaDoc status -> Contact status value. Written only if the value exists in the picklist.
    public static final Map<String, String> SF_STATUS_BY_PANDADOC = new Map<String, String>{
        'document.uploaded'         => 'Uploaded',
        'document.draft'            => 'Draft',
        'document.waiting_approval' => 'Waiting Approval',
        'document.approved'         => 'Approved',
        'document.rejected'         => 'Rejected',
        'document.error'            => 'Error',
        'document.sent'             => 'Sent',
        'document.viewed'           => 'Viewed',
        'document.external_review'  => 'External Review',
        'document.waiting_pay'      => 'Waiting Payment',
        'document.paid'             => 'Paid',
        'document.completed'        => 'Completed',
        'document.declined'         => 'Declined',
        'document.voided'           => 'Voided',
        'document.expired'           => 'expired'
    };

    // Status stages (final = 3, out for signature = 2, preparing = 1).
    // A status never replaces one from a later stage.
    private static final Set<String> FINAL_STATUSES = new Set<String>{
        'document.completed', 'document.declined', 'document.voided'
    };
    private static final Set<String> SIGNING_STATUSES = new Set<String>{
        'document.sent', 'document.viewed', 'document.external_review',
        'document.waiting_pay', 'document.paid'
    };

    public static final String PD_COMPLETED    = 'document.completed';
    public static final String EVENT_PDF_READY = 'document_completed_pdf_ready';

    // Documents per run; the rest go to a chained job (keeps PDF downloads within callout limits)
    private static final Integer CHUNK_SIZE = 5;

    // Debug switch. Set to false to turn debug lines off.
    private static final Boolean DEBUG_ON = true;

    private class ProcessorException extends Exception {}

    public class Job {
        public String  docId;
        public String  pandaDocStatus;
        public String  sfStatus;
        public Id      contactId;
        public String  formApiName;
        public String  formLabel;
        public String  title;
        public String  statusField;      // Contact field to update, or null
        public Blob    pdf;              // only for completed documents
        public Boolean savedFile     = false;
        public Boolean changedStatus = false;

        public String key() {
            return docId + '|' + pandaDocStatus;
        }
    }

    private final List<Job> jobs;

    public PandaDocEventProcessor(List<Job> jobs) {
        this.jobs = jobs;
    }

    public void execute(QueueableContext ctx) {
        dbg('execute: ' + jobs.size() + ' job(s), running user=' + UserInfo.getUserName()
            + ' type=' + UserInfo.getUserType());

        List<Job> batch = new List<Job>();
        List<Job> rest  = new List<Job>();
        for (Job j : jobs) {
            if (batch.size() < CHUNK_SIZE) {
                batch.add(j);
            } else {
                rest.add(j);
            }
        }

        String summary = process(batch);
        PandaDocApi.logInfo('processor: ' + summary);

        if (!rest.isEmpty()) {
            System.enqueueJob(new PandaDocEventProcessor(rest));
        }
    }

    /*
     * Test helper. Run in Execute Anonymous to process one document right away:
     *   System.debug(PandaDocEventProcessor.syncDocument('DOCUMENT_ID'));
     */
    public static String syncDocument(String docId) {
        Job j = buildJob(PandaDocService.getDocumentDetails(docId), 'manual sync');
        if (j == null) {
            return 'Not processed: status not mapped, or no contact or form in metadata. See the debug log.';
        }
        return process(new List<Job>{ j });
    }

    /* Downloads PDFs first (callouts), then saves files and statuses (DML). Returns a summary. */
    public static String process(List<Job> jobs) {
        List<Job> ready = new List<Job>();
        Set<String> seen = new Set<String>();
        Integer failed = 0;

        // Phase 1: callouts only
        for (Job j : jobs) {
            if (seen.contains(j.key())) {
                continue;
            }
            seen.add(j.key());
            try {
                preparePdf(j);
                ready.add(j);
            } catch (Exception e) {
                failed++;
                PandaDocApi.logError('processor: download failed for ' + j.docId + ' - ' + e.getMessage());
                dbg('download FAILED for ' + j.docId + ' - ' + e.getTypeName() + ': ' + e.getMessage());
            }
        }

        // Phase 2: DML only
        Integer filesSaved = 0;
        Integer statusesSet = 0;
        for (Job j : ready) {
            try {
                saveJob(j);
                if (j.savedFile) {
                    filesSaved++;
                }
                if (j.changedStatus) {
                    statusesSet++;
                }
            } catch (Exception e) {
                failed++;
                PandaDocApi.logError('processor: save failed for ' + j.docId + ' - ' + e.getMessage());
                dbg('save FAILED for ' + j.docId + ' - ' + e.getTypeName() + ': ' + e.getMessage());
            }
        }

        String summary = 'files=' + filesSaved + ' statuses=' + statusesSet + ' failed=' + failed;
        dbg('done ' + summary);
        return summary;
    }

    /* Builds a job from the webhook payload or document details. Null = nothing to do. */
    public static Job buildJob(Map<String, Object> doc, String eventName) {
        Map<String, Object> meta = (doc.get('metadata') instanceof Map<String, Object>)
            ? (Map<String, Object>) doc.get('metadata') : new Map<String, Object>();
        dbg('event=' + eventName + ' metadata=' + JSON.serialize(meta));
        return newJob(
            PandaDocApi.str(doc.get('id')),
            PandaDocApi.str(doc.get('status')),
            PandaDocApi.str(meta.get('salesforce_contact_id')),
            PandaDocApi.str(meta.get('form_api_name')),
            PandaDocApi.str(meta.get('form_label'))
        );
    }

    /* Builds a job from a published PandaDoc_Webhook__e event. */
    public static Job fromEvent(PandaDoc_Webhook__e e) {
        return newJob(e.Document_Id__c, e.PandaDoc_Status__c, e.Contact_Id__c, e.Form_Api_Name__c, e.Form_Label__c);
    }

    private static Job newJob(String docId, String rawStatus, String contactText, String formApiName, String formLabel) {
        String status = lower(rawStatus);
        dbg('doc=' + docId + ' status=' + status + ' contact=' + contactText + ' form=' + formApiName);

        if (String.isBlank(docId)) {
            PandaDocApi.logInfo('processor: event has no document id, skipped');
            return null;
        }

        String sfStatus = SF_STATUS_BY_PANDADOC.get(status);
        if (sfStatus == null) {
            PandaDocApi.logInfo('processor: ' + docId + ' status "' + status + '" is not mapped to a Salesforce status, skipped');
            return null;
        }

        Id contactId = toContactId(contactText);
        if (contactId == null) {
            PandaDocApi.logInfo('processor: ' + docId + ' has no valid salesforce_contact_id metadata, skipped');
            return null;
        }

        String label = String.isNotBlank(formLabel) ? formLabel : formApiName;
        if (String.isBlank(label)) {
            PandaDocApi.logInfo('processor: ' + docId + ' has no form_label or form_api_name metadata, skipped');
            return null;
        }

        Job j = new Job();
        j.docId          = docId;
        j.pandaDocStatus = status;
        j.sfStatus       = sfStatus;
        j.contactId      = contactId;
        j.formApiName    = formApiName;
        j.formLabel      = formLabel;
        j.title          = PandaDocService.finalTitle(label);   // same title the portal looks up
        j.statusField    = resolveStatusField(formApiName, formLabel);
        return j;
    }

    /* Downloads the PDF for a completed document, unless it is already saved. */
    private static void preparePdf(Job j) {
        if (!isCompleted(j)) {
            return;
        }
        if (statusAlreadySet(j) || alreadySaved(j.contactId, j.title)) {
            dbg('"' + j.title + '" already saved, no download needed');
            return;
        }
        j.pdf = PandaDocApi.downloadPdf(j.docId);
        if (j.pdf == null || j.pdf.size() == 0) {
            throw new ProcessorException('PandaDoc returned no PDF for ' + j.docId);
        }
        dbg('downloaded PDF for ' + j.docId + ', ' + j.pdf.size() + ' bytes');
    }

    /* DML only. Saves the file (completed only), then sets the Contact status. */
    private static void saveJob(Job j) {
        if (j.pdf != null) {
            Savepoint sp = Database.setSavepoint();
            try {
                PandaDocService.saveFinalPdf(j.contactId, j.title, j.pdf);
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
            j.savedFile = true;
            PandaDocApi.logInfo('processor: saved "' + j.title + '" to contact ' + j.contactId);
        }
        j.changedStatus = setContactStatus(j);
    }

    /* Writes the mapped value to the Contact status field. Returns true when the field changed. */
    private static Boolean setContactStatus(Job j) {
        if (String.isBlank(j.statusField)) {
            PandaDocApi.logInfo('processor: no Contact status field found for this form, status not set');
            return false;
        }
        Schema.DescribeFieldResult f = Schema.SObjectType.Contact.fields.getMap()
            .get(j.statusField.toLowerCase()).getDescribe();
        String field = f.getName();
        String value = picklistValue(f, j.sfStatus);
        if (value == null) {
            PandaDocApi.logInfo('processor: "' + j.sfStatus + '" is not a picklist value of ' + field + ', status not set');
            return false;
        }
        String current = currentValue(j.contactId, field);
        dbg(field + ' current=' + current + ' new=' + value);

        if (value.equals(current)) {
            PandaDocApi.logInfo('processor: ' + field + ' is already ' + current + ', not changed');
            return false;
        }

        // Never go back to an earlier stage (for example a late "viewed" after "completed")
        if (stageOf(j.pandaDocStatus) < stageOfValue(current)) {
            PandaDocApi.logInfo('processor: ' + field + ' is ' + current + ', not changed back to ' + value);
            return false;
        }

        Contact con = new Contact(Id = j.contactId);
        con.put(field, value);
        update con;
        PandaDocApi.logInfo('processor: ' + field + ' = ' + value);
        return true;
    }

    /* True when the Contact status field already has this job's value. */
    private static Boolean statusAlreadySet(Job j) {
        if (String.isBlank(j.statusField)) {
            return false;
        }
        Schema.DescribeFieldResult f = Schema.SObjectType.Contact.fields.getMap()
            .get(j.statusField.toLowerCase()).getDescribe();
        String value = picklistValue(f, j.sfStatus);
        return value != null && value.equals(currentValue(j.contactId, f.getName()));
    }

    private static Boolean alreadySaved(Id contactId, String title) {
        List<ContentDocumentLink> existing = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
              AND ContentDocument.Title = :title
            LIMIT 1
        ];
        return !existing.isEmpty();
    }

    /*
     * Finds the Contact field for this form. Tries the exact API name first,
     * then matches on letters and digits so the label and API name both work.
     */
    private static String resolveStatusField(String formApiName, String formLabel) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Contact.fields.getMap();

        if (String.isNotBlank(formApiName) && fields.containsKey(formApiName.toLowerCase())) {
            return fields.get(formApiName.toLowerCase()).getDescribe().getName();
        }

        List<String> keys = new List<String>{ normalizeKey(formApiName), normalizeKey(formLabel) };
        for (String key : keys) {
            if (String.isBlank(key)) {
                continue;
            }
            for (String f : fields.keySet()) {
                if (f.endsWith('__c') && normalizeKey(f) == key) {
                    return fields.get(f).getDescribe().getName();
                }
            }
        }
        return null;
    }

    /* Lowercase letters and digits only. Drops a trailing __c. */
    private static String normalizeKey(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String v = value.trim();
        if (v.endsWithIgnoreCase('__c')) {
            v = v.left(v.length() - 3);
        }
        return v.replaceAll('[^A-Za-z0-9]', '').toLowerCase();
    }

    /* Returns the value as a Contact Id, or null. */
    private static Id toContactId(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        try {
            Id candidate = Id.valueOf(raw.trim());
            return candidate.getSObjectType() == Contact.SObjectType ? candidate : null;
        } catch (Exception e) {
            return null;
        }
    }

    /* Current value of a Contact field, or null. */
    private static String currentValue(Id contactId, String field) {
        List<SObject> rows = Database.query(
            'SELECT Id, ' + field + ' FROM Contact WHERE Id = :contactId LIMIT 1'
        );
        if (rows.isEmpty() || rows[0].get(field) == null) {
            return null;
        }
        return String.valueOf(rows[0].get(field));
    }

    /* Returns the picklist's own spelling of the value (case-insensitive), or null if the picklist doesn't have it. */
    private static String picklistValue(Schema.DescribeFieldResult f, String wanted) {
        Schema.DisplayType t = f.getType();
        if (t != Schema.DisplayType.PICKLIST && t != Schema.DisplayType.MULTIPICKLIST) {
            return wanted;
        }
        for (Schema.PicklistEntry pe : f.getPicklistValues()) {
            if (pe.isActive() && pe.getValue().equalsIgnoreCase(wanted)) {
                return pe.getValue();
            }
        }
        return null;
    }

    /* Stage of a PandaDoc status: final = 3, out for signature = 2, preparing = 1. */
    private static Integer stageOf(String pandaDocStatus) {
        if (FINAL_STATUSES.contains(pandaDocStatus)) {
            return 3;
        }
        if (SIGNING_STATUSES.contains(pandaDocStatus)) {
            return 2;
        }
        return 1;
    }

    /* Stage of the value currently on the Contact. Blank or unknown = 0. */
    private static Integer stageOfValue(String sfValue) {
        if (String.isBlank(sfValue)) {
            return 0;
        }
        for (String pd : SF_STATUS_BY_PANDADOC.keySet()) {
            if (SF_STATUS_BY_PANDADOC.get(pd).equalsIgnoreCase(sfValue)) {
                return stageOf(pd);
            }
        }
        return 0;
    }

    private static String lower(String s) {
        return (s == null) ? '' : s.trim().toLowerCase();
    }

    private static Boolean isCompleted(Job j) {
        return PD_COMPLETED.equals(j.pandaDocStatus);
    }

    private static void dbg(String msg) {
        if (DEBUG_ON) {
            System.debug(LoggingLevel.ERROR, 'PDS-DEBUG processor ' + msg);
        }
    }
}