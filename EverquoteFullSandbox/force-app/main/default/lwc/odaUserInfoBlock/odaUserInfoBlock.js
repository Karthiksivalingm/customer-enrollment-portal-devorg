import { LightningElement, api, track } from "lwc";
import getLeadUserInfo from "@salesforce/apex/OdaUserInfoBlockController.getLeadUserInfo";

export default class OdaUserInfoBlock extends LightningElement {
  @api recordId;
  @track displayInfo = [];

  connectedCallback() {
    if (this.recordId) {
      getLeadUserInfo({ leadId: this.recordId }).then(results =>
        this.handleLeadData(results)
      );
    }
  }

  handleLeadData(leadReturnData) {
    let displayInfoArray = leadReturnData.apiNames.map((apiName, index) => ({
      label: leadReturnData.labels[index],
      apiName: apiName,
      value: leadReturnData.lead[apiName]
    }));

    this.displayInfo = this.cloneArray(displayInfoArray);
  }

  cloneArray(arr) {
    return JSON.parse(JSON.stringify(arr));
  }
}