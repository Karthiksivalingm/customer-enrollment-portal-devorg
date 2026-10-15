import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import PdfLib from '@salesforce/resourceUrl/PdfLib';
import getFormForFill from '@salesforce/apex/FormFillController.getFormForFill';
import saveFilledForm from '@salesforce/apex/FormFillController.saveFilledForm';

/**
 * formFillPage
 * -----------------------------------------------------------------------
 * NEW COMPONENT. Talks only to the new FormFillController - it does not
 * touch DynamicFormsContact, CustomerFormController or anything else that
 * already exists.
 *
 * Renders the fields configured in Form__mdt for this form, draws the
 * answers onto the PDF that was emailed to the customer, and sends the
 * completed PDF back to Salesforce.
 *
 * The token comes from the ?token= URL parameter on a public page, or from
 * the Token property when the component sits on an internal Lightning page
 * for testing.
 *
 * NOTE ON PUBLIC BOOLEANS
 *   LWC forbids initializing an @api Boolean to true (LWC1503). Both
 *   public booleans here default to false for that reason, and are named
 *   so that false is the sensible default.
 */
export default class FormFillPage extends LightningElement {

    /** Set this on an internal Lightning page to test without a real link. */
    @api token;

    /**
     * Outlines every configured coordinate in red on the output PDF and
     * shows the page-size panel on screen. Turn on while calibrating,
     * off before anyone sees it.
     */
    @api showCalibration = false;

    /**
     * Paints a white box over ###Marker### text before drawing the value,
     * for templates that still contain the markers. Leave off when the
     * template uses blank underscore lines, which is the cleaner setup.
     */
    @api coverMarkers = false;

    @track fields = [];
    formLabel = '';
    contactName = '';
    pdfBase64;

    isLoading = true;
    isSaving = false;
    isSubmitted = false;
    fatalError;
    softError;
    successMessage = '';

    pageWidth = 0;
    pageHeight = 0;

    sigReady = false;
    isDrawing = false;
    hasSignature = false;

    /* =====================================================================
     * LIFECYCLE
     * ===================================================================== */

    connectedCallback() {
        this.resolveToken();
        if (!this.token) {
            this.fatalError =
                'This link is missing its form code. Please use the link from your email.';
            this.isLoading = false;
            return;
        }
        this.load();
    }

    renderedCallback() {
        if (!this.sigReady) {
            const canvas = this.template.querySelector('.sig-canvas');
            if (canvas) {
                this.initSignature(canvas);
                this.sigReady = true;
            }
        }
    }

    resolveToken() {
        if (this.token) {
            return;
        }
        try {
            this.token = new URLSearchParams(window.location.search).get('token');
        } catch (e) {
            this.token = null;
        }
    }

    async load() {
        try {
            await loadScript(this, PdfLib);

            const data = await getFormForFill({ token: this.token });

            this.formLabel = data.formLabel;
            this.contactName = data.contactName;
            this.pdfBase64 = data.pdfBase64;
            this.fields = (data.fields || []).map((f) => this.decorate(f));

            this.measurePage();

        } catch (e) {
            this.fatalError = this.messageOf(e);
        } finally {
            this.isLoading = false;
        }
    }

    decorate(field) {
        const type = (field.type || 'text').toLowerCase();
        let value = field.value === null || field.value === undefined
            ? ''
            : String(field.value);

        if (type === 'checkbox') {
            value = value.toLowerCase() === 'true';
        }

        return {
            ...field,
            type,
            value,
            isCheckbox: type === 'checkbox',
            isDate: type === 'date',
            isSignature: type === 'signature' || type === 'sig',
            isText: type !== 'checkbox' && type !== 'date'
                    && type !== 'signature' && type !== 'sig'
        };
    }

    /** Reads the PDF's real page size, purely to help with calibration. */
    async measurePage() {
        if (!this.pdfBase64) {
            return;
        }
        try {
            // eslint-disable-next-line no-undef
            const { PDFDocument } = PDFLib;
            const doc = await PDFDocument.load(this.base64ToBytes(this.pdfBase64));
            const size = doc.getPages()[0].getSize();
            this.pageWidth = Math.round(size.width);
            this.pageHeight = Math.round(size.height);
        } catch (e) {
            // calibration info only - never fatal
        }
    }

    /* =====================================================================
     * GETTERS
     * ===================================================================== */

    get showForm() {
        return !this.isLoading && !this.fatalError && !this.isSubmitted;
    }

    get inputFields() {
        return this.fields.filter((f) => !f.isSignature);
    }

    get signatureField() {
        return this.fields.find((f) => f.isSignature);
    }

    get pageSizeText() {
        return this.pageWidth
            ? `${this.pageWidth} x ${this.pageHeight} points`
            : 'unknown';
    }

    /* =====================================================================
     * INPUT
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
     * SIGNATURE PAD
     * ===================================================================== */

    initSignature(canvas) {
        const ctx = canvas.getContext('2d');
        ctx.lineWidth = 2.5;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.strokeStyle = '#111';

        const pos = (evt) => {
            const rect = canvas.getBoundingClientRect();
            const src = evt.touches && evt.touches.length ? evt.touches[0] : evt;
            return {
                x: (src.clientX - rect.left) * (canvas.width / rect.width),
                y: (src.clientY - rect.top) * (canvas.height / rect.height)
            };
        };

        const start = (evt) => {
            evt.preventDefault();
            this.isDrawing = true;
            this.hasSignature = true;
            const p = pos(evt);
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
        };
        const move = (evt) => {
            if (!this.isDrawing) {
                return;
            }
            evt.preventDefault();
            const p = pos(evt);
            ctx.lineTo(p.x, p.y);
            ctx.stroke();
        };
        const end = () => {
            this.isDrawing = false;
        };

        canvas.addEventListener('mousedown', start);
        canvas.addEventListener('mousemove', move);
        canvas.addEventListener('mouseup', end);
        canvas.addEventListener('mouseleave', end);
        canvas.addEventListener('touchstart', start, { passive: false });
        canvas.addEventListener('touchmove', move, { passive: false });
        canvas.addEventListener('touchend', end);
    }

