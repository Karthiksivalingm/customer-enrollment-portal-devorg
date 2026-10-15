import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import PdfLib from '@salesforce/resourceUrl/PdfLib';
import getFormMapping from '@salesforce/apex/DynamicFormsController.getFormMapping';
import updateFormStatus from '@salesforce/apex/DynamicFormsController.updateFormStatus';
import getPdfForFilling from '@salesforce/apex/DynamicFormsController.getPdfForFilling';
import getMergeFieldValues from '@salesforce/apex/DynamicFormsController.getMergeFieldValues';
import saveFilledPdf from '@salesforce/apex/DynamicFormsController.saveFilledPdf';
import matchTemplates from '@salesforce/apex/TSDocumentService.matchTemplates';
import getFormStates from '@salesforce/apex/FormWorkflowService.getFormStates';
import uploadFormFile from '@salesforce/apex/FormWorkflowService.uploadFormFile';
import promoteSignedToFinal from '@salesforce/apex/FormWorkflowService.promoteSignedToFinal';
import createForm from '@salesforce/apex/PandaDocService.createForm';
import getStatus from '@salesforce/apex/PandaDocService.getStatus';
import prepareForSigning from '@salesforce/apex/PandaDocService.prepareForSigning';
import getContactStatuses from '@salesforce/apex/PandaDocService.getContactStatuses';

