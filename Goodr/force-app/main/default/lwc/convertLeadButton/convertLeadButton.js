import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import convertLead from '@salesforce/apex/LeadConversionService.convertLead';
import canConvert from '@salesforce/apex/LeadConversionService.canConvert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

const FIELDS = ['Lead.Status'];

export default class ConvertLead extends LightningElement {
    @api recordId;
    leadStatus;
    canConvertLead = false;
    isProcessing = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            this.leadStatus = data.fields.Status.value;
            this.checkCanConvert();
        } else if (error) {
            console.error('Error loading lead:', error);
        }
    }

    checkCanConvert() {
        canConvert({ leadId: this.recordId })
            .then(result => {
                this.canConvertLead = result;
            })
            .catch(error => {
                console.error('Error checking conversion eligibility:', error);
                this.canConvertLead = false;
            });
    }

    get isButtonDisabled() {
        return !this.canConvertLead || this.isProcessing;
    }

    get buttonVariant() {
        return this.canConvertLead ? 'brand' : 'neutral';
    }

    handleClick() {
        if (!this.canConvertLead) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Convert Lead',
                    message: 'Lead must be Qualified and have a Parent Vertical value defined before conversion.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isProcessing = true;

        convertLead({ leadId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Lead successfully converted.',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.isProcessing = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error converting lead',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}