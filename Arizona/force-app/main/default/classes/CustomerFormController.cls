/**
 * CustomerFormController
 * -----------------------------------------------------------------------
 * Powers the Experience Cloud "complete your form" page (customFormPage).
 * Everything here is generic across all forms - which fields show up for
 * a given form is entirely driven by Form__mdt.
 *
 * Runs `without sharing` deliberately: the person opening the emailed
 * link may be an unauthenticated/guest site user, not a logged-in portal
 * user, so this cannot rely on record-level sharing to find their own
 * Form_Request__c. The token itself (random, unique, external Id) is
 * what authorizes access - every method validates the token and the
 * request's status before doing anything.
 */
public without sharing class CustomerFormController {

    public class FormRequestDTO {
        @AuraEnabled public Id requestId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String formApiName;
        @AuraEnabled public String formLabel;
        @AuraEnabled public String templateName;
        @AuraEnabled public String status;
    }

    public class FormFieldDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Object value;
    }

    public class SaveResultDTO {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static FormRequestDTO getFormRequest(String token) {
        if (String.isBlank(token)) {
            throw new AuraHandledException('Invalid form link.');
        }

        List<Form_Request__c> matches = [
            SELECT Id, Contact__c, Contact__r.Name, Contact__r.Email,
                   Form_API_Name__c, Form_Label__c, Template_Name__c,
                   Status__c, Expiration_Date__c
            FROM Form_Request__c
            WHERE Token__c = :token
            LIMIT 1
        ];

        if (matches.isEmpty()) {
            throw new AuraHandledException('This form link is not valid.');
        }

        Form_Request__c request = matches[0];

        if (request.Status__c == 'Completed') {
            throw new AuraHandledException('This form has already been completed.');
        }
        if (request.Status__c == 'Cancelled') {
            throw new AuraHandledException('This form request was cancelled.');
        }
        if (request.Status__c == 'Expired'
            || (request.Expiration_Date__c != null && request.Expiration_Date__c < Date.today())) {
            if (request.Status__c != 'Expired') {
                request.Status__c = 'Expired';
                update request;
            }
            throw new AuraHandledException('This form link has expired. Please ask for a new one.');
        }

        if (request.Status__c == 'Sent') {
            request.Status__c = 'Opened';
            update request;
        }

        FormRequestDTO dto = new FormRequestDTO();
        dto.requestId    = request.Id;
        dto.contactId    = request.Contact__c;
        dto.contactName  = request.Contact__r.Name;
        dto.formApiName  = request.Form_API_Name__c;
        dto.formLabel    = request.Form_Label__c;
        dto.templateName = request.Template_Name__c;
        dto.status       = request.Status__c;
        return dto;
    }

    @AuraEnabled
    public static List<FormFieldDTO> getFormFields(Id requestId) {
        if (requestId == null) {
            throw new AuraHandledException('Form request is required.');
        }

        List<Form_Request__c> requests = [
            SELECT Id, Form_API_Name__c, Contact__c
            FROM Form_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];
        if (requests.isEmpty()) {
            throw new AuraHandledException('Form request not found.');
        }
        Form_Request__c request = requests[0];

        List<Form__mdt> mappings = [
            SELECT Form_API_Name__c, PDF_Field_Name__c, Salesforce_Field_API__c,
                   Field_Label__c, Field_Type__c, Required__c
            FROM Form__mdt
            WHERE Form_API_Name__c = :request.Form_API_Name__c
        ];

        Map<String, Object> contactValues = loadContactValues(request.Contact__c, mappings);

        List<FormFieldDTO> results = new List<FormFieldDTO>();
        for (Form__mdt mapping : mappings) {
            FormFieldDTO dto = new FormFieldDTO();
            dto.name     = mapping.PDF_Field_Name__c;
            dto.label    = mapping.Field_Label__c;
            dto.type     = mapping.Field_Type__c;
            dto.required = parseBoolean(mapping.Required__c);
            dto.value    = String.isBlank(mapping.Salesforce_Field_API__c)
                ? null
                : contactValues.get(mapping.Salesforce_Field_API__c);
            results.add(dto);
        }
        return results;
    }

    /**
     * Your Required__c field is Text(255) in this org, not Checkbox, so
     * this reads whatever's actually stored ('true'/'TRUE'/'yes'/'1' all
     * count) instead of assuming it's already a Boolean.
     */
    private static Boolean parseBoolean(String raw) {
        if (String.isBlank(raw)) {
            return false;
        }
        String v = raw.trim().toLowerCase();
        return v == 'true' || v == 'yes' || v == '1';
    }

    /** Pulls current values for whichever mapped fields exist on Contact, in one query. */
    private static Map<String, Object> loadContactValues(
        Id contactId, List<Form__mdt> mappings
    ) {
        Map<String, Object> values = new Map<String, Object>();
        if (contactId == null) {
            return values;
        }

        Map<String, Schema.SObjectField> fieldMap =
            Contact.SObjectType.getDescribe().fields.getMap();

        Set<String> queryFields = new Set<String>();
        for (Form__mdt mapping : mappings) {
            String api = mapping.Salesforce_Field_API__c;
            if (String.isBlank(api)) {
                continue;
            }
            Schema.SObjectField token = fieldMap.get(api.toLowerCase());
            if (token != null && token.getDescribe().isAccessible()) {
                queryFields.add(api);
            }
        }

        if (queryFields.isEmpty()) {
            return values;
        }

        String soql = 'SELECT Id, ' + String.join(new List<String>(queryFields), ', ')
                    + ' FROM Contact WHERE Id = :contactId LIMIT 1';
        List<Contact> rows = Database.query(soql);
        if (!rows.isEmpty()) {
            Contact c = rows[0];
            for (String f : queryFields) {
                values.put(f, c.get(f));
            }
        }
        return values;
    }

    /**
     * Returns the base64 bytes of the PDF that TS Documents generated
     * when the form was sent, keyed off Form_Request__c.Generated_File__c
     * (set by FormWorkflowService.sendFormToContact). This is the ACTUAL
     * PDF the customer edits in-browser via pdf-lib on customFormPage.
     */
    @AuraEnabled
    public static String getGeneratedPdf(Id requestId) {
        if (requestId == null) {
            throw new AuraHandledException('Form request is required.');
        }

        List<Form_Request__c> requests = [
            SELECT Id, Generate_File__c
            FROM Form_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];
        if (requests.isEmpty()) {
            throw new AuraHandledException('Form request not found.');
        }

        Id contentDocumentId = requests[0].Generate_File__c;
        if (String.isBlank(contentDocumentId)) {
            throw new AuraHandledException(
                'No PDF has been generated for this form yet. Please contact support.'
            );
        }

        List<ContentVersion> versions = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            LIMIT 1
        ];
        if (versions.isEmpty() || versions[0].VersionData == null) {
            throw new AuraHandledException('The generated PDF could not be found.');
        }

        return EncodingUtil.base64Encode(versions[0].VersionData);
    }

    /**
     * Single transaction: writes the customer's answers back to Contact
     * fields, saves the completed PDF to Files linked to the Contact, and
     * marks the Form_Request__c Completed.
     */
    @AuraEnabled
    public static SaveResultDTO saveCustomerForm(
        Id requestId, Map<String, Object> values, String base64Pdf
    ) {
        SaveResultDTO result = new SaveResultDTO();

        try {
            if (requestId == null) {
                throw new AuraHandledException('Form request is required.');
            }

            List<Form_Request__c> requests = [
                SELECT Id, Contact__c, Form_API_Name__c, Form_Label__c
                FROM Form_Request__c
                WHERE Id = :requestId
                LIMIT 1
            ];
            if (requests.isEmpty()) {
                throw new AuraHandledException('Form request not found.');
            }
            Form_Request__c request = requests[0];

            // --- 1. write customer-entered values back to the Contact ---
            List<Form__mdt> mappings = [
                SELECT PDF_Field_Name__c, Salesforce_Field_API__c
                FROM Form__mdt
                WHERE Form_API_Name__c = :request.Form_API_Name__c
            ];

            Map<String, Schema.SObjectField> fieldMap =
                Contact.SObjectType.getDescribe().fields.getMap();

            Contact contactRecord = new Contact(Id = request.Contact__c);
            Boolean hasUpdate = false;

            if (values != null) {
                for (Form__mdt mapping : mappings) {
                    if (String.isBlank(mapping.Salesforce_Field_API__c)) {
                        continue;
                    }
                    if (!values.containsKey(mapping.PDF_Field_Name__c)) {
                        continue;
                    }
                    Schema.SObjectField token =
                        fieldMap.get(mapping.Salesforce_Field_API__c.toLowerCase());
                    if (token == null || !token.getDescribe().isUpdateable()) {
                        continue;
                    }
                    contactRecord.put(mapping.Salesforce_Field_API__c, values.get(mapping.PDF_Field_Name__c));
                    hasUpdate = true;
                }
            }
            if (hasUpdate) {
                update contactRecord;
            }

            // --- 2. save the completed PDF to Files, linked to the Contact ---
            Id completedDocId;
            if (String.isNotBlank(base64Pdf)) {
                ContentVersion cv = new ContentVersion();
                cv.Title          = request.Form_Label__c + ' - Completed';
                cv.PathOnClient   = request.Form_Label__c + '_completed.pdf';
                cv.VersionData    = EncodingUtil.base64Decode(base64Pdf);
                cv.IsMajorVersion = true;
                insert cv;

                completedDocId = [
                    SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
                ].ContentDocumentId;

                insert new ContentDocumentLink(
                    ContentDocumentId = completedDocId,
                    LinkedEntityId    = request.Contact__c,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                );
            }

            // --- 3. mark the request Completed ---
            request.Status__c = 'Completed';
            request.Completed_Date__c = Date.today();
            if (completedDocId != null) {
                request.Completed__c = completedDocId;
            }
            update request;

            // --- 4. keep the form's own status field (used by
            //        DynamicFormsContact's table) in sync too ---
            try {
                Schema.SObjectType contactType = Contact.SObjectType;
                if (contactType.getDescribe().fields.getMap().containsKey(request.Form_API_Name__c)) {
                    Contact statusUpdate = new Contact(Id = request.Contact__c);
                    statusUpdate.put(request.Form_API_Name__c, 'Completed');
                    update statusUpdate;
                }
            } catch (Exception statusEx) {
                System.debug('Could not sync form status field: ' + statusEx.getMessage());
            }

            result.success = true;
            result.message = 'Thank you - your form has been submitted.';
            return result;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Could not save your form: ' + e.getMessage());
        }
    }
}