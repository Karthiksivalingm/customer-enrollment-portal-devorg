import { LightningElement, api, track } from "lwc";
import { genders, statesShortForm } from "c/odaConstants";
import saveLeadRequiredInformation from "@salesforce/apex/ODALeadController.saveLeadRequiredInformation";
export default class OdaValidateLeadInfo extends LightningElement {
  _lead;

  @track isLoading = false;

  @track
  leadDetails = {
    gender: null,
    state: null,
    dateOfBirth: null
  };

  @api
  get lead() {
    return this._lead;
  }

  set lead(value) {
    this._lead = value;
    this.leadDetails.gender = this._lead.Gender__c;
    this.leadDetails.state = this._lead.State;
    this.leadDetails.dateOfBirth = this._lead.Date_of_Birth__c;
  }

  get genderOptions() {
    return Object.values(genders).map((gender) => {
      return { value: gender, label: gender };
    });
  }

  get stateOptions() {
    return statesShortForm.map((state) => {
      return { value: state, label: state };
    });
  }

  get genderIsValid() {
    return (
      !!this._lead.Gender__c &&
      Object.keys(genders).includes(this.lead.Gender__c.toLocaleLowerCase())
    );
  }

  get stateIsValid() {
    return !!this._lead.State && statesShortForm.includes(this._lead.State.toLocaleUpperCase());
  }

  get dateOfBirthIsValid() {
    return !!this._lead.Date_of_Birth__c;
  }

  get allFieldsAreValid() {
    return !Object.values(this.leadDetails)
      .map((value) => {
        return value == null;
      })
      .includes(true);
  }

  get saveButtonDisabled() {
    return !this.allFieldsAreValid;
  }

  onGenderChange(event) {
    this.leadDetails.gender = event.target.value;
  }

  onStateChange(event) {
    this.leadDetails.state = event.target.value;
  }

  onDateOfBirthChange(event) {
    this.leadDetails.dateOfBirth = event.target.value;
  }

  saveLeadDetails() {
    if (this.allFieldsAreValid) {
      this.isLoading = true;

      let params = {
        leadId: this._lead.Id,
        gender: this.leadDetails.gender,
        state: this.leadDetails.state,
        dateOfBirth: this.leadDetails.dateOfBirth
      };

      saveLeadRequiredInformation(params).then((result) => {
        this.isLoading = false;
        this.notifyLeadUpdated(result);
      });
    }
  }

  notifyLeadUpdated(lead) {
    this.dispatchEvent(
      new CustomEvent("leadupdated", {
        detail: {
          lead: lead
        }
      })
    );
  }

  notifyValidState(valid) {
    this.dispatchEvent(
      new CustomEvent("validatelead", {
        detail: {
          valid: valid
        }
      })
    );
  }

  renderedCallback() {
    if (this.genderIsValid && this.stateIsValid && this.dateOfBirthIsValid) {
      this.notifyValidState(true);
    }
  }
}