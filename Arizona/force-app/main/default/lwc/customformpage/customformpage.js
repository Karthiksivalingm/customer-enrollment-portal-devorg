import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import PdfLib from '@salesforce/resourceUrl/PdfLib';

import getFormRequest from '@salesforce/apex/CustomerFormController.getFormRequest';
import getFormFields from '@salesforce/apex/CustomerFormController.getFormFields';
import getGeneratedPdf from '@salesforce/apex/CustomerFormController.getGeneratedPdf';
import saveCustomerForm from '@salesforce/apex/CustomerFormController.saveCustomerForm';

export default class CustomFormPage extends LightningElement {

    token;

    isLoading = true;
    loadError;

    formRequest;
    @track fields = [];
    originalPdfBase64;

    isSaving = false;
    submitError;
    showSuccess = false;
    successMessage = '';

    pdfLibLoaded = false;

    /* =====================================================================
     * TOKEN FROM URL
     * The emailed link is:
     *   https://<site>/<complete-form-path>?token=xxxxx
     * Experience Cloud exposes query params through CurrentPageReference.
     * ===================================================================== */
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!pageRef) {
            return;
        }
        const incomingToken = pageRef.state && pageRef.state.token;
        if (incomingToken && incomingToken !== this.token) {
            this.token = incomingToken;
            this.init();
        } else if (!incomingToken && !this.token && this.isLoading) {
            this.isLoading = false;
            this.loadError = 'This link is missing its access code. Please use the link exactly as it was emailed to you.';
        }
    }

    /* =====================================================================
     * LOAD
     * ===================================================================== */
    async init() {
        this.isLoading = true;
        this.loadError = undefined;

        try {
            this.formRequest = await getFormRequest({ token: this.token });

            const [rawFields, pdfBase64] = await Promise.all([
                getFormFields({ requestId: this.formRequest.requestId }),
                getGeneratedPdf({ requestId: this.formRequest.requestId })
            ]);

            this.fields = (rawFields || []).map((f) => ({
                name: f.name,
                label: f.label,
                required: !!f.required,
                isCheckbox: (f.type || '').toLowerCase() === 'checkbox',
                value: f.value == null ? (
                    (f.type || '').toLowerCase() === 'checkbox' ? false : ''
                ) : f.value
            }));

            this.originalPdfBase64 = pdfBase64;

        } catch (e) {
            this.loadError = this.reduceError(e);
        } finally {
            this.isLoading = false;
        }
    }

    /* =====================================================================
     * GETTERS
     * ===================================================================== */
    get showForm() {
        return !this.isLoading && !this.loadError && !this.showSuccess && !!this.formRequest;
    }

    get showNoFieldsMessage() {
        return this.fields.length === 0;
    }

    /* =====================================================================
     * FIELD EDITING
     * ===================================================================== */
    handleFieldChange(event) {
        const name = event.target.dataset.name;
        const isCheckbox = event.target.type === 'checkbox';
        const newValue = isCheckbox ? event.target.checked : event.target.value;

        this.fields = this.fields.map((f) =>
            f.name === name ? { ...f, value: newValue } : f
        );
    }

    /* =====================================================================
     * SUBMIT
     * ===================================================================== */
    async handleSubmit() {
        this.submitError = undefined;

        if (!this.allRequiredFieldsFilled()) {
            this.submitError = 'Please fill in all required fields before submitting.';
            return;
        }

        this.isSaving = true;

        try {
            await this.ensurePdfLib();

            const filledPdfBase64 = await this.buildFilledPdf();

            const values = {};
            this.fields.forEach((f) => {
                values[f.name] = f.value;
            });

            const result = await saveCustomerForm({
                requestId: this.formRequest.requestId,
                values: values,
                base64Pdf: filledPdfBase64
            });

            this.showSuccess = true;
            this.successMessage = (result && result.message)
                ? result.message
                : 'Thank you - your form has been submitted.';

        } catch (e) {
            this.submitError = this.reduceError(e);
        } finally {
            this.isSaving = false;
        }
    }

    allRequiredFieldsFilled() {
        return this.fields.every((f) => {
            if (!f.required) {
                return true;
            }
            if (f.isCheckbox) {
                return f.value === true;
            }
            return f.value !== null && f.value !== undefined && String(f.value).trim() !== '';
        });
    }

    /* =====================================================================
     * PDF FILL (pdf-lib, in-browser - same pattern as the internal
     * "Complete Your Form" panel)
     * ===================================================================== */
    async ensurePdfLib() {
        if (this.pdfLibLoaded) {
            return;
        }
        await loadScript(this, PdfLib);
        this.pdfLibLoaded = true;
    }

    async buildFilledPdf() {
        // eslint-disable-next-line no-undef
        const { PDFDocument } = PDFLib;
        const bytes = this.base64ToBytes(this.originalPdfBase64);
        const pdfDoc = await PDFDocument.load(bytes);
        const form = pdfDoc.getForm();

        this.fields.forEach((field) => {
            try {
                if (field.isCheckbox) {
                    const cb = form.getCheckBox(field.name);
                    if (field.value) {
                        cb.check();
                    } else {
                        cb.uncheck();
                    }
                } else {
                    const tf = form.getTextField(field.name);
                    tf.setText(String(field.value || ''));
                }
            } catch (fieldErr) {
                // A mapped field that isn't actually a fillable field on
                // this particular PDF - the answer is still captured in
                // `values` for saveCustomerForm, so this is non-fatal.
                console.warn(`Could not set PDF field ${field.name}`, fieldErr);
            }
        });

        form.flatten();

        const filledBytes = await pdfDoc.save();
        return this.bytesToBase64(filledBytes);
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
    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return (
            error?.body?.message ||
            error?.message ||
            'Something went wrong. Please try again or contact us.'
        );
    }
}