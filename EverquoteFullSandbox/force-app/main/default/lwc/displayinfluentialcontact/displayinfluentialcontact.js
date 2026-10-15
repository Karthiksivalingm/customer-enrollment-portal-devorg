import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ACCOUNT_ID from "@salesforce/schema/VoiceCall.Account__c";
import INFLUENTIAL_AGENT from "@salesforce/schema/Account.Influential_Agent__c";

export default class DisplayInfluentialContact extends LightningElement {
  @api recordId;
  @track accoutId;
  @track isInfluential = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [ACCOUNT_ID],
  })
  voiceCallData({ error, data }) {
    if (data) {
      this.accoutId = getFieldValue(data, ACCOUNT_ID);
      console.log("accoutId ID:", this.accoutId);
    } else if (error) {
      console.error("Error fetching VoiceCall record:", error);
    }
  }

  @wire(getRecord, {
    recordId: "$accoutId",
    fields: [INFLUENTIAL_AGENT],
  })
  contactData({ error, data }) {
    if (data) {
      this.isInfluential = getFieldValue(data, INFLUENTIAL_AGENT);
    } else if (error) {
      console.error("Error fetching Contact record:", error);
    }
  }

  hideModalBox() {
    this.isInfluential = false;
  }
}