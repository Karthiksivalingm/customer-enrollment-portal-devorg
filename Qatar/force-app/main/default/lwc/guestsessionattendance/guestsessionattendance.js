import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSessionAttendance from '@salesforce/apex/GuestSessionAttendanceController.getSessionAttendance';

const PAGE_SIZE = 20;

export default class GuestSessionAttendance extends NavigationMixin(LightningElement) {

    @api recordId;

    @track _allRecords   = [];
    @track searchTerm    = '';
    @track isLoading     = true;
    @track isLoadingMore = false;
    @track error         = false;
    @track totalCount    = 0;
    @track hasMore       = false;
    _offset              = 0;

    connectedCallback() { this._loadRecords(false); }

    _loadRecords(append) {
        if (append) { this.isLoadingMore = true; }
        else        { this.isLoading = true; this._allRecords = []; this._offset = 0; }

        getSessionAttendance({
            guestListId : this.recordId,
            pageSize    : PAGE_SIZE,
            offset      : this._offset
        })
        .then(result => {
            this.error      = false;
            this.totalCount = result.totalCount;
            this.hasMore    = result.hasMore;
            const newRecs   = (result.records || []).map((r, idx) => ({
                ...r,
                rowNum  : this._offset + idx + 1,
                rowClass: (this._offset + idx) % 2 === 0 ? 'gsa-row gsa-row-even' : 'gsa-row gsa-row-odd'
            }));
            this._allRecords   = append ? [...this._allRecords, ...newRecs] : newRecs;
            this._offset      += newRecs.length;
            this.isLoading     = false;
            this.isLoadingMore = false;
        })
        .catch(err => {
            this.error = true; this.isLoading = false; this.isLoadingMore = false;
            console.error('GuestSessionAttendance error:', err);
        });
    }

    handleScroll(event) {
        if (this.isLoadingMore || !this.hasMore) return;
        const el = event.target;
        if (el.scrollTop + el.clientHeight >= el.scrollHeight - 100) this._loadRecords(true);
    }

    get filteredRecords() {
        if (!this.searchTerm) return this._allRecords;
        const term = this.searchTerm.toLowerCase();
        return this._allRecords.filter(r =>
            (r.subEventName || '').toLowerCase().includes(term) ||
            (r.eventName    || '').toLowerCase().includes(term)
        );
    }

    get filteredCount()   { return this.filteredRecords.length; }
    get loadedCount()     { return this._allRecords.length; }
    get hasRecords()      { return !this.isLoading && !this.error && this._allRecords.length > 0; }
    get isEmpty()         { return !this.isLoading && !this.error && this._allRecords.length === 0; }
    get noSearchResults() { return !!this.searchTerm && this.filteredRecords.length === 0; }
    get attendedCount()   { return this._allRecords.filter(r => r.attended).length; }
    get registeredCount() { return this._allRecords.filter(r => r.registered).length; }

    handleSearch(event) { this.searchTerm = event.target.value; }
    clearSearch()       { this.searchTerm = ''; }

    handleNavigation(event) {
        event.preventDefault();
        const id = event.currentTarget.dataset.id;
        if (!id) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, actionName: 'view' }
        });
    }
}