// Hardcoded status options - no Apex call needed
const STATUS_OPTIONS = [
    { label: 'None', value: 'None' },
    { label: 'Sent', value: 'Sent' },
    { label: 'Pending', value: 'Pending' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Completed', value: 'completed' },
    { label: 'Expired', value: 'Expired' },
    { label: 'Declined', value: 'Declined' },
    { label: 'Viewed', value: 'Viewed' },
    { label: 'Not Needed', value: 'Not Needed' }
];

// Keys returned by DynamicFormsController.getFormMapping()
const LANG_ENGLISH = 'English';
const LANG_SPANISH = 'Spanish';

// Wait for PandaDoc to finish preparing a new document
const POLL_INTERVAL_MS = 1000;
const POLL_MAX_ATTEMPTS = 15;

// While any row shows "Sent", re-read the Contact statuses so "Completed"
// appears once the webhook has saved the signed file.
const STATUS_REFRESH_MS = 15000;
const STATUS_MAX_REFRESHES = 240;

/* =========================================================================
 * Category filtering support.
 *
 * Every mapping key from Apex follows the shape:
 *     "<Prefix> - <Value> - <Language>"
 * e.g. "Driving Status - Non-Driver - English"
 * ========================================================================= */
const CATEGORY_FIELD_MAP = {
    'driving status': 'drivingStatusTokens',
    'contract type': 'contractTypeTokens',
    'service type': 'serviceTypeTokens',
    'living status': 'livingStatusTokens'
};

// Picklist values and mapping keys don't always spell things identically
const TOKEN_ALIASES = {
    rsh: 'rsp',        // legacy "Service Type - RSH" keys
    respite: 'rsp',
    habilitation: 'hah',
    nondriver: 'nondriver',
    w4: 'w2',          // some orgs label the W2 contract "W-4"
    notlivein: 'notlivein'
};

export default class DynamicFormsContact extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    /** Contact field holding the preferred language (English / Spanish). */
    @api languageFieldApiName = 'Preferred_Language__c';

    /** Contact field holding Division (Member, Parent Provider, Provider, Tutor). */
    @api divisionFieldApiName = 'Division__c';

    /** Filter fields. Leave one blank to switch that filter off. */
    @api drivingStatusFieldApiName = 'Driving_Status__c';
    @api contractTypeFieldApiName = 'Contract_Type__c';
    @api serviceFieldApiName = 'Service__c';
    @api livingStatusFieldApiName = 'Living_Status__c';

    /** Off by default. Tick to hide rows that have no matching template. */
    @api hideUnmappedForms;

    /** DEPRECATED - no effect. Kept for metadata compatibility. */
    @api showUnmappedForms;

    @track formSections = [];
    @track statusOptions = STATUS_OPTIONS;
    @track isLoading = false;
    @track error = null;
    @track debugMessage = '';
    @track apexError = null;
    @track allFormMappings = {};
    @track completionPercentage = 0;
    @track totalFormCount = 0;
    @track completedFormCount = 0;

    circumference = 2 * Math.PI * 54; // radius = 54

    // Status refresh timer
    pollTimer = null;
    pollCount = 0;

    // Which row the single shared file input is currently uploading for.
    pendingFormApiName;
    pendingFormLabel;
    pendingStage;

    language = LANG_ENGLISH;
    mappingLoaded = false;
    templateMatches = {};

    // Division filtering
    division = null;
    divisionResolved = false;

    // Raw values for the filtered fields.
    drivingStatus = null;
    contractType = null;
    serviceValue = null;   // multi-select: "ATC;HAH;RSP"
    livingStatus = null;

    // Inline "Complete Your Form" panel state (non-PandaDoc forms only)
    pdfLibLoaded = false;
    activeFieldApiName;
    activeFormLabel = '';
    originalPdfBase64;
    @track pdfFields = [];
    isFillLoading = false;
    isSavingFill = false;
    fillError;
    showFillSuccess = false;

    /* =====================================================================
     * LIFECYCLE
     * ===================================================================== */

    connectedCallback() {
        this.addDebug('Component connected');

        if (!this.recordId) {
            this.error = 'ERROR: No recordId. Component must be on a record page.';
            return;
        }

        this.loadForms();
    }

    disconnectedCallback() {
        this.stopStatusPolling();
    }

    /* =====================================================================
     * FIELD PATHS
     * ===================================================================== */

    get objectName() {
        return this.objectApiName || 'Contact';
    }

    get languageFieldPath() {
        return this.languageFieldApiName ? `${this.objectName}.${this.languageFieldApiName}` : null;
    }

    get divisionFieldPath() {
        return this.divisionFieldApiName ? `${this.objectName}.${this.divisionFieldApiName}` : null;
    }

    get drivingStatusFieldPath() {
        return this.drivingStatusFieldApiName ? `${this.objectName}.${this.drivingStatusFieldApiName}` : null;
    }

    get contractTypeFieldPath() {
        return this.contractTypeFieldApiName ? `${this.objectName}.${this.contractTypeFieldApiName}` : null;
    }

    get serviceFieldPath() {
        return this.serviceFieldApiName ? `${this.objectName}.${this.serviceFieldApiName}` : null;
    }

    get livingStatusFieldPath() {
        return this.livingStatusFieldApiName ? `${this.objectName}.${this.livingStatusFieldApiName}` : null;
    }

    get allRequiredFieldPaths() {
        return [
            this.languageFieldPath,
            this.divisionFieldPath,
            this.drivingStatusFieldPath,
            this.contractTypeFieldPath,
            this.serviceFieldPath,
            this.livingStatusFieldPath
        ].filter((path) => !!path);
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$allRequiredFieldPaths' })
    wiredRecord({ data, error }) {
        if (data) {
            if (this.languageFieldPath) {
                const raw = getFieldValue(data, this.languageFieldPath);
                this.language = this.normalizeLanguage(raw);
                this.addDebug(`Language field read: "${raw}" -> ${this.language}`);
            }

            if (this.divisionFieldPath) {
                this.division = getFieldValue(data, this.divisionFieldPath);
                this.addDebug(`Division field read: "${this.division}"`);
            }

            if (this.drivingStatusFieldPath) {
                this.drivingStatus = getFieldValue(data, this.drivingStatusFieldPath);
            }
            if (this.contractTypeFieldPath) {
                this.contractType = getFieldValue(data, this.contractTypeFieldPath);
            }
            if (this.serviceFieldPath) {
                this.serviceValue = getFieldValue(data, this.serviceFieldPath);
            }
            if (this.livingStatusFieldPath) {
                this.livingStatus = getFieldValue(data, this.livingStatusFieldPath);
            }

            this.divisionResolved = true;
            this.buildSections();
        } else if (error) {
            // Fall back to showing everything rather than a stale filter
            this.language = LANG_ENGLISH;
            this.division = null;
            this.drivingStatus = null;
            this.contractType = null;
            this.serviceValue = null;
            this.livingStatus = null;
            this.addDebug(`Error reading record fields: ${this.reduceError(error)}`);
            this.divisionResolved = true;
            this.buildSections();
        }
    }

    normalizeLanguage(value) {
        if (!value) {
            return LANG_ENGLISH;
        }
        const v = String(value).trim().toLowerCase();
        if (v.startsWith('sp') || v.startsWith('es') || v.includes('span') || v.includes('espa')) {
            return LANG_SPANISH;
        }
        return LANG_ENGLISH;
    }

    /* =====================================================================
     * CATEGORY FILTERING HELPERS
     * ===================================================================== */

    normalizeToken(value) {
        if (value === null || value === undefined) {
            return '';
        }
        const token = String(value).toLowerCase().replace(/[^a-z0-9]/g, '');
        return TOKEN_ALIASES[token] || token;
    }

    get drivingStatusTokens() {
        const token = this.normalizeToken(this.drivingStatus);
        return token ? [token] : [];
    }

    get contractTypeTokens() {
        const token = this.normalizeToken(this.contractType);
        return token ? [token] : [];
    }

    get serviceTypeTokens() {
        if (!this.serviceValue) {
            return [];
        }
        return String(this.serviceValue)
            .split(';')
            .map((part) => this.normalizeToken(part))
            .filter((token) => token.length > 0);
    }

    get livingStatusTokens() {
        const token = this.normalizeToken(this.livingStatus);
        return token ? [token] : [];
    }

    parseCategoryName(categoryName) {
        if (!categoryName) {
            return null;
        }
        const parts = categoryName.split(' - ');
        if (parts.length < 3) {
            return null;
        }
        return {
            prefix: parts[0].trim().toLowerCase(),
            value: parts.slice(1, parts.length - 1).join(' - ').trim()
        };
    }

    shouldShowCategory(categoryName) {
        const parsed = this.parseCategoryName(categoryName);
        if (!parsed) {
            return true;
        }

        const tokenProperty = CATEGORY_FIELD_MAP[parsed.prefix];
        if (!tokenProperty) {
            return true;
        }

        const contactTokens = this[tokenProperty] || [];
        if (!contactTokens.length) {
            this.addDebug(`"${parsed.prefix}" is blank on this contact - showing all its sections`);
            return true;
        }

        const categoryToken = this.normalizeToken(parsed.value);
        const matched = contactTokens.includes(categoryToken);
        this.addDebug(
            `${matched ? 'Showing' : 'Skipping'} "${categoryName}" ` +
            `(category="${categoryToken}", contact=[${contactTokens.join(', ')}])`
        );
        return matched;
    }

    /* =====================================================================
     * LOAD
     * ===================================================================== */

    async loadForms() {
        try {
            this.isLoading = true;
            this.addDebug('Loading form mapping from Apex...');

            const result = await getFormMapping({});

            if (!result || Object.keys(result).length === 0) {
                this.error = 'ERROR: No form data from Apex. Check form mapping configuration.';
                this.isLoading = false;
                return;
            }

            this.allFormMappings = result;
            this.mappingLoaded = true;
            this.addDebug(`Form mapping loaded with ${Object.keys(result).length} languages`);
            this.buildSections();
        } catch (error) {
            this.error = `ERROR: ${this.reduceError(error)}`;
            this.isLoading = false;
            this.addDebug(`Error loading forms: ${this.reduceError(error)}`);
        }
    }

    async buildSections() {
        if (!this.mappingLoaded || !this.divisionResolved) {
            return;
        }

        this.isLoading = true;

        try {
            const forLanguage =
                this.allFormMappings[this.language] ||
                this.allFormMappings[LANG_ENGLISH] ||
                {};

            if (!Object.keys(forLanguage).length) {
                this.error = `ERROR: No ${this.language} forms in the Apex response.`;
                this.formSections = [];
                return;
            }

            const divisionFilteringEnabled = !!this.divisionFieldApiName;
            const sections = [];

            for (const [categoryName, categoryData] of Object.entries(forLanguage)) {
                // Division filtering
                if (divisionFilteringEnabled && this.division && categoryName.startsWith('Division - ')) {
                    const expectedCategoryName = `Division - ${this.division} - ${this.language}`;
                    if (categoryName !== expectedCategoryName) {
                        continue;
                    }
                }

                // Driving Status / Contract Type / Service Type / Living Status
                if (!this.shouldShowCategory(categoryName)) {
                    continue;
                }

                if (!categoryData || !Array.isArray(categoryData.forms)) {
                    continue;
                }

                sections.push({
                    categoryName: categoryName,
                    forms: categoryData.forms.map((form, index) => ({
                        id: `${categoryName}-${form.apiName || form.label}-${index}`,
                        label: form.label,
                        apiName: form.apiName,
                        templateName: form.tsTemplateName || form.templateName || null,
                        hasTemplate: false,
                        status: 'None',
                        nextAction: 'send',
                        canUpload: false,
                        showUpload: false,
                        uploadLabel: '',
                        showPdfHint: false,
                        isNotNeeded: false,
                        uploadedFiles: []
                    }))
                });
            }

            this.formSections = await this.applyTemplateMatching(sections);
            await this.loadFormStates();
            this.calculateCompletionPercentage();

            this.addDebug(`Build complete. Showing ${this.formSections.length} section(s)`);
            this.error = null;
        } catch (error) {
            this.error = `ERROR: ${this.reduceError(error)}`;
            this.addDebug(`Error building sections: ${this.reduceError(error)}`);
        } finally {
            this.isLoading = false;
        }
    }

    async applyTemplateMatching(sections) {
        const labels = [];
        sections.forEach((section) => {
            section.forms.forEach((form) => labels.push(form.label));
        });

        if (!labels.length) {
            return sections;
        }

        let matches = {};
        try {
            matches = (await matchTemplates({
                labels: [...new Set(labels)],
                baseObject: this.objectName
            })) || {};
        } catch (error) {
            console.error('Template matching failed:', error);
            return sections;
        }

        this.templateMatches = matches;

        const hideUnmapped = this.hideUnmappedForms === true;
        const result = [];

        sections.forEach((section) => {
            const forms = section.forms
                .map((form) => {
                    const templateName = form.templateName || matches[form.label] || null;
                    return {
                        ...form,
                        templateName: templateName,
                        hasTemplate: !!templateName
                    };
                })
                .filter((form) => !hideUnmapped || form.hasTemplate);

            if (forms.length) {
                result.push({ categoryName: section.categoryName, forms: forms });
            }
        });

        return result;
    }

    calculateCompletionPercentage() {
        let total = 0;
        let completed = 0;

        this.formSections.forEach((section) => {
            section.forms.forEach((form) => {
                if (form.status === 'Not Needed') {
                    return;
                }
                total++;
                if (form.status === 'Completed') {
                    completed++;
                }
            });
        });

        this.totalFormCount = total;
        this.completedFormCount = completed;
        this.completionPercentage = total > 0 ? Math.round((completed / total) * 100) : 0;
    }

    /* =====================================================================
     * GETTERS
     * ===================================================================== */

    get showEmptyState() {
        return !this.isLoading && !this.error && this.formSections.length === 0;
    }

    get isSpanish() {
        return this.language === LANG_SPANISH;
    }

    get formCountLabel() {
        return `${this.completedFormCount}/${this.totalFormCount} forms`;
    }

    get cardTitle() {
        return this.isSpanish ? 'Certificados y Documentos' : 'Certificate and Documents';
    }

    get columnFormName() {
        return this.isSpanish ? 'Nombre del Formulario' : 'Form Name';
    }

    get columnStatus() {
        return this.isSpanish ? 'Estado' : 'Status';
    }

    get columnAction() {
        return this.isSpanish ? 'Acción' : 'Action';
    }

    get reviewButtonLabel() {
        return this.isSpanish ? 'Envíe el formulario' : 'Send the Form';
    }

    get uploadSignedLabel() {
        return this.isSpanish ? 'Cargar formulario firmado' : 'Upload signed form';
    }

    get uploadFinalLabel() {
        return this.isSpanish ? 'Guardar PDF final' : 'Save final PDF';
    }

    get notNeededLabel() {
        return this.isSpanish ? 'No Requerido' : 'Not required';
    }

    get emptyStateMessage() {
        return this.isSpanish
            ? 'No hay formularios disponibles para este registro.'
            : 'No forms are available for this record.';
    }

    get completeFormTitle() {
        return this.isSpanish ? 'Complete su Formulario' : 'Complete Your Form';
    }

    get saveFormLabel() {
        return this.isSpanish ? 'Guardar' : 'Save';
    }

    get fillSuccessMessage() {
        return this.isSpanish
            ? 'Su formulario completado ha sido guardado.'
            : 'Your completed form has been saved.';
    }

    get fillEmptyStateMessage() {
        return this.isSpanish
            ? 'Envíe un formulario arriba para completarlo aquí.'
            : 'Send a form above to fill it in here.';
    }

    get showFillForm() {
        return !this.isFillLoading && !this.fillError && !this.showFillSuccess && this.pdfFields.length > 0;
    }

    get showFillEmptyState() {
        return !this.isFillLoading && !this.fillError && !this.showFillSuccess && this.pdfFields.length === 0;
    }

    get progressRingStyle() {
        const offset = this.circumference - (this.completionPercentage / 100) * this.circumference;
        return `stroke-dashoffset: ${offset}px;`;
    }

    /* =====================================================================
     * STATUS DROPDOWN
     * ===================================================================== */

    async handleStatusChange(event) {
        const formApiName = event.target.name;
        const newStatus = event.detail.value;

        if (newStatus === 'Completed') {
            await this.promoteToFinal(formApiName);
            return;
        }

        if (newStatus === 'Pending') {
            const form = this.findFormByApiName(formApiName);
            this.openUploadPicker(formApiName, form ? form.label : formApiName, 'signed');
            return;
        }

        if (newStatus === 'Not Needed') {
            try {
                await updateFormStatus({
                    recordId: this.recordId,
                    formApiName: formApiName,
                    status: newStatus
                });

                this.applyToForm(formApiName, (form) => {
                    form.status = newStatus;
                    form.canSend = false;
                    form.canUpload = false;
                    form.showUpload = false;
                    form.isNotNeeded = true;
                });

                this.showToast('Success', 'Status updated successfully', 'success');
            } catch (error) {
                this.handleError('Error updating status: ' + this.reduceError(error));
            }
            return;
        }

        try {
            await updateFormStatus({
                recordId: this.recordId,
                formApiName: formApiName,
                status: newStatus
            });

            this.applyToForm(formApiName, (form) => {
                form.status = newStatus;
                form.isNotNeeded = false;
            });

            this.showToast('Success', 'Status updated successfully', 'success');
        } catch (error) {
            this.handleError('Error updating status: ' + this.reduceError(error));
        }
    }

    /* =====================================================================
     * PANDADOC: "Send the Form" (staff record page)
     *
     * PandaDoc emails the signing link to the contact. Nothing opens for staff.
     * The row shows "Sent" once the send succeeds, and "Completed" once the
     * webhook has saved the signed file to the contact's Files.
     * ===================================================================== */

    async handleReviewFormClick(event) {
        const formApiName = event.currentTarget.dataset.formId;
        const formLabel = event.currentTarget.dataset.formLabel;

        if (!formApiName) {
            this.showToast('Error', 'This form has no field API name.', 'error');
            return;
        }

        await this.sendPandaDocForm(this.recordId, formApiName, formLabel, null);
    }

    wait(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    /**
     * 1. Creates the PandaDoc document from the template.
     * 2. Waits until PandaDoc has prepared it.
     * 3. Sends it, so PandaDoc emails the contact.
     * 4. Sets the row to "Sent" (the value is read back from the Contact).
     */
    async sendPandaDocForm(contactId, formApiName, formLabel, opportunityId) {
        this.isLoading = true;

        try {
            const oppId = opportunityId || null;

            const docId = await createForm({
                contactId,
                formApiName,
                formLabel,
                opportunityId: oppId
            });

            let status = await getStatus({ docId });
            for (let i = 0; i < POLL_MAX_ATTEMPTS && status === 'document.uploaded'; i++) {
                await this.wait(POLL_INTERVAL_MS);
                status = await getStatus({ docId });
            }

            // sendEmail = true: PandaDoc emails the contact the signing link
            await prepareForSigning({
                docId,
                contactId,
                opportunityId: oppId,
                sendEmail: true,
                formApiName
            });

            this.markRowSent(formApiName);

            this.showToast(
                'Form sent',
                'The contact was emailed the form. The status changes to Completed once it is signed.',
                'success'
            );

            // Read the stored value back, so the row shows what is really saved on the Contact
            await this.refreshStatusesFromContact();
            const row = this.findFormByApiName(formApiName);
            if (row && row.status !== 'Sent') {
                this.showToast(
                    'Status not saved',
                    `The document was sent, but this form still shows "${row.status}". Check the debug log for [PandaDoc] setContactStatus.`,
                    'warning'
                );
            }

            this.startStatusPolling();
        } catch (e) {
            this.showToast('Error', this.reduceError(e), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /** Sets a row to "Sent" in the UI straight away. */
    markRowSent(formApiName) {
        this.applyToForm(formApiName, (form) => {
            form.status = 'Sent';
            form.isNotNeeded = false;
        });
    }

    /* =====================================================================
     * STATUS FROM THE CONTACT FIELDS
     * The Contact field is the source of truth for PandaDoc rows.
     * ===================================================================== */

    async refreshStatusesFromContact() {
        const names = [];
        this.formSections.forEach((section) => {
            section.forms.forEach((form) => {
                if (form.apiName) {
                    names.push(form.apiName);
                }
            });
        });

        if (!names.length || !this.recordId) {
            return;
        }

        try {
            const map = (await getContactStatuses({
                contactId: this.recordId,
                fieldNames: [...new Set(names)]
            })) || {};

            this.formSections = this.formSections.map((section) => ({
                categoryName: section.categoryName,
                forms: section.forms.map((form) => {
                    const value = form.apiName ? map[form.apiName.toLowerCase()] : undefined;
                    if (!value) {
                        return form;
                    }
                    return {
                        ...form,
                        status: value,
                        isNotNeeded: value === 'Not Needed',
                        canSend: value === 'Not Needed' ? false : form.canSend
                    };
                })
            }));

            this.calculateCompletionPercentage();
        } catch (error) {
            console.warn('Could not read statuses from the Contact', error);
        }
    }

    hasSentRows() {
        return this.formSections.some((section) =>
            section.forms.some((form) => form.status === 'Sent')
        );
    }

    startStatusPolling() {
        if (this.pollTimer) {
            return;
        }
        this.pollCount = 0;
        this.pollTimer = setInterval(() => this.refreshPendingStatuses(), STATUS_REFRESH_MS);
    }

    async refreshPendingStatuses() {
        this.pollCount++;

        if (!this.hasSentRows() || this.pollCount > STATUS_MAX_REFRESHES) {
            this.stopStatusPolling();
            return;
        }

        await this.refreshStatusesFromContact();
    }

    stopStatusPolling() {
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
    }

    /* =====================================================================
     * UPLOAD / FINAL (non-PandaDoc flow, kept for existing forms)
     * ===================================================================== */

    handleUploadClick(event) {
        const formApiName = event.currentTarget.dataset.formId;
        const formLabel = event.currentTarget.dataset.formLabel;

        if (event.currentTarget.dataset.action === 'uploadFinal') {
            this.promoteToFinal(formApiName);
            return;
        }

        this.openUploadPicker(formApiName, formLabel, 'signed');
    }

    async promoteToFinal(formApiName) {
        const form = this.findFormByApiName(formApiName);
        const formLabel = form ? form.label : formApiName;

        this.isLoading = true;

        try {
            const state = await promoteSignedToFinal({
                recordId: this.recordId,
                fieldApiName: formApiName,
                formLabel: formLabel
            });

            this.applyState(formApiName, state);

            this.showToast(
                'Saved',
                state.message || `"${formLabel}" was saved to Files.`,
                'success'
            );
        } catch (error) {
            const message = this.reduceError(error);

            if (message.includes('No signed PDF has been uploaded yet')) {
                this.isLoading = false;
                this.openUploadPicker(formApiName, formLabel, 'final');
                return;
            }

            this.showToast('Could not save', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    openUploadPicker(formApiName, formLabel, stage) {
        this.pendingFormApiName = formApiName;
        this.pendingFormLabel = formLabel;
        this.pendingStage = stage;

        const input = this.template.querySelector('.hidden-file-input');
        if (input) {
            input.value = null;
            input.click();
        }
    }

    handleFileSelected(event) {
        const file = event.target.files && event.target.files[0];
        if (!file || !this.pendingFormApiName) {
            return;
        }

        const formApiName = this.pendingFormApiName;
        const formLabel = this.pendingFormLabel;
        const stage = this.pendingStage;

        const reader = new FileReader();

        reader.onerror = () => {
            this.showToast('Error', 'That file could not be read.', 'error');
        };

        reader.onload = async () => {
            const base64 = reader.result.split(',')[1];
            this.isLoading = true;

            try {
                const state = await uploadFormFile({
                    recordId: this.recordId,
                    fieldApiName: formApiName,
                    formLabel: formLabel,
                    fileName: file.name,
                    base64Data: base64,
                    stage: stage
                });

                this.applyState(formApiName, state);

                this.showToast(
                    'File saved',
                    state.message || `${file.name} was saved to this contact.`,
                    'success'
                );
            } catch (error) {
                this.showToast('Upload failed', this.reduceError(error), 'error');
            } finally {
                this.isLoading = false;
            }
        };

        reader.readAsDataURL(file);
    }

    handleFileClick(event) {
        event.preventDefault();
        const contentDocumentId = event.currentTarget.dataset.docid;
        if (!contentDocumentId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: { selectedRecordId: contentDocumentId }
        });
    }

    /* =====================================================================
     * FORM STATE
     * ===================================================================== */

    findFormByApiName(formApiName) {
        for (const section of this.formSections) {
            const form = section.forms.find((f) => f.apiName === formApiName);
            if (form) {
                return form;
            }
        }
        return null;
    }

    async loadFormStates() {
        const fields = [];
        const labels = [];

        this.formSections.forEach((section) => {
            section.forms.forEach((form) => {
                fields.push(form.apiName);
                labels.push(form.label);
            });
        });

        if (!fields.length) {
            return;
        }

        try {
            const states = await getFormStates({
                recordId: this.recordId,
                fields: fields,
                labels: labels
            });

            const byField = {};
            (states || []).forEach((state) => {
                byField[state.fieldApiName] = state;
            });

            this.formSections = this.formSections.map((section) => ({
                categoryName: section.categoryName,
                forms: section.forms.map((form) => this.mergeState(form, byField[form.apiName]))
            }));

            this.calculateCompletionPercentage();
        } catch (error) {
            console.error('Could not load saved form states', error);
        }

        // The Contact field is the source of truth for PandaDoc rows
        await this.refreshStatusesFromContact();
    }

    mergeState(form, state) {
        if (!state) {
            return form;
        }

        const status = state.status || 'None';
        const files = (state.files || []).map((f) => ({
            id: f.contentDocumentId,
            name: f.name,
            url: f.url,
            stage: f.stage
        }));

        const isFinalStep = state.nextAction === 'uploadFinal';
        const isNotNeeded = status === 'Not Needed';

        return {
            ...form,
            status: status,
            nextAction: state.nextAction || 'send',
            canSend: isNotNeeded ? false : (state.canSend !== false),
            canUpload: isNotNeeded ? false : (state.canUpload === true),
            showUpload: isNotNeeded ? false : (state.canUpload === true),
            uploadLabel: isFinalStep ? this.uploadFinalLabel : this.uploadSignedLabel,
            showPdfHint: !isFinalStep,
            fieldMissing: state.fieldExists === false,
            isNotNeeded: isNotNeeded,
            uploadedFiles: files
        };
    }

    applyState(formApiName, state) {
        if (!state) {
            return;
        }
        this.formSections = this.formSections.map((section) => ({
            categoryName: section.categoryName,
            forms: section.forms.map((form) =>
                form.apiName === formApiName ? this.mergeState(form, state) : form
            )
        }));
        this.calculateCompletionPercentage();
    }

    applyToForm(formApiName, mutate) {
        for (const section of this.formSections) {
            const form = section.forms.find((f) => f.apiName === formApiName);
            if (form) {
                mutate(form);
            }
        }
        this.formSections = [...this.formSections];
        this.calculateCompletionPercentage();
    }

    /* =====================================================================
     * INLINE "COMPLETE YOUR FORM" PANEL (non-PandaDoc forms only)
     * ===================================================================== */

    async ensurePdfLib() {
        if (this.pdfLibLoaded) {
            return;
        }
        await loadScript(this, PdfLib);
        this.pdfLibLoaded = true;
    }

    async loadPdfForFilling(formApiName, formLabel) {
        this.activeFieldApiName = formApiName;
        this.activeFormLabel = formLabel;
        this.pdfFields = [];
        this.fillError = undefined;
        this.showFillSuccess = false;
        this.isFillLoading = true;

        try {
            await this.ensurePdfLib();

            const base64 = await getPdfForFilling({
                recordId: this.recordId,
                fieldApiName: formApiName
            });
            this.originalPdfBase64 = base64;

            // eslint-disable-next-line no-undef
            const { PDFDocument } = PDFLib;
            const bytes = this.base64ToBytes(base64);
            const pdfDoc = await PDFDocument.load(bytes);
            const form = pdfDoc.getForm();
            const fields = form.getFields();

            let parsedFields = fields.map((f) => {
                const name = f.getName();
                const isCheckbox = f.constructor.name === 'PDFCheckBox';
                let value = '';
                try {
                    value = isCheckbox
                        ? (f.isChecked ? f.isChecked() : false)
                        : (f.getText ? f.getText() || '' : '');
                } catch (readErr) {
                    value = isCheckbox ? false : '';
                }
                return { name, label: this.humanizeFieldName(name), isCheckbox, value };
            });

            try {
                const prefill = await getMergeFieldValues({
                    recordId: this.recordId,
                    fieldNames: parsedFields.map((f) => f.name)
                });
                if (prefill) {
                    parsedFields = parsedFields.map((f) => {
                        if (Object.prototype.hasOwnProperty.call(prefill, f.name) && !f.value) {
                            return { ...f, value: prefill[f.name] };
                        }
                        return f;
                    });
                }
            } catch (prefillErr) {
                console.warn('Prefill unavailable', prefillErr);
            }

            this.pdfFields = parsedFields;

            if (!this.pdfFields.length) {
                this.fillError = this.isSpanish
                    ? 'Este PDF no tiene campos para completar.'
                    : 'This PDF has no fillable fields.';
            }
        } catch (e) {
            this.fillError =
                (e && e.body && e.body.message) ||
                (e && e.message) ||
                (this.isSpanish ? 'No se pudo cargar el formulario.' : 'Could not load the form.');
        } finally {
            this.isFillLoading = false;
        }
    }

    handlePdfFieldChange(event) {
        const name = event.target.dataset.name;
        const isCheckbox = event.target.type === 'checkbox';
        const newValue = isCheckbox ? event.target.checked : event.target.value;

        this.pdfFields = this.pdfFields.map((f) =>
            f.name === name ? { ...f, value: newValue } : f
        );
    }

    async handleSaveFilledForm() {
        this.isSavingFill = true;
        this.fillError = undefined;

        try {
            // eslint-disable-next-line no-undef
            const { PDFDocument } = PDFLib;
            const bytes = this.base64ToBytes(this.originalPdfBase64);
            const pdfDoc = await PDFDocument.load(bytes);
            const form = pdfDoc.getForm();

            this.pdfFields.forEach((field) => {
                try {
                    if (field.isCheckbox) {
                        const cb = form.getCheckBox(field.name);
                        if (field.value) {
                            cb.check();
                        } else {
                            cb.uncheck();
                        }
                    } else {
                        form.getTextField(field.name).setText(String(field.value || ''));
                    }
                } catch (fieldErr) {
                    console.warn(`Could not set field ${field.name}`, fieldErr);
                }
            });

            form.flatten();

            const filledBytes = await pdfDoc.save();
            const filledBase64 = this.bytesToBase64(filledBytes);

            await saveFilledPdf({
                recordId: this.recordId,
                fieldApiName: this.activeFieldApiName,
                formLabel: this.activeFormLabel,
                base64Pdf: filledBase64
            });

            this.applyToForm(this.activeFieldApiName, (f) => {
                f.status = 'Completed';
            });
            await this.loadFormStates();

            this.showFillSuccess = true;
            this.pdfFields = [];

            this.showToast('Saved', `"${this.activeFormLabel}" was saved to Files.`, 'success');
        } catch (e) {
            this.fillError =
                (e && e.body && e.body.message) ||
                (e && e.message) ||
                (this.isSpanish ? 'No se pudo guardar el formulario.' : 'Could not save the form.');
        } finally {
            this.isSavingFill = false;
        }
    }

    humanizeFieldName(name) {
        return name
            .replace(/[_\-.]+/g, ' ')
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .replace(/\b\w/g, (c) => c.toUpperCase())
            .trim();
    }

    base64ToBytes(base64) {
        const binary = atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes;
    }

    bytesToBase64(bytes) {
        let binary = '';
        const chunkSize = 0x8000;
        for (let i = 0; i < bytes.length; i += chunkSize) {
            binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize));
        }
        return btoa(binary);
    }

    /* =====================================================================
     * HELPERS
     * ===================================================================== */

    addDebug(message) {
        const timestamp = new Date().toLocaleTimeString();
        this.debugMessage = `[${timestamp}] ${message}`;
        console.log(this.debugMessage);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        }));
    }

    handleError(errorMessage) {
        this.error = errorMessage;
        this.isLoading = false;
        this.showToast('Error', errorMessage, 'error');
    }

    handleCloseError() {
        this.error = null;
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