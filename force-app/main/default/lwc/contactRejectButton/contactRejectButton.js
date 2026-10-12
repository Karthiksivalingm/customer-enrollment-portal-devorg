import { LightningElement, api } from 'lwc';
import approveContact from '@salesforce/apex/ContactManualApproveController.approveContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ContactRejectButton extends LightningElement {
    @api recordId;

    async handleReject() {
        try {
            await approveContact({ contactId: this.recordId, statusValue: 'Rejected' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Contact set to Rejected',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
            window.location.href = '/lightning/o/Contact/home';

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