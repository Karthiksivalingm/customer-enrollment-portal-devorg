public without sharing class PandaDocService {

    /*
     * While testing with a SANDBOX key, PandaDoc only sends to addresses on the
     * same domain as the sandbox login. Set it to that domain (for example
     * 'unitedtechno.com'). Leave it blank in production.
     */
    private static final String SANDBOX_EMAIL_DOMAIN = 'unitedtechno.com';

    private static final String DATE_TOKEN      = '__TODAY__';
    private static final String FULL_NAME_TOKEN = '__FULLNAME__';

    /*
     * Recipient role used when the template does not return one.
     * Must match the role name shown in the PandaDoc template editor.
     */
    private static final String DEFAULT_RECIPIENT_ROLE = 'Member';

    // NEW: debug switch. Set to false to turn debug lines off.
    private static final Boolean DEBUG_ON     = true;
    private static final String  DEBUG_PREFIX = 'PDS-DEBUG';
    /*
     * Template lookup, built once per transaction from the PandaDoc_Template__mdt
     * records. Each record matches a form by any of its names: the Contact field
     * API name, the template name, or the PandaDoc template name. Names are
     * normalized, so spacing, dashes and "__c" do not matter.
     * Add or change templates in Setup, with no code change.
     */
    private static Map<String, String> templateByKey;

    private static Map<String, String> templateMap() {
        if (templateByKey == null) {
            templateByKey = new Map<String, String>();
            for (PandaDoc_Template__mdt t : [
                SELECT Field_API_Name__c, Template_Name__c, Template_Id__c
                FROM PandaDoc_Template__mdt
                WHERE Is_Active__c = true
                  AND Template_Id__c != null
            ]) {
                String templateId = t.Template_Id__c.trim();
                addTemplateKey(templateByKey, t.Field_API_Name__c, templateId);
                addTemplateKey(templateByKey, t.Template_Name__c, templateId);
              
            }
            dbg('templateMap: loaded ' + templateByKey.size() + ' lookup key(s) from custom metadata');
        }
        return templateByKey;
    }

    /* Adds one normalized name as a key. The first record to claim a key keeps it. */
    private static void addTemplateKey(Map<String, String> target, String name, String templateId) {
        String key = normalizeKey(name);
        if (String.isNotBlank(key) && !target.containsKey(key)) {
            target.put(key, templateId);
        }
    }
    /* =====================================================================
     * SHARED TITLE FORMAT
     * The webhook saves the completed PDF with this title, and the portal
     * looks it up with the same function, so both always agree.
     * ===================================================================== */

    public static String finalTitle(String label) {
        return label + ' - Final';
    }

    /* =====================================================================
     * 1. CREATE the document from the template. Returns the PandaDoc document ID.
     * ===================================================================== */
    @AuraEnabled
    public static String createForm(Id contactId, String formApiName, String formLabel, Id opportunityId) {
        PandaDocApi.logInfo('createForm: contact=' + contactId + ' form=' + formApiName + ' label=' + formLabel);
        dbg('createForm START contact=' + contactId + ' formApiName="' + formApiName
            + '" formLabel="' + formLabel + '" opp=' + opportunityId);
        dbgUser('createForm');
        PhaseDocumentTrackerController.validateContactOwnership(String.valueOf(contactId));

        String templateId = resolveTemplateId(formApiName, formLabel);
        dbg('createForm: resolved template=' + templateId);
        if (String.isBlank(templateId)) {
            String shown = String.isNotBlank(formLabel) ? formLabel : formApiName;
            PandaDocApi.logError('createForm: no template configured for "' + shown + '"');
            throw new AuraHandledException('No PandaDoc template is configured for: ' + shown);
        }

        // Template details decide the tokens and the recipient role
        Map<String, Object> details = PandaDocApi.getTemplateDetails(templateId);
        List<String> tokenNames = templateTokenNames(details);
        String role = templateRecipientRole(details);
        if (String.isBlank(role)) {
            role = DEFAULT_RECIPIENT_ROLE;
            PandaDocApi.logInfo('createForm: template returned no recipient role, using ' + role);
        }
        dbg('createForm: role=' + role + ' tokens=' + tokenNames);

        // Work out which Contact field feeds each token
        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Map<String, String> tokenSource = new Map<String, String>();
        Set<String> fieldsToRead = new Set<String>{ 'FirstName', 'LastName', 'Email' };
        for (String tokenName : tokenNames) {
            String source = resolveTokenSource(tokenName, contactFields);
            tokenSource.put(tokenName, source);
            if (source != null && source != DATE_TOKEN && source != FULL_NAME_TOKEN) {
                fieldsToRead.add(source);
            }
        }

        Map<String, String> contactValues = readContactValues(contactId, fieldsToRead);
        String firstName = contactValues.get('firstname');
        String lastName  = contactValues.get('lastname');
        String email     = contactValues.get('email');

        if (String.isBlank(email)) {
            PandaDocApi.logError('createForm: contact ' + contactId + ' has no email');
            throw new AuraHandledException('This contact has no email address. Add one before sending the form.');
        }

        // Check the recipient before creating anything, so no draft is left behind
        checkRecipientAllowed(email);

        List<Object> tokens = new List<Object>();
        for (String tokenName : tokenNames) {
            String value = tokenValue(tokenName, tokenSource.get(tokenName), contactValues);
            PandaDocApi.logInfo('token ' + tokenName + ' -> ' + (String.isBlank(value) ? '(blank)' : 'set'));
            tokens.add(new Map<String, Object>{ 'name' => tokenName, 'value' => value });
        }

        String docName = String.isNotBlank(formLabel) ? formLabel : formApiName;

        Map<String, Object> payload = new Map<String, Object>{
            'name'          => docName + ' - ' + joinParts(new List<String>{ firstName, lastName }, ' '),
            'template_uuid' => templateId,
            'recipients'    => new List<Object>{
                new Map<String, Object>{
                    'email'      => email,
                    'first_name' => firstName == null ? '' : firstName,
                    'last_name'  => lastName == null ? '' : lastName,
                    'role'       => role
                }
            },
            'tokens'        => tokens,
            // Metadata comes back with the document, so the webhook can find the contact later
            'metadata'      => new Map<String, Object>{
                'salesforce_contact_id' => String.valueOf(contactId),
                'form_api_name'         => formApiName == null ? '' : formApiName,
                'form_label'            => formLabel == null ? '' : formLabel
            }
        };
        dbg('createForm: metadata sent=' + JSON.serialize(payload.get('metadata')));

        String res = PandaDocApi.send('POST', '/documents', JSON.serialize(payload));
        String docId = PandaDocApi.str(((Map<String, Object>) JSON.deserializeUntyped(res)).get('id'));
        PandaDocApi.logInfo('createForm: document id=' + docId);
        dbg('createForm END docId=' + docId);
        return docId;
    }

    /* =====================================================================
     * 2. STATUS - document.uploaded while PandaDoc prepares it, document.draft when ready
     * ===================================================================== */
    @AuraEnabled
    public static String getStatus(String docId) {
        String status = PandaDocApi.str(PandaDocApi.getDocument(docId).get('status'));
        PandaDocApi.logInfo('getStatus: doc=' + docId + ' status=' + status);
        dbg('getStatus: doc=' + docId + ' status="' + status + '"');
        return status;
    }

    /* =====================================================================
     * 3. LINK OPPORTUNITY, SEND, RETURN LINK, SET CONTACT STATUS = Sent
     *
     * sendEmail = true  (record page): PandaDoc emails the contact.
     * sendEmail = false (community):   silent send, returns the signing link.
     * ===================================================================== */
    @AuraEnabled
    public static String prepareForSigning(String docId, Id contactId, Id opportunityId,
                                           Boolean sendEmail, String formApiName) {
        PandaDocApi.logInfo('prepareForSigning: doc=' + docId + ' sendEmail=' + sendEmail + ' form=' + formApiName);
        dbg('prepareForSigning START doc=' + docId + ' contact=' + contactId + ' opp=' + opportunityId
            + ' sendEmail=' + sendEmail + ' formApiName="' + formApiName + '"');
        dbgUser('prepareForSigning');
        PhaseDocumentTrackerController.validateContactOwnership(String.valueOf(contactId));
        dbg('prepareForSigning: ownership check passed');

        Contact c = [SELECT Id, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        dbg('prepareForSigning: contact email=' + c.Email);
        if (String.isBlank(c.Email)) {
            PandaDocApi.logError('prepareForSigning: contact has no email');
            throw new AuraHandledException('This contact has no email address.');
        }

        Map<String, Object> doc = PandaDocApi.getDocument(docId);
        String status = PandaDocApi.str(doc.get('status'));
        PandaDocApi.logInfo('prepareForSigning: status=' + status);
        dbg('prepareForSigning: PandaDoc status="' + status + '" metadata=' + JSON.serialize(doc.get('metadata')));

        if ('document.uploaded'.equals(status)) {
            dbg('prepareForSigning: still uploading, stopping. Contact status NOT set.');
            throw new AuraHandledException('The form is still being prepared. Please try again in a few seconds.');
        }

        // 1. Link to the Opportunity before sending (once per document)
        if (opportunityId != null && 'document.draft'.equals(status)) {
            dbg('prepareForSigning: linking opportunity ' + opportunityId);
            try {
                PandaDocApi.send('POST', '/documents/' + docId + '/linked-objects', JSON.serialize(new Map<String, Object>{
                    'provider'    => 'salesforce',
                    'entity_type' => 'Opportunity',
                    'entity_id'   => String.valueOf(opportunityId)
                }));
                dbg('prepareForSigning: opportunity linked');
            } catch (AuraHandledException e) {
                dbg('prepareForSigning: link failed, getMessage()="' + e.getMessage() + '"');
                if (!e.getMessage().contains('409')) {
                    dbg('prepareForSigning: message has no 409, rethrowing. Contact status NOT set.');
                    throw e;   // 409 = already linked
                }
                dbg('prepareForSigning: 409 already linked, continuing');
            }
        } else {
            dbg('prepareForSigning: opportunity link skipped (opp=' + opportunityId + ', status=' + status + ')');
        }

        // 2. Send only while still a draft. silent = false means PandaDoc emails the contact.
        if ('document.draft'.equals(status)) {
            Boolean silent = (sendEmail != true);
            PandaDocApi.send('POST', '/documents/' + docId + '/send', JSON.serialize(new Map<String, Object>{
                'silent' => silent
            }));
            PandaDocApi.logInfo('prepareForSigning: sent, silent=' + silent);
            dbg('prepareForSigning: send call returned, silent=' + silent);
        } else {
            dbg('prepareForSigning: send skipped, status is "' + status + '" (not document.draft)');
        }

        // 3. Link to return
        dbg('prepareForSigning: getting signing link');
        String link;
        if (sendEmail == true) {
            link = PandaDocApi.PANDADOC_APP + '/a/#/documents/' + docId;
        } else {
            link = getRecipientLink(docId, c.Email);
            dbg('prepareForSigning: recipient shared_link=' + link);
            if (String.isBlank(link)) {
                link = createSessionLink(docId, c.Email);
                dbg('prepareForSigning: session link=' + link);
            }
        }
        PandaDocApi.logInfo('prepareForSigning: link=' + link);

        // 4. Contact status = Sent (last, after all callouts)
        // CHANGED: set Sent only when this call sent the document; later statuses come from the webhook
        if (!'document.draft'.equals(status)) {
            dbg('prepareForSigning: document already sent (status=' + status + '), Contact status left unchanged');
        } else {
            String fieldName = String.isNotBlank(formApiName) ? formApiName : getFormApiNameFromMetadata(doc);
            dbg('prepareForSigning: status field taken from '
                + (String.isNotBlank(formApiName) ? 'parameter' : 'document metadata')
                + ' = "' + fieldName + '"');
            setContactStatus(contactId, fieldName, 'Sent');
        }

        dbg('prepareForSigning END');
        return link;
    }

    /* Returns Contact field values for the given API names. Keys are lower case. */
    @AuraEnabled
    public static Map<String, String> getContactStatuses(Id contactId, List<String> fieldNames) {
        dbg('getContactStatuses START contact=' + contactId + ' fields=' + fieldNames);
        Map<String, String> result = new Map<String, String>();
        if (contactId == null || fieldNames == null || fieldNames.isEmpty()) {
            dbg('getContactStatuses: no contact or no fields, returning empty');
            return result;
        }
        dbgUser('getContactStatuses');
        PhaseDocumentTrackerController.validateContactOwnership(String.valueOf(contactId));

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Contact.fields.getMap();
        Set<String> valid = new Set<String>();
        for (String f : fieldNames) {
            if (String.isBlank(f) || !fieldMap.containsKey(f.toLowerCase())) {
                dbg('getContactStatuses: "' + f + '" is not a Contact field, ignored');
                continue;
            }
            Schema.DescribeFieldResult d = fieldMap.get(f.toLowerCase()).getDescribe();
            if (d.isAccessible()) {
                valid.add(d.getName());
            } else {
                dbg('getContactStatuses: ' + d.getName() + ' is NOT readable by the running user '
                    + '(field-level security), so it is left out of the result');
            }
        }
        if (valid.isEmpty()) {
            dbg('getContactStatuses: no readable fields, returning empty');
            return result;
        }

        List<String> names = new List<String>(valid);
        List<SObject> rows = Database.query(
            'SELECT Id, ' + String.join(names, ', ') + ' FROM Contact WHERE Id = :contactId LIMIT 1'
        );
        if (rows.isEmpty()) {
            dbg('getContactStatuses: contact not found, returning empty');
            return result;
        }
        for (String n : names) {
            Object v = rows[0].get(n);
            dbg('getContactStatuses: ' + n + ' = ' + (v == null ? '(null)' : '"' + String.valueOf(v) + '"'));
            if (v != null) {
                result.put(n.toLowerCase(), String.valueOf(v));
            }
        }
        dbg('getContactStatuses END result=' + result);
        return result;
    }

    /* =====================================================================
     * COMPLETED FILES (community portal)
     * Returns the saved final PDF for each form label. Matched on the file
     * title "<label> - Final", which the webhook writes when PandaDoc completes.
     * ===================================================================== */

    public class CompletedFile {
        @AuraEnabled public String label;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
    }

    @AuraEnabled
    public static List<CompletedFile> getCompletedFiles(Id contactId, List<String> formLabels) {
        List<CompletedFile> out = new List<CompletedFile>();
        if (contactId == null || formLabels == null || formLabels.isEmpty()) {
            return out;
        }
        PhaseDocumentTrackerController.validateContactOwnership(String.valueOf(contactId));

        Map<String, String> labelByTitle = new Map<String, String>();
        for (String label : formLabels) {
            if (String.isNotBlank(label)) {
                labelByTitle.put(finalTitle(label), label);
            }
        }
        if (labelByTitle.isEmpty()) {
            return out;
        }

        Set<String> titles = labelByTitle.keySet();
        dbg('getCompletedFiles START contact=' + contactId + ' titles=' + titles);
        Map<String, CompletedFile> found = new Map<String, CompletedFile>();

        for (ContentDocumentLink l : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
              AND ContentDocument.Title IN :titles
        ]) {
            String label = labelByTitle.get(l.ContentDocument.Title);
            if (label != null && !found.containsKey(label)) {
                CompletedFile f = new CompletedFile();
                f.label = label;
                f.contentDocumentId = l.ContentDocumentId;
                f.fileName = l.ContentDocument.Title + '.pdf';
                found.put(label, f);
            }
        }
        dbg('getCompletedFiles END found=' + found.keySet());
        return found.values();
    }

    /* =====================================================================
     * PORTAL SYNC
     * Called when the contact returns to the portal. If PandaDoc reports the
     * document as completed, saves the final PDF to the contact and sets the
     * form's status field to Completed. Uses the contact and form details the
     * portal already has, so it works even when the document has no metadata.
     * Safe to call repeatedly.
     * ===================================================================== */
    @AuraEnabled
    public static String syncPortalDocument(String docId, Id contactId, String formApiName, String formLabel) {
        dbg('syncPortalDocument START doc=' + docId + ' contact=' + contactId
            + ' formApiName="' + formApiName + '" formLabel="' + formLabel + '"');
        dbgUser('syncPortalDocument');
        PhaseDocumentTrackerController.validateContactOwnership(String.valueOf(contactId));

        // CHANGED: details endpoint, which includes metadata
        Map<String, Object> doc = getDocumentDetails(docId);
        String rawStatus = PandaDocApi.str(doc.get('status'));
        dbg('syncPortalDocument: PandaDoc status="' + rawStatus + '"');
        String status = rawStatus.toLowerCase();
        PandaDocApi.logInfo('syncPortalDocument: doc=' + docId + ' status=' + status);

        if (!status.contains('completed')) {
            dbg('syncPortalDocument: not completed yet. No file saved, Contact status not changed.');
            return status;
        }

        String metaContact = '';
        Object metaRaw = doc.get('metadata');
        dbg('syncPortalDocument: metadata=' + JSON.serialize(metaRaw));
        if (metaRaw != null) {
            metaContact = PandaDocApi.str(((Map<String, Object>) metaRaw).get('salesforce_contact_id'));
        }
        if (String.isNotBlank(metaContact) && !metaContact.equals(String.valueOf(contactId))) {
            PandaDocApi.logError('syncPortalDocument: doc ' + docId + ' belongs to contact ' + metaContact);
            dbg('syncPortalDocument: contact mismatch, metadata=' + metaContact + ' portal=' + contactId
                + '. Status NOT set.');
            throw new AuraHandledException('This document does not belong to this contact.');
        }

        String label = String.isNotBlank(formLabel) ? formLabel : formApiName;
        dbg('syncPortalDocument: label="' + label + '" file title="' + finalTitle(label) + '"');

        // 1. Save the file. This is kept even if the status update fails below.
        saveFinalPdf(contactId, finalTitle(label), PandaDocApi.downloadPdf(docId));

        // 2. Set the status. A validation rule error is returned to the portal, not thrown,
        //    so the file save above is not rolled back.
        Boolean hasField = String.isNotBlank(formApiName) && formApiName.endsWith('__c');
        dbg('syncPortalDocument: status update ' + (hasField ? 'will run' : 'SKIPPED')
            + ' (formApiName="' + formApiName + '", must end in lower-case __c)');
        if (hasField) {
            try {
                setStatusOrThrow(contactId, formApiName, 'Completed');
            } catch (DmlException e) {
                String msg = e.getDmlMessage(0);
                PandaDocApi.logError('syncPortalDocument: status blocked for ' + formApiName + ' - ' + msg);
                dbg('syncPortalDocument: status update FAILED - ' + dbgException(e));
                return 'status-blocked: ' + msg;
            } catch (Exception e) {
                dbg('syncPortalDocument: status update FAILED (not DML, rethrowing, file save rolls back) - '
                    + dbgException(e));
                throw e;
            }
        }

        PandaDocApi.logInfo('syncPortalDocument: saved "' + finalTitle(label) + '" and set status Completed');
        dbg('syncPortalDocument END');
        return 'document.completed';
    }

    /* =====================================================================
     * ADMIN REPAIR
     * Saves the final PDF and sets the form's status to Completed for one
     * PandaDoc document. Use from Execute Anonymous for documents signed
     * before the automatic path worked. Skips the contact-ownership check,
     * so it is for administrators only. Returns a message instead of
     * throwing, so a batch run continues past a blocked form.
     * ===================================================================== */
    public static String repairForm(String docId, Id contactId, String formApiName, String formLabel) {
        dbg('repairForm START doc=' + docId + ' contact=' + contactId
            + ' formApiName="' + formApiName + '" formLabel="' + formLabel + '"');
        Map<String, Object> doc = PandaDocApi.getDocument(docId);
        String status = PandaDocApi.str(doc.get('status')).toLowerCase();
        String label = String.isNotBlank(formLabel) ? formLabel : formApiName;
        dbg('repairForm: PandaDoc status="' + status + '"');

        if (!status.contains('completed')) {
            dbg('repairForm: skipped, not completed');
            return 'Skipped ' + label + ': PandaDoc status is ' + status;
        }

        saveFinalPdf(contactId, finalTitle(label), PandaDocApi.downloadPdf(docId));

        try {
            setStatusOrThrow(contactId, formApiName, 'Completed');
        } catch (DmlException e) {
            dbg('repairForm: status update FAILED - ' + dbgException(e));
            return 'File saved, status blocked for ' + label + ': ' + e.getDmlMessage(0);
        }
        dbg('repairForm END completed ' + label);
        return 'Completed: ' + label;
    }

    // NEW: full document details, including metadata (also used by PandaDocWebhook)
    public static Map<String, Object> getDocumentDetails(String docId) {
        String body = PandaDocApi.send('GET', '/documents/' + docId + '/details', null);
        dbg('getDocumentDetails: doc=' + docId + ' bodyChars=' + (body == null ? 0 : body.length()));
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    /* Saves the PDF to the contact's Files, unless a file with this title is already there. */
    // CHANGED: public so PandaDocEventProcessor can use it
    public static void saveFinalPdf(Id contactId, String title, Blob pdf) {
        dbg('saveFinalPdf START contact=' + contactId + ' title="' + title + '" pdf size='
            + (pdf == null ? 'null' : String.valueOf(pdf.size()) + ' bytes'));
        Integer existing = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
              AND ContentDocument.Title = :title
        ];
        dbg('saveFinalPdf: files with this title already on contact=' + existing);
        if (existing > 0) {
            PandaDocApi.logInfo('saveFinalPdf: "' + title + '" already on contact, skipped');
            return;
        }

        ContentVersion cv = new ContentVersion(
            Title        = title,
            PathOnClient = title + '.pdf',
            VersionData  = pdf
        );
        insert cv;
        dbg('saveFinalPdf: ContentVersion inserted id=' + cv.Id);

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        insert new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId    = contactId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        dbg('saveFinalPdf END linked ContentDocument ' + cdId + ' to contact ' + contactId);
    }

    /* Sets a Contact status field. Errors are thrown so the caller can report them. */
    private static void setStatusOrThrow(Id contactId, String formApiName, String value) {
        dbg('setStatusOrThrow START contact=' + contactId + ' field="' + formApiName + '" value="' + value + '"');
        Schema.SObjectField field = Schema.SObjectType.Contact.fields.getMap().get(formApiName.toLowerCase());
        if (field == null) {
            dbg('setStatusOrThrow: "' + formApiName + '" is NOT a Contact field, throwing');
            throw new AuraHandledException('Contact field not found: ' + formApiName);
        }
        String apiName = field.getDescribe().getName();
        dbgFieldInfo(apiName, value);
        dbg('setStatusOrThrow: value BEFORE update=' + dbgReadValue(contactId, apiName));

        Contact con = new Contact(Id = contactId);
        con.put(apiName, value);
        try {
            update con;
        } catch (Exception e) {
            dbg('setStatusOrThrow: update FAILED - ' + dbgException(e));
            throw e;
        }
        dbg('setStatusOrThrow: value AFTER update=' + dbgReadValue(contactId, apiName)
            + ' (if this differs from "' + value + '", a trigger or flow changed it)');
    }

    /* =====================================================================
     * TEMPLATE AND TOKEN HELPERS
     * ===================================================================== */

    /* Template ID for a form, looked up by API name first, then by label. */
    private static String resolveTemplateId(String formApiName, String formLabel) {
        Map<String, String> templates = templateMap();
        String id = templates.get(normalizeKey(formApiName));
        if (String.isBlank(id)) {
            id = templates.get(normalizeKey(formLabel));
        }
        return id;
    }

    /*
     * Lowercase letters and digits only. Drops a trailing __c so the Contact
     * field name and the form label produce the same key.
     */
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

    /* Token names defined on the template. */
    private static List<String> templateTokenNames(Map<String, Object> details) {
        List<String> names = new List<String>();
        Object raw = details.get('tokens');
        if (raw == null) {
            return names;
        }
        for (Object o : (List<Object>) raw) {
            Map<String, Object> t = (Map<String, Object>) o;
            String n = PandaDocApi.str(t.get('name'));
            if (String.isNotBlank(n) && !names.contains(n)) {
                names.add(n);
            }
        }
        return names;
    }

    /* First recipient role defined on the template. */
    private static String templateRecipientRole(Map<String, Object> details) {
        Object raw = details.get('recipients');
        if (raw == null) {
            return null;
        }
        for (Object o : (List<Object>) raw) {
            Map<String, Object> r = (Map<String, Object>) o;
            String role = PandaDocApi.str(r.get('role'));
            if (String.isNotBlank(role)) {
                return role;
            }
        }
        return null;
    }

    /*
     * Maps a token name to a Contact field. Examples:
     *   Member.FirstName     -> FirstName
     *   Contact.AHCCCS_ID__c -> AHCCCS_ID__c
     *   Member.Date          -> today's date
     *   Member.FullName      -> first + last name
     * Returns null when nothing matches. Those tokens are left blank.
     */
    private static String resolveTokenSource(String tokenName, Map<String, Schema.SObjectField> contactFields) {
        String bare = tokenName.contains('.') ? tokenName.substringAfterLast('.') : tokenName;
        String key = bare.toLowerCase();
        String compact = key.replaceAll('[^a-z]', '');

        if (compact == 'fullname' || compact == 'membername' || compact == 'name') {
            return FULL_NAME_TOKEN;
        }
        if (contactFields.containsKey(key)) {
            Schema.DescribeFieldResult d = contactFields.get(key).getDescribe();
            if (d.isAccessible()) {
                return d.getName();
            }
        }
        if (contactFields.containsKey(key + '__c')) {
            Schema.DescribeFieldResult d = contactFields.get(key + '__c').getDescribe();
            if (d.isAccessible()) {
                return d.getName();
            }
        }
        if (key.contains('date')) {
            return DATE_TOKEN;
        }
        return null;
    }

    /* Reads the needed Contact fields in one query. Keys are lower case. */
    private static Map<String, String> readContactValues(Id contactId, Set<String> fields) {
        Map<String, String> out = new Map<String, String>();
        List<String> names = new List<String>(fields);
        List<SObject> rows = Database.query(
            'SELECT Id, ' + String.join(names, ', ') + ' FROM Contact WHERE Id = :contactId LIMIT 1'
        );
        if (rows.isEmpty()) {
            return out;
        }
        for (String n : names) {
            Object v = rows[0].get(n);
            if (v != null) {
                out.put(n.toLowerCase(), String.valueOf(v));
            }
        }
        return out;
    }

    private static String tokenValue(String tokenName, String source, Map<String, String> contactValues) {
        if (source == null) {
            return '';
        }
        if (source == DATE_TOKEN) {
            return Datetime.now().format('MM/dd/yyyy');
        }
        if (source == FULL_NAME_TOKEN) {
            return joinParts(new List<String>{ contactValues.get('firstname'), contactValues.get('lastname') }, ' ');
        }
        String v = contactValues.get(source.toLowerCase());
        return v == null ? '' : v;
    }

    /* =====================================================================
     * SANDBOX CHECK, LINKS, CONTACT STATUS
     * ===================================================================== */

    /* Stops with a clear message when a sandbox key is used for an address outside the sandbox domain. */
    private static void checkRecipientAllowed(String email) {
        if (String.isBlank(SANDBOX_EMAIL_DOMAIN)) {
            return;
        }
        String domain = email.substringAfterLast('@');
        if (!domain.equalsIgnoreCase(SANDBOX_EMAIL_DOMAIN.trim())) {
            throw new AuraHandledException(
                'PandaDoc sandbox sends only to @' + SANDBOX_EMAIL_DOMAIN + ' addresses. '
                + 'For testing, set the contact email to one on that domain. '
                + 'For real contacts, use the production API key and clear SANDBOX_EMAIL_DOMAIN.'
            );
        }
    }

    /* The signing link PandaDoc assigned to the recipient with this email, if any. */
    private static String getRecipientLink(String docId, String email) {
        Map<String, Object> doc = PandaDocApi.getDocument(docId);
        Object raw = doc.get('recipients');
        if (raw == null) {
            return null;
        }
        for (Object o : (List<Object>) raw) {
            Map<String, Object> r = (Map<String, Object>) o;
            String recipientEmail = PandaDocApi.str(r.get('email'));
            String sharedLink = PandaDocApi.str(r.get('shared_link'));
            if (String.isNotBlank(sharedLink) && recipientEmail.equalsIgnoreCase(email)) {
                return sharedLink;
            }
        }
        return null;
    }

    /* Creates an embedded signing session and returns its link. */
    private static String createSessionLink(String docId, String email) {
        String body = PandaDocApi.send('POST', '/documents/' + docId + '/session', JSON.serialize(new Map<String, Object>{
            'recipient' => email,
            'lifetime'  => 3600
        }));
        Map<String, Object> session = (Map<String, Object>) JSON.deserializeUntyped(body);
        String sessionId = PandaDocApi.str(session.get('id'));
        if (String.isBlank(sessionId)) {
            PandaDocApi.logError('createSessionLink: no id in response: ' + body);
            throw new AuraHandledException('PandaDoc did not return a signing link.');
        }
        return PandaDocApi.PANDADOC_APP + '/s/' + sessionId;
    }

    private static String getFormApiNameFromMetadata(Map<String, Object> doc) {
        Object raw = doc.get('metadata');
        if (raw == null) {
            dbg('getFormApiNameFromMetadata: document has no metadata');
            return null;
        }
        String name = PandaDocApi.str(((Map<String, Object>) raw).get('form_api_name'));
        dbg('getFormApiNameFromMetadata: form_api_name="' + name + '"');
        return name;
    }

    /*
     * Writes the status to the Contact field named after the form.
     * Skipped for label-only forms. Errors are logged, so the send is kept.
     */
    private static void setContactStatus(Id contactId, String formApiName, String status) {
        dbg('setContactStatus START contact=' + contactId + ' field="' + formApiName + '" value="' + status + '"');
        if (String.isBlank(formApiName)) {
            PandaDocApi.logInfo('setContactStatus: no field name, skipped');
            dbg('setContactStatus: SKIPPED, no field name (parameter blank and none in document metadata)');
            return;
        }
        String fieldName = formApiName.toLowerCase();
        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Boolean endsWithC = fieldName.endsWith('__c');
        Boolean isContactField = contactFields.containsKey(fieldName);
        dbg('setContactStatus: endsWith __c=' + endsWithC + ' isContactField=' + isContactField);
        if (!endsWithC || !isContactField) {
            PandaDocApi.logInfo('setContactStatus: "' + formApiName + '" is not a Contact field, skipped');
            dbg('setContactStatus: SKIPPED, "' + formApiName + '" is not a custom Contact field '
                + '(a form label passed instead of the API name causes this)');
            return;
        }

        String apiName = contactFields.get(fieldName).getDescribe().getName();
        dbgFieldInfo(apiName, status);
        dbg('setContactStatus: value BEFORE update=' + dbgReadValue(contactId, apiName));

        try {
            Contact con = new Contact(Id = contactId);
            con.put(formApiName, status);
            update con;
            PandaDocApi.logInfo('setContactStatus: ' + formApiName + ' = ' + status);
            dbg('setContactStatus: value AFTER update=' + dbgReadValue(contactId, apiName)
                + ' (if this differs from "' + status + '", a trigger or flow changed it)');
        } catch (Exception e) {
            PandaDocApi.logError('setContactStatus: could not set ' + formApiName + ' to ' + status + ' - ' + e.getMessage());
            dbg('setContactStatus: UPDATE FAILED (error is swallowed, caller sees no error) - ' + dbgException(e));
            dbg('setContactStatus: stack=' + e.getStackTraceString());
        }
    }

    private static String joinParts(List<String> parts, String sep) {
        List<String> keep = new List<String>();
        for (String p : parts) {
            if (String.isNotBlank(p)) {
                keep.add(p);
            }
        }
        return String.join(keep, sep);
    }

    /* =====================================================================
     * NEW: DEBUG HELPERS
     * ===================================================================== */

    /* Writes one debug line. */
    private static void dbg(String msg) {
        if (DEBUG_ON) {
            System.debug(LoggingLevel.ERROR, DEBUG_PREFIX + ' ' + msg);
        }
    }

    /* Logs the running user. */
    private static void dbgUser(String location) {
        dbg(location + ': running user=' + UserInfo.getUserName()
            + ' id=' + UserInfo.getUserId()
            + ' type=' + UserInfo.getUserType()
            + ' profile=' + UserInfo.getProfileId());
    }

    /* Logs the field type and picklist values. */
    private static void dbgFieldInfo(String apiName, String value) {
        if (!DEBUG_ON) {
            return;
        }
        try {
            Schema.SObjectField f = Schema.SObjectType.Contact.fields.getMap().get(apiName.toLowerCase());
            if (f == null) {
                dbg('fieldInfo: "' + apiName + '" is NOT a field on Contact');
                return;
            }
            Schema.DescribeFieldResult d = f.getDescribe();
            dbg('fieldInfo: ' + d.getName()
                + ' type=' + d.getType()
                + ' accessible=' + d.isAccessible()
                + ' updateable=' + d.isUpdateable()
                + ' restrictedPicklist=' + d.isRestrictedPicklist()
                + ' length=' + d.getLength());

            Schema.DisplayType t = d.getType();
            if (t == Schema.DisplayType.PICKLIST || t == Schema.DisplayType.MULTIPICKLIST) {
                List<String> active = new List<String>();
                Boolean exact = false;
                Boolean ignoreCase = false;
                for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                    if (!pe.isActive()) {
                        continue;
                    }
                    active.add(pe.getValue());
                    if (pe.getValue().equals(value)) {
                        exact = true;
                    }
                    if (pe.getValue().equalsIgnoreCase(value)) {
                        ignoreCase = true;
                    }
                }
                dbg('fieldInfo: active picklist values=' + active);
                dbg('fieldInfo: "' + value + '" exact match=' + exact + ' case-insensitive match=' + ignoreCase);
            }
        } catch (Exception e) {
            dbg('fieldInfo: describe failed - ' + e.getMessage());
        }
    }

    /* Reads a Contact field value for logging. */
    private static String dbgReadValue(Id contactId, String apiName) {
        if (!DEBUG_ON) {
            return '(debug off)';
        }
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, ' + apiName + ' FROM Contact WHERE Id = :contactId LIMIT 1'
            );
            if (rows.isEmpty()) {
                return '(contact not found)';
            }
            Object v = rows[0].get(apiName);
            return v == null ? '(null)' : '"' + String.valueOf(v) + '"';
        } catch (Exception e) {
            return '(read failed: ' + e.getMessage() + ')';
        }
    }

    /* Exception details for logging. */
    private static String dbgException(Exception e) {
        String s = e.getTypeName() + ': ' + e.getMessage();
        if (e instanceof DmlException) {
            DmlException de = (DmlException) e;
            for (Integer i = 0; i < de.getNumDml(); i++) {
                s += ' | DML[' + i + '] code=' + de.getDmlType(i)
                   + ' fields=' + de.getDmlFieldNames(i)
                   + ' message=' + de.getDmlMessage(i);
            }
        }
        return s;
    }
}