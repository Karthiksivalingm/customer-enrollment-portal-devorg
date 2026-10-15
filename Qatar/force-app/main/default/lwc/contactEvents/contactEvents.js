import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContactEvents from '@salesforce/apex/ContactEventsController.getContactEvents';

export default class ContactEvents extends NavigationMixin(LightningElement) {
    @api recordId;

    @track events = [];
    @track filteredEvents = [];
    @track selectedEvent = {};
    @track showModal = false;
    @track isLoading = true;
    @track error;
    @track searchTerm = '';
    @track sortField = 'StartDateTime';
    @track sortDirection = 'desc';

    @wire(getContactEvents, { contactId: '$recordId' })
    wiredEvents({ data, error }) {
        if (data) {
            this.events = data;
            this.filteredEvents = [...data];
            this.isLoading = false;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'Unknown error';
            this.isLoading = false;
        }
    }

    // Getters
    get hasEvents() {
        return !this.isLoading && this.filteredEvents.length > 0;
    }

    get noEvents() {
        return !this.isLoading && this.filteredEvents.length === 0 && !this.error;
    }

    get totalEvents() {
        return this.events.length;
    }

    get sortedBySubject() {
        return this.sortField === 'Subject';
    }

    get sortedByDate() {
        return this.sortField === 'StartDateTime';
    }

    get sortIcon() {
        return this.sortDirection === 'asc'
            ? 'utility:arrowup'
            : 'utility:arrowdown';
    }

    // Search
    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.applyFilter();
    }

    applyFilter() {
        let filtered = [...this.events];

        if (this.searchTerm) {
            filtered = filtered.filter(e =>
                (e.Subject        && e.Subject.toLowerCase().includes(this.searchTerm)) ||
                (e.Description    && e.Description.toLowerCase().includes(this.searchTerm)) ||
                (e.CRM_Notes__c   && e.CRM_Notes__c.toLowerCase().includes(this.searchTerm)) ||
                (e.PA_Notes__c    && e.PA_Notes__c.toLowerCase().includes(this.searchTerm))
            );
        }

        this.filteredEvents = this.sortEvents(filtered);
    }

    // Sorting
    sortBySubject() {
        if (this.sortField === 'Subject') {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = 'Subject';
            this.sortDirection = 'asc';
        }
        this.filteredEvents = this.sortEvents([...this.filteredEvents]);
    }

    sortByDate() {
        if (this.sortField === 'StartDateTime') {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = 'StartDateTime';
            this.sortDirection = 'desc';
        }
        this.filteredEvents = this.sortEvents([...this.filteredEvents]);
    }

    sortEvents(eventsToSort) {
        return eventsToSort.sort((a, b) => {
            let valA = a[this.sortField] || '';
            let valB = b[this.sortField] || '';
            if (valA < valB) return this.sortDirection === 'asc' ? -1 : 1;
            if (valA > valB) return this.sortDirection === 'asc' ? 1 : -1;
            return 0;
        });
    }

    // View Details Modal
    handleViewDetails(event) {
        const eventId = event.currentTarget.dataset.id;
        this.selectedEvent = this.events.find(e => e.Id === eventId) || {};
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.selectedEvent = {};
    }

    // Navigate to Event record
    handleEventClick(event) {
        const eventId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: eventId,
                actionName: 'view'
            }
        });
    }
}