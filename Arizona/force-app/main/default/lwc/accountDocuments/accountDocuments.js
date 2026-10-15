import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAccountDocuments from '@salesforce/apex/AccountDocumentController.getAccountDocuments';
import getUploadedFileInfoForAccount from '@salesforce/apex/AccountDocumentController.getUploadedFileInfoForAccount';
import uploadAccountDocument from '@salesforce/apex/AccountDocumentController.uploadAccountDocument';
import updateAccountDocumentStatus from '@salesforce/apex/AccountDocumentController.updateAccountDocumentStatus';
import deleteAccountDocument from '@salesforce/apex/AccountDocumentController.deleteAccountDocument';

// Authorizations__c / PCSP__c always default to "Pending" (see
// AccountDocumentController.StatusDocument), never "Not Started",
// so that option is intentionally left out here.
const STATUS_OPTIONS = [
    { label: 'Pending', value: 'Pending' },
    { label: 'Completed', value: 'Completed' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Expired', value: 'Expired' }
];

const UPLOAD_SOURCE = 'internal';

export default class AccountDocuments extends NavigationMixin(LightningElement) {

    @api recordId;

    isLoading = true;
    errorMessage;

    statusOptions = STATUS_OPTIONS;

    docs = [];
    uploadedFileInfo = {};

    docsResult;
    fileInfoResult;

    pendingFieldApiName;

    @wire(getAccountDocuments, { accountId: '$recordId' })
    wiredDocuments(result) {
        this.docsResult = result;
        this.isLoading = false;

        if (result.data) {
            this.docs = result.data;
            this.errorMessage = undefined;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    @wire(getUploadedFileInfoForAccount, { accountId: '$recordId' })
    wiredFiles(result) {
        this.fileInfoResult = result;

        if (result.data) {
            this.uploadedFileInfo = result.data;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    buildRow(doc) {
        const filesList = this.uploadedFileInfo[doc.fieldApiName] || [];
        
        const files = Array.isArray(filesList) 
            ? filesList 
            : (filesList && filesList.contentDocumentId ? [filesList] : []);

        const statusKey = (doc.status || 'not-started')
            .toLowerCase()
            .replace(/\s+/g, '-');

        const canDeleteFilesBase = !doc.isCompleted && files.length > 0;

        // Process files: only the most recent file (index 0) can be deleted,
        // and never a file that was already present when the doc was once
        // marked Completed (file.isLocked) - that stays protected even if
        // a later upload pushes the status back to Pending.
        const processedFiles = files.map((file, index) => {
            // Only the first file (most recent/latest) can be deleted
            const isRecentFile = index === 0;
            // Grey out completed-doc files and any permanently locked file
            const isGreyedOut = doc.isCompleted || file.isLocked;

            const itemClass = isGreyedOut
                ? 'file-item file-item_greyed-out'
                : 'file-item';

            const linkClass = isGreyedOut
                ? 'uploaded-file-link uploaded-file-link_disabled'
                : 'uploaded-file-link';

            return {
                ...file,
                canDelete: canDeleteFilesBase && isRecentFile && !file.isLocked,
                isGreyedOut: isGreyedOut,
                itemClass: itemClass,
                linkClass: linkClass
            };
        });

        const filesContainerClass = doc.isCompleted 
            ? 'uploaded-files-section uploaded-files-section_completed' 
            : 'uploaded-files-section';

        return {
            ...doc,
            dropdownWrapClass: 'status-dropdown-wrap status-dropdown-wrap_' + statusKey,
            uploadLabel: doc.status === 'Rejected' || doc.status === 'Expired' ? 'Re-upload' : 'Upload Files',
            files: processedFiles,
            hasFile: files.length > 0,
            fileCount: files.length,
            filesContainerClass: filesContainerClass,
            canDeleteFiles: canDeleteFilesBase
        };
    }

    get documentRows() {
        return this.docs.map(doc => this.buildRow(doc));
    }

    handleStatusChange(event) {
        const fieldApiName = event.currentTarget.dataset.field;
        const newStatus = event.detail.value;

        this.isLoading = true;

        updateAccountDocumentStatus({
            accountId: this.recordId,
            fieldApiName,
            newStatus
        })
            .then(() => {
                this.showToast('Success', 'Status Updated', 'success');
                return refreshApex(this.docsResult);
            })
            .catch(error => {
                this.showToast('Error', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleUploadButtonClick(event) {
        this.pendingFieldApiName = event.currentTarget.dataset.field;
        const input = this.template.querySelector('.hidden-file-input');
        input.value = null;
        input.click();
    }

    handleFileSelected(event) {
        const file = event.target.files[0];

        if (!file) {
            return;
        }

        const maxSize = 25 * 1024 * 1024;
        if (file.size > maxSize) {
            this.showToast('Error', 'File size exceeds 25MB limit', 'error');
            return;
        }

        const reader = new FileReader();

        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.isLoading = true;

            uploadAccountDocument({
                accountId: this.recordId,
                fieldApiName: this.pendingFieldApiName,
                base64Data: base64,
                fileName: file.name,
                uploadSource: UPLOAD_SOURCE
            })
                .then(() => {
                    this.showToast('Success', `File "${file.name}" uploaded successfully`, 'success');
                    return Promise.all([
                        refreshApex(this.docsResult),
                        refreshApex(this.fileInfoResult)
                    ]);
                })
                .catch(error => {
                    this.showToast('Error', this.reduceError(error), 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        };

        reader.onerror = () => {
            this.showToast('Error', 'Failed to read file', 'error');
        };

        reader.readAsDataURL(file);
    }

    handleDeleteFile(event) {
        const fileId = event.currentTarget.dataset.docid;

        this.isLoading = true;

        deleteAccountDocument({
            accountId: this.recordId,
            contentDocumentId: fileId,
            fieldApiName: event.currentTarget.dataset.field
        })
            .then(() => {
                this.showToast('Success', 'File deleted successfully', 'success');
                return Promise.all([
                    refreshApex(this.docsResult),
                    refreshApex(this.fileInfoResult)
                ]);
            })
            .catch(error => {
                this.showToast('Error', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleFileClick(event) {
        event.preventDefault();

        const link = event.currentTarget;
        if (link.classList.contains('uploaded-file-link_disabled')) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.currentTarget.dataset.docid
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unknown Error';
    }
}