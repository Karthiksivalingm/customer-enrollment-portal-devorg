import { LightningElement, api } from 'lwc';
import initiateSSNSearch from '@salesforce/apex/NiprSSNsearch.initiateSSNSearch';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SsnSearchButton extends LightningElement {
    @api recordId;

    handleClick() {
        initiateSSNSearch({ contactId: this.recordId })
            .then(() => {
                this.showToast('Success', 'SSN Search initiated', 'success');
                this.closeAction();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.closeAction(); // Optional: also close on error
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}