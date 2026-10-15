import { LightningElement, wire, track } from 'lwc';
import getPendingContacts from '@salesforce/apex/GuestApprovalController.getPendingContacts';
import updateApproval from '@salesforce/apex/GuestApprovalController.updateApproval';

export default class GuestApprovalPage extends LightningElement {

    @track contacts = [];
    decisions = {};

    @wire(getPendingContacts)
    wiredContacts({ data }) {
        if (data) {
            this.contacts = data;
        }
    }

    handleApprove(event) {
        this.decisions[event.target.dataset.id] = 'Approved';
    }

    handleReject(event) {
        this.decisions[event.target.dataset.id] = 'Rejected';
    }

    handleSubmit() {
        updateApproval({ decisions: this.decisions })
            .then(() => {
                alert('Updated!');
                location.reload();
            });
    }
}