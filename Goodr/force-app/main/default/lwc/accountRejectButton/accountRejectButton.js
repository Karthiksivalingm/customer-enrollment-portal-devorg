import { LightningElement, api } from 'lwc';
import approveAccount from '@salesforce/apex/AccountManualApproveController.approveAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AccountApproveButton extends LightningElement {
    @api recordId;

    async handleReject() {
        try {
            await approveAccount({ accountId: this.recordId, statusValue: 'Rejected' });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Account set to Rejected',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
            window.location.href = '/lightning/o/Account/home';

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