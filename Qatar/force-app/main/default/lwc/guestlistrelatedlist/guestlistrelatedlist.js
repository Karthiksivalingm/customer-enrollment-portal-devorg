import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getGuestList from '@salesforce/apex/GuestListRelatedListController.getGuestList';
import upsertHERequest from '@salesforce/apex/GuestListRelatedListController.upsertHERequest';

export default class GuestListRelatedList extends NavigationMixin(LightningElement) {

    @api recordId; // Invitation__c record Id from record page

    @track guestList = [];
    @track isLoading = true;
    @track error = false;

    _wiredResult;          // held for refreshApex
    _noteEdits = {};       // temp store: { guestListId: noteString }

    // ─── Wire ────────────────────────────────────────────────────────────────

    @wire(getGuestList, { invitationId: '$recordId' })
    wiredGuests(result) {
        this._wiredResult = result;
        this.isLoading = false;
        const { data, error } = result;
        if (data) {
            this.error = false;
            this.guestList = data.map(guest => {
                // Pull existing HE note from child subquery (HE_Requests__r)
                const existingNote = guest.HE_Request__r && guest.HE_Request__r.length > 0
                    ? guest.HE_Request__r[0].Feedback__c
                    : '';
                return {
                    ...guest,
                    heNote: existingNote || '',
                    isEditingNote: false,
                    isSavingNote: false,
                    rsvpBadgeClass: this._rsvpBadgeClass(guest.RSVP__c),
                    contactPhotoUrl: null
                };
            });
        } else if (error) {
            this.error = true;
            console.error('GuestListRelatedList wire error:', error);
        }
    }

    // ─── Computed ─────────────────────────────────────────────────────────────

    get hasRecords() {
        return !this.isLoading && !this.error && this.guestList.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.error && this.guestList.length === 0;
    }

    // ─── Navigation ───────────────────────────────────────────────────────────

    handleNavigation(event) {
        event.preventDefault();
        const id   = event.currentTarget.dataset.id;
        const type = event.currentTarget.dataset.type;

        // Both guest-list and contact navigate to their respective record pages
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view'
            }
        });
    }

    // ─── Note Editing ─────────────────────────────────────────────────────────

    handleNoteEdit(event) {
        const id = event.currentTarget.dataset.id;
        this.guestList = this.guestList.map(g =>
            g.Id === id ? { ...g, isEditingNote: true } : g
        );
    }

    handleNoteChange(event) {
        const id = event.currentTarget.dataset.id;
        this._noteEdits[id] = event.detail.value;
    }

    handleNoteSave(event) {
        const id = event.currentTarget.dataset.id;
        const guest = this.guestList.find(g => g.Id === id);
        if (!guest) return;

        const feedbackNote = this._noteEdits[id] !== undefined
            ? this._noteEdits[id]
            : guest.heNote;

        const guestName = guest.Contact__r ? guest.Contact__r.Name : 'Unknown';

        // Show saving spinner on this row
        this.guestList = this.guestList.map(g =>
            g.Id === id ? { ...g, isSavingNote: true } : g
        );

        upsertHERequest({
            guestListId:  id,
            guestName:    guestName,
            feedbackNote: feedbackNote
        })
        .then(() => {
            this.guestList = this.guestList.map(g =>
                g.Id === id
                    ? { ...g, heNote: feedbackNote, isEditingNote: false, isSavingNote: false }
                    : g
            );
            delete this._noteEdits[id];
            this._toast('Success', 'HE Request saved successfully.', 'success');
            return refreshApex(this._wiredResult);
        })
        .catch(err => {
            console.error('upsertHERequest error:', err);
            this.guestList = this.guestList.map(g =>
                g.Id === id ? { ...g, isSavingNote: false } : g
            );
            this._toast('Error', 'Failed to save HE Request. Please try again.', 'error');
        });
    }

    handleNoteCancel(event) {
        const id = event.currentTarget.dataset.id;
        delete this._noteEdits[id];
        this.guestList = this.guestList.map(g =>
            g.Id === id ? { ...g, isEditingNote: false } : g
        );
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _rsvpBadgeClass(rsvp) {
        const base = 'rsvp-badge ';
        if (!rsvp) return base + 'rsvp-default';
        const val = rsvp.toLowerCase();
        if (val === 'accepted' || val === 'confirmed') return base + 'rsvp-accepted';
        if (val === 'declined')                         return base + 'rsvp-declined';
        if (val === 'pending')                          return base + 'rsvp-pending';
        return base + 'rsvp-default';
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}