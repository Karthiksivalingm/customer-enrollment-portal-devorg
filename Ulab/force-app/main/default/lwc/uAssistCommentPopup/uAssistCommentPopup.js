import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import updateComments from '@salesforce/apex/TechReviewController.updateComments';

export default class TechReviewPopup extends LightningElement {
    @api recordId;
    comments = '';

    handleChange(event) {
        this.comments = event.target.value;
    }

    handleSave() {
        updateComments({ recordId: this.recordId, comments: this.comments })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Comments saved successfully',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}