import { LightningElement, api } from 'lwc';
import approveLead from '@salesforce/apex/LeadManualApproveController.approveLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class LeadRejectButton extends LightningElement {
    @api recordId;

    async handleReject() {
        try {
            await approveLead({ leadId: this.recordId, action: 'Rejected' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead set to Manual Rejected',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
            window.location.href = '/' + this.recordId;

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || error.message,
                    variant: 'error'
                })
            );
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}