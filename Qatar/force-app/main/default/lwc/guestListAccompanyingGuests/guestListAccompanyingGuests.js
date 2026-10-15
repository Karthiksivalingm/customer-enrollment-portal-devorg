import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import GUEST_LIST_OBJECT from '@salesforce/schema/Guest_List__c';
import getAccompanyingGuests from '@salesforce/apex/GuestListAccompanyingGuestsController.getAccompanyingGuests';

const AVATAR_COLORS = [
    { bg: '#EEF2FF', text: '#4338CA' }, { bg: '#F0FDF4', text: '#16A34A' },
    { bg: '#FFF7ED', text: '#EA580C' }, { bg: '#FDF4FF', text: '#9333EA' },
    { bg: '#FFF1F2', text: '#E11D48' }, { bg: '#ECFEFF', text: '#0891B2' },
];

export default class GuestListAccompanyingGuests extends NavigationMixin(LightningElement) {

    // recordId = the parent Guest_List__c record (the one the user clicked into)
    @api recordId;

    @track guests    = [];
    @track isLoading = true;
    @track error     = false;

    @track isNewGuestModalOpen = false;
    @track isSavingNewGuest    = false;

    guestListObjectApiName = GUEST_LIST_OBJECT;
    _wiredResult;

    @wire(getAccompanyingGuests, { parentGuestId: '$recordId' })
    wiredGuests(result) {
        this._wiredResult = result;
        const { data, error } = result;
        this.isLoading = false;
        if (data) {
            this.error  = false;
            this.guests = data.map(g => {
                const colorIdx = this._hashColor(g.contactName || '');
                const c = AVATAR_COLORS[colorIdx];
                const initial = (g.contactName || '?').trim().charAt(0).toUpperCase();
                return {
                    ...g,
                    avatarStyle: 'background:' + c.bg + ';color:' + c.text + ';',
                    initial
                };
            });
        } else if (error) {
            this.error  = true;
            this.guests = [];
            console.error('getAccompanyingGuests error:', error);
        }
    }

    get hasGuests() { return !this.isLoading && !this.error && this.guests.length > 0; }
    get isEmpty()   { return !this.isLoading && !this.error && this.guests.length === 0; }
    get guestCount() { return this.guests.length; }

    handleNavigation(event) {
        event.preventDefault();
        const id = event.currentTarget.dataset.id;
        if (!id) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, actionName: 'view' }
        });
    }

    handleNew() {
        this.isNewGuestModalOpen = true;
    }

    closeNewGuestModal() {
        this.isNewGuestModalOpen = false;
        this.isSavingNewGuest    = false;
    }

    handleNewGuestSubmit(event) {
        event.preventDefault();
        this.isSavingNewGuest = true;
        // Main_Guest__c is never shown to the user — always the parent record
        // they clicked "New" from.
        const fields = { ...event.detail.fields, Main_Guest__c: this.recordId };
        this.template.querySelector('lightning-record-edit-form.cg-new-guest-form').submit(fields);
    }

    handleNewGuestSuccess() {
        this.isSavingNewGuest    = false;
        this.isNewGuestModalOpen = false;
        this._toast('Success', 'Guest created successfully.', 'success');
        refreshApex(this._wiredResult);
    }

    handleNewGuestError(event) {
        this.isSavingNewGuest = false;
        console.error('New accompanying guest create error:', event.detail);
        const message = (event.detail && event.detail.message) || 'Failed to create guest. Please try again.';
        this._toast('Error', message, 'error');
    }

    _hashColor(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) hash = str.charCodeAt(i) + ((hash << 5) - hash);
        return Math.abs(hash) % AVATAR_COLORS.length;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}