import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_INFLUENTIAL_AGENT_FIELD from '@salesforce/schema/Account.Influential_Agent__c';
import INACTIVE_ACCOUNT from '@salesforce/schema/Account.Inactive_Account__c';
import ACCOUNT_PARENTID from '@salesforce/schema/Account.ParentId';
import CONTACT_INFLUENTIAL_CONTACT_FIELD from '@salesforce/schema/Contact.Influential_contact_from_Account__c';


export default class BannerInfluentialAgent extends LightningElement {
    @api recordId;
    @api objectApiName;
    influentialAgent = false;
    parentAccountId;
    inactiveAccount = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$fieldsToQuery'
    })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.objectApiName === 'Account') {
                this.influentialAgent = data.fields.Influential_Agent__c?.value;
                this.inactiveAccount = data.fields.Inactive_Account__c?.value;
                this.parentAccountId = data.fields.ParentId?.value;
            } else if (this.objectApiName === 'Contact') {
                this.influentialAgent = data.fields.Influential_contact_from_Account__c?.value;
            }
        } else if (error) {
            console.error(error);
        }
    }
    get fieldsToQuery() {
        return this.objectApiName === 'Account'
            ? [ACCOUNT_INFLUENTIAL_AGENT_FIELD, ACCOUNT_PARENTID, INACTIVE_ACCOUNT]
            : [CONTACT_INFLUENTIAL_CONTACT_FIELD];

    }
    get showBannerInactiveAccount() {
        return this.inactiveAccount;
    }

    get showBanner() {
        return this.influentialAgent;
    }
    @wire(getRecord, {
        recordId: "$parentAccountId",
        fields: [ACCOUNT_INFLUENTIAL_AGENT_FIELD,INACTIVE_ACCOUNT],
    })
    contactData({ error, data }) {
        if (data) {
            this.inactiveAccount = data.fields.Inactive_Account__c?.value;
            this.influentialAgent = data.fields.Influential_Agent__c?.value;
        } else if (error) {
            console.error("Error fetching Contact record:", error);
        }
    }
}