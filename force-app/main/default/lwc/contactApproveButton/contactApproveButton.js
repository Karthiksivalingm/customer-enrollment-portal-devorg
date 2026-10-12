import { LightningElement, api } from 'lwc';
import approveContact from '@salesforce/apex/ContactManualApproveController.approveContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ContactApproveButton extends LightningElement {
    @api recordId;

    async handleApprove() {
        try {
            await approveContact({ contactId: this.recordId, statusValue: 'Approved' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Contact set to Approved',
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