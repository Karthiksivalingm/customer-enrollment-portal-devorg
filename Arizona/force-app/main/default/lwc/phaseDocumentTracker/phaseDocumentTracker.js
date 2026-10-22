import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCurrentUserContext from '@salesforce/apex/PhaseDocumentTrackerController.getCurrentUserContext';
import getPhaseTabs from '@salesforce/apex/PhaseDocumentTrackerController.getPhaseTabs';
import getDocumentSignatureStatuses from '@salesforce/apex/PhaseDocumentTrackerController.getDocumentSignatureStatuses';
import getCertificationAndDriverDocuments from '@salesforce/apex/PhaseDocumentTrackerController.getCertificationAndDriverDocuments';
import getDriverFormDocuments from '@salesforce/apex/PhaseDocumentTrackerController.getDriverFormDocuments';
import getServiceAgreementForms from '@salesforce/apex/PhaseDocumentTrackerController.getServiceAgreementForms';
import getServiceFormDocuments from '@salesforce/apex/PhaseDocumentTrackerController.getServiceFormDocuments';
import getUploadedFileInfo from '@salesforce/apex/PhaseDocumentTrackerController.getUploadedFileInfo';
import uploadDocument from '@salesforce/apex/PhaseDocumentTrackerController.uploadDocument';
import deleteUploadedDocument from '@salesforce/apex/PhaseDocumentTrackerController.deleteUploadedDocument';
import createForm from '@salesforce/apex/PandaDocService.createForm';
import getStatus from '@salesforce/apex/PandaDocService.getStatus';
import prepareForSigning from '@salesforce/apex/PandaDocService.prepareForSigning';
import getCompletedFiles from '@salesforce/apex/PandaDocService.getCompletedFiles';
import syncPortalDocument from '@salesforce/apex/PandaDocService.syncPortalDocument';

// Based Forms / Pay and Tax / Live-In rows have no backing status field,
// so their files are keyed on the form LABEL instead.
import getFilesByLabel from '@salesforce/apex/FormWorkflowService.getFilesByLabel';
import uploadFormFile from '@salesforce/apex/FormWorkflowService.uploadFormFile';

const VF_DOMAIN = 'https://azlionhearts--arizonalh--c.sandbox.vf.force.com';

const BASED_FORMS_PHASE_NAME   = 'Based Forms';
const DOCS_CERT_PHASE_NAME     = 'Documents and Certifications';
const PAY_TAX_PHASE_NAME       = 'Pay and Tax Forms';
const SERVICE_FORMS_PHASE_NAME = 'Service Forms';

const POLL_INTERVAL_MS = 1500;
const POLL_MAX_ATTEMPTS = 10;

