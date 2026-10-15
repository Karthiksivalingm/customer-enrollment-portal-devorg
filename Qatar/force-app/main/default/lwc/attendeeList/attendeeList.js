import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LIST_OF_ATTENDEES_FIELD from '@salesforce/schema/Meeting_Request__c.List_of_Attendeess__c';
import ATTENDEES_LIST_FIELD from '@salesforce/schema/Meeting_Request__c.Attendees_List__c';
import { getFieldValue } from 'lightning/uiRecordApi';

const fields = [LIST_OF_ATTENDEES_FIELD, ATTENDEES_LIST_FIELD];

export default class AttendeeList extends LightningElement {
    @api recordId;
    @track numberOfAttendees = 0;
    @track attendees = [];

    @wire(getRecord, { recordId: '$recordId', fields })
    meetingRequest;

    get listOfAttendees() {
        return getFieldValue(this.meetingRequest.data, LIST_OF_ATTENDEES_FIELD);
    }

    get attendeesList() {
        return getFieldValue(this.meetingRequest.data, ATTENDEES_LIST_FIELD);
    }

    handleAttendeeNumberChange(event) {
        this.numberOfAttendees = event.target.value;
        this.attendees = [];
        for (let i = 1; i <= this.numberOfAttendees; i++) {
            this.attendees.push({
                id: i,
                label: `Attendee ${i}`
            });
        }
    }

    handleSave() {
        const fields = {};
        fields.Id = this.recordId;
        fields[LIST_OF_ATTENDEES_FIELD.fieldApiName] = this.numberOfAttendees;
        fields[ATTENDEES_LIST_FIELD.fieldApiName] = this.attendees.map(att => att.label).join('; ');

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Meeting Request updated',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}