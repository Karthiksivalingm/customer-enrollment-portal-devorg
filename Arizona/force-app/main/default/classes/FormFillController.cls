/**
 * FormFillController
 * -----------------------------------------------------------------------
 * NEW CLASS. Nothing existing is modified by this POC.
 *
 * CustomerFormController, DynamicFormsController, FormWorkflowService,
 * TSDocumentService, TSTemplateSelector, PerContactDocumentService,
 * GoogleDriveService and the whole dynamicformsContact bundle are all left
 * exactly as they are. This class is a self-contained replacement for the
 * three or four methods the fill-in page needs, so the POC can be deployed
 * and rolled back without touching a single existing line.
 *
 * WHAT IT DOES
 *   getFormForFill(token)     validate the link, return the form's identity
 *                             AND its field list AND the PDF, in one call
 *   saveFilledForm(...)       write answers to the Contact, save the
 *                             completed PDF to Files on the Contact, mark
 *                             the request Completed
 *
 * DIFFERENCES FROM CustomerFormController, and why
 *   - getFormForFill performs NO DML. CustomerFormController.getFormRequest
 *     updates Status__c to 'Opened', which an unauthenticated guest user
 *     often cannot do; that update would block the page from loading at
 *     all. Here the status only moves on submit.
 *   - It returns the coordinate fields (PDF_X__c, PDF_Y__c, PDF_Page__c,
 *     Font_Size__c) that the LWC needs to draw values onto the PDF.
 *   - One round trip instead of three, so the page renders faster.
 *
 * WHO CAN RUN IT
 *   `without sharing` for the same reason CustomerFormController is: the
 *   person holding the link may be a guest with no record access. The
 *   random token is the authorization.
 *
 *   For the FIRST test you run this as yourself (a normal internal user),
 *   which needs no site or guest configuration at all. The guest layer is
 *   added afterwards - see the notes at the bottom of the class.
 */
