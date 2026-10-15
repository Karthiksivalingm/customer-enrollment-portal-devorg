import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getRelatedAccountsWithATCData from '@salesforce/apex/ATCMonitoringDatesController.getRelatedAccountsWithATCData';

// Contact fields to fetch
const CONTACT_FIELDS = [
    'Contact.Id',
    'Contact.Name',
    'Contact.AccountId'
];

export default class AtcMonitoringDatesTab extends LightningElement {
    @api recordId;
    @api enableCaching;
    @api componentTitle;
    @api showAccountLink;

    contactRecord;
    relatedAccountsList = [];
    isLoading = true;
    errorMessage;
    hasData = false;

    // Wire adapter to get contact record
    @wire(getRecord, { recordId: '$recordId', fields: CONTACT_FIELDS })
    wiredContact({ error, data }) {
        if (data) {
            this.contactRecord = data;
            this.fetchRelatedAccountsData();
        } else if (error) {
            this.errorMessage = 'Error loading contact: ' + error.body.message;
            this.isLoading = false;
        }
    }

    // Apex method to get related accounts with ATC data
    fetchRelatedAccountsData() {
        getRelatedAccountsWithATCData({ contactId: this.recordId })
            .then(result => {
                if (result && result.length > 0) {
                    this.relatedAccountsList = result.map(item => ({
                        ...item,
                        // Force real booleans so the checkboxes bind correctly
                        FirstATCMonitoringMeeting: item.FirstATCMonitoringMeeting === true,
                        Day30ATCMonitoringMeetingCheck: item.Day30ATCMonitoringMeetingCheck === true,
                        Day60ATCMonitoringMeetingCheck: item.Day60ATCMonitoringMeetingCheck === true,
                        First90DayATCMonitoringMeeting: item.First90DayATCMonitoringMeeting === true,
                        hasData: this.checkIfHasData(item)
                    }));
                    this.hasData = true;
                } else {
                    this.errorMessage = 'No related accounts found for this contact.';
                    this.hasData = false;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : 'Error loading account data';
                this.isLoading = false;
            });
    }

    // Check if account has ATC data
    checkIfHasData(item) {
        return item.AccountId &&
               (item.InitialServiceDate ||
                item.FirstATCMonitoringMeeting ||
                item.FirstATCMonitoringMeetingDate ||
                item.FirstATCMonitoringMeetingType ||
                item.Day30ATCMonitoringMeetingCheck ||
                item.Day30ATCMonitoringMeetingDate ||
                item.Day60ATCMonitoringMeetingCheck ||
                item.Day60ATCMonitoringMeetingDate ||
                item.First90DayATCMonitoringMeeting ||
                item.First90DayATCMonitoringMeetingDate ||
                item.Last90DayATCMonitoringMeetingDate ||
                item.Next90DayATCMonitoringMeetingDate);
    }

    get noDataMessage() {
        return !this.hasData && !this.isLoading;
    }

    get showContent() {
        return this.hasData && !this.isLoading && !this.errorMessage;
    }
}