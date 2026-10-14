import { LightningElement, api } from 'lwc';
import resolveCase from '@salesforce/apex/CaseActionController.resolveCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ResolveCaseButton extends LightningElement {
    @api recordId;

    async handleResolve() {
        try {
            await resolveCase({ caseId: this.recordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case has been resolved',
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