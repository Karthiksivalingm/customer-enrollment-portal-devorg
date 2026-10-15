public with sharing class DynamicFormsController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFormMapping() {
        try {
            Map<String, Object> allFormMapping = new Map<String, Object>();

            // ===== ENGLISH FORMS =====
            Map<String, Object> englishForms = new Map<String, Object>();

            // ENGLISH - DIVISION MEMBER
            englishForms.put('Division - Member - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('DDD-EVM Member Contingency Back-Up Plan', 'DDD_EVV_Member_Contingency_Back_Up_Plan__c'),
                    createForm('EVV Designee Attestation', 'EVV_Designee_Attestation__c'),
                    createForm('EVV Timesheet Attestation - English', 'EVV_Timesheet_Attestation_English__c'),
                    createForm('False Claims Act Policy - English', 'False_Claims_Act_Policy_English__c'),
                    createForm('Member Handbook - English', 'Member_Handbook_English__c'),
                    createForm('Pre-Service Orientation', 'Pre_Service_Orientation__c'),
                    createForm('ATC Monitoring Agreement', 'ATC_Monitoring_Agreement__c'),
                    createForm('HCBS Service Contract', 'HCBS_Service_Contract__c')    
                }
            });

            // ENGLISH - DIVISION PARENT PROVIDER
            englishForms.put('Division - Parent Provider - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Abuse & Neglect Policy - English', 'Abuse_Neglect_Policy_English__c'),
                    createForm('Bloodborne Pathogens Exposure - English', 'Bloodborne_Pathogens_Exposure_Eng__c'),
                    createForm('Certifications Policy - English', 'Certifications_Policy_English__c'),
                    createForm('DDD Reference Request - English', 'DDD_Reference_Request_English__c'),
                    createForm('Direct Service Position - English', 'Direct_Service_Position_English__c'),
                    createForm('Employee Policies - English', 'Employee_Policies_English__c'),
                    createForm('False Claims Act Policy - English', 'False_Claims_Act_Policy_English__c'),
                    createForm('Incident Reporting Policy - English', 'Incident_Reporting_Policy_English__c'),
                    createForm('AZLH DCW Training Database - English', 'AZLH_DCW_Training_Database_Eng__c'),
                    createForm('Bring Your Own Device Policy - English', 'Bring_Your_Own_Device_Policy_English__c'),
                    createForm('Employee Handbook - English', 'Employee_Handbook_English__c'),
                    createForm('HIPAA Confidentiality - English', 'HIPAA_Confidentiality_English__c'),
                    createForm('Client Orientation - English', 'Client_Orientation_English__c'),
                    createForm('I-9 - English', 'I_9_English__c'),
                    createForm('Communication Authorization - English', 'Communication_Authorization_English__c'),
                    createForm('DDD-EVM Member Contingency Back-Up Plan', 'DDD_EVV_Member_Contingency_Back_Up_Plan__c'),
                    createForm('EEO-1 Self Identification Form - English', 'EEO_1_Self_Identification_Form_English__c'),
                    createForm('EVV Designee Attestation - English', 'EVV_Designee_Attestation_English__c'),
                    createForm('HIPAA Policy - English', 'HIPAA_Policy_English__c'),
                    createForm('Substance Abuse Testing Policy - English', 'Substance_Abuse_Testing_Policy_English__c'),
                    createForm('Employment Application - English', 'Employment_Application_English__c'),
                    createForm('Central Registry Clearance Form - English', 'Central_Registry_Clearance_Form_Englis__c'),
                    createForm('Criminal History - English', 'Criminal_History_English__c'),
                    createForm('Direct Deposit Authorization - English', 'Direct_Deposit_Authorization_English__c'),
                    createForm('EVV Timesheet Attestation - English', 'EVV_Timesheet_Attestation_English__c'),
                    createForm('HCBS Service Contract', 'HCBS_Service_Contract__c')
                }
            });

            // ENGLISH - DIVISION PROVIDER
            englishForms.put('Division - Provider - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Abuse & Neglect Policy - English', 'Abuse_Neglect_Policy_English__c'),
                    createForm('Bloodborne Pathogens Exposure - English', 'Bloodborne_Pathogens_Exposure_Eng__c'),
                    createForm('Certifications Policy - English', 'Certifications_Policy_English__c'),
                    createForm('DDD Reference Request - English', 'DDD_Reference_Request_English__c'),
                    createForm('Direct Service Position - English', 'Direct_Service_Position_English__c'),
                    createForm('Employee Policies - English', 'Employee_Policies_English__c'),
                    createForm('HIPAA Policy - English', 'HIPAA_Policy_English__c'),
                    createForm('Substance Abuse Testing Policy - English', 'Substance_Abuse_Testing_Policy_English__c'),
                    createForm('AZLH DCW Training Database - English', 'AZLH_DCW_Training_Database_Eng__c'),
                    createForm('Bring Your Own Device Policy - English', 'Bring_Your_Own_Device_Policy_English__c'),
                    createForm('Direct Deposit Authorization - English', 'Direct_Deposit_Authorization_English__c'),
                    createForm('False Claims Act Policy - English', 'False_Claims_Act_Policy_English__c'),
                    createForm('Incident Reporting Policy - English', 'Incident_Reporting_Policy_English__c'),
                    createForm('Communication Authorization - English', 'Communication_Authorization_English__c'),
                    createForm('DDD-EVM Member Contingency Back-Up Plan', 'DDD_EVV_Member_Contingency_Back_Up_Plan__c'),
                    createForm('EEO-1 Self Identification Form - English', 'EEO_1_Self_Identification_Form_English__c'),
                    createForm('EVV Timesheet Attestation - English', 'EVV_Timesheet_Attestation_English__c'),
                    createForm('HIPAA Confidentiality - English', 'HIPAA_Confidentiality_English__c'),
                    createForm('Unlicensed Home Policy - English', 'Unlicensed_Home_Policy_English__c'),
                    createForm('Employment Application - English', 'Employment_Application_English__c'),
                    createForm('Central Registry Clearance Form - English', 'Central_Registry_Clearance_Form_Englis__c'),
                    createForm('Criminal History - English', 'Criminal_History_English__c'),
                    createForm('Employee Handbook - English', 'Employee_Handbook_English__c'),
                    createForm('Client Orientation - English', 'Client_Orientation_English__c'),
                    createForm('I-9 - English', 'I_9_English__c')
                }
            });

            // ENGLISH - DIVISION TUTOR
            englishForms.put('Division - Tutor - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Direct Deposit Authorization - English', 'Direct_Deposit_Authorization_English__c'),
                    createForm('Payroll Deduction Authorization - English', 'Payroll_Deduction_Authorization_Englis__c'),
                    createForm('Federal W-9', 'Federal_W_9__c'),
                    createForm('Independent Contractor Agreement for Tutor', 'Independent_Contractor_Agreement_for_Tut__c'),
                    createForm('Worker Comp Waiver 1099 Sole Proprietor', 'Worker_Comp_Waiver_1099_Sole_Propriet__c')
                }
            });

            // ENGLISH - DRIVING STATUS DRIVER
            englishForms.put('Driving Status - Driver - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Employee Vehicle Checklist - English', 'Employee_Vehicle_Checklist_Eng__c'),
                    createForm('Motor Vehicle Release - English', 'Motor_Vehicle_Release_English__c'),
                    createForm('Transportation Policy - English', 'Transportation_Policy_English__c')
                }
            });

            // ENGLISH - DRIVING STATUS NON-DRIVER
            englishForms.put('Driving Status - Non-Driver - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Non-Driver Agreement', 'Non_Driver_Agreement__c')
                }
            });

            // ENGLISH - SERVICE ATC
            englishForms.put('Service Type - ATC - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Attendant Care Service Work Agreement - English', 'Attendant_Care_Service_Work_Eng__c'),
                    createForm('DCW Guidelines Acknowledgement - English', 'DCW_Guidelines_Acknowledgement_Engl__c')
                }
            });

            // ENGLISH - SERVICE HAH
            englishForms.put('Service Type - HAH - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Habilitation Work Agreement - English', 'Habillitation_Work_Agreement_English__c')
                }
            });

            // ENGLISH - SERVICE RSP
            // CHANGED (requirement 3): this key used to read
            // 'Service Type - RSH - English'. The Service__c picklist value
            // is RSP (Respite), not RSH, and the LWC now matches category
            // keys against the picklist value, so the key has to agree with
            // the picklist. Forms inside are untouched.
            englishForms.put('Service Type - RSP - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Respite Provider Job Description - English', 'Respite_Provider_Job_Description_Eng__c'),
                    createForm('Respite Sleep Policy - English', 'Respite_Sleep_Policy_English__c')
                }
            });

            // ENGLISH - CONTRACT W2
            englishForms.put('Contract Type - W2 - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Federal W-4 - English', 'Federal_W_4_English__c'),
                    createForm('Payroll Deduction Authorization - English', 'Payroll_Deduction_Authorization_Englis__c'),
                    createForm('Return to Work Policy - English', 'Return_to_work_Policy_English__c'),
                    createForm('Sick Day Policy - English', 'Sick_Day_Policy_English__c'),
                    createForm('Workers Compensation Policy - English', 'Workers_Compensation_Policy_English__c'),
                    createForm('Arizona A-4', 'Arizona_A_4__c'),
                    createForm('Rate Agreement', 'Rate_Agreement__c')
                }
            });

            // ENGLISH - CONTRACT 1099
            englishForms.put('Contract Type - 1099 - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Federal W-9', 'Federal_W_9__c'),
                    createForm('HCBS Provider 1099 Contract - English', 'HCBS_Provider_1099_Contract_English__c'),
                    createForm('Worker Comp Waiver 1099 Sole Proprietor', 'Worker_Comp_Waiver_1099_Sole_Propriet__c'),
                    createForm('Contractor Notification Approval Request', 'Contractor_Notification_Approval_Reque__c')
                }
            });

            // ENGLISH - LIVING STATUS
            englishForms.put('Living Status - Live-In - English', new Map<String, Object>{
                'forms' => new List<Map<String, Object>>{
                    createForm('Difficulty of Care Income Attestation', 'Difficulty_of_Care_Income_Attestation__c'),
                    createForm('Parent as a Paid Caregiver for Minor Child', 'Parent_as_a_Paid_Caregiver_for_Minor_Chi__c')
                }
            });

            allFormMapping.put('English', englishForms);

            // ===== SPANISH FORMS =====
            Map<String, Object> spanishForms = createSpanishForms();
            allFormMapping.put('Spanish', spanishForms);

            return allFormMapping;

        } catch (Exception e) {
            System.debug('Error in getFormMapping: ' + e.getMessage());
            throw new AuraHandledException('Error getting form mapping: ' + e.getMessage());
        }
    }


    private static Map<String, Object> createSpanishForms() {
        Map<String, Object> spanishForms = new Map<String, Object>();

        spanishForms.put('Division - Member - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('DDD-EVM Member Contingency Back-Up Plan - Spanish', 'DDD_EVV_Member_Contingency_BackUpSpanish__c'),
                createForm('EVV Designee Attestation - Spanish', 'EVV_Designee_Attestation_Spanish__c'),
                createForm('EVV Timesheet Attestation - Spanish', 'EVV_Timesheet_Attestation_Spanish__c'),
                createForm('False Claims Act Policy - Spanish', 'False_Claims_Act_Policy_Spanish__c'),
                createForm('Member Handbook - Spanish', 'Member_Handbook_Spanish__c'),
                createForm('Pre-Service Orientation - Spanish', 'Pre_Service_Orientation_Spanish__c'),
                createForm('ATC Monitoring Agreement - Spanish', 'ATC_Monitoring_Agreement__c'),
                createForm('HCBS Service Contract - Spanish', 'HCBS_Service_Contract__c')
            }
        });

        spanishForms.put('Division - Parent Provider - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Abuse & Neglect Policy - Spanish', 'Abuse_Neglect_Policy_Spanish__c'),
                createForm('Bloodborne Pathogens Exposure - Spanish', 'Bloodborne_Pathogens_Exposure_Spanish__c'),
                createForm('Certifications Policy - Spanish', 'Certifications_Policy_Spanish__c'),
                createForm('DDD Reference Request - Spanish', 'DDD_Reference_Request_Spanish__c'),
                createForm('Direct Service Position - Spanish', 'Direct_Service_Position_Spanish__c'),
                createForm('Employee Policies - Spanish', 'Employee_Policies_Spanish__c'),
                createForm('False Claims Act Policy - Spanish', 'False_Claims_Act_Policy_Spanish__c'),
                createForm('Incident Reporting Policy - Spanish', 'Incident_Reporting_Policy_Spanish__c'),
                createForm('AZLH DCW Training Database - Spanish', 'AZLH_DCW_Training_Database_Eng__c'),
                createForm('Bring Your Own Device Policy - Spanish', 'Bring_Your_Own_Device_Policy_Spanish__c'),
                createForm('Employee Handbook - Spanish', 'Employee_Handbook_Spanish__c'),
                createForm('HIPAA Confidentiality - Spanish', 'HIPAA_Confidentiality_Spanish__c'),
                createForm('Client Orientation - Spanish', 'Client_Orientation_English__c'),
                createForm('I-9 - Spanish', 'I_9_English__c'),
                createForm('Communication Authorization - Spanish', 'Communication_Authorization_Spanish__c'),
                createForm('DDD-EVM Member Contingency Back-Up Plan', 'DDD_EVV_Member_Contingency_Back_Up_Plan__c'),
                createForm('EEO-1 Self Identification Form - Spanish', 'EEO_1_Self_Identification_Form_Spanish__c'),
                createForm('EVV Designee Attestation - Spanish', 'EVV_Designee_Attestation_Spanish__c'),
                createForm('HIPAA Policy - Spanish', 'HIPAA_Policy_Spanish__c'),
                createForm('Substance Abuse Testing Policy - Spanish', 'Substance_Abuse_Testing_Policy_Spanish__c'),
                createForm('Employment Application - Spanish', 'Employment_Application_Spanish__c'),
                createForm('Central Registry Clearance Form - Spanish', 'Central_Registry_Clearance_Form_Spanis__c'),
                createForm('Criminal History - Spanish', 'Criminal_History_Spanish__c'),
                createForm('Direct Deposit Authorization - Spanish', 'Direct_Deposit_Authorization_Spanish__c'),
                createForm('EVV Timesheet Attestation - Spanish', 'EVV_Timesheet_Attestation_Spanish__c')
            }
        });

        spanishForms.put('Division - Provider - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Abuse & Neglect Policy - Spanish', 'Abuse_Neglect_Policy_Spanish__c'),
                createForm('Bloodborne Pathogens Exposure - Spanish', 'Bloodborne_Pathogens_Exposure_Spanish__c'),
                createForm('Certifications Policy - Spanish', 'Certifications_Policy_Spanish__c'),
                createForm('DDD Reference Request - Spanish', 'DDD_Reference_Request_Spanish__c'),
                createForm('Direct Service Position - Spanish', 'Direct_Service_Position_Spanish__c'),
                createForm('Employee Policies - Spanish', 'Employee_Policies_Spanish__c'),
                createForm('HIPAA Policy - Spanish', 'HIPAA_Policy_Spanish__c'),
                createForm('Substance Abuse Testing Policy - Spanish', 'Substance_Abuse_Testing_Policy_Spanish__c'),
                createForm('AZLH DCW Training Database - Spanish', 'AZLH_DCW_Training_Database_Eng__c'),
                createForm('Bring Your Own Device Policy - Spanish', 'Bring_Your_Own_Device_Policy_Spanish__c'),
                createForm('Direct Deposit Authorization - Spanish', 'Direct_Deposit_Authorization_Spanish__c'),
                createForm('False Claims Act Policy - Spanish', 'False_Claims_Act_Policy_Spanish__c'),
                createForm('Incident Reporting Policy - Spanish', 'Incident_Reporting_Policy_Spanish__c'),
                createForm('Communication Authorization - Spanish', 'Communication_Authorization_Spanish__c'),
                createForm('DDD-EVM Member Contingency Back-Up Plan', 'DDD_EVV_Member_Contingency_BackUpSpanish__c'),
                createForm('EEO-1 Self Identification Form - Spanish', 'EEO_1_Self_Identification_Form_Spanish__c'),
                createForm('EVV Timesheet Attestation - Spanish', 'EVV_Timesheet_Attestation_Spanish__c'),
                createForm('HIPAA Confidentiality - Spanish', 'HIPAA_Confidentiality_Spanish__c'),
                createForm('Unlicensed Home Policy - Spanish', 'Unlicensed_Home_Policy_Spanish__c'),
                createForm('Employment Application - Spanish', 'Employment_Application_Spanish__c'),
                createForm('Central Registry Clearance Form - Spanish', 'Central_Registry_Clearance_Form_Spanis__c'),
                createForm('Criminal History - Spanish', 'Criminal_History_Spanish__c'),
                createForm('Employee Handbook - Spanish', 'Employee_Handbook_Spanish__c'),
                createForm('Client Orientation - Spanish', 'Client_Orientation_English__c'),
                createForm('I-9 - Spanish', 'I_9_English__c')
            }
        });

        spanishForms.put('Division - Tutor - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Direct Deposit Authorization - Spanish', 'Direct_Deposit_Authorization_Spanish__c'),
                createForm('Payroll Deduction Authorization - Spanish', 'Payroll_Deduction_Authorization_Spanis__c'),
                createForm('Federal W-9', 'Federal_W_9__c')
            }
        });

        spanishForms.put('Driving Status - Driver - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Employee Vehicle Checklist - Spanish', 'Employee_Vehicle_Checklist_Spanish__c'),
                createForm('Motor Vehicle Release - Spanish', 'Motor_Vehicle_Release_Spanish__c'),
                createForm('Transportation Policy - Spanish', 'Transportation_Policy_Spanish__c')
            }
        });

        spanishForms.put('Driving Status - Non-Driver - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Non-Driver Agreement - Spanish', 'Non_Driver_Agreement_Spanish__c')
            }
        });

        spanishForms.put('Service Type - ATC - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Attendant Care Service Work Agreement - Spanish', 'Attendant_Care_Service_Work_Agreement__c'),
                createForm('DCW Guidelines Acknowledgement - Spanish', 'DCW_Guidelines_Acknowledgement_Span__c')
            }
        });

        spanishForms.put('Service Type - HAH - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Habilitation Work Agreement - Spanish', 'Habillitation_Work_Agreement_Spanish__c')
            }
        });

        // CHANGED (requirement 3): key was 'Service Type - RSH - Spanish'.
        spanishForms.put('Service Type - RSP - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Respite Provider Job Description - Spanish', 'Respite_Provider_Job_Description_Spani__c'),
                createForm('Respite Sleep Policy - Spanish', 'Respite_Sleep_Policy_Spanish__c')
            }
        });

        spanishForms.put('Contract Type - W2 - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Federal W-4 - Spanish', 'Federal_W_4_2026_Spanish__c'),
                createForm('Payroll Deduction Authorization - Spanish', 'Payroll_Deduction_Authorization_Span__c'),
                createForm('Return to Work Policy - Spanish', 'Return_to_work_Policy_Spanish__c'),
                createForm('Sick Day Policy - Spanish', 'Sick_Day_Policy_Spanish__c'),
                createForm('Workers Compensation Policy - Spanish', 'Workers_Compensation_Policy_Spanish__c'),
                createForm('Arizona A-4', 'Arizona_A_4__c'),
                createForm('Rate Agreement', 'Rate_Agreement__c')
            }
        });

        spanishForms.put('Contract Type - 1099 - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Federal W-9', 'Federal_W_9__c')
            }
        });

        spanishForms.put('Living Status - Live-In - Spanish', new Map<String, Object>{
            'forms' => new List<Map<String, Object>>{
                createForm('Difficulty of Care Income - Spanish', 'Difficulty_of_Care_Income_Spanish__c'),
                createForm('Parent as a Paid Caregiver - Spanish', 'Parent_as_a_Paid_Caregiver_Spanish__c')
            }
        });

        return spanishForms;
    }


    private static Map<String, Object> createForm(String label, String apiName) {
        return new Map<String, Object>{
            'label' => label,
            'apiName' => apiName
        };
    }


    @AuraEnabled
    public static void updateFormStatus(String recordId, String formApiName, String status) {
        try {
            if (String.isEmpty(recordId) || String.isEmpty(formApiName) || String.isEmpty(status)) {
                throw new AuraHandledException('Missing required parameters');
            }
            System.debug('Form status updated - Record: ' + recordId + ', Form: ' + formApiName + ', Status: ' + status);
        } catch (Exception e) {
            System.debug('Error in updateFormStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating form status: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static void uploadFormFile(String recordId, String formApiName, String fileName, String fileContent) {
        try {
            if (String.isEmpty(recordId) || String.isEmpty(formApiName) || String.isEmpty(fileName) || String.isEmpty(fileContent)) {
                throw new AuraHandledException('Missing required parameters');
            }

            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(fileContent);
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            insert cv;

            System.debug('File uploaded successfully');
        } catch (Exception e) {
            System.debug('Error in uploadFormFile: ' + e.getMessage());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    /* =====================================================================
     * NEW - Generic PDF fill-and-save support
     * Works for any form/record combination; nothing here is hardcoded to
     * a specific form. Called from DynamicFormsContact's inline
     * "Complete Your Form" panel.
     * ===================================================================== */

    /**
     * Returns the base64 bytes of the most recently generated PDF that's
     * linked to this record and tagged with this form's field API name in
     * its Title (that's the pattern the rest of this component already
     * uses for locating a form's file - see uploadedFiles matching).
     * Adjust the LIKE filter if TSDocumentService names files differently.
     */
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
                    'No document has been generated for this form yet. Click Send the Form first.'
                );
            }

            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink l : links) {
                docIds.add(l.ContentDocumentId);
            }

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
                throw new AuraHandledException('No fillable PDF found for this form yet.');
            }

            return EncodingUtil.base64Encode(versions[0].VersionData);

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading PDF: ' + e.getMessage());
        }
    }

    /**
     * Generic merge-field prefill: given the exact PDF field names parsed
     * client-side, returns whichever of them also happen to be real,
     * accessible field API names on the record's own object. No mapping
     * table needed - a PDF field literally named e.g. FirstName or
     * MailingCity is auto-matched and pre-filled from the record; PDF
     * fields with no matching Salesforce field are simply left for the
     * contact to type in themselves.
     */
    @AuraEnabled
    public static Map<String, Object> getMergeFieldValues(Id recordId, List<String> fieldNames) {
        Map<String, Object> results = new Map<String, Object>();
        try {
            if (recordId == null || fieldNames == null || fieldNames.isEmpty()) {
                return results;
            }

            Schema.SObjectType objType = recordId.getSObjectType();
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

            List<String> matchedFields = new List<String>();
            for (String requested : fieldNames) {
                Schema.SObjectField sf = fieldMap.get(requested);
                if (sf != null && sf.getDescribe().isAccessible()) {
                    matchedFields.add(sf.getDescribe().getName());
                }
            }

            if (matchedFields.isEmpty()) {
                return results;
            }

            String query = 'SELECT Id, ' + String.join(matchedFields, ', ') +
                            ' FROM ' + objType.getDescribe().getName() +
                            ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);

            if (!records.isEmpty()) {
                SObject record = records[0];
                for (String fieldName : matchedFields) {
                    Object val = record.get(fieldName);
                    if (val != null) {
                        results.put(fieldName, val);
                    }
                }
            }

            return results;

        } catch (Exception e) {
            System.debug('getMergeFieldValues error (non-fatal): ' + e.getMessage());
            // Prefill is a convenience, not a requirement - fail quiet so
            // the contact can still fill the form in manually.
            return results;
        }
    }

    /**
     * Saves the completed PDF (already filled in and flattened
     * client-side) as a File on the record, and marks the form Completed
     * if a matching status field exists.
     */
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
                SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
            ].ContentDocumentId;

            insert new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = recordId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );

            try {
                Schema.SObjectType objType = recordId.getSObjectType();
                if (objType.getDescribe().fields.getMap().containsKey(fieldApiName)) {
                    SObject record = objType.newSObject(recordId);
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