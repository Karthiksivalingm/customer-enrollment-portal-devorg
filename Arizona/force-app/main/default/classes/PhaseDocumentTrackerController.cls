public with sharing class PhaseDocumentTrackerController {
    // Valid status values a field is expected to hold. Anything else is
    // treated as 'Not Started' so the UI never breaks on an unexpected value.
    // NEW: 'Not Needed' added so a document can be explicitly marked as not
    // required for this contact. Rows in that state keep their dropdown
    // enabled (so it can be switched back) but the Upload button is hidden
    // in the LWC and uploadDocument() rejects the upload server-side too.
    private static final Set<String> KNOWN_STATUSES = new Set<String>{
        'Completed', 'Pending', 'Rejected', 'Expired', 'Not Needed'
    };

    // NOTE: SAM and OIG used to be tracked on the Boolean checkbox fields
    // SAM__c/OIG__c, which could only ever hold true/false and needed
    // special-case handling everywhere a status String was written
    // ('Illegal assignment from String to Boolean' on upload, and an
    // unhandled DmlException trying to null a checkbox on delete). They
    // are now tracked on dedicated text/picklist fields, SAM_Status__c
    // and OIG_Status__c, so they behave exactly like every other status
    // document in this class - no boolean special-casing needed anywhere
    // below. The old SAM__c/OIG__c checkboxes are no longer read or
    // written by this class.

    @AuraEnabled(cacheable=true)
    public static UserContext getCurrentUserContext() {
        try {
            // Confirms the running user record exists; ContactId itself is
            // resolved separately via getCurrentUserContactId() below,
            // which is safe even in orgs where that field doesn't exist.
            User currentUser = [
                SELECT Id
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            String contactId = getCurrentUserContactId();
            String division = 'none';
            String userLanguage = 'english'; // default
            String drivingStatus = 'none';
            String contractType = 'none';
            String serviceType = 'none';
            String livingStatus = 'none';
            if (String.isNotEmpty(contactId)) {
                Contact con = [
                    SELECT
                        Id,
                        Division__c,
                        Preferred_Language__c,
                        Driving_Status__c,
                        Contract_Type__c,
                        Service__c,
                        Living_Status__c
                    FROM Contact
                    WHERE Id = :contactId
                    WITH USER_MODE
                    LIMIT 1
                ];
                if (con != null) {
                    if (String.isNotEmpty(con.Division__c)) {
                        division = con.Division__c.toLowerCase();
                    }
                    if (String.isNotEmpty(con.Preferred_Language__c)) {
                        String prefLang = con.Preferred_Language__c.toLowerCase();
                        if (prefLang.contains('spanish') || prefLang.contains('español')) {
                            userLanguage = 'spanish';
                        } else if (prefLang.contains('english')) {
                            userLanguage = 'english';
                        }
                    }
                    if (String.isNotEmpty(con.Driving_Status__c)) {
                        drivingStatus = con.Driving_Status__c.toLowerCase();
                    }
                    if (String.isNotEmpty(con.Contract_Type__c)) {
                        String rawContract = con.Contract_Type__c.toLowerCase();
                        if (rawContract.contains('1099')) {
                            contractType = '1099';
                        } else if (rawContract.contains('w4') || rawContract.contains('w-4') || rawContract.contains('w2') || rawContract.contains('w-2')) {
                            contractType = 'w4';
                        } else {
                            contractType = rawContract;
                        }
                    }
                    // UPDATED: Service__c is now multi-select picklist
                    // Multi-select values are separated by semicolons: "atc;hah;rsp"
                    if (String.isNotEmpty(con.Service__c)) {
                        serviceType = parseServiceType(con.Service__c);
                    }
                    if (String.isNotEmpty(con.Living_Status__c)) {
                        String rawLiving = con.Living_Status__c.toLowerCase();
                        if (rawLiving.contains('live-in') || rawLiving.contains('live in')) {
                            livingStatus = 'live-in';
                        } else {
                            livingStatus = rawLiving;
                        }
                    }
                }
            }
            return new UserContext(
                division,
                userLanguage,
                contactId,
                drivingStatus,
                contractType,
                serviceType,
                livingStatus
            );
        } catch (Exception e) {
            throwAura('Error retrieving user context: ' + e.getMessage());
            return null;
        }
    }

    private static String parseServiceType(String serviceValue) {
        if (String.isEmpty(serviceValue)) {
            return 'none';
        }
        String rawService = serviceValue.toLowerCase();

        // Check for each service type in priority order
        if (rawService.contains('atc')) {
            return 'atc';
        } else if (rawService.contains('hah') || rawService.contains('habilitation')) {
            return 'hah';
        } else if (rawService.contains('rsp') || rawService.contains('respite')) {
            return 'rsp';
        } else {
            return rawService;
        }
    }
    private static Set<String> parseAllServiceTypes(String serviceValue) {
        Set<String> serviceTypes = new Set<String>();

        if (String.isEmpty(serviceValue)) {
            return serviceTypes;
        }
        String rawService = serviceValue.toLowerCase();

        if (rawService.contains('atc')) {
            serviceTypes.add('atc');
        }
        if (rawService.contains('hah') || rawService.contains('habilitation')) {
            serviceTypes.add('hah');
        }
        if (rawService.contains('rsp') || rawService.contains('respite')) {
            serviceTypes.add('rsp');
        }

        return serviceTypes;
    }

    @AuraEnabled(cacheable=true)
    public static List<PhaseTab> getPhaseTabs(String division, String language) {
        try {
            List<PhaseTab> tabs = new List<PhaseTab>();
            tabs.add(new PhaseTab('Based Forms', null, true, null));
            tabs.add(new PhaseTab('Documents and Certifications', null, isPhaseApplicable('Documents', division), 'Documents'));
            tabs.add(new PhaseTab('Pay and Tax Forms', null, isPhaseApplicable('PayForms', division), 'Tax Forms'));
            tabs.add(new PhaseTab('Service Forms', null, isPhaseApplicable('ServiceForms', division), 'Service Forms'));
            return tabs;
        } catch (Exception e) {
            throwAura('Error retrieving phase tabs: ' + e.getMessage());
            return null;
        }
    }
    private static Boolean isPhaseApplicable(String phaseType, String division) {
        return !String.isEmpty(division) && division != 'none';
    }

    @AuraEnabled(cacheable=true)
    public static List<StatusDocument> getCertificationAndDriverDocuments(String contactId) {
        List<StatusDocument> results = new List<StatusDocument>();
        if (String.isBlank(contactId)) {
            return results;
        }
        try {
            List<Contact> contacts = [
                SELECT Id,
                       Age_Verification_Back__c, Age_Verification_Front__c,
                       CBC_Annual__c,
                       Fingerprint_Clearance_Card_Back__c, Fingerprint_Clearance_Card_Front__c,
                       Notarized_Criminal_History__c,
                       Social_Security_Card_Back__c, Social_Security_Card_Front__c,
                       StatusArticle9__c, CPR_Certification_Card__c,
                       First_Aid_Certification_Card__c,
                       Driver_s_License__c, Liability_Insurance__c, Vehicle_Registration__c,
                       Driving_Status__c,
                       SAM_Status__c,
                       OIG_Status__c,
                       // NEW: three Reference document status fields
                       Reference_1_Document__c,
                       Reference_2_Document__c,
                       Reference_3_Document__c
                FROM Contact
                WHERE Id = :contactId
                WITH USER_MODE
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                return results;
            }
            Contact con = contacts[0];
            // ---- Auto Documents ----
            results.add(new StatusDocument('Age Verification (Back)', 'Age_Verification_Back__c', con.Age_Verification_Back__c, 'auto'));
            results.add(new StatusDocument('Age Verification (Front)', 'Age_Verification_Front__c', con.Age_Verification_Front__c, 'auto'));
            results.add(new StatusDocument('CBC Annual', 'CBC_Annual__c', con.CBC_Annual__c, 'auto'));
            results.add(new StatusDocument('Fingerprint Clearance Card (Back)', 'Fingerprint_Clearance_Card_Back__c', con.Fingerprint_Clearance_Card_Back__c, 'auto'));
            results.add(new StatusDocument('Fingerprint Clearance Card (Front)', 'Fingerprint_Clearance_Card_Front__c', con.Fingerprint_Clearance_Card_Front__c, 'auto'));
            results.add(new StatusDocument('Notarized Criminal History', 'Notarized_Criminal_History__c', con.Notarized_Criminal_History__c, 'auto'));
            results.add(new StatusDocument('Social Security Card (Back)', 'Social_Security_Card_Back__c', con.Social_Security_Card_Back__c, 'auto'));
            results.add(new StatusDocument('Social Security Card (Front)', 'Social_Security_Card_Front__c', con.Social_Security_Card_Front__c, 'auto'));
            results.add(new StatusDocument('SAM', 'SAM_Status__c', con.SAM_Status__c, 'auto'));
            results.add(new StatusDocument('OIG', 'OIG_Status__c', con.OIG_Status__c, 'auto'));
            // ---- NEW: Reference Documents (same 'auto' group, so they
            // render under the existing "Basic Documents Status" heading
            // and behave exactly like Age Verification (Back)) ----
            results.add(new StatusDocument('Reference 1 Document', 'Reference_1_Document__c', con.Reference_1_Document__c, 'auto'));
            results.add(new StatusDocument('Reference 2 Document', 'Reference_2_Document__c', con.Reference_2_Document__c, 'auto'));
            results.add(new StatusDocument('Reference 3 Document', 'Reference_3_Document__c', con.Reference_3_Document__c, 'auto'));
            // ---- Certifications ----
            results.add(new StatusDocument('Article 9 Certification', 'StatusArticle9__c', con.StatusArticle9__c, 'certification'));
            results.add(new StatusDocument('CPR Certification Card', 'CPR_Certification_Card__c', con.CPR_Certification_Card__c, 'certification'));
            results.add(new StatusDocument('First Aid Certification Card', 'First_Aid_Certification_Card__c', con.First_Aid_Certification_Card__c, 'certification'));
            // ---- Driver Documents (gated) ----
            Boolean isDriver = isDrivingStatusDriver(con.Driving_Status__c);
            if (isDriver) {
                results.add(new StatusDocument('Driver\'s License', 'Driver_s_License__c', con.Driver_s_License__c, 'driver'));
                results.add(new StatusDocument('Liability Insurance', 'Liability_Insurance__c', con.Liability_Insurance__c, 'driver'));
                results.add(new StatusDocument('Vehicle Registration', 'Vehicle_Registration__c', con.Vehicle_Registration__c, 'driver'));
            }
            return results;
        } catch (Exception e) {
            throwAura('Error retrieving certification/driver documents: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FormStatusDocument> getDriverFormDocuments(String contactId, String drivingStatus, String language) {
        List<FormStatusDocument> results = new List<FormStatusDocument>();
        if (String.isBlank(contactId)) {
            return results;
        }
        try {
            List<Contact> contacts = [
                SELECT Id,
                       Employee_Vehicle_Checklist_Eng__c,
                       Motor_Vehicle_Release_English__c,
                       Transportation_Policy_English__c,
                       Employee_Vehicle_Checklist_Spanish__c,
                       Motor_Vehicle_Release_Spanish__c,
                       Transportation_Policy_Spanish__c,
                       Non_Driver_Agreement__c,
                       Non_Driver_Agreement_Spanish__c
                FROM Contact
                WHERE Id = :contactId
                WITH USER_MODE
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                return results;
            }
            Contact con = contacts[0];
            Boolean isDriver = isDrivingStatusDriver(drivingStatus);
            Boolean isSpanish = String.isNotBlank(language) && language.toLowerCase() == 'spanish';
            if (isDriver) {
                if (isSpanish) {
                    results.add(new FormStatusDocument(
                        'Employee Vehicle Checklist - Spanish',
                        'Employee_Vehicle_Checklist_Spanish__c',
                        con.Employee_Vehicle_Checklist_Spanish__c,
                        'EmployeeVehicleChecklistSpanish',
                        'driverForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Motor Vehicle Release - Spanish',
                        'Motor_Vehicle_Release_Spanish__c',
                        con.Motor_Vehicle_Release_Spanish__c,
                        'MotorVehicleReleaseSpanish',
                        'driverForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Transportation Policy - Spanish',
                        'Transportation_Policy_Spanish__c',
                        con.Transportation_Policy_Spanish__c,
                        'TransportationPolicySpanish',
                        'driverForms'
                    ));
                } else {
                    results.add(new FormStatusDocument(
                        'Employee Vehicle Checklist - Eng',
                        'Employee_Vehicle_Checklist_Eng__c',
                        con.Employee_Vehicle_Checklist_Eng__c,
                        'EmployeeVehicleChecklistEnglish',
                        'driverForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Motor Vehicle Release - English',
                        'Motor_Vehicle_Release_English__c',
                        con.Motor_Vehicle_Release_English__c,
                        'MotorVehicleReleaseEnglish',
                        'driverForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Transportation Policy - English',
                        'Transportation_Policy_English__c',
                        con.Transportation_Policy_English__c,
                        'TransportationPolicyEnglish',
                        'driverForms'
                    ));
                }
            } else {
                if (isSpanish) {
                    results.add(new FormStatusDocument(
                        'Non-Driver Agreement - Spanish',
                        'Non_Driver_Agreement_Spanish__c',
                        con.Non_Driver_Agreement_Spanish__c,
                        'NonDriverAgreementSpanish',
                        'nonDriverForms'
                    ));
                } else {
                    results.add(new FormStatusDocument(
                        'Non-Driver Agreement',
                        'Non_Driver_Agreement__c',
                        con.Non_Driver_Agreement__c,
                        'NonDriverAgreementEnglish',
                        'nonDriverForms'
                    ));
                }
            }
            return results;
        } catch (Exception e) {
            throwAura('Error retrieving driver/non-driver forms: ' + e.getMessage());
            return null;
        }
    }
    private static Boolean isDrivingStatusDriver(String drivingStatus) {
        return String.isNotBlank(drivingStatus)
            && drivingStatus.toLowerCase().contains('driver')
            && !drivingStatus.toLowerCase().contains('non');
    }

    @AuraEnabled(cacheable=true)
    public static List<StatusDocument> getServiceFormDocuments(String contactId, String serviceType) {
        List<StatusDocument> results = new List<StatusDocument>();
        if (String.isBlank(contactId) || String.isBlank(serviceType)) {
            return results;
        }
        try {
            List<Contact> contacts = [
                SELECT Id, DCW_1_Certificate_Status__c, DCW_2_Certificate_Status__c,
                       HAH_Certificate__c
                FROM Contact
                WHERE Id = :contactId
                WITH USER_MODE
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                return results;
            }
            Contact con = contacts[0];
            if (serviceType == 'atc') {
                results.add(new StatusDocument('DCW 1 Certificate', 'DCW_1_Certificate_Status__c', con.DCW_1_Certificate_Status__c, 'service'));
                results.add(new StatusDocument('DCW 2 Certificate', 'DCW_2_Certificate_Status__c', con.DCW_2_Certificate_Status__c, 'service'));
            } else if (serviceType == 'hah') {
                results.add(new StatusDocument('HAH Certificate', 'HAH_Certificate__c', con.HAH_Certificate__c, 'service'));
            }
            // else if (serviceType == 'rsp') { ... add once fields are confirmed ... }
            return results;
        } catch (Exception e) {
            throwAura('Error retrieving service form documents: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FormStatusDocument> getServiceAgreementForms(String contactId, String serviceType, String language) {
        List<FormStatusDocument> results = new List<FormStatusDocument>();
        if (String.isBlank(contactId) || String.isBlank(serviceType)) {
            return results;
        }
        try {
            List<Contact> contacts = [
                SELECT Id,
                       // ATC
                       Attendant_Care_Service_Work_Eng__c,
                       Attendant_Care_Service_Work_Agreement__c,
                       DCW_Guidelines_Acknowledgement_Engl__c,
                       DCW_Guidelines_Acknowledgement_Span__c,
                       // HAH
                       Habillitation_Work_Agreement_English__c,
                       Habillitation_Work_Agreement_Spanish__c,
                       // RSP
                       Respite_Provider_Job_Description_Eng__c,
                       Respite_Provider_Job_Description_Spani__c,
                       Respite_Sleep_Policy_English__c,
                       Respite_Sleep_Policy_Spanish__c
                FROM Contact
                WHERE Id = :contactId
                WITH USER_MODE
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                return results;
            }
            Contact con = contacts[0];
            Boolean isSpanish = String.isNotBlank(language) && language.toLowerCase() == 'spanish';
            if (serviceType == 'atc') {
                if (isSpanish) {
                    results.add(new FormStatusDocument(
                        'Attendant Care Service Work Agreement - Spanish',
                        'Attendant_Care_Service_Work_Agreement__c',
                        con.Attendant_Care_Service_Work_Agreement__c,
                        'AttendantCareServiceWorkAgreementSpanish',
                        'serviceAgreementForms'
                    ));
                    results.add(new FormStatusDocument(
                        'DCW Guidelines Acknowledgement - Spanish',
                        'DCW_Guidelines_Acknowledgement_Span__c',
                        con.DCW_Guidelines_Acknowledgement_Span__c,
                        'DCWGuidelinesAcknowledgementSpanish',
                        'serviceAgreementForms'
                    ));
                } else {
                    results.add(new FormStatusDocument(
                        'Attendant Care Service Work Agreement - English',
                        'Attendant_Care_Service_Work_Eng__c',
                        con.Attendant_Care_Service_Work_Eng__c,
                        'AttendantCareServiceWorkAgreementEnglish',
                        'serviceAgreementForms'
                    ));
                    results.add(new FormStatusDocument(
                        'DCW Guidelines Acknowledgement - English',
                        'DCW_Guidelines_Acknowledgement_Engl__c',
                        con.DCW_Guidelines_Acknowledgement_Engl__c,
                        'DCWGuidelinesAcknowledgementEnglish',
                        'serviceAgreementForms'
                    ));
                }
            } else if (serviceType == 'hah') {
                if (isSpanish) {
                    results.add(new FormStatusDocument(
                        'Habillitation Work Agreement - Spanish',
                        'Habillitation_Work_Agreement_Spanish__c',
                        con.Habillitation_Work_Agreement_Spanish__c,
                        'HabilitationWorkAgreementSpanish',
                        'serviceAgreementForms'
                    ));
                } else {
                    results.add(new FormStatusDocument(
                        'Habillitation Work Agreement - English',
                        'Habillitation_Work_Agreement_English__c',
                        con.Habillitation_Work_Agreement_English__c,
                        'HabilitationWorkAgreementEnglish',
                        'serviceAgreementForms'
                    ));
                }
            } else if (serviceType == 'rsp') {
                if (isSpanish) {
                    results.add(new FormStatusDocument(
                        'Respite Provider Job Description - Spanish',
                        'Respite_Provider_Job_Description_Spani__c',
                        con.Respite_Provider_Job_Description_Spani__c,
                        'RespiteProviderJobDescriptionSpanish',
                        'serviceAgreementForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Respite Sleep Policy - Spanish',
                        'Respite_Sleep_Policy_Spanish__c',
                        con.Respite_Sleep_Policy_Spanish__c,
                        'RespiteSleepPolicySpanish',
                        'serviceAgreementForms'
                    ));
                } else {
                    results.add(new FormStatusDocument(
                        'Respite Provider Job Description - English',
                        'Respite_Provider_Job_Description_Eng__c',
                        con.Respite_Provider_Job_Description_Eng__c,
                        'RespiteProviderJobDescriptionEnglish',
                        'serviceAgreementForms'
                    ));
                    results.add(new FormStatusDocument(
                        'Respite Sleep Policy - English',
                        'Respite_Sleep_Policy_English__c',
                        con.Respite_Sleep_Policy_English__c,
                        'RespiteSleepPolicyEnglish',
                        'serviceAgreementForms'
                    ));
                }
            }
            return results;
        } catch (Exception e) {
            throwAura('Error retrieving service agreement forms: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<StatusDocument> getServiceFormDocumentsForContact(Id contactId) {
        if (contactId == null) {
            return new List<StatusDocument>();
        }
        List<Contact> contacts = [
            SELECT Id, Service__c
            FROM Contact
            WHERE Id = :contactId
            WITH USER_MODE
            LIMIT 1
        ];
        if (contacts.isEmpty()) {
            return new List<StatusDocument>();
        }
        List<StatusDocument> results = new List<StatusDocument>();

        // UPDATED: Handle multi-select picklist
        // Get ALL service types from the field
        Set<String> serviceTypes = parseAllServiceTypes(contacts[0].Service__c);

        // Query once for all data
        List<Contact> fullContacts = [
            SELECT Id, DCW_1_Certificate_Status__c, DCW_2_Certificate_Status__c,
                   HAH_Certificate__c
            FROM Contact
            WHERE Id = :contactId
            WITH USER_MODE
            LIMIT 1
        ];
        if (fullContacts.isEmpty()) {
            return results;
        }
        Contact con = fullContacts[0];
        // Add results for each service type
        if (serviceTypes.contains('atc')) {
            results.add(new StatusDocument('DCW 1 Certificate', 'DCW_1_Certificate_Status__c', con.DCW_1_Certificate_Status__c, 'service'));
            results.add(new StatusDocument('DCW 2 Certificate', 'DCW_2_Certificate_Status__c', con.DCW_2_Certificate_Status__c, 'service'));
        }

        if (serviceTypes.contains('hah')) {
            results.add(new StatusDocument('HAH Certificate', 'HAH_Certificate__c', con.HAH_Certificate__c, 'service'));
        }

        if (serviceTypes.contains('rsp')) {
            // TODO: add RSP fields once confirmed
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, FileInfo> getUploadedFileInfo(Id contactId) {
        Map<String, FileInfo> result = new Map<String, FileInfo>();
        if (contactId == null) {
            return result;
        }
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate,
                   ContentDocument.LatestPublishedVersion.Description
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
            WITH USER_MODE
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        // Newest-first, so the first match per field wins - naturally
        // surfaces the most recent file if something was re-uploaded.
        for (ContentDocumentLink link : links) {
            String fileTitle = link.ContentDocument.Title;
            String description = link.ContentDocument.LatestPublishedVersion != null
                ? link.ContentDocument.LatestPublishedVersion.Description
                : null;
            String fieldApiName;
            String uploadSource;
            String fileName;
            if (String.isNotBlank(description) && description.contains('::')) {
                // ---- CURRENT scheme: tag lives in Description ----
                Integer delim = description.indexOf('::');
                fieldApiName = description.substring(0, delim);
                String candidateSource = description.substring(delim + 2);
                uploadSource = (candidateSource == 'internal' || candidateSource == 'portal') ? candidateSource : null;
                fileName = fileTitle; // Title is already just the plain filename
            } else if (String.isNotBlank(fileTitle) && fileTitle.contains('::')) {
                // ---- LEGACY fallback: tag was baked into Title ----
                Integer firstDelim = fileTitle.indexOf('::');
                fieldApiName = fileTitle.substring(0, firstDelim);
                String remainder = fileTitle.substring(firstDelim + 2);
                uploadSource = null;
                fileName = remainder;
                Integer secondDelim = remainder.indexOf('::');
                if (secondDelim >= 0) {
                    String candidateSource = remainder.substring(0, secondDelim);
                    if (candidateSource == 'internal' || candidateSource == 'portal') {
                        uploadSource = candidateSource;
                        fileName = remainder.substring(secondDelim + 2);
                    }
                }
            } else {
                // Neither scheme matched - not one of our tracked uploads
                // (e.g. an unrelated file someone attached directly via
                // the standard Files related list).
                continue;
            }
            if (!result.containsKey(fieldApiName)) {
                result.put(fieldApiName, new FileInfo(
                    link.ContentDocumentId,
                    fileName,
                    uploadSource
                ));
            }
        }
        return result;
    }

    @AuraEnabled
    public static void tagUploadedFile(Id contentDocumentId, String fieldApiName, String uploadSource) {
        String source = (uploadSource == 'internal') ? 'internal' : 'portal';
        List<ContentVersion> versions = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            WITH USER_MODE
            LIMIT 1
        ];
        if (versions.isEmpty()) {
            return;
        }
        ContentVersion cv = versions[0];
        cv.Description = fieldApiName + '::' + source;
        update cv;
    }

    @AuraEnabled
    public static void uploadDocument(Id contactId, String fieldApiName, String base64Data, String fileName, String uploadSource) {
        Set<String> allowedFields = new Set<String>{
            'Age_Verification_Back__c', 'Age_Verification_Front__c', 'CBC_Annual__c',
            'Fingerprint_Clearance_Card_Back__c', 'Fingerprint_Clearance_Card_Front__c',
            'Notarized_Criminal_History__c', 'Social_Security_Card_Back__c', 'Social_Security_Card_Front__c',
            'StatusArticle9__c', 'CPR_Certification_Card__c', 'First_Aid_Certification_Card__c',
            'Driver_s_License__c', 'Liability_Insurance__c', 'Vehicle_Registration__c',
            'Employee_Vehicle_Checklist_Eng__c', 'Motor_Vehicle_Release_English__c',
            'Transportation_Policy_English__c', 'Employee_Vehicle_Checklist_Spanish__c',
            'Motor_Vehicle_Release_Spanish__c', 'Transportation_Policy_Spanish__c',
            'Non_Driver_Agreement__c', 'Non_Driver_Agreement_Spanish__c',
            'DCW_1_Certificate_Status__c', 'DCW_2_Certificate_Status__c', 'HAH_Certificate__c',
            'SAM_Status__c', 'OIG_Status__c',
            // NEW: Reference documents
            'Reference_1_Document__c', 'Reference_2_Document__c', 'Reference_3_Document__c'
        };
        if (String.isBlank(contactId) || String.isBlank(fieldApiName) || String.isBlank(base64Data) || String.isBlank(fileName)) {
            throwAura('Missing required upload parameters.');
        }
        if (!allowedFields.contains(fieldApiName)) {
            throwAura('Field is not an allowed status field: ' + fieldApiName);
        }
        if (UserInfo.getUserType() == 'Guest') {
            throwAura('You must be logged in to upload a document. Please sign in and try again.');
        }
        validateContactOwnership(contactId);
        // ---- NEW: server-side guard for the "Not Needed" status. The LWC
        // already hides the Upload button for these rows; this stops a
        // direct Apex/API call from slipping a file in behind that. ----
        if (isFieldNotNeeded(contactId, fieldApiName)) {
            throwAura('This document is marked "Not Needed" and cannot be uploaded.');
        }
        String source = (uploadSource == 'portal') ? 'portal' : 'internal';
        ContentVersion newCv = new ContentVersion();
        newCv.Title = fileName;
        newCv.PathOnClient = fileName;
        newCv.Description = fieldApiName + '::' + source;
        newCv.VersionData = EncodingUtil.base64Decode(base64Data);
        insert newCv;
        List<ContentVersion> insertedVersions = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newCv.Id LIMIT 1
        ];
        if (insertedVersions.isEmpty() || insertedVersions[0].ContentDocumentId == null) {
            throwAura('Unable to retrieve the uploaded file right after saving it.');
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedVersions[0].ContentDocumentId;
        cdl.LinkedEntityId = contactId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        // Reuses markDocumentPending(), which itself now branches on user
        // type (direct write for internal, Platform Event for portal) -
        // see that method's own comments.
        markDocumentPending(contactId, fieldApiName);
    }

    // NEW: reads the current value of a status field at runtime and reports
    // whether it is 'Not Needed'. Uses DYNAMIC SOQL + sObject.get() for the
    // same reason getCurrentUserContactId() does - the field name only
    // exists as a String here, so it can't be referenced with dot notation.
    private static Boolean isFieldNotNeeded(Id contactId, String fieldApiName) {
        try {
            String soql = 'SELECT ' + String.escapeSingleQuotes(fieldApiName) +
                          ' FROM Contact WHERE Id = :contactId LIMIT 1';
            List<SObject> rows = Database.query(soql);
            if (rows.isEmpty()) {
                return false;
            }
            Object rawValue = rows[0].get(fieldApiName);
            return rawValue != null && String.valueOf(rawValue) == 'Not Needed';
        } catch (Exception e) {
            // Field not readable/queryable for this user - fall back to the
            // previous behaviour rather than blocking a legitimate upload.
            System.debug('Not Needed check skipped for ' + fieldApiName + ': ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static void markDocumentPending(String contactId, String fieldApiName) {
        Set<String> allowedFields = new Set<String>{
            // Auto Documents - matches getCertificationAndDriverDocuments() query
            'Age_Verification_Back__c', 'Age_Verification_Front__c', 'CBC_Annual__c',
            'Fingerprint_Clearance_Card_Back__c', 'Fingerprint_Clearance_Card_Front__c',
            'Notarized_Criminal_History__c', 'Social_Security_Card_Back__c', 'Social_Security_Card_Front__c',
            'SAM_Status__c', 'OIG_Status__c',
            // NEW: Reference documents
            'Reference_1_Document__c', 'Reference_2_Document__c', 'Reference_3_Document__c',
            // Certifications
            'StatusArticle9__c', 'CPR_Certification_Card__c', 'First_Aid_Certification_Card__c',
            // Driver Documents
            'Driver_s_License__c', 'Liability_Insurance__c', 'Vehicle_Registration__c',
            // Driver Forms / Non-Driver Forms
            'Employee_Vehicle_Checklist_Eng__c', 'Motor_Vehicle_Release_English__c',
            'Transportation_Policy_English__c', 'Employee_Vehicle_Checklist_Spanish__c',
            'Motor_Vehicle_Release_Spanish__c', 'Transportation_Policy_Spanish__c',
            'Non_Driver_Agreement__c', 'Non_Driver_Agreement_Spanish__c',
            // Service Forms - existing file-upload/status-badge certificates
            'DCW_1_Certificate_Status__c', 'DCW_2_Certificate_Status__c', 'HAH_Certificate__c',
            // Service Forms - work-agreement/policy forms (confirmed field names)
            'Attendant_Care_Service_Work_Eng__c', 'Attendant_Care_Service_Work_Agreement__c',
            'DCW_Guidelines_Acknowledgement_Engl__c', 'DCW_Guidelines_Acknowledgement_Span__c',
            'Habillitation_Work_Agreement_English__c', 'Habillitation_Work_Agreement_Spanish__c',
            'Respite_Provider_Job_Description_Eng__c', 'Respite_Provider_Job_Description_Spani__c',
            'Respite_Sleep_Policy_English__c', 'Respite_Sleep_Policy_Spanish__c'
        };
        // ---- Validation happens OUTSIDE the try/catch below, so these
        // AuraHandledExceptions are never re-caught-and-rewrapped. ----
        if (String.isBlank(contactId) || String.isBlank(fieldApiName)) {
            throwAura('Missing contactId or fieldApiName.');
        }
        if (!allowedFields.contains(fieldApiName)) {
            throwAura('Field is not an allowed status field: ' + fieldApiName);
        }
        // ---- Guest User check (kept as a defensive check even though
        // the confirmed cause turned out to be CspLitePortal, not Guest -
        // no harm leaving it in place). ----
        if (UserInfo.getUserType() == 'Guest') {
            throwAura('You must be logged in to update this document. Please sign in and try again.');
        }
        validateContactOwnership(contactId);
        if (!isCurrentUserPortalUser()) {
            // INTERNAL user (e.g. the recordCertificateDocuments upload
            // button on the Contact record page): write directly and
            // synchronously. No CspLitePortal restriction applies here,
            // so there's no reason to route through the Platform Event -
            // doing so was the actual root cause of internal uploads
            // never reaching 'Pending'.
            Contact con = new Contact(Id = contactId);
            con.put(fieldApiName, 'Pending');
            update con;
            return;
        }
        // ---- PORTAL (CspLitePortal / High-Volume Customer Portal
        // license) user: that license type cannot perform direct DML on
        // Contact under ANY circumstances. Publishing a Platform Event
        // is NOT a standard-object DML, so it isn't subject to that
        // restriction. DocumentStatusUpdateEventTrigger.trigger
        // subscribes to this event and performs the actual Contact
        // update as the "Automated Process" system user instead of as
        // this CspLitePortal user.
        Document_Status_Update_Event__e evt = new Document_Status_Update_Event__e(
            Contact_Id_c__c = contactId,
            Field_Api_Name__c = fieldApiName
        );
        Database.SaveResult result = EventBus.publish(evt);
        if (!result.isSuccess()) {
            String errors = '';
            for (Database.Error err : result.getErrors()) {
                errors += err.getMessage() + '; ';
            }
            throwAura('Error updating document status: ' + errors);
        }
    }

    // Returns the running user's Contact Id (set only for
    // portal/community/CspLite-licensed users), or null if they have none
    // or the ContactId field isn't exposed at all in this org (e.g. Digital
    // Experiences/Communities has never been enabled here).
    //
    // This uses DYNAMIC SOQL (Database.query with a String) and
    // sObject.get('ContactId') instead of a static "SELECT Id, ContactId
    // FROM User" query with dot-notation (someUser.ContactId). Apex
    // validates every field referenced in STATIC SOQL, and every
    // dot-notation field access, against the org's schema at COMPILE
    // TIME - so in an org where User.ContactId doesn't exist, a
    // try/catch around a static query does NOT help; the whole class
    // fails to compile/deploy with "No such column 'ContactId' on
    // entity 'User'" before any code ever runs. Dynamic SOQL and
    // sObject.get() are both resolved at RUNTIME instead, so the
    // try/catch here actually works as intended.
    private static String getCurrentUserContactId() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<SObject> currentUsers = Database.query(
                'SELECT Id, ContactId FROM User WHERE Id = :currentUserId LIMIT 1'
            );
            if (currentUsers.isEmpty()) {
                return null;
            }
            Object contactIdValue = currentUsers[0].get('ContactId');
            return contactIdValue == null ? null : String.valueOf(contactIdValue);
        } catch (Exception e) {
            // ContactId field not available on User in this org (or any
            // other query failure) - treat the running user as internal.
            System.debug('ContactId field not available on User: ' + e.getMessage());
            return null;
        }
    }

    private static Boolean isCurrentUserPortalUser() {
        return String.isNotBlank(getCurrentUserContactId());
    }

   public static void validateContactOwnership(String contactId) {
        String currentUserContactId = getCurrentUserContactId();
        if (String.isBlank(currentUserContactId)) {
            return; // internal user (or ContactId unavailable) - no additional restriction from this method
        }
        if (currentUserContactId != contactId) {
            throwAura('You do not have permission to update this record.');
        }
    }

    private static void throwAura(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDocument(String contentDocumentId) {
        try {
            Map<String, Object> documentInfo = new Map<String, Object>();
            if (String.isEmpty(contentDocumentId)) {
                return documentInfo;
            }
            ContentDocument doc = [
                SELECT Id, Title, Description
                FROM ContentDocument
                WHERE Id = :contentDocumentId
                WITH USER_MODE
                LIMIT 1
            ];
            documentInfo.put('Id', doc.Id);
            documentInfo.put('Title', doc.Title);
            documentInfo.put('Description', doc.Description);
            return documentInfo;
        } catch (Exception e) {
            System.debug('Error retrieving document: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<DocumentStatus> getDocumentSignatureStatuses(String contactId) {
        List<DocumentStatus> statuses = new List<DocumentStatus>();
        if (String.isBlank(contactId)) {
            return statuses;
        }
        try {
            // TODO once Adobe Sign is integrated, replace with a real query.
        } catch (Exception e) {
            System.debug('Error retrieving signature statuses: ' + e.getMessage());
        }
        return statuses;
    }

    @AuraEnabled
    public static void updateDocumentStatusInternal(Id contactId, String fieldApiName, String newStatus) {
        Set<String> allowedFields = new Set<String>{
            'Age_Verification_Back__c', 'Age_Verification_Front__c', 'CBC_Annual__c',
            'Fingerprint_Clearance_Card_Back__c', 'Fingerprint_Clearance_Card_Front__c',
            'Notarized_Criminal_History__c', 'Social_Security_Card_Back__c', 'Social_Security_Card_Front__c',
            'StatusArticle9__c', 'CPR_Certification_Card__c', 'First_Aid_Certification_Card__c',
            'Driver_s_License__c', 'Liability_Insurance__c', 'Vehicle_Registration__c',
            'DCW_1_Certificate_Status__c', 'DCW_2_Certificate_Status__c', 'HAH_Certificate__c',
            'SAM_Status__c', 'OIG_Status__c',
            // NEW: Reference documents
            'Reference_1_Document__c', 'Reference_2_Document__c', 'Reference_3_Document__c'
        };
        if (contactId == null || String.isBlank(fieldApiName) || String.isBlank(newStatus)) {
            throwAura('Missing contactId, fieldApiName, or newStatus.');
        }
        if (!allowedFields.contains(fieldApiName)) {
            throwAura('Field is not an allowed status field: ' + fieldApiName);
        }
        Contact con = new Contact(Id = contactId);
        if (newStatus == 'Not Started') {
            con.put(fieldApiName, null);
        } else {
            // 'Not Needed' is part of KNOWN_STATUSES now, so it passes this
            // check and is stored on the field like any other status value.
            if (!KNOWN_STATUSES.contains(newStatus)) {
                throwAura('Invalid status value: ' + newStatus);
            }
            con.put(fieldApiName, newStatus);
        }
        update con;
    }

    @AuraEnabled
    public static void deleteUploadedDocument(Id contactId, Id contentDocumentId, String fieldApiName) {
        if (contactId == null || contentDocumentId == null || String.isBlank(fieldApiName)) {
            throwAura('Missing contactId, contentDocumentId, or fieldApiName.');
        }
        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            AND LinkedEntityId = :contactId
            WITH USER_MODE
            LIMIT 1
        ];
        if (links.isEmpty()) {
            throwAura('This file is not linked to the specified record.');
        }
        validateContactOwnership(contactId);
        try {
            PhaseDocumentPrivilegedUpdater.deleteContentDocumentPrivileged(contentDocumentId);
        } catch (Exception e) {
            throwAura('Error removing file: ' + e.getMessage());
        }
        // Reset status back to blank ("Not Started") now that the file is
        // gone. Internal users: direct update. Portal users: same
        // Platform-Event workaround markDocumentPending() uses - see
        // resetDocumentStatusViaEvent() below, PENDING your trigger's
        // exact fields before I can finalize that part.
        Boolean isPortalUser = isCurrentUserPortalUser();
        if (!isPortalUser) {
            resetStatusDirect(contactId, fieldApiName);
        } else {
            // TODO: publish reset event once Document_Status_Update_Event__e
            // supports carrying a "reset to blank" instruction - see below.
        }
    }

    private static void resetStatusDirect(Id contactId, String fieldApiName) {
        Contact con = new Contact(Id = contactId);
        con.put(fieldApiName, null);
        update con;
    }
    @AuraEnabled
    public static void logDocumentAccess(String documentId, String action) {
        try {
            Task auditLog = new Task(
                Subject = 'Document Access: ' + action,
                Description = 'Document ID: ' + documentId,
                OwnerId = UserInfo.getUserId(),
                ActivityDate = Date.today(),
                Status = 'Completed'
            );
            insert auditLog;
        } catch (Exception e) {
            System.debug('Error logging document access: ' + e.getMessage());
        }
    }
    // ========== INNER CLASSES ==========
    public class UserContext {
        @AuraEnabled public String division;
        @AuraEnabled public String preferredLanguage;
        @AuraEnabled public String contactId;
        @AuraEnabled public String drivingStatus;
        @AuraEnabled public String contractType;
        @AuraEnabled public String serviceType;
        @AuraEnabled public String livingStatus;
        public UserContext(
            String division,
            String preferredLanguage,
            String contactId,
            String drivingStatus,
            String contractType,
            String serviceType,
            String livingStatus
        ) {
            this.division = division;
            this.preferredLanguage = preferredLanguage;
            this.contactId = contactId;
            this.drivingStatus = drivingStatus;
            this.contractType = contractType;
            this.serviceType = serviceType;
            this.livingStatus = livingStatus;
        }
    }
    public class PhaseTab {
        @AuraEnabled public String phaseName;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public Boolean isApplicable;
        @AuraEnabled public String documentLabel;
        public PhaseTab(String phaseName, String contentDocumentId, Boolean isApplicable, String documentLabel) {
            this.phaseName = phaseName;
            this.contentDocumentId = contentDocumentId;
            this.isApplicable = isApplicable;
            this.documentLabel = documentLabel;
        }
    }
    public class DocumentStatus {
        @AuraEnabled public String page;
        @AuraEnabled public Boolean isSigned;
        @AuraEnabled public String signedDate;
        public DocumentStatus(String page, Boolean isSigned, String signedDate) {
            this.page = page;
            this.isSigned = isSigned;
            this.signedDate = signedDate;
        }
    }
    public class FileInfo {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String uploadSource;
        public FileInfo(String contentDocumentId, String fileName, String uploadSource) {
            this.contentDocumentId = contentDocumentId;
            this.fileName = fileName;
            this.uploadSource = uploadSource;
        }
    }

    public class StatusDocument {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Boolean isNotNeeded; // NEW
        @AuraEnabled public String groupName;
        public StatusDocument(String label, String fieldApiName, String rawStatus, String groupName) {
            this.label = label;
            this.fieldApiName = fieldApiName;
            this.groupName = groupName;
            this.status = (String.isNotBlank(rawStatus) && KNOWN_STATUSES.contains(rawStatus))
                ? rawStatus
                : (String.isBlank(rawStatus) ? 'Not Started' : rawStatus);
            this.isCompleted = this.status == 'Completed';
            this.isNotNeeded = this.status == 'Not Needed'; // NEW
        }
    }
    public class FormStatusDocument {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Boolean isNotNeeded; // NEW
        @AuraEnabled public String page;
        @AuraEnabled public String groupName;
        public FormStatusDocument(String label, String fieldApiName, String rawStatus, String page, String groupName) {
            this.label = label;
            this.fieldApiName = fieldApiName;
            this.page = page;
            this.groupName = groupName;
            this.status = (String.isNotBlank(rawStatus) && KNOWN_STATUSES.contains(rawStatus))
                ? rawStatus
                : (String.isBlank(rawStatus) ? 'Not Started' : rawStatus);
            this.isCompleted = this.status == 'Completed';
            this.isNotNeeded = this.status == 'Not Needed'; // NEW
        }
    }
}