// Rendered as a disabled lightning-combobox. A combobox renders BLANK when
// its value isn't in this list, so every workflow stage must appear here.
const STATUS_OPTIONS = [
    { label: 'None', value: 'None' },
    { label: 'Not Started', value: 'Not Started' },
    { label: 'Sent', value: 'Sent' },
    { label: 'Pending', value: 'Pending' },
    { label: 'Completed', value: 'Completed' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Expired', value: 'Expired' },
    { label: 'Declined', value: 'Declined' },
    { label: 'Viewed', value: 'Viewed' },
    { label: 'Not Needed', value: 'Not Needed' }
];

// Used to decide whether the delete "X" shows for a given row. Only the
// side that uploaded a file may delete it (untagged legacy files show on both).
const UPLOAD_SOURCE = 'portal';

// Category filter rules (from the eligibility matrix).
// Tokens are normalized: lowercase, letters and digits only.
// "Member" -> "member", "Parent Provider" -> "parentprovider", "Non-Driver" -> "nondriver".
const DIVISION_ONLY_TOKENS = ['member', 'tutor'];
const PARENT_PROVIDER_TOKEN = 'parentprovider';

// Order in which service sections are displayed. Every selected service
// gets its own section (ATC, HAH, RSP).
const SERVICE_PRIORITY = ['atc', 'hah', 'rsp'];

// Picklist/token aliases used by the filter (service and driving values)
const TOKEN_ALIASES = {
    rsh: 'rsp',        // legacy "RSH" values
    respite: 'rsp',
    habilitation: 'hah'
};

// Contract type token -> key used by PAY_TAX_DOCS ('w4' = W2 contract, '1099' = 1099 contract)
const CONTRACT_KEY_MAP = {
    w2: 'w4',
    w4: 'w4',
    '1099': '1099'
};

const UI_TEXT = {
    english: {
        tabNames: {
            [BASED_FORMS_PHASE_NAME]: 'Based Forms',
            [DOCS_CERT_PHASE_NAME]: 'Documents and Certifications',
            [PAY_TAX_PHASE_NAME]: 'Pay and Tax Forms',
            [SERVICE_FORMS_PHASE_NAME]: 'Service Forms'
        },
        completed: 'Completed',
        reviewAndComplete: 'Review and Complete the form',
        view: 'View',
        upload: 'Upload Files',
        reUpload: 'Re-upload Files',
        uploadSigned: 'Upload signed form',
        uploadFinal: 'Upload final copy',
        reviewSuccess: 'The form is now open. It is pending staff review.',
        autoDocumentsHeading: 'Basic Documents Status',
        certificationHeading: 'Certification Status',
        driverHeading: 'Driver Documents Status',
        driverFormsHeading: 'Driver Forms',
        nonDriverFormsHeading: 'Non-Driver Forms',
        serviceFormsHeading: 'Service Forms',
        serviceAgreementFormsHeading: 'Service Agreement Forms',
        uploadSuccess: 'Document uploaded. It is now pending review.',
        uploadError: 'There was a problem uploading your document.',
        confirmDeleteFile: 'Remove this file? This cannot be undone.',
        notEligible: {
            basedForms: 'Division is not yet on file for your account, or this division has no Based Forms configured.',
            payTax: 'Contract type is not yet on file for your account.',
            serviceForms: 'Service type or living status is not yet on file for your account.',
            generic: 'This section is not currently available.'
        }
    },
    spanish: {
        tabNames: {
            [BASED_FORMS_PHASE_NAME]: 'Formularios Base',
            [DOCS_CERT_PHASE_NAME]: 'Documentos y Certificaciones',
            [PAY_TAX_PHASE_NAME]: 'Formularios de Pago e Impuestos',
            [SERVICE_FORMS_PHASE_NAME]: 'Formularios de Servicio'
        },
        completed: 'Completado',
        reviewAndComplete: 'Revisar y Completar el formulario',
        view: 'Ver',
        upload: 'Cargar Archivos',
        reUpload: 'Volver a Cargar Archivos',
        uploadSigned: 'Cargar formulario firmado',
        uploadFinal: 'Cargar copia final',
        reviewSuccess: 'El formulario está abierto. Está pendiente de revisión.',
        autoDocumentsHeading: 'Estado de Documentos Básicos',
        certificationHeading: 'Estado de Certificación',
        driverHeading: 'Estado de Documentos del Conductor',
        driverFormsHeading: 'Formularios del Conductor',
        nonDriverFormsHeading: 'Formularios de No Conductor',
        serviceFormsHeading: 'Formularios de Servicio',
        serviceAgreementFormsHeading: 'Formularios de Acuerdo de Servicio',
        uploadSuccess: 'Documento cargado. Está pendiente de revisión.',
        uploadError: 'Hubo un problema al cargar su documento.',
        confirmDeleteFile: '¿Eliminar este archivo? Esta acción no se puede deshacer.',
        notEligible: {
            basedForms: 'La división aún no está registrada en su cuenta, o esta división no tiene Formularios Base configurados.',
            payTax: 'El tipo de contrato aún no está registrado en su cuenta.',
            serviceForms: 'El tipo de servicio o el estado de vivienda aún no está registrado en su cuenta.',
            generic: 'Esta sección no está disponible actualmente.'
        }
    }
};

// -----------------------------------------------------------------
// BASED FORMS + PAY/TAX FORMS document config. These tabs are driven by
// static per-division / per-contract-type lists. Rows are keyed by LABEL.
// -----------------------------------------------------------------
const BASED_FORMS_DOCS = {
    member: {
        english: [
            // The TS Documents template is spelled EVM, the form label EVV -
            // tsTemplate bridges the two.
            { label: 'DDD-EVV Member Contingency Back-Up Plan - English', page: 'DDDEVVMemberContingencyEnglish', tsTemplate: 'DDD-EVM Member Contingency Back-Up Plan' },
            { label: 'EVV Designee Attestation - English', page: 'EVVDesigneeAttestationEnglish' },
            { label: 'EVV Timesheet Attestation - English', page: 'EVVTimesheetAttestationEnglish' },
            { label: 'False Claims Act Policy - English', page: 'FalseClaimsActPolicyEnglish' },
            { label: 'Member Handbook - English', page: 'MemberHandbookEnglish' },
            { label: 'Pre-Service Orientation - English', page: 'PreServiceOrientationEnglish' },
            { label: 'ATC Monitoring Agreement - English', page: 'ATCMonitoringAgreement' },
            { label: 'HCBS Service Contract - English', page: 'HCBSServiceContractMember' }
        ],
        spanish: [
            { label: 'DDD-EVV Member Contingency Back-Up Plan - Spanish', page: 'DDDEVVMemberContingencySpanish' },
            { label: 'EVV Designee Attestation - Spanish', page: 'EVVDesigneeAttestationSpanish' },
            { label: 'EVV Timesheet Attestation - Spanish', page: 'EVVTimesheetAttestationSpanish' },
            { label: 'False Claims Act Policy - English', page: 'FalseClaimsActPolicyEnglish2' },
            { label: 'Member Handbook - Spanish', page: 'MemberHandbookSpanish' },
            { label: 'Pre-Service Orientation - Spanish', page: 'PreServiceOrientationSpanish' },
            { label: 'Member_Opt_Out_Agreement - Spanish', page: 'MemberOptOutAgreementSpanish' },
            { label: 'HCBS Service Contract - English', page: 'HCBSServiceContractMemberEs' }
        ]
    },
    'parent provider': {
        english: [
            { label: 'AZLH Client Orientation - English', page: 'ClientOrientationPP' },
    { label: 'AZLH_DCW Training Database Authorization', page: 'DCWTrainingDatabaseAuthPP' },
    { label: 'AZLH Employment Application FINAL', page: 'EmploymentApplicationEnglishPP' },
    { label: 'Abuse & Neglect Policy - English', page: 'AbuseNeglectPolicyEnglishPP' },
    { label: 'Bloodborne Pathogens Exposure Control Plan - English', page: 'BloodbornePathogensEnglishPP' },
    { label: 'Bring Your Own Device Policy - English', page: 'BYODPolicyEnglishPP' },
    { label: 'Central Registry Clearance Form - English', page: 'CentralRegistryClearanceEnglishPP' },
    { label: 'Certifications Policy - English', page: 'CertificationsPolicyEnglishPP' },
    { label: 'Communication Authorization - English', page: 'CommunicationAuthEnglishPP' },
    { label: 'Criminal History - English', page: 'CriminalHistoryEnglishPP' },
    { label: 'DDD Reference Request - English', page: 'DDDReferenceRequestEnglishPP' },
    { label: 'DDD-EVV Member Contingency Back-Up Plan - English', page: 'DDDEVVContingencyEnglishPP' },
    { label: 'Direct Deposit Authorization - English', page: 'DirectDepositAuthEnglishPP' },
    { label: 'Direct Service Position - English', page: 'DirectServicePositionEnglishPP' },
    { label: 'EEO-1 Self Identification Form - English', page: 'EEO1SelfIdEnglishPP' },
    { label: 'Employee Handbook - English', page: 'EmployeeHandbookEnglishPP' },
    { label: 'Employee Policies - English', page: 'EmployeePoliciesEnglishPP' },
    { label: 'EVV Designee Attestation - English', page: 'EVVDesigneeAttestationEnglishPP' },
    { label: 'EVV Timesheet Attestation - English', page: 'EVVTimesheetAttestationEnglishPP' },
    { label: 'False Claims Act Policy - English', page: 'FalseClaimsActPolicyEnglishPP' },
    { label: 'HCBS Service Contract - English', page: 'HCBSServiceContractPP' },
    { label: 'HIPAA Confidentiality - English', page: 'HIPAAConfidentialityEnglishPP' },
    { label: 'HIPAA Policy - English', page: 'HIPAAPolicyEnglishPP' },
    { label: 'I-9 - English', page: 'I9PP' },
    { label: 'Incident Reporting Policy - English', page: 'IncidentReportingPolicyEnglishPP' },
    { label: 'Substance Abuse Testing Policy - English', page: 'SubstanceAbuseTestingEnglishPP' },
    { label: 'Unlicensed Home Policy - English', page: 'UnlicensedHomePolicyEnglishPP' }
        ],
        spanish: [
            { label: 'Abuse & Neglect Policy - Spanish', page: 'AbuseNeglectPolicySpanishPP' },
    { label: 'Bloodborne Pathogens Exposure Control Plan - Spanish', page: 'BloodbornePathogensSpanishPP' },
    { label: 'Bring Your Own Device Policy - Spanish', page: 'BYODPolicySpanishPP' },
    { label: 'Central Registry Clearance Form - Spanish', page: 'CentralRegistryClearanceSpanishPP' },
    { label: 'Certifications Policy - Spanish', page: 'CertificationsPolicySpanishPP' },
    { label: 'Client Orientation - Spanish', page: 'ClientOrientationSpanishPP' },
    { label: 'Communication Authorization - Spanish', page: 'CommunicationAuthSpanishPP' },
    { label: 'Criminal History - Spanish', page: 'CriminalHistorySpanishPP' },
    { label: 'DDD Reference Request - Spanish', page: 'DDDReferenceRequestSpanishPP' },
    { label: 'DDD-EVV Member Contingency Back-Up Plan - Spanish', page: 'DDDEVVContingencySpanishPP' },
    { label: 'Direct Deposit Authorization - Spanish', page: 'DirectDepositAuthSpanishPP' },
    { label: 'Direct Service Position - Spanish', page: 'DirectServicePositionSpanishPP' },
    { label: 'EEO-1 Self Identification Form - Spanish', page: 'EEO1SelfIdSpanishPP' },
    { label: 'Employee Handbook - Spanish', page: 'EmployeeHandbookSpanishPP' },
    { label: 'Employee Policies - Spanish', page: 'EmployeePoliciesSpanishPP' },
    { label: 'AZLH_Employment_Application_4.2026_FINAL', page: 'EmploymentApplicationSpanishPP' },
    { label: 'EVV Designee Attestation - Spanish', page: 'EVVDesigneeAttestationSpanishPP' },
    { label: 'EVV Timesheet Attestation - Spanish', page: 'EVVTimesheetAttestationSpanishPP' },
    { label: 'False Claims Act Policy - Spanish', page: 'FalseClaimsActPolicySpanishPP' },
    { label: 'HCBS_Service_Contract - Spanish', page: 'HCBSServiceContractSpanishPP' },
    { label: 'HIPAA Confidentiality - Spanish', page: 'HIPAAConfidentialitySpanishPP' },
    { label: 'HIPAA Policy - Spanish', page: 'HIPAAPolicySpanishPP' },
    { label: 'I-9 - Spanish', page: 'I9SpanishPP' },
    { label: 'Incident Reporting Policy - Spanish', page: 'IncidentReportingPolicySpanishPP' },
    { label: 'Substance Abuse Testing Policy - Spanish', page: 'SubstanceAbuseTestingSpanishPP' },
    { label: 'Training Database Authorization - Spanish', page: 'TrainingDatabaseAuthSpanishPP' },
    { label: 'Unlicensed Home Policy - Spanish', page: 'UnlicensedHomePolicySpanishPP' }
        ]
    },
    provider: {
        english: [
             { label: 'Abuse & Neglect Policy - English', page: 'AbuseNeglectPolicyEnglishProv' },
             { label: 'AZLH Client Orientation - English', page: 'ClientOrientationProv' },
    { label: 'AZLH_DCW Training Database Authorization', page: 'DCWTrainingDatabaseAuthProv' },
    { label: 'AZLH_Employment_Application_4.2026_FINAL', page: 'AZLHEmploymentApplicationFINALProv' },
    { label: 'Bloodborne Pathogens Exposure Control Plan - English', page: 'BloodbornePathogensEnglishProv' },
    { label: 'Bring Your Own Device Policy - English', page: 'BYODPolicyEnglishProv' },
    { label: 'Central Registry Clearance Form - English', page: 'CentralRegistryClearanceEnglishProv' },
    { label: 'Certifications Policy - English', page: 'CertificationsPolicyEnglishProv' },
    { label: 'Communication Authorization - English', page: 'CommunicationAuthEnglishProv' },
    { label: 'Criminal History - English', page: 'CriminalHistoryEnglishProv' },
    { label: 'DDD Reference Request - English', page: 'DDDReferenceRequestEnglishProv' },
    { label: 'DDD-EVV Member Contingency Back-Up Plan - English', page: 'DDDEVVContingencyEnglishProv' },
    { label: 'Direct Deposit Authorization - English', page: 'DirectDepositAuthEnglishProv' },
    { label: 'Direct Service Position - English', page: 'DirectServicePositionEnglishProv' },
    { label: 'EEO-1 Self Identification Form - English', page: 'EEO1SelfIdEnglishProv' },
    { label: 'Employee Handbook - English', page: 'EmployeeHandbookEnglishProv' },
    { label: 'Employee Policies - English', page: 'EmployeePoliciesEnglishProv' },
    { label: 'EVV Timesheet Attestation - English', page: 'EVVTimesheetAttestationEnglishProv' },
    { label: 'False Claims Act Policy - English', page: 'FalseClaimsActPolicyEnglishProv' },
    {label: 'HCBS Service Contract - English', page: 'HCBSServiceContractProv' },
    { label: 'HIPAA Confidentiality - English', page: 'HIPAAConfidentialityEnglishProv' },
    { label: 'HIPAA Policy - English', page: 'HIPAAPolicyEnglishProv' },
    { label: 'I-9 - English', page: 'I9EnglishProv' },
    { label: 'Incident Reporting Policy - English', page: 'IncidentReportingPolicyEnglishProv' },
    { label: 'Substance Abuse Testing Policy - English', page: 'SubstanceAbuseTestingEnglishProv' },
    { label: 'Unlicensed Home Policy - English', page: 'UnlicensedHomePolicyEnglishProv' }
        ],
        spanish: [
            { label: 'Abuse & Neglect Policy - Spanish', page: 'AbuseNeglectPolicySpanishProv' },
    { label: 'Bloodborne Pathogens Exposure Control Plan - Spanish', page: 'BloodbornePathogensSpanishProv' },
    { label: 'Bring Your Own Device Policy - Spanish', page: 'BYODPolicySpanishProv' },
    { label: 'Central Registry Clearance Form - Spanish', page: 'CentralRegistryClearanceSpanishProv' },
    { label: 'Client Orientation - Spanish', page: 'ClientOrientationSpanishPP' },
    { label: 'Certifications Policy - Spanish', page: 'CertificationsPolicySpanishProv' },
    { label: 'Communication Authorization - Spanish', page: 'CommunicationAuthSpanishProv' },
    { label: 'Criminal History - Spanish', page: 'CriminalHistorySpanishProv' },
    { label: 'DDD Reference Request - Spanish', page: 'DDDReferenceRequestSpanishProv' },
    { label: 'DDD-EVV Member Contingency Back-Up Plan - Spanish', page: 'DDDEVVContingencySpanishProv' },
    { label: 'Direct Deposit Authorization - Spanish', page: 'DirectDepositAuthSpanishProv' },
    { label: 'Direct Service Position - Spanish', page: 'DirectServicePositionSpanishProv' },
    { label: 'EEO-1 Self Identification Form - Spanish', page: 'EEO1SelfIdSpanishProv' },
    { label: 'Employee Handbook - Spanish', page: 'EmployeeHandbookSpanishProv' },
    { label: 'Employee Policies - Spanish', page: 'EmployeePoliciesSpanishProv' },
    { label: 'AZLH_Employment_Application_4.2026_FINAL', page: 'EmploymentApplicationSpanishProv' },
    { label: 'EVV Timesheet Attestation - Spanish', page: 'EVVTimesheetAttestationSpanishProv' },
    { label: 'False Claims Act Policy - Spanish', page: 'FalseClaimsActPolicySpanishProv' },
    { label: 'HIPAA Confidentiality - Spanish', page: 'HIPAAConfidentialitySpanishProv' },
    { label: 'HIPAA Policy - Spanish', page: 'HIPAAPolicySpanishProv' },
    { label: 'I-9 - Spanish', page: 'I9SpanishProv' },
    { label: 'Incident Reporting Policy - Spanish', page: 'IncidentReportingPolicySpanishProv' },
    { label: 'Substance Abuse Testing Policy - Spanish', page: 'SubstanceAbuseTestingSpanishProv' },
    { label: 'Training Database Authorization - Spanish', page: 'TrainingDatabaseAuthSpanishProv' },
    { label: 'Unlicensed Home Policy - Spanish', page: 'UnlicensedHomePolicySpanishProv' }
        ]
    },
    tutor: {
        english: [
            { label: 'Direct Deposit Authorization - English', page: 'DirectDepositAuthEnglishTutor' },
            { label: 'Payroll Deduction Authorization - English', page: 'PayrollDeductionAuthEnglishTutor' },
            { label: 'Federal W-9 - English', page: 'FederalW9Tutor' },
            { label: 'Independent Contractor Agreement for Tutoring Services - English', page: 'ICAgreementTutoring' },
            { label: 'Worker Comp Waiver - 1099 Sole Proprietor - English', page: 'WorkerCompWaiverTutor' }
        ],
        spanish: [
            { label: 'Direct Deposit Authorization - Spanish', page: 'DirectDepositAuthSpanishTutor' },
            { label: 'Payroll Deduction Authorization - Spanish', page: 'PayrollDeductionAuthSpanishTutor' },
            { label: 'Federal W-9 - Spanish', page: 'FederalW9TutorSpan' },
            { label: 'Independent Contractor Agreement for Tutoring Services - Spanish', page: 'ICAgreementTutoringSpan' },
            { label: 'Worker Comp Waiver - 1099 Sole Proprietor - Spanish', page: 'WorkerCompWaiverTutorSpan' }
        ]
    }
};

const PAY_TAX_DOCS = {
    '1099': {
        english: [
            { label: 'Contractor Notification & Approval Request - English', page: 'ContractorNotificationsApproval' },
            { label: 'Federal W-9 - English', page: 'FederalW9_1099' },
            { label: 'HCBS Provider 1099 Contract - English', page: 'HCBSProvider1099Contract' },
            { label: 'Worker Comp Waiver - 1099 Sole Proprietor - English', page: 'WorkerCompWaiver1099' }
        ],
        spanish: [
            { label: 'Contractor Notification & Approval Request - Spanish', page: 'ContractorNotificationsApprovalSpan' },
            { label: 'Federal W-9 - Spanish', page: 'FederalW9_1099Span' },
            { label: 'HCBS_Provider_Contract - Spanish', page: 'HCBSProvider1099ContractSpan' },
            { label: 'Worker Comp Waiver - 1099 Sole Proprietor - Spanish', page: 'WorkerCompWaiver1099Span' }
        ]
    },
    w4: {
        english: [
            { label: 'Federal W-4 - English', page: 'FederalW4_2026_English' },
            { label: 'Payroll Deduction Authorization - English', page: 'PayrollDeductionAuthorizationEnglish' },
            { label: 'Return to Work Policy - English', page: 'ReturnToWorkPolicyEnglish' },
            { label: 'Sick Day Policy - English', page: 'SickDayPolicyEnglish' },
            { label: 'Workers Compensation Policy - English', page: 'WorkersCompPolicyEnglish' },
            { label: 'Arizona A-4 - English', page: 'ArizonaA4' },
            { label: 'Rate Agreement - English', page: 'RateAgreement' }
        ],
        spanish: [
            { label: 'Federal W-4 2026 - Spanish', page: 'FederalW4_2026_Spanish' },
            { label: 'Payroll Deduction Authorization - Spanish', page: 'PayrollDeductionAuthorizationSpanish' },
            { label: 'Return to Work Policy - Spanish', page: 'ReturnToWorkPolicySpanish' },
            { label: 'Sick Day Policy - Spanish', page: 'SickDayPolicySpanish' },
            { label: 'Workers Compensation Policy - Spanish', page: 'WorkersCompPolicySpanish' },
            { label: 'Rate Agreement - Spanish', page: 'RateAgreementSpanish' },
            { label: 'Arizona A-4 - Spanish', page: 'ArizonaA4Spanish' }
        ]
    }
};

const LIVE_IN_DOCS = {
    english: [
        { label: 'Difficulty of Care Income Attestation - English', page: 'DifficultyOfCareIncomeAttestationEnglish' },
        { label: 'Parents as Paid Caregiver for Minor Children Affidavit - English', page: 'ParentPaidCaregiverAffidavitEnglish' }
    ],
    spanish: [
        { label: 'Difficulty of Care Income Attestation - Spanish', page: 'DifficultyOfCareIncomeAttestationSpanish' },
        { label: 'Parents as Paid Caregiver for Minor Children Affidavit - Spanish', page: 'ParentPaidCaregiverAffidavitSpanish' }
    ]
};

export default class PhaseDocumentTracker extends NavigationMixin(LightningElement) {
    @api cardTitle = 'Forms';

    division;
    preferredLanguage;
    contactId;
    drivingStatus;
    contractType;
    serviceType;
    livingStatus;
    isLoading = true;
    errorMessage;

    tabs = [];
    activeTabName;

    signedPages = {};

    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];
    statusOptions = STATUS_OPTIONS;

    // Shared hidden file input state
    pendingFieldApiName;
    pendingDocumentLabel;
    pendingUploadKind = 'status';   // 'status' or 'basedForm'
    pendingFormLabel;
    pendingStage = 'signed';

    // Label -> FormState for label-keyed lists (Based Forms, Pay and Tax, Live-In)
    basedFormStates = {};

    // Label -> CompletedFile for the Driver / Non-Driver / Service Agreement rows
    completedFiles = {};

    // Documents sent in this session that are waiting for PandaDoc to report completion
    pendingDocs = {};

    // Service data is kept per service token (atc / hah / rsp), so every
    // selected service shows its own forms and documents.
    serviceDocsBySvc = {};
    serviceFormsBySvc = {};
    serviceDocsResults = {};
    serviceFormsResults = {};

    certDriverDocsResult;
    driverFormDocsResult;
    fileInfoResult;
    certDriverDocs = [];
    driverFormDocs = [];
    uploadedFileInfo = {};

    _onWindowFocus;

    /* =====================================================================
     * LIFECYCLE
     * ===================================================================== */

    connectedCallback() {
        // Returning from the PandaDoc tab refreshes statuses and file names
        this._onWindowFocus = () => this.refreshAfterPandaDoc();
        window.addEventListener('focus', this._onWindowFocus);
    }

    disconnectedCallback() {
        window.removeEventListener('focus', this._onWindowFocus);
    }

    /* =====================================================================
     * WIRES
     * ===================================================================== */

    @wire(getCurrentUserContext)
    wiredUserContext({ data, error }) {
        if (data) {
            this.division = data.division;
            this.preferredLanguage = data.preferredLanguage;
            this.contactId = data.contactId;
            this.drivingStatus = data.drivingStatus;
            this.contractType = data.contractType;
            this.serviceType = data.serviceType;
            this.livingStatus = data.livingStatus;
            this.loadTabs();
            this.loadSignatureStatuses();
        } else if (error) {
            this.isLoading = false;
            this.errorMessage = this.reduceError(error);
        }
    }

    @wire(getCertificationAndDriverDocuments, { contactId: '$contactId' })
    wiredCertDriverDocs(result) {
        this.certDriverDocsResult = result;
        if (result.data) {
            this.certDriverDocs = result.data;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    @wire(getDriverFormDocuments, { contactId: '$contactId', drivingStatus: '$drivingStatus', language: '$preferredLanguage' })
    wiredDriverFormDocs(result) {
        this.driverFormDocsResult = result;
        if (result.data) {
            this.driverFormDocs = result.data;
            this.loadCompletedFiles();
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    // One wire per service for documents and agreement forms.
    // Each wire is only active when that service is selected on the contact.
    @wire(getServiceFormDocuments, { contactId: '$contactId', serviceType: '$atcParam' })
    wiredAtcServiceDocs(result) {
        this.handleServiceDocsResult('atc', result);
    }

    @wire(getServiceFormDocuments, { contactId: '$contactId', serviceType: '$hahParam' })
    wiredHahServiceDocs(result) {
        this.handleServiceDocsResult('hah', result);
    }

    @wire(getServiceFormDocuments, { contactId: '$contactId', serviceType: '$rspParam' })
    wiredRspServiceDocs(result) {
        this.handleServiceDocsResult('rsp', result);
    }

    @wire(getServiceAgreementForms, { contactId: '$contactId', serviceType: '$atcParam', language: '$preferredLanguage' })
    wiredAtcServiceForms(result) {
        this.handleServiceFormsResult('atc', result);
    }

    @wire(getServiceAgreementForms, { contactId: '$contactId', serviceType: '$hahParam', language: '$preferredLanguage' })
    wiredHahServiceForms(result) {
        this.handleServiceFormsResult('hah', result);
    }

    @wire(getServiceAgreementForms, { contactId: '$contactId', serviceType: '$rspParam', language: '$preferredLanguage' })
    wiredRspServiceForms(result) {
        this.handleServiceFormsResult('rsp', result);
    }

    @wire(getUploadedFileInfo, { contactId: '$contactId' })
    wiredFileInfo(result) {
        this.fileInfoResult = result;
        if (result.data) {
            this.uploadedFileInfo = result.data;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    handleServiceDocsResult(service, result) {
        this.serviceDocsResults = { ...this.serviceDocsResults, [service]: result };
        if (result.data) {
            this.serviceDocsBySvc = { ...this.serviceDocsBySvc, [service]: result.data };
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    handleServiceFormsResult(service, result) {
        this.serviceFormsResults = { ...this.serviceFormsResults, [service]: result };
        if (result.data) {
            this.serviceFormsBySvc = { ...this.serviceFormsBySvc, [service]: result.data };
            this.loadCompletedFiles();
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    /* =====================================================================
     * LOAD
     * ===================================================================== */

    loadTabs() {
        this.isLoading = true;

        getPhaseTabs({
            division: this.division,
            language: this.preferredLanguage
        })
            .then((result) => {
                // Member / Tutor only see their Based Forms tab
                const visibleTabs = this.filterTabsByDivision(result || []);

                this.tabs = visibleTabs.map((tab) => ({
                    ...tab,
                    key: tab.phaseName,
                    displayName: this.uiText.tabNames[tab.phaseName] || tab.phaseName
                }));

                if (this.tabs.length) {
                    this.activeTabName = this.tabs[0].phaseName;
                }

                this.loadBasedFormStates();
            })
            .catch((error) => {
                this.errorMessage = this.reduceError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadSignatureStatuses() {
        if (!this.contactId) {
            return;
        }

        getDocumentSignatureStatuses({ contactId: this.contactId })
            .then((result) => {
                const map = {};
                (result || []).forEach((status) => {
                    map[status.page] = {
                        isSigned: !!status.isSigned,
                        signedDate: status.signedDate
                    };
                });
                this.signedPages = map;
            })
            .catch((error) => {
                console.error('Error loading signature statuses', error);
            });
    }

    /**
     * Files already attached for the Based Forms / Pay and Tax / Live-In
     * lists. Those rows have no status field, so files are matched on label.
     */
    loadBasedFormStates() {
        if (!this.contactId) {
            return;
        }

        const labels = [];
        const collect = (list) => {
            (list || []).forEach((doc) => labels.push(doc.label));
        };

        const byDivision = BASED_FORMS_DOCS[this.normalizedDivision];
        if (byDivision) {
            collect(this.isSpanish ? byDivision.spanish : byDivision.english);
        }

        if (this.isPayTaxAllowed) {
            const byContract = PAY_TAX_DOCS[this.contractKey];
            if (byContract) {
                collect(this.isSpanish ? byContract.spanish : byContract.english);
            }
        }

        collect(this.isSpanish ? LIVE_IN_DOCS.spanish : LIVE_IN_DOCS.english);

        if (!labels.length) {
            return;
        }

        getFilesByLabel({
            recordId: this.contactId,
            labels: [...new Set(labels)]
        })
            .then((states) => {
                const map = {};
                (states || []).forEach((state) => {
                    map[state.label] = state;
                });
                this.basedFormStates = map;
            })
            .catch((error) => {
                console.error('Could not load Based Forms files', error);
            });
    }

    /**
     * Loads the saved final PDF for every Driver / Non-Driver / Service
     * Agreement form row, matched by label.
     */
    loadCompletedFiles() {
        if (!this.contactId) {
            return;
        }

        // Gathers agreement forms from every selected service
        const serviceForms = Object.values(this.serviceFormsBySvc || {})
            .reduce((all, list) => all.concat(list || []), []);

        const labels = [...(this.driverFormDocs || []), ...serviceForms]
            .map((doc) => doc.label)
            .filter((label) => !!label);
        const unique = [...new Set(labels)];

        if (!unique.length) {
            this.completedFiles = {};
            return;
        }

        getCompletedFiles({ contactId: this.contactId, formLabels: unique })
            .then((files) => {
                const map = {};
                (files || []).forEach((f) => {
                    map[f.label] = f;
                });
                this.completedFiles = map;
            })
            .catch((error) => {
                console.error('Could not load completed form files', error);
            });
    }

    /* =====================================================================
     * CATEGORY FILTERING
     * Rules from the eligibility matrix:
     *   Member / Tutor    -> Based Forms only; no other categories
     *   Parent Provider   -> Based Forms; Pay and Tax 1099 only; no driver
     *                        forms or driver documents; Service and Live-In
     *                        follow the contact's values
     *   Provider          -> every category follows the contact's values
     *                        (W2 or 1099, Driver or Non-Driver, ATC/HAH/RSP, Live-In)
     * A blank contact value hides the category that depends on it.
     * ===================================================================== */

    /** Normalizes a picklist/label value: lowercase, letters and digits only. */
    normalizeToken(value) {
        if (value === null || value === undefined) {
            return '';
        }
        const token = String(value).toLowerCase().replace(/[^a-z0-9]/g, '');
        return TOKEN_ALIASES[token] || token;
    }

    get divisionToken() {
        return this.normalizeToken(this.division);
    }

    get isDivisionOnly() {
        return DIVISION_ONLY_TOKENS.includes(this.divisionToken);
    }

    get isParentProvider() {
        return this.divisionToken === PARENT_PROVIDER_TOKEN;
    }

    /** 'w4' for a W2 contract, '1099' for a 1099 contract, '' otherwise. */
    get contractKey() {
        const token = this.normalizeToken(this.contractType);
        return CONTRACT_KEY_MAP[token] || '';
    }

    /** 'driver', 'nondriver', or '' when blank. */
    get drivingToken() {
        return this.normalizeToken(this.drivingStatus);
    }

    /** Driver document and driver form rows: Provider + Driver only. */
    get canShowDriverItems() {
        return !this.isParentProvider && this.drivingToken === 'driver';
    }

    /** Non-Driver form rows: Provider + Non-Driver only. */
    get canShowNonDriverItems() {
        return !this.isParentProvider && this.drivingToken === 'nondriver';
    }

    /** Pay and Tax: any contract for Provider; 1099 only for Parent Provider. */
    get isPayTaxAllowed() {
        if (!this.contractKey) {
            return false;
        }
        if (this.isParentProvider) {
            return this.contractKey === '1099';
        }
        return true;
    }

    /**
     * The contact's service value, split into normalized tokens.
     * Multi-select "atc;hah;rsp" becomes ['atc', 'hah', 'rsp'].
     */
    get serviceTokens() {
        if (!this.serviceType || this.serviceType === 'none') {
            return [];
        }
        return String(this.serviceType)
            .split(';')
            .map((part) => this.normalizeToken(part))
            .filter((token) => token.length > 0);
    }

    /** Every selected service, in display order (ATC, HAH, RSP). */
    get activeServices() {
        const tokens = this.serviceTokens;
        return SERVICE_PRIORITY.filter((service) => tokens.includes(service));
    }

    // Per-service wire parameters. Each is undefined unless that service
    // is selected, so its wire stays idle.
    get atcParam() {
        return this.serviceTokens.includes('atc') ? 'atc' : undefined;
    }

    get hahParam() {
        return this.serviceTokens.includes('hah') ? 'hah' : undefined;
    }

    get rspParam() {
        return this.serviceTokens.includes('rsp') ? 'rsp' : undefined;
    }

    /** Tabs filter: Member and Tutor see only Based Forms. */
    filterTabsByDivision(tabs) {
        if (this.isDivisionOnly) {
            return tabs.filter((tab) => tab.phaseName === BASED_FORMS_PHASE_NAME);
        }
        return tabs;
    }

    /* =====================================================================
     * GETTERS
     * ===================================================================== */

    get isMemberDivision() {
        return this.normalizedDivision === 'member';
    }

    get normalizedDivision() {
        return this.division ? this.division.toLowerCase() : '';
    }

    get isSpanish() {
        return this.preferredLanguage === 'spanish';
    }

    get uiText() {
        return this.isSpanish ? UI_TEXT.spanish : UI_TEXT.english;
    }

    get hasContractType() {
        return this.contractType && this.contractType !== 'none';
    }

    // True when the contact has at least one selected service
    get hasServiceType() {
        return this.activeServices.length > 0;
    }

    get isLiveIn() {
        return this.livingStatus === 'live-in';
    }

    get activeTabIndex() {
        return this.tabs.findIndex((tab) => tab.phaseName === this.activeTabName);
    }

    get displayTabs() {
        const activeIndex = this.activeTabIndex;

        return this.tabs.map((tab, index) => {
            let segmentClass = 'phase-segment';

            if (index === activeIndex) {
                segmentClass += ' phase-segment_active';
            } else if (index < activeIndex) {
                segmentClass += ' phase-segment_completed';
            }

            return {
                ...tab,
                segmentClass,
                isActive: index === activeIndex
            };
        });
    }

    get activeTab() {
        return this.tabs.find((tab) => tab.phaseName === this.activeTabName);
    }

    get isBasedFormsTab() {
        return !!this.activeTab && this.activeTab.phaseName === BASED_FORMS_PHASE_NAME;
    }

    get isDocsCertTab() {
        return !!this.activeTab && this.activeTab.phaseName === DOCS_CERT_PHASE_NAME;
    }

    get isPayTaxTab() {
        return !!this.activeTab && this.activeTab.phaseName === PAY_TAX_PHASE_NAME;
    }

    get isServiceFormsTab() {
        return !!this.activeTab && this.activeTab.phaseName === SERVICE_FORMS_PHASE_NAME;
    }

    get isSpecialCategoryTab() {
        return this.isBasedFormsTab || this.isDocsCertTab || this.isPayTaxTab || this.isServiceFormsTab;
    }

    get isOtherDocumentTab() {
        return !this.isSpecialCategoryTab && !!this.activeTab;
    }

    get showBasedFormsSection() {
        return this.isBasedFormsTab && !!BASED_FORMS_DOCS[this.normalizedDivision];
    }

    get showDocsCertSection() {
        return this.isDocsCertTab && this.certDriverDocs.length > 0;
    }

    get showPayTaxSection() {
        return this.isPayTaxTab && this.isPayTaxAllowed && !!PAY_TAX_DOCS[this.contractKey];
    }

    get showLiveInSection() {
        return this.isServiceFormsTab && this.isLiveIn;
    }

    // Shown when at least one selected service has documents or forms
    get showServiceFormsSection() {
        return this.isServiceFormsTab && this.serviceGroups.length > 0;
    }

    get showNotEligibleMessage() {
        if (this.isBasedFormsTab) {
            return !this.showBasedFormsSection;
        }
        if (this.isDocsCertTab) {
            return !this.showDocsCertSection;
        }
        if (this.isPayTaxTab) {
            return !this.showPayTaxSection;
        }
        if (this.isServiceFormsTab) {
            return !this.showServiceFormsSection && !this.showLiveInSection && !this.hasServiceAgreementFormRows;
        }
        return false;
    }

    get notEligibleMessage() {
        const text = this.uiText.notEligible;

        if (this.isBasedFormsTab) {
            return text.basedForms;
        }
        if (this.isPayTaxTab) {
            return text.payTax;
        }
        if (this.isServiceFormsTab) {
            return text.serviceForms;
        }
        return text.generic;
    }

    get basedFormsDocuments() {
        if (!this.showBasedFormsSection) {
            return [];
        }
        const byDivision = BASED_FORMS_DOCS[this.normalizedDivision];
        return this.buildRows(this.isSpanish ? byDivision.spanish : byDivision.english);
    }

    get payTaxDocuments() {
        if (!this.showPayTaxSection) {
            return [];
        }
        const byContract = PAY_TAX_DOCS[this.contractKey];
        return this.buildRows(this.isSpanish ? byContract.spanish : byContract.english);
    }

    get liveInDocuments() {
        if (!this.showLiveInSection) {
            return [];
        }
        return this.buildRows(this.isSpanish ? LIVE_IN_DOCS.spanish : LIVE_IN_DOCS.english);
    }

    get autoDocumentRows() {
        if (!this.showDocsCertSection) {
            return [];
        }
        return this.certDriverDocs
            .filter((doc) => doc.groupName === 'auto')
            .map((doc) => this.buildStatusRow(doc));
    }

    get certificationRows() {
        if (!this.showDocsCertSection) {
            return [];
        }
        return this.certDriverDocs
            .filter((doc) => doc.groupName === 'certification')
            .map((doc) => this.buildStatusRow(doc));
    }

    // Driver document rows only for Provider + Driver
    get driverDocumentRows() {
        if (!this.showDocsCertSection || !this.canShowDriverItems) {
            return [];
        }
        return this.certDriverDocs
            .filter((doc) => doc.groupName === 'driver')
            .map((doc) => this.buildStatusRow(doc));
    }

    get hasDriverDocumentRows() {
        return this.driverDocumentRows.length > 0;
    }

    // Driver form rows only for Provider + Driver
    get driverFormRows() {
        if (!this.showDocsCertSection || !this.canShowDriverItems) {
            return [];
        }
        return this.driverFormDocs
            .filter((doc) => doc.groupName === 'driverForms')
            .map((doc) => this.buildFormRow(doc));
    }

    get hasDriverFormRows() {
        return this.driverFormRows.length > 0;
    }

    // Non-driver form rows only for Provider + Non-Driver
    get nonDriverFormRows() {
        if (!this.showDocsCertSection || !this.canShowNonDriverItems) {
            return [];
        }
        return this.driverFormDocs
            .filter((doc) => doc.groupName === 'nonDriverForms')
            .map((doc) => this.buildFormRow(doc));
    }

    get hasNonDriverFormRows() {
        return this.nonDriverFormRows.length > 0;
    }

    /**
     * One section per selected service (ATC, HAH, RSP). Each entry has its
     * own certification heading, agreement heading, status rows and form
     * rows. Services with nothing to show are left out.
     */
    get serviceGroups() {
        if (!this.isServiceFormsTab) {
            return [];
        }

        return this.activeServices
            .map((service) => {
                const statusRows = (this.serviceDocsBySvc[service] || [])
                    .map((doc) => this.buildStatusRow(doc));

                const formRows = (this.serviceFormsBySvc[service] || [])
                    .filter((doc) => doc.groupName === 'serviceAgreementForms')
                    .map((doc) => this.buildFormRow(doc));

                return {
                    key: service,
                    certificationHeading: this.certificationHeadingFor(service),
                    agreementHeading: this.agreementHeadingFor(service),
                    statusRows,
                    formRows,
                    hasStatusRows: statusRows.length > 0,
                    hasFormRows: formRows.length > 0
                };
            })
            .filter((group) => group.hasStatusRows || group.hasFormRows);
    }

    /** Every agreement form row across all selected services. */
    get serviceAgreementFormRows() {
        return this.serviceGroups.reduce((all, group) => all.concat(group.formRows), []);
    }

    get hasServiceAgreementFormRows() {
        return this.serviceAgreementFormRows.length > 0;
    }

    certificationHeadingFor(service) {
        if (service === 'atc') {
            return this.isSpanish ? 'Certificación de Servicio ATC' : 'Service ATC Certification';
        }
        if (service === 'hah') {
            return this.isSpanish ? 'Certificación de Servicio HAH' : 'Service HAH Certification';
        }
        return this.uiText.serviceFormsHeading;
    }

    agreementHeadingFor(service) {
        const languageLabel = this.isSpanish ? 'Spanish' : 'English';

        if (service === 'atc') {
            return `Service - ATC - ${languageLabel}`;
        }
        if (service === 'hah') {
            return `Service - HAH - ${languageLabel}`;
        }
        if (service === 'rsp') {
            return `Service - RSH - ${languageLabel}`;
        }
        return this.uiText.serviceAgreementFormsHeading;
    }

    get activeTabHasAction() {
        if (!this.activeTab || this.isSpecialCategoryTab) {
            return false;
        }
        return !!(this.activeTab.isApplicable && this.activeTab.contentDocumentId);
    }

    get activeTabIsNotApplicable() {
        if (!this.activeTab || this.isSpecialCategoryTab) {
            return false;
        }
        return !this.activeTab.isApplicable;
    }

    get activeTabButtonLabel() {
        if (!this.activeTab) {
            return this.uiText.view;
        }
        return this.activeTab.documentLabel
            ? `${this.uiText.view} ${this.activeTab.documentLabel}`
            : this.uiText.view;
    }

    /* =====================================================================
     * ROW BUILDERS
     * ===================================================================== */
    normalizeStatus(raw) {
        if (raw === null || raw === undefined || raw === '') {
            return 'None';
        }
        const cleaned = String(raw).trim().toLowerCase().replace(/^document\./, '');
        const match = STATUS_OPTIONS.find(
            (o) => o.value.toLowerCase() === cleaned || o.label.toLowerCase() === cleaned
        );
        return match ? match.value : 'None';
    }
 
    buildStatusRow(doc) {
        const text = this.uiText;
         const status = this.normalizeStatus(doc.status);
        const isCompleted = !!doc.isCompleted||status === 'Completed' ;
        const fileInfo = this.uploadedFileInfo[doc.fieldApiName];
        const uploadSource = fileInfo ? fileInfo.uploadSource : null;
        const canDelete = !isCompleted && !!fileInfo && (uploadSource === UPLOAD_SOURCE || !uploadSource);

        return {
            key: doc.fieldApiName,
            label: doc.label,
            fieldApiName: doc.fieldApiName,
            status: status,
            isCompleted,
            statusClass: 'status-badge status-badge_' + (status === 'None' ? 'not-started' : status).toLowerCase().replace(/\s+/g, '-'),
            rowClass: isCompleted ? 'document-row document-row_completed' : 'document-row',
            uploadLabel: status === 'Rejected' || status === 'Expired' ? text.reUpload : text.upload,
            hasFile: !!fileInfo,
            fileName: fileInfo ? fileInfo.fileName : '',
            contentDocumentId: fileInfo ? fileInfo.contentDocumentId : null,
            canDelete
        };
    }

    buildFormRow(doc) {
        const status = this.normalizeStatus(doc.status);
        const isCompleted = !!doc.isCompleted|| status === 'Completed';
        const file = this.completedFiles[doc.label];
        return {
            key: doc.fieldApiName,
            label: doc.label,
            fieldApiName: doc.fieldApiName,
            page: doc.page,
            status: status,
            isCompleted,
            statusClass: 'status-badge status-badge_' + (status === 'None' ? 'not-started' : status).toLowerCase().replace(/\s+/g, '-'),
            rowClass: isCompleted ? 'document-row document-row_completed' : 'document-row',
            hasFile: !!file,
            fileName: file ? file.fileName : '',
            contentDocumentId: file ? file.contentDocumentId : null
        };
    }

    buildRows(docs) {
        const text = this.uiText;
        return (docs || []).map((doc, index) => {
            const signedInfo = this.signedPages[doc.page];
            const isSigned = !!(signedInfo && signedInfo.isSigned);

            const state = this.basedFormStates[doc.label] || {};
            const files = state.files || [];
            const newest = files.length ? files[0] : null;

            const workflowStatus = this.normalizeStatus(state.status);
            const isCompleted = workflowStatus === 'Completed';
            const nextAction = state.nextAction || 'send';

            return {
                key: doc.page + '-' + index,
                label: doc.label,
                page: doc.page,
                isSigned,
                status: workflowStatus,
                isCompleted,
                nextAction,
                canSend: state.canSend !== false && !isCompleted,
                canUpload: state.canUpload === true,
                uploadLabel: nextAction === 'uploadFinal' ? text.uploadFinal : text.uploadSigned,
                buttonLabel: isCompleted ? text.completed : text.reviewAndComplete,
                buttonVariant: isCompleted ? 'neutral' : 'brand',
                tsTemplate: doc.tsTemplate,
                hasFile: !!newest,
                fileName: newest ? newest.name : '',
                contentDocumentId: newest ? newest.contentDocumentId : null,
                rowClass: isCompleted ? 'document-row document-row_completed' : 'document-row'
            };
        });
    }

    /* =====================================================================
     * NAVIGATION / TABS
     * ===================================================================== */

    handleTabClick(event) {
        this.activeTabName = event.currentTarget.dataset.phase;
    }

    handleViewClick(event) {
        const page = event.currentTarget.dataset.page;

        if (page) {
            this.openForm(page);
        } else {
            this.handleRegularDocumentViewClick();
        }
    }

    openForm(page) {
        const url = `${VF_DOMAIN}/apex/${page}?recordId=${this.contactId}`;
        window.open(url, '_blank');
    }

    handleRegularDocumentViewClick() {
        if (!this.activeTab) {
            return;
        }
        if (this.activeTab.contentDocumentId) {
            const url = `${VF_DOMAIN}/apex/PhaseDocumentViewer?cdId=${this.activeTab.contentDocumentId}`;
            window.open(url, '_blank');
        }
    }

    handleFileClick(event) {
        event.preventDefault();
        const contentDocumentId = event.currentTarget.dataset.docid;
        if (!contentDocumentId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocumentId
            }
        });
    }

    /* =====================================================================
     * PANDADOC: "Review and Complete" (community page)
     * The contact is NOT emailed. The link opens in a new tab.
     * ===================================================================== */

    /**
     * Based Forms / Pay and Tax / Live-In rows. The label is the form key,
     * because these rows are not backed by a Contact status field.
     */
    async handleBasedFormReviewClick(event) {
        const formLabel = event.currentTarget.dataset.label;
        if (!formLabel || !this.contactId) {
            return;
        }

        await this.openPandaDocForm(this.contactId, formLabel, formLabel, null, false);
    }

    /**
     * Driver Forms / Non-Driver Forms / Service Agreement Forms rows.
     * The Contact field API name is the form key; the label is the
     * human-readable name used for the saved file title.
     */
    async handleFormViewClick(event) {
        const formApiName = event.currentTarget.dataset.field;
        const formLabel = event.currentTarget.dataset.label || formApiName;

        if (!formApiName || !this.contactId) {
            return;
        }

        await this.openPandaDocForm(this.contactId, formApiName, formLabel, null, false);
    }

    wait(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    /**
     * Creates the PandaDoc document, waits until it is ready, sends it
     * silently, and opens the signing link in a new tab. Documents that
     * update a Contact status field are tracked so returning to the portal
     * can save the final PDF and set the status to Completed.
     */
    async openPandaDocForm(contactId, formApiName, formLabel, opportunityId, sendEmail) {
        // Open the tab now, so the browser doesn't block the popup after the awaits
        const win = window.open('', '_blank');
        this.isLoading = true;

        try {
            const oppId = opportunityId || null;
            const docId = await createForm({ contactId, formApiName, formLabel, opportunityId: oppId });

            let status = await getStatus({ docId });
            for (let i = 0; i < POLL_MAX_ATTEMPTS && status === 'document.uploaded'; i++) {
                await this.wait(POLL_INTERVAL_MS);
                status = await getStatus({ docId });
            }

            const link = await prepareForSigning({
                docId,
                contactId,
                opportunityId: oppId,
                sendEmail: sendEmail === true,
                formApiName
            });

            if (formApiName && formApiName.endsWith('__c')) {
                this.pendingDocs = {
                    ...this.pendingDocs,
                    [formLabel]: { docId, contactId, formApiName, formLabel }
                };
            }

            if (win) {
                win.location = link;
                this.showToast('Form ready', 'Complete and sign the form.', 'success');
            } else {
                this.showToast(
                    'Pop-up blocked',
                    'Allow pop-ups for this site, then select Review and Complete the form again.',
                    'warning'
                );
            }
        } catch (e) {
            if (win) {
                win.close();
            }
            this.showToast('Error', this.reduceError(e), 'error');
        } finally {
            this.isLoading = false;
            this.refreshAfterPandaDoc();
        }
    }

    /* =====================================================================
     * UPLOADS (status rows and label-keyed rows)
     * ===================================================================== */

    /**
     * Upload button on a Documents / Certifications / Driver row.
     * Triggers the shared hidden file input.
     */
    handleUploadButtonClick(event) {
        this.pendingUploadKind = 'status';
        this.pendingFieldApiName = event.currentTarget.dataset.field;
        this.pendingDocumentLabel = event.currentTarget.dataset.label;

        const input = this.template.querySelector('.hidden-file-input');
        if (input) {
            input.value = null;
            input.click();
        }
    }

    /**
     * Upload button on a Based Forms / Pay and Tax / Live-In row.
     */
    handleBasedFormUploadClick(event) {
        this.pendingUploadKind = 'basedForm';
        this.pendingFormLabel = event.currentTarget.dataset.label;
        this.pendingFieldApiName = null;
        this.pendingStage =
            event.currentTarget.dataset.action === 'uploadFinal' ? 'final' : 'signed';

        const input = this.template.querySelector('.hidden-file-input');
        if (input) {
            input.value = null;
            input.click();
        }
    }

    applyBasedFormState(formLabel, state) {
        if (!state) {
            return;
        }
        this.basedFormStates = {
            ...this.basedFormStates,
            [formLabel]: state
        };
    }

    /**
     * Routes the picked file to the correct Apex method.
     */
    handleFileSelected(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }

        if (this.pendingUploadKind === 'basedForm') {
            this.uploadBasedFormFile(file);
            return;
        }

        if (!this.pendingFieldApiName) {
            return;
        }

        const fieldApiName = this.pendingFieldApiName;
        const documentLabel = this.pendingDocumentLabel;

        const reader = new FileReader();
        reader.onload = () => {
            const base64Data = reader.result.split(',')[1];
            this.isLoading = true;

            uploadDocument({
                contactId: this.contactId,
                fieldApiName,
                base64Data,
                fileName: file.name,
                uploadSource: UPLOAD_SOURCE,
                documentLabel
            })
                .then(() => {
                    this.showToast('Success', this.uiText.uploadSuccess, 'success');
                    return this.wait(1200);
                })
                .then(() => this.refreshAll())
                .catch((error) => {
                    this.showToast('Error', this.reduceError(error) || this.uiText.uploadError, 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        };
        reader.readAsDataURL(file);
    }

    /**
     * Saves a Based Forms / Pay and Tax / Live-In attachment.
     */
    uploadBasedFormFile(file) {
        const formLabel = this.pendingFormLabel;
        const stage = this.pendingStage || 'signed';
        if (!formLabel) {
            return;
        }

        const reader = new FileReader();

        reader.onerror = () => {
            this.showToast('Error', this.uiText.uploadError, 'error');
        };

        reader.onload = () => {
            const base64Data = reader.result.split(',')[1];
            this.isLoading = true;

            uploadFormFile({
                recordId: this.contactId,
                fieldApiName: null,
                formLabel: formLabel,
                fileName: file.name,
                base64Data: base64Data,
                stage: stage
            })
                .then((state) => {
                    this.showToast(
                        'Success',
                        (state && state.message) || this.uiText.uploadSuccess,
                        'success'
                    );
                    this.applyBasedFormState(formLabel, state);
                })
                .catch((error) => {
                    this.showToast('Error', this.reduceError(error) || this.uiText.uploadError, 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        };

        reader.readAsDataURL(file);
    }

    /**
     * Removes an uploaded file this portal user is allowed to delete.
     */
    handleDeleteFile(event) {
        const contentDocumentId = event.currentTarget.dataset.docid;
        const fieldApiName = event.currentTarget.dataset.field;
        if (!contentDocumentId || !fieldApiName) {
            return;
        }

        // eslint-disable-next-line no-alert
        if (!window.confirm(this.uiText.confirmDeleteFile)) {
            return;
        }

        deleteUploadedDocument({ contactId: this.contactId, contentDocumentId, fieldApiName })
            .then(() => {
                this.showToast('Success', 'File removed. Status reset to Not Started.', 'success');
                return this.wait(1200);
            })
            .then(() => this.refreshAll())
            .catch((error) => {
                this.showToast('Error', this.reduceError(error) || this.uiText.uploadError, 'error');
            });
    }

    /* =====================================================================
     * REFRESH
     * ===================================================================== */

    /**
     * Re-reads every wired list after an upload or delete, so the rows and
     * file names update without a page reload. Skips wires that have not
     * emitted yet.
     */
    refreshAll() {
        const results = [
            this.certDriverDocsResult,
            this.driverFormDocsResult,
            this.fileInfoResult,
            ...Object.values(this.serviceDocsResults),
            ...Object.values(this.serviceFormsResults)
        ].filter(Boolean);
        return Promise.all(results.map((r) => refreshApex(r)));
    }

    /**
     * Refreshes everything the PandaDoc flow can change. First checks any
     * tracked documents with PandaDoc, so a completed form is saved and set
     * to Completed even if the webhook missed it.
     */
    refreshAfterPandaDoc() {
        this.loadBasedFormStates();
        this.loadCompletedFiles();
        return this.syncPendingDocuments().then(() => this.refreshAll());
    }

    /**
     * For every tracked document, asks PandaDoc for its status. When the
     * document is completed, the PDF is saved to the contact and the form's
     * status is set to Completed. The document is then removed from the
     * pending list.
     */
    async syncPendingDocuments() {
        const entries = Object.entries(this.pendingDocs);
        if (!entries.length) {
            return;
        }

        let anyCompleted = false;

        for (const [key, pending] of entries) {
            try {
                const result = await syncPortalDocument({
                    docId: pending.docId,
                    contactId: pending.contactId,
                    formApiName: pending.formApiName,
                    formLabel: pending.formLabel
                });

                if (result === 'document.completed') {
                    const next = { ...this.pendingDocs };
                    delete next[key];
                    this.pendingDocs = next;
                    anyCompleted = true;

                    this.showToast(
                        'Form completed',
                        `${pending.formLabel} has been saved to the contact's files.`,
                        'success'
                    );
                } else if (result && result.startsWith('status-blocked:')) {
                    // File is saved; the status could not be set. Keep retrying.
                    anyCompleted = true;
                    this.showToast(
                        'Status not updated',
                        result.replace('status-blocked: ', ''),
                        'error'
                    );
                }
            } catch (error) {
                console.error('Could not sync PandaDoc document', this.reduceError(error));
                this.showToast('Could not sync form', this.reduceError(error), 'error');
            }
        }

        if (anyCompleted) {
            this.loadCompletedFiles();
        }
    }

    handleRefreshClick() {
        this.isLoading = true;
        this.refreshAfterPandaDoc().finally(() => {
            this.isLoading = false;
        });
    }

    /* =====================================================================
     * HELPERS
     * ===================================================================== */

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return (
            error?.body?.message ||
            error?.message ||
            'An unknown error occurred.'
        );
    }
}