public without sharing class FormFillController {

    /* =====================================================================
     * DTOs
     * ===================================================================== */

    public class FillFieldDTO {
        @AuraEnabled public String  name;
        @AuraEnabled public String  label;
        @AuraEnabled public String  type;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String  value;
        @AuraEnabled public Decimal x;
        @AuraEnabled public Decimal y;
        @AuraEnabled public Integer page;
        @AuraEnabled public Integer fontSize;
    }

    public class FillFormDTO {
        @AuraEnabled public Id     requestId;
        @AuraEnabled public Id     contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String formLabel;
        @AuraEnabled public String formApiName;
        @AuraEnabled public String status;
        @AuraEnabled public String pdfBase64;
        @AuraEnabled public List<FillFieldDTO> fields;
    }

    public class FillResultDTO {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  message;
        @AuraEnabled public String  contentDocumentId;
    }

    /* =====================================================================
     * READ - everything the page needs, in one call
     * ===================================================================== */

    @AuraEnabled
    public static FillFormDTO getFormForFill(String token) {
        if (String.isBlank(token)) {
            throw new AuraHandledException('This link is missing its form code.');
        }

        Form_Request__c request = loadRequest(token);

        FillFormDTO out = new FillFormDTO();
        out.requestId   = request.Id;
        out.contactId   = request.Contact__c;
        out.contactName = request.Contact__r.Name;
        out.formLabel   = request.Form_Label__c;
        out.formApiName = request.Form_API_Name__c;
        out.status      = request.Status__c;
        out.fields      = buildFields(request);
        out.pdfBase64   = loadPdf(request);

        if (out.fields.isEmpty()) {
            throw new AuraHandledException(
                'This form has no fields configured yet. Add Form_Field_Mapping '
                + 'records where Form API Name is "' + request.Form_API_Name__c + '".'
            );
        }

        return out;
    }

    /**
     * Finds and validates the request. No DML - deliberately, so a guest
     * user without Edit permission can still open the page.
     */
    private static Form_Request__c loadRequest(String token) {
        List<Form_Request__c> matches = [
            SELECT Id, Contact__c, Contact__r.Name, Contact__r.Email,
                   Form_API_Name__c, Form_Label__c, Template_Name__c,
                   Status__c, Expiration_Date__c, Generate_File__c
            FROM Form_Request__c
            WHERE Token__c = :token
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            throw new AuraHandledException('This form link is not valid.');
        }

        Form_Request__c request = matches[0];

        if (request.Status__c == 'Completed') {
            throw new AuraHandledException(
                'This form has already been completed. Thank you.'
            );
        }
        if (request.Status__c == 'Cancelled') {
            throw new AuraHandledException('This form request was cancelled.');
        }
        if (request.Status__c == 'Expired'
            || (request.Expiration_Date__c != null
                && request.Expiration_Date__c < Date.today())) {
            throw new AuraHandledException(
                'This form link has expired. Please ask us for a new one.'
            );
        }
        return request;
    }

    /**
     * The field list, straight from Form__mdt. Ordered by page then down
     * the page, so the on-screen order matches the printed order.
     */
    private static List<FillFieldDTO> buildFields(Form_Request__c request) {
        List<FillFieldDTO> out = new List<FillFieldDTO>();

        if (String.isBlank(request.Form_API_Name__c)) {
            return out;
        }

        List<Form__mdt> mappings = [
            SELECT PDF_Field_Name__c, Field_Label__c, Field_Type__c, Required__c,
                   Salesforce_Field_API__c,
                   PDF_X__c, PDF_Y__c, PDF_Page__c, Font_Size__c
            FROM Form__mdt
            WHERE Form_API_Name__c = :request.Form_API_Name__c
            ORDER BY PDF_Page__c ASC NULLS FIRST, PDF_Y__c DESC NULLS LAST
        ];

        if (mappings.isEmpty()) {
            return out;
        }

        Map<String, Object> prefill = loadPrefill(request.Contact__c, mappings);

        for (Form__mdt m : mappings) {
            if (String.isBlank(m.PDF_Field_Name__c)) {
                // No field name means nothing to draw and nothing to key
                // an answer against - skip rather than render a dead input.
                continue;
            }

            FillFieldDTO f = new FillFieldDTO();
            f.name     = m.PDF_Field_Name__c;
            f.label    = String.isBlank(m.Field_Label__c)
                            ? m.PDF_Field_Name__c.replace('_', ' ')
                            : m.Field_Label__c;
            f.type     = String.isBlank(m.Field_Type__c)
                            ? 'text'
                            : m.Field_Type__c.trim().toLowerCase();
            f.required = isTrue(m.Required__c);
            f.x        = m.PDF_X__c;
            f.y        = m.PDF_Y__c;
            f.page     = m.PDF_Page__c == null ? 1 : m.PDF_Page__c.intValue();
            f.fontSize = m.Font_Size__c == null ? 11 : m.Font_Size__c.intValue();

            Object raw = String.isBlank(m.Salesforce_Field_API__c)
                            ? null
                            : prefill.get(m.Salesforce_Field_API__c);
            f.value = (raw == null) ? '' : String.valueOf(raw);

            out.add(f);
        }
        return out;
    }

    /** Current Contact values for whichever mapped fields actually exist. */
    private static Map<String, Object> loadPrefill(
        Id contactId, List<Form__mdt> mappings
    ) {
        Map<String, Object> values = new Map<String, Object>();
        if (contactId == null) {
            return values;
        }

        Map<String, Schema.SObjectField> fieldMap =
            Contact.SObjectType.getDescribe().fields.getMap();

        Set<String> queryFields = new Set<String>();
        for (Form__mdt m : mappings) {
            if (String.isBlank(m.Salesforce_Field_API__c)) {
                continue;
            }
            Schema.SObjectField token =
                fieldMap.get(m.Salesforce_Field_API__c.toLowerCase());
            if (token != null && token.getDescribe().isAccessible()) {
                queryFields.add(token.getDescribe().getName());
            }
        }
        if (queryFields.isEmpty()) {
            return values;
        }

        String soql = 'SELECT Id, '
            + String.join(new List<String>(queryFields), ', ')
            + ' FROM Contact WHERE Id = :contactId LIMIT 1';

        List<Contact> rows = Database.query(soql);
        if (!rows.isEmpty()) {
            for (String f : queryFields) {
                values.put(f, rows[0].get(f));
            }
        }
        return values;
    }

    /** Base64 of the PDF that was emailed, so the LWC can draw onto it. */
    private static String loadPdf(Form_Request__c request) {
        if (String.isBlank(request.Generate_File__c)) {
            throw new AuraHandledException(
                'No document has been generated for this form yet. '
                + 'Please contact us.'
            );
        }

        String docId = request.Generate_File__c.trim();

        List<ContentVersion> versions = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
              AND IsLatest = true
            LIMIT 1
        ];
        if (versions.isEmpty() || versions[0].VersionData == null) {
            throw new AuraHandledException(
                'The form document could not be found. Please contact us.'
            );
        }
        return EncodingUtil.base64Encode(versions[0].VersionData);
    }

    /* =====================================================================
     * WRITE - save the completed form
     * ===================================================================== */

    /**
     * @param token      re-validated here, so a page left open past expiry
     *                   cannot submit
     * @param values     PDF field name -> the customer's answer
     * @param base64Pdf  the completed PDF, already drawn client-side
     */
    @AuraEnabled
    public static FillResultDTO saveFilledForm(
        String token, Map<String, Object> values, String base64Pdf
    ) {
        FillResultDTO result = new FillResultDTO();

        if (String.isBlank(base64Pdf)) {
            throw new AuraHandledException('No completed document was received.');
        }

        Form_Request__c request = loadRequest(token);

        try {
            // --- 1. answers back onto the Contact -------------------------
            writeBackToContact(request, values);

            // --- 2. the completed PDF into Files on the Contact ----------
            Id completedDocId = saveCompletedPdf(request, base64Pdf);

            // --- 3. mark the request Completed --------------------------
            request.Status__c         = 'Completed';
            request.Completed_Date__c = Date.today();
            if (completedDocId != null) {
                request.Completed__c = String.valueOf(completedDocId);
            }
            update request;

            // --- 4. sync the Contact's own per-form status field, which
            //        is what makes the row read Completed in the staff
            //        component. Non-fatal if it fails.
            syncFormStatusField(request);

            result.success           = true;
            result.message           = 'Thank you - your form has been submitted.';
            result.contentDocumentId = completedDocId;
            return result;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Could not save your form: ' + e.getMessage()
            );
        }
    }

    private static void writeBackToContact(
        Form_Request__c request, Map<String, Object> values
    ) {
        if (values == null || values.isEmpty() || request.Contact__c == null) {
            return;
        }

        List<Form__mdt> mappings = [
            SELECT PDF_Field_Name__c, Salesforce_Field_API__c
            FROM Form__mdt
            WHERE Form_API_Name__c = :request.Form_API_Name__c
        ];
        if (mappings.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> fieldMap =
            Contact.SObjectType.getDescribe().fields.getMap();

        Contact target = new Contact(Id = request.Contact__c);
        Boolean touched = false;

        for (Form__mdt m : mappings) {
            if (String.isBlank(m.Salesforce_Field_API__c)
                || String.isBlank(m.PDF_Field_Name__c)) {
                continue;
            }
            if (!values.containsKey(m.PDF_Field_Name__c)) {
                continue;
            }
            Schema.SObjectField token =
                fieldMap.get(m.Salesforce_Field_API__c.toLowerCase());
            if (token == null) {
                continue;
            }
            Schema.DescribeFieldResult dfr = token.getDescribe();
            if (!dfr.isUpdateable()) {
                // Contact.Name is a compound field and is not writable -
                // silently skip rather than fail the whole submission.
                continue;
            }
            Object coerced = coerce(values.get(m.PDF_Field_Name__c), dfr.getType());
            if (coerced != null) {
                target.put(dfr.getName(), coerced);
                touched = true;
            }
        }

        if (touched) {
            update target;
        }
    }

    private static Id saveCompletedPdf(Form_Request__c request, String base64Pdf) {
        String title = request.Form_Label__c + ' - Completed';

        ContentVersion cv = new ContentVersion();
        cv.Title          = title;
        cv.PathOnClient   = title + '.pdf';
        cv.VersionData    = EncodingUtil.base64Decode(base64Pdf);
        cv.IsMajorVersion = true;

        // Re-submitting adds a new VERSION of the same file rather than a
        // duplicate, which keeps the Files list clean during calibration.
        Id existingDocId = findExistingCompleted(request.Contact__c, title);
        if (existingDocId != null) {
            cv.ContentDocumentId = existingDocId;
        }
        insert cv;

        Id docId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        if (existingDocId == null) {
            insert new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId    = request.Contact__c,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
        }
        return docId;
    }

    private static Id findExistingCompleted(Id contactId, String title) {
        if (contactId == null) {
            return null;
        }
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

    private static void syncFormStatusField(Form_Request__c request) {
        if (String.isBlank(request.Form_API_Name__c) || request.Contact__c == null) {
            return;
        }
        try {
            Map<String, Schema.SObjectField> fieldMap =
                Contact.SObjectType.getDescribe().fields.getMap();
            Schema.SObjectField token =
                fieldMap.get(request.Form_API_Name__c.toLowerCase());
            if (token == null || !token.getDescribe().isUpdateable()) {
                return;
            }
            Contact statusUpdate = new Contact(Id = request.Contact__c);
            statusUpdate.put(token.getDescribe().getName(), 'Completed');
            update statusUpdate;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'Could not sync the form status field: ' + e.getMessage());
        }
    }

    /* =====================================================================
     * HELPERS
     * ===================================================================== */

    /** Required__c is Text(255) in this org, not a Checkbox. */
    private static Boolean isTrue(String raw) {
        if (String.isBlank(raw)) {
            return false;
        }
        String v = raw.trim().toLowerCase();
        return v == 'true' || v == 'yes' || v == '1';
    }

    /** Answers arrive as strings; convert to what the Contact field wants. */
    private static Object coerce(Object raw, Schema.DisplayType type) {
        if (raw == null) {
            return null;
        }
        String s = String.valueOf(raw).trim();
        if (String.isBlank(s)) {
            return null;
        }
        try {
            if (type == Schema.DisplayType.DATE) {
                return Date.valueOf(s);           // LWC sends yyyy-MM-dd
            }
            if (type == Schema.DisplayType.BOOLEAN) {
                return s.equalsIgnoreCase('true') || s == '1'
                    || s.equalsIgnoreCase('yes');
            }
            if (type == Schema.DisplayType.CURRENCY
                || type == Schema.DisplayType.DOUBLE
                || type == Schema.DisplayType.PERCENT) {
                return Decimal.valueOf(s);
            }
            if (type == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(s);
            }
            return s;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'Could not convert "' + s + '" to ' + type);
            return null;
        }
    }

    /* =====================================================================
     * LATER - making this work for unauthenticated guests
     * ---------------------------------------------------------------------
     * Everything above works as-is for an internal user, which is how the
     * POC is tested first. When you expose it on a public Experience Cloud
     * page, the READ path (getFormForFill) will work for a guest as soon
     * as the guest profile has Read on Form_Request__c, Read on
     * Form_Field_Mapping, Read on ContentVersion, and Apex access to this
     * class - it performs no DML at all, deliberately.
     *
     * The WRITE path (saveFilledForm) is the part that needs attention.
     * Under Secure guest user record access a Site guest typically cannot
     * update a Contact or insert a ContentDocumentLink. Test it; if it
     * fails, the fix is to have saveFilledForm insert only the
     * ContentVersion and then publish a Form_Submission__e platform event,
     * whose trigger runs as Automated Process and performs the Contact
     * update, the ContentDocumentLink insert and the status changes. That
     * is a change to THIS class only - still nothing existing is touched.
     * ===================================================================== */
}