    handleClearSignature() {
        const canvas = this.template.querySelector('.sig-canvas');
        if (canvas) {
            canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
        }
        this.hasSignature = false;
    }

    signatureDataUrl() {
        const canvas = this.template.querySelector('.sig-canvas');
        return canvas ? canvas.toDataURL('image/png') : null;
    }

    /* =====================================================================
     * SUBMIT
     * ===================================================================== */

    async handleSubmit() {
        this.softError = undefined;

        const missing = [];
        this.fields.forEach((f) => {
            if (!f.required) {
                return;
            }
            if (f.isSignature) {
                if (!this.hasSignature) {
                    missing.push(f.label);
                }
            } else if (f.isCheckbox) {
                if (f.value !== true) {
                    missing.push(f.label);
                }
            } else if (!String(f.value || '').trim()) {
                missing.push(f.label);
            }
        });

        if (missing.length) {
            this.softError = 'Please complete: ' + missing.join(', ') + '.';
            return;
        }

        this.isSaving = true;

        try {
            const completedPdf = await this.buildCompletedPdf();

            const values = {};
            this.fields.forEach((f) => {
                if (!f.isSignature) {
                    values[f.name] = f.isCheckbox
                        ? String(f.value)
                        : String(f.value || '');
                }
            });

            const result = await saveFilledForm({
                token: this.token,
                values: values,
                base64Pdf: completedPdf
            });

            this.successMessage = (result && result.message)
                || 'Thank you - your form has been submitted.';
            this.isSubmitted = true;

        } catch (e) {
            this.softError = this.messageOf(e);
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Draws each answer onto the emailed PDF at the coordinates held in
     * Form__mdt. pdf-lib uses PDF points with the origin at the
     * BOTTOM-LEFT of the page, so Y grows upward.
     */
    async buildCompletedPdf() {
        if (!this.pdfBase64) {
            throw new Error('The form document could not be loaded.');
        }

        // eslint-disable-next-line no-undef
        const { PDFDocument, StandardFonts, rgb } = PDFLib;

        const pdfDoc = await PDFDocument.load(this.base64ToBytes(this.pdfBase64));
        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const pages = pdfDoc.getPages();

        for (const field of this.fields) {
            if (field.x === null || field.x === undefined
                || field.y === null || field.y === undefined) {
                continue;
            }
            const page = pages[Math.max(0, (field.page || 1) - 1)];
            if (!page) {
                continue;
            }

            const x = Number(field.x);
            const y = Number(field.y);
            const size = field.fontSize || 11;

            // ---- optional: white out a ###Marker### underneath --------
            if (this.coverMarkers) {
                const marker = '###' + field.name + '###';
                let coverWidth;
                try {
                    coverWidth = font.widthOfTextAtSize(marker, size) * 1.12;
                } catch (e) {
                    coverWidth = marker.length * size * 0.58;
                }
                page.drawRectangle({
                    x: x - 2,
                    y: y - Math.round(size * 0.28),
                    width: coverWidth + 6,
                    height: size * 1.35,
                    color: rgb(1, 1, 1)
                });
            }

            // ---- calibration outline, drawn for every field type -----
            if (this.showCalibration) {
                page.drawRectangle({
                    x: x,
                    y: y,
                    width: field.isSignature ? 150 : 120,
                    height: field.isSignature ? 45 : size,
                    borderColor: rgb(1, 0, 0),
                    borderWidth: 0.6
                });
            }

            // ---- the value itself ------------------------------------
            if (field.isSignature) {
                if (!this.hasSignature) {
                    continue;
                }
                // eslint-disable-next-line no-await-in-loop
                const png = await pdfDoc.embedPng(this.signatureDataUrl());
                const sigWidth = 150;
                page.drawImage(png, {
                    x: x,
                    y: y,
                    width: sigWidth,
                    height: (png.height / png.width) * sigWidth
                });
                continue;
            }

            const text = this.textFor(field);
            if (!text) {
                continue;
            }

            page.drawText(text, {
                x: x,
                y: y,
                size: size,
                font: font,
                color: rgb(0, 0, 0)
            });
        }

        return this.bytesToBase64(await pdfDoc.save());
    }

    /** Formats a value for printing. Dates render as MM/DD/YYYY. */
    textFor(field) {
        if (field.isCheckbox) {
            return field.value ? 'X' : '';
        }
        const raw = String(field.value || '');
        if (!raw) {
            return '';
        }
        if (field.isDate) {
            const parts = raw.split('-');
            if (parts.length === 3) {
                return parts[1] + '/' + parts[2] + '/' + parts[0];
            }
        }
        return raw;
    }

    /* =====================================================================
     * HELPERS
     * ===================================================================== */

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
        const chunk = 0x8000;
        for (let i = 0; i < bytes.length; i += chunk) {
            binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
        }
        return btoa(binary);
    }

    messageOf(error) {
        return (
            (error && error.body && error.body.message) ||
            (error && error.message) ||
            'Something went wrong. Please contact us.'
        );
    }
}