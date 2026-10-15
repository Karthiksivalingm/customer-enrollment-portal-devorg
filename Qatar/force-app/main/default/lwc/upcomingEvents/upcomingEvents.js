import { LightningElement, track, wire } from 'lwc';
import getUpcomingEvents from '@salesforce/apex/UpcomingEventsController.getUpcomingEvents';
import { NavigationMixin } from 'lightning/navigation';

export default class UpcomingEvents extends NavigationMixin(LightningElement) {
    @track events = [];
    @track filter = 'this_week';
    @track isLoading = false;
    @track error;

    filterOptions = [
        { label: 'This Week', value: 'this_week' },
        { label: 'This Month', value: 'this_month' },
        { label: 'Next 30 Days', value: 'next_30' },
        { label: 'All Upcoming', value: 'all' }
    ];

    connectedCallback() {
        this.loadEvents();
    }

    handleFilterChange(event) {
        this.filter = event.detail.value;
        this.loadEvents();
    }

    loadEvents() {
        this.isLoading = true;
        getUpcomingEvents({ filter: this.filter })
            .then(result => {
                this.events = result.map(e => ({
                    ...e,
                    StartFormatted: new Date(e.StartDateTime).toLocaleString(),
                    EndFormatted: new Date(e.EndDateTime).toLocaleString()
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
            });
    }

    handleSubjectClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}