import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createNewDocumentFromTemplate from '@salesforce/apex/NewPandaDocController.createNewDocumentFromTemplate';
import linkDocumentToSalesforce from '@salesforce/apex/NewPandaDocController.linkDocumentToSalesforce';

/**
 * ⚠️ IMPORTANT: You MUST update the TEMPLATE constant below with YOUR actual template ID from PandaDoc
 * 
 * How to get your template ID:
 * 1. Go to PandaDoc: https://app.pandadoc.com/templates/
 * 2. Click on the template you want to use
 * 3. Look at the URL in your browser: https://app.pandadoc.com/templates/YOUR_ID_HERE/edit
 * 4. Copy the ID (the part between /templates/ and /edit)
 * 5. Replace the ID below with your actual template ID
 */
const TEMPLATE = {
    id: 'YSoeJMbNfZ6zsW2CL2Qj5d', // ⚠️ CHANGE THIS TO YOUR ACTUAL TEMPLATE ID!
    name: 'Worker Comp Waiver - 1099 Sole Proprietor',    // ⚠️ UPDATE THIS TOO
};

export default class NewPandaDoc extends LightningElement {
    _recordId;
    _objectApiName;
    isLoading = false;

    @api set recordId(value) {
        this._recordId = value;
    }

    @api set objectApiName(value) {
        this._objectApiName = value;
    }

    get recordId() {
        return this._recordId;
    }

    get objectApiName() {
        return this._objectApiName;
    }

    get template() {
        return TEMPLATE;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCreate() {
        // Validate template ID
        if (!this.template.id || this.template.id === 'YOUR_ACTUAL_TEMPLATE_ID_HERE') {
            this.showToast(
                'Configuration Error',
                'Please update the template ID in the LWC code. Go to newPandaDoc.js and replace YOUR_ACTUAL_TEMPLATE_ID_HERE with your real template ID from PandaDoc.',
                'error'
            );
            return;
        }

        this.isLoading = true;
        
        createNewDocumentFromTemplate({
            recordId: this.recordId,
            templateId: this.template.id,
        })
            .then((result) => {
                let documentUuid = result;
                this.showToast(
                    'Success',
                    `Document ${documentUuid} successfully created! Linking to ${this.objectApiName}, please wait...`,
                    'success'
                );
                
                // Wait 3 seconds for PandaDoc to process the document
                setTimeout(() => {
                    linkDocumentToSalesforce({
                        documentUuid: documentUuid,
                        recordId: this.recordId,
                    })
                        .then(() => {
                            this.showToast(
                                'Success',
                                `Document ${documentUuid} successfully linked to the ${this.objectApiName}!`,
                                'success'
                            );
                            this.dispatchEvent(new CloseActionScreenEvent());
                        })
                        .catch((error) => {
                            console.error('Link error:', error);
                            let errorMessage = this.getErrorMessage(error);
                            this.showToast('Linking Error', errorMessage, 'error');
                        })
                        .finally(() => {
                            this.isLoading = false;
                        });
                }, 3000);
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Creation error:', error);
                let errorMessage = this.getErrorMessage(error);
                this.showToast('Creation Error', errorMessage, 'error');
            });
    }

    getErrorMessage(error) {
        let errorMessage = 'Unknown error';
        if (!error) {
            return errorMessage;
        }
        
        if (error.body) {
            if (Array.isArray(error.body)) {
                errorMessage = error.body.map((e) => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                errorMessage = error.body.message;
            } else if (typeof error.body === 'string') {
                errorMessage = error.body;
            }
        }
        
        return errorMessage;
    }

    showToast(title, message, variant, mode = 'dismissable') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode,
            })
        );
    }
}