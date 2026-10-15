import { LightningElement, wire, track } from 'lwc';
import getApprovedRequests from '@salesforce/apex/CreditRequestController.getApprovedRequests';

const COLUMNS = [
    { 
        label: 'Name', 
        fieldName: 'recordLink', // This matches the dynamic property we create below
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Name' }, // This shows the Name as the clickable text
            target: '_blank' 
        } 
    },
    { label: 'Status', fieldName: 'Credit_Request_Status__c', type: 'text' },
    { label: 'Amount', fieldName: 'Total_Amount_Requested__c', type: 'currency' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date', 
        typeAttributes: {
            year: 'numeric', month: 'short', day: '2-digit'
        }
    }
];

export default class ApprovedCreditRequests extends LightningElement {
    columns = COLUMNS;
    @track wiredRecords = [];
    error;

    @wire(getApprovedRequests)
    wiredData({ error, data }) {
        if (data) {
            // We map the data to add a "recordLink" property to each row
            this.wiredRecords = data.map(record => {
                return {
                    ...record,
                    recordLink: `/lightning/r/Credit_Request__c/${record.Id}/view`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.wiredRecords = [];
        }
    }

    get hasData() {
        return this.wiredRecords.length > 0;
    }
}