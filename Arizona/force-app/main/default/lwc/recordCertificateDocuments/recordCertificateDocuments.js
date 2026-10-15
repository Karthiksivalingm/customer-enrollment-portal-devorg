import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getCertificationAndDriverDocuments from '@salesforce/apex/PhaseDocumentTrackerController.getCertificationAndDriverDocuments';
import getServiceFormDocumentsForContact from '@salesforce/apex/PhaseDocumentTrackerController.getServiceFormDocumentsForContact';
import getUploadedFileInfo from '@salesforce/apex/PhaseDocumentTrackerController.getUploadedFileInfo';
import uploadDocument from '@salesforce/apex/PhaseDocumentTrackerController.uploadDocument';
import updateDocumentStatusInternal from '@salesforce/apex/PhaseDocumentTrackerController.updateDocumentStatusInternal';
import deleteUploadedDocument from '@salesforce/apex/PhaseDocumentTrackerController.deleteUploadedDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Status options for regular picklist fields
// NEW: 'Not Needed' added. When a row is set to this value the Upload
// button is hidden for that row (see canUpload in buildRow()), so no file
// can be attached until the status is changed back to something else.
const STATUS_OPTIONS = [
    { label: 'Not Started', value: 'Not Started' },
    { label: 'Pending', value: 'Pending' },
    { label: 'Completed', value: 'Completed' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Expired', value: 'Expired' },
    { label: 'Not Needed', value: 'Not Needed' }
];

// This component always uploads through the Apex uploadDocument() path,
// which tags every new ContentVersion's Title with this source. Used to
// decide whether to show the delete "X" for a given row - only the side
// that uploaded a file may delete it (legacy files with no source tag
// still show the X on both sides, since uploadSource comes back null).
const UPLOAD_SOURCE = 'internal';

// The status value that suppresses uploading for a row.
const NOT_NEEDED_STATUS = 'Not Needed';

// NOTE: SAM and OIG used to be tracked on Boolean checkbox fields
// (SAM__c/OIG__c) and needed a restricted Not Started/Completed-only
// dropdown here, since a checkbox can't represent "Pending". They're now
// tracked on dedicated text/picklist fields (SAM_Status__c/OIG_Status__c)
// on the Apex side, so they use the full STATUS_OPTIONS list below like
// every other document - no field-specific branching needed anymore.

export default class RecordCertificateDocuments extends NavigationMixin(LightningElement) {
    @api recordId;

    isLoading = true;
    errorMessage;

    statusOptions = STATUS_OPTIONS;

    docsResult;
    serviceDocsResult;
    fileInfoResult;
    docs = [];
    serviceDocs = [];
    uploadedFileInfo = {};

    pendingFieldApiName;
 ringCircumference = 2 * Math.PI * 54;
    @wire(getCertificationAndDriverDocuments, { contactId: '$recordId' })
    wiredDocs(result) {
        this.docsResult = result;
        this.isLoading = false;
        if (result.data) {
            this.docs = result.data;
            this.errorMessage = undefined;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    @wire(getServiceFormDocumentsForContact, { contactId: '$recordId' })
    wiredServiceDocs(result) {
        this.serviceDocsResult = result;
        if (result.data) {
            this.serviceDocs = result.data;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    @wire(getUploadedFileInfo, { contactId: '$recordId' })
    wiredFileInfo(result) {
        this.fileInfoResult = result;
        if (result.data) {
            this.uploadedFileInfo = result.data;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    buildRow(doc) {
        const isCompleted = !!doc.isCompleted;
        // NEW: rows explicitly marked as not required.
        const isNotNeeded = doc.status === NOT_NEEDED_STATUS;
        const fileInfo = this.uploadedFileInfo[doc.fieldApiName];
        const uploadSource = fileInfo ? fileInfo.uploadSource : null;
        const statusKey = (doc.status || 'not-started').toLowerCase().replace(/\s+/g, '-');

        // Only show the delete "X" for a file uploaded from THIS side
        // (internal), or a legacy file with no source tag at all - never
        // for a file that was uploaded through the Experience Portal.
        const canDelete = !isCompleted && !!fileInfo && (uploadSource === UPLOAD_SOURCE || !uploadSource);

        return {
            key: doc.fieldApiName,
            label: doc.label,
            fieldApiName: doc.fieldApiName,
            status: doc.status,
            isCompleted,
            isNotNeeded, // NEW
            // NEW: single flag the template uses to decide whether the
            // Upload button renders. Completed behaves exactly as before;
            // Not Needed is the new case that also suppresses it.
            canUpload: !isCompleted && !isNotNeeded,
            rowClass: isCompleted ? 'document-row document-row_completed' : 'document-row',
            dropdownWrapClass: 'status-dropdown-wrap status-dropdown-wrap_' + statusKey,
            uploadLabel: doc.status === 'Rejected' || doc.status === 'Expired' ? 'Re-upload' : 'Upload Files',
            hasFile: !!fileInfo,
            fileName: fileInfo ? fileInfo.fileName : '',
            contentDocumentId: fileInfo ? fileInfo.contentDocumentId : null,
            canDelete,
            statusOptions: STATUS_OPTIONS
        };
    }

    get autoRows() {
        return this.docs.filter((d) => d.groupName === 'auto').map((d) => this.buildRow(d));
    }
    get hasAutoRows() {
        return this.autoRows.length > 0;
    }

    get certificationRows() {
        return this.docs.filter((d) => d.groupName === 'certification').map((d) => this.buildRow(d));
    }
    get hasCertificationRows() {
        return this.certificationRows.length > 0;
    }

    get driverRows() {
        return this.docs.filter((d) => d.groupName === 'driver').map((d) => this.buildRow(d));
    }
    get hasDriverRows() {
        return this.driverRows.length > 0;
    }

    get serviceRows() {
        return this.serviceDocs.map((d) => this.buildRow(d));
    }
    get hasServiceRows() {
        return this.serviceRows.length > 0;
    }
 get allDocs() {
        return [...this.docs, ...this.serviceDocs];
    }

    get applicableDocs() {
        return this.allDocs.filter((d) => d.status !== NOT_NEEDED_STATUS);
    }

    get totalDocumentCount() {
        return this.applicableDocs.length;
    }
     get completedDocumentCount() {
        return this.applicableDocs.filter((d) => d.status === 'Completed').length;
    }

    get completionPercentage() {
        const total = this.totalDocumentCount;
        return total > 0 ? Math.round((this.completedDocumentCount / total) * 100) : 0;
    }

    get progressRingStyle() {
        const offset =
            this.ringCircumference - (this.completionPercentage / 100) * this.ringCircumference;
        return `stroke-dashoffset: ${offset}px;`;
    }

    get formCountLabel() {
        return `${this.completedDocumentCount}/${this.totalDocumentCount} forms`;
    }

    // Section heading labels.
    get basicDocumentsHeading() {
        return 'Basic Documents Status';
    }

    get driverDocumentsHeading() {
        return 'Driver Documents Status';
    }

    get serviceSectionHeading() {
        const isAtc = this.serviceDocs.some((d) => d.fieldApiName && d.fieldApiName.startsWith('DCW_'));
        const isHah = this.serviceDocs.some((d) => d.fieldApiName === 'HAH_Certificate__c');

        if (isAtc) {
            return 'Service - ATC Documents Status';
        }
        if (isHah) {
            return 'Service - HAH Documents Status';
        }
        return 'Service Documents Status';
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

    handleStatusChange(event) {
        const fieldApiName = event.currentTarget.dataset.field;
        const newStatus = event.detail.value;
        if (!fieldApiName || !newStatus) {
            return;
        }

        this.isLoading = true;

        updateDocumentStatusInternal({ contactId: this.recordId, fieldApiName, newStatus })
            .then(() => {
                this.showToast('Success', 'Status updated.', 'success');
                return Promise.all([
                    refreshApex(this.docsResult),
                    refreshApex(this.serviceDocsResult)
                ]);
            })
            .catch((error) => {
                this.showToast('Error', this.reduceError(error) || 'There was a problem updating the status.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleUploadButtonClick(event) {
        this.pendingFieldApiName = event.currentTarget.dataset.field;

        // NEW: belt-and-braces guard. The button isn't rendered at all for
        // a "Not Needed" row, but if the status changed in another tab
        // between render and click, stop here rather than opening the
        // file picker for a row that can't accept a file.
        if (this.isFieldNotNeeded(this.pendingFieldApiName)) {
            this.showToast('Not allowed', 'This document is marked "Not Needed". Change the status before uploading.', 'warning');
            return;
        }

        const input = this.template.querySelector('.hidden-file-input');
        if (input) {
            input.value = null; // reset so re-selecting the same file still fires 'change'
            input.click();
        }
    }

    // NEW: looks up the current status of a field across both doc lists.
    isFieldNotNeeded(fieldApiName) {
        if (!fieldApiName) {
            return false;
        }
        const match = [...this.docs, ...this.serviceDocs].find((d) => d.fieldApiName === fieldApiName);
        return !!match && match.status === NOT_NEEDED_STATUS;
    }

    handleFileSelected(event) {
        const file = event.target.files[0];
        if (!file || !this.pendingFieldApiName) {
            return;
        }
        const fieldApiName = this.pendingFieldApiName;

        const reader = new FileReader();
        reader.onload = () => {
            const base64Data = reader.result.split(',')[1];
            this.isLoading = true;

            uploadDocument({ contactId: this.recordId, fieldApiName, base64Data, fileName: file.name, uploadSource: 'internal' })
                .then(() => {
                    // uploadDocument() ends by calling markDocumentPending(),
                    // which now writes the status field directly and
                    // synchronously for internal users (no Platform Event /
                    // trigger round trip - that indirection was only ever
                    // needed for the Experience Portal's CspLitePortal DML
                    // restriction, and routing internal writes through it
                    // too was why this row could get stuck showing
                    // "Not Started" even after the file was attached).
                    // By the time this promise resolves, the field is
                    // already updated, so refreshApex() can run right away.
                    this.showToast('Success', 'Document uploaded. It is now pending review.', 'success');
                    return Promise.all([
                        refreshApex(this.docsResult),
                        refreshApex(this.serviceDocsResult),
                        refreshApex(this.fileInfoResult)
                    ]);
                })
                .catch((error) => {
                    this.showToast('Error', this.reduceError(error) || 'There was a problem uploading your document.', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        };
        reader.readAsDataURL(file);
    }

    handleDeleteFile(event) {
        const contentDocumentId = event.currentTarget.dataset.docid;
        const fieldApiName = event.currentTarget.dataset.field;
        if (!contentDocumentId || !fieldApiName) {
            return;
        }

        // eslint-disable-next-line no-alert
        if (!window.confirm('Remove this file? This cannot be undone.')) {
            return;
        }

        this.isLoading = true;

        deleteUploadedDocument({ contactId: this.recordId, contentDocumentId, fieldApiName })
            .then(() => {
                this.showToast('Success', 'File removed. Status reset to Not Started.', 'success');
                return Promise.all([
                    refreshApex(this.docsResult),
                    refreshApex(this.serviceDocsResult),
                    refreshApex(this.fileInfoResult)
                ]);
            })
            .catch((error) => {
                this.showToast('Error', this.reduceError(error) || 'There was a problem removing the file.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'An unknown error occurred.';
    }
}