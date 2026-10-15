import { LightningElement, api } from 'lwc';

import getGuestLists     from '@salesforce/apex/GuestListApprovalController.getGuestLists';
import submitForApproval from '@salesforce/apex/GuestListApprovalController.submitForApproval';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GuestListApproval extends LightningElement {

    @api recordId;

    showModal    = false;
    selectedRows = [];
    isLoading    = false;
    guestLists   = [];

    columns = [
        { label: 'Guest List', fieldName: 'Name' },
        { label: 'Contact',    fieldName: 'ContactName' },
        { label: 'Invitation', fieldName: 'InvitationName' },
        { label: 'Title',      fieldName: 'Title__c' },
        { label: 'Reason',     fieldName: 'Reason__c' }
    ];

    // Called every time button is clicked - always fresh from DB
    openModal() {
        this.isLoading = true;
        getGuestLists({ sessionId: this.recordId })
            .then(data => {
                this.guestLists = data.map(rec => ({
                    ...rec,
                    ContactName:    rec.Contact__r    ? rec.Contact__r.Name    : '-',
                    InvitationName: rec.Invitation__r ? rec.Invitation__r.Name : '-'
                }));
                this.showModal = true;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : 'Failed to load guest lists',
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    closeModal() {
        this.showModal    = false;
        this.selectedRows = [];
        this.guestLists   = [];
    }

    handleSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }

    submitSelected() {
        if (!this.selectedRows.length) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No records selected',
                message: 'Please select at least one guest list.',
                variant: 'warning'
            }));
            return;
        }

        this.isLoading = true;

        submitForApproval({ guestListIds: this.selectedRows })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Sent for approval successfully.',
                    variant: 'success'
                }));
                this.closeModal();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : 'Submission failed',
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}