import { LightningElement, api } from 'lwc';
import approveAccount from '@salesforce/apex/AccountManualApproveController.approveAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AccountApproveButton extends LightningElement {
    @api recordId;

    async handleApprove() {
        try {
            await approveAccount({ accountId: this.recordId, statusValue: 'Approved' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Account set to Approved',
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