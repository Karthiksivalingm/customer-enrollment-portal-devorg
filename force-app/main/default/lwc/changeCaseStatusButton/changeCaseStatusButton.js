import { LightningElement, api, track } from 'lwc';
import changeStatus from '@salesforce/apex/CaseActionController.changeStatus';
import getCaseStatusesExcludingResolved from '@salesforce/apex/CaseActionController.getCaseStatusesExcludingResolved';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ChangeCaseStatusButton extends LightningElement {
    @api recordId;
    @track statuses = [];
    @track selectedStatus;

    connectedCallback() {
        getCaseStatusesExcludingResolved()
            .then(result => {
                this.statuses = result.map(s => ({ label: s, value: s }));
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

    handleChange(event) {
        this.selectedStatus = event.target.value;
    }

    async handleUpdate() {
        if(!this.selectedStatus) {
            this.showToast('Error', 'Please select a status', 'error');
            return;
        }

        try {
            await changeStatus({ caseId: this.recordId, newStatus: this.selectedStatus });

            this.showToast('Success', 'Status updated!', 'success');

            this.dispatchEvent(new CloseActionScreenEvent());

            window.location.href = '/' + this.recordId;

        } catch(error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}