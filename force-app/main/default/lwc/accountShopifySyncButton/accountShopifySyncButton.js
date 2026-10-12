import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import resyncRecords from '@salesforce/apex/ShopifySyncButton.recreateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AccountShopifySyncButton extends LightningElement {
    @api recordId;
    isProcessing = false;
    disabledMessage = '';

    // Wire using plain string — avoids schema import issue entirely
    @wire(getRecord, { recordId: '$recordId', fields: ['Account.Sales_Channel__c'] })
    wiredAccount({ error, data }) {
        if (data) {
            const salesChannel = data.fields.Sales_Channel__c.value;
            if (!salesChannel) {
                this.disabledMessage =
                    'Button will be available when Sales Channel is filled in ' +
                    'for the Account, all Store Locations and all Contacts.';
            } else {
                this.disabledMessage = '';
            }
        } else if (error) {
            console.error('Error loading account:', error);
        }
    }

    get isButtonEnabled() {
        return !this.disabledMessage && !this.isProcessing;
    }

    get isButtonDisabled() {
        return !this.isButtonEnabled;
    }

    get buttonVariant() {
        return this.isButtonEnabled ? 'brand' : 'neutral';
    }

    handleClick() {
        if (!this.isButtonEnabled) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Resync',
                    message: this.disabledMessage,
                    variant: 'warning'
                })
            );
            return;
        }

        this.isProcessing = true;

        resyncRecords({ accountId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Resync to Shopify triggered successfully.',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
                setTimeout(() => {
                    window.location.href = '/' + this.recordId;
                }, 500);
            })
            .catch(error => {
                this.isProcessing = false;
                this.disabledMessage = error.body?.message || error.message;
            });
    }
}