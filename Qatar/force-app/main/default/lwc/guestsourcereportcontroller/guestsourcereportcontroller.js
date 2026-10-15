import { LightningElement, api, wire } from 'lwc';
import getReport from '@salesforce/apex/GuestSourceReportController.getReport';

export default class GuestSourceReport extends LightningElement {
    @api recordId; // Invitation__c (Event) record Id, auto-provided on a record page

    eventName;
    reportType;
    reportDate;
    error;

    isLoaded = false;

    statusColumns = [];
    locationStatusColumns = [];
    rsvpStatusColumns = [];

    sourceRows = [];
    sourceTotalRow = { label: '', cells: [] };
    tierRows = [];
    tierTotalRow = { label: '', cells: [] };
    sourceRsvpRows = [];
    sourceRsvpTotalRow = { label: '', cells: [] };
    tierRsvpRows = [];
    tierRsvpTotalRow = { label: '', cells: [] };

    // Glossary — edit these definitions as needed
    glossary = [
        { term: 'Accepted', def: 'Guest accepted the invitation.' },
        { term: 'Bounced Email', def: 'Invitation Email bounced back..' },
        { term: 'No Response', def: 'Guest received the invitation email but did not reply.' },
        { term: 'Visited', def: 'Guest checked in / visited the event.' },
        { term: 'Declined', def: 'Guest declined the invitation.' },
        { term: 'Confirmed', def: 'Guest registration is confirmed.' },
        { term: 'Attended', def: 'Guest attended the event.' },
        { term: 'Not Responded', def: 'Guest has not responded to registration.' },
        { term: 'Rejected', def: 'Guest registration was rejected.' },
        { term: 'Cancelled', def: 'Guest registration was cancelled.' },
        { term: 'None', def: 'No status value is set.' }
    ];

    @wire(getReport, { eventId: '$recordId' })
    wiredReport({ data, error }) {
        if (data) {
            this.eventName = data.eventName;
            this.reportType = data.reportType;
            this.reportDate = data.reportDate;

            // Apex now returns 'None' directly as a column for blank/null statuses,
            // so no front-end normalization is needed here.
            this.statusColumns = data.statusColumns;
            this.locationStatusColumns = data.locationStatusColumns;
            this.rsvpStatusColumns = data.rsvpStatusColumns;

            this.sourceRows = data.sourceRows.map((r) => this.toDisplayRow(r, this.statusColumns));
            this.sourceTotalRow = this.toDisplayRow(data.sourceTotalRow, this.statusColumns);

            this.tierRows = data.tierRows.map((r) => this.toDisplayRow(r, this.locationStatusColumns));
            this.tierTotalRow = this.toDisplayRow(data.tierTotalRow, this.locationStatusColumns);

            this.sourceRsvpRows = data.sourceRsvpRows.map((r) => this.toDisplayRow(r, this.rsvpStatusColumns));
            this.sourceRsvpTotalRow = this.toDisplayRow(data.sourceRsvpTotalRow, this.rsvpStatusColumns);

            this.tierRsvpRows = data.tierRsvpRows.map((r) => this.toDisplayRow(r, this.rsvpStatusColumns));
            this.tierRsvpTotalRow = this.toDisplayRow(data.tierRsvpTotalRow, this.rsvpStatusColumns);

            this.error = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.isLoaded = true;
        }
    }

    get showTables() {
        return this.isLoaded && !this.error;
    }

    toDisplayRow(row, columns) {
        return {
            label: row.label,
            cells: row.values.map((v, idx) => ({ key: columns[idx] + row.label, value: v }))
        };
    }

    get hasError() {
        return !!this.error;
    }
}