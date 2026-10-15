import { LightningElement, api, track } from "lwc";
import saveBirthDate from "@salesforce/apex/ODALeadController.saveBirthDate";
import { showToastNotification, toastVariant } from "c/fireNotification";

export default class OdaLeadDateBirth extends LightningElement {
  _product = "";
  _lead;
  _dateOfBirth;

  @track loading = false;

  @api minAge = 0;
  @api maxAge = 0;

  @api
  get product() {
    return this._product.toUpperCase();
  }

  set product(value) {
    this._product = value;
  }

  @api
  get lead() {
    return this._lead;
  }

  set lead(value) {
    this._lead = value;
  }

  @api
  get dateOfBirth() {
    return this._dateOfBirth;
  }

  set dateOfBirth(value) {
    this._dateOfBirth = value;
  }

  onDateOfBirthChange(event) {
    this._dateOfBirth = event.target.value;
  }

  get ageMessage() {
    if (this._lead.Age__c < this.minAge) {
      return "Lead is too young";
    }
    if (this._lead.Age__c > this.maxAge) {
      return "Lead is too old";
    }
  }

  saveDateOfBirth() {
    this.loading = true;
    let params = {
      leadId: this._lead.Id,
      dateOfBirth: this._dateOfBirth
    };

    saveBirthDate(params)
      .then((result) => {
        this.dispatchEvent(
          new CustomEvent("leadupdated", {
            detail: {
              lead: result
            },
            bubbles: true,
            composed: true
          })
        );
      })
      .catch((err) => {
        showToastNotification(this, "", err, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }
}