import { LightningElement, api, track } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import saveAdditionalLevelTermInformation from "@salesforce/apex/ODALeadController.saveAdditionalLevelTermInformation";
import oda from "@salesforce/resourceUrl/oda";
import { heightValues } from "c/odaConstants";

export default class OdaLevelTermUserInfo extends LightningElement {
  //#region Private fields
  _lead;
  _coverageBandsCombobox;
  _heightCombobox;
  _weightInput;

  _coverageOptions;
  _riskClassDetails;
  _buildRiskClass;
  _overrideRiskClass;
  _defaultOverrideOption = { value: "default", label: "No different risk class selected" };
  //#endregion

  //#region Track
  @track coverageBand = "";
  @track coverageBandValid = true;

  @track height = "";
  @track heightValid = true;

  @track weight = "";
  @track weightValid = true;

  @track
  selectedOverrideOption = "default";
  @track loading = false;

  //#endregion

  //#region Api

  @api
  get overrideRiskClass() {
    return this._overrideRiskClass;
  }

  set overrideRiskClass(value) {
    this._overrideRiskClass = value;
  }

  @api
  get buildRiskClass() {
    return this._buildRiskClass;
  }

  set buildRiskClass(value) {
    this._buildRiskClass = value;
  }

  @api
  get lead() {
    return this._lead;
  }

  set lead(value) {
    this._lead = value;
    this.height = this._lead.Height_new__c;
    this.weight = this._lead.Weight_new__c;
  }

  @api
  get riskClassDetails() {
    return this._riskClassDetails;
  }

  set riskClassDetails(value) {
    if (!value) {
      return;
    }
    this._riskClassDetails = value;
  }

  @api
  get coverageOptions() {
    return this._coverageOptions;
  }

  set coverageOptions(value) {
    this._coverageOptions = value;
  }

  //#endregion

  //#region Getters
  get isCalculateNewRateDisabled() {
    let disabled =
      this.riskClassDetails == undefined ||
      this.selectedOverrideOption === "default" ||
      (this.buildRiskClass.code === this.selectedOverrideOption &&
        this.overrideRiskClass == undefined);
    return disabled;
  }

  get riskClassQuotedText() {
    let option;

    if (this.buildRiskClass != undefined && this.overrideRiskClass == undefined) {
      option = this.buildRiskClassText;
    }

    if (this.overrideRiskClass != undefined) {
      option = this.overrideRiskClass.text;
    }

    return "The Risk Class quoted in table below is: " + option;
  }

  get buildRiskClassText() {
    if (this._buildRiskClass) {
      return this._buildRiskClass.text;
    }
    return "Build Class not yet determined";
  }

  get anyInvalidField() {
    return !this.coverageBandValid || !this.heightValid || !this.weightValid;
  }

  get coverageBandOptions() {
    return Object.keys(this.coverageOptions).map((key) => {
      return { value: key, label: key };
    });
  }

  get heightOptions() {
    return heightValues;
  }

  get riskClassOptions() {
    let options = [this._defaultOverrideOption];
    if (this.riskClassDetails != undefined) {
      options = options.concat(
        this.riskClassDetails["overrideOptions"].map((option) => {
          return { value: option["code"], label: option["text"] };
        })
      );
    }

    return options;
  }
  //#endregion

  //#region Fields change events
  onHeightChange(event) {
    this.height = event.detail.value;
    this.validateHeight();
  }

  onWeightChange(event) {
    this.weight = event.target.value;
    this.validateWeight();
  }

  onCoverageBandChange(event) {
    this.coverageBand = event.detail.value;
    this.validateCoverageBand();
  }

  onRiskClassChange(event) {
    this.selectedOverrideOption = event.detail.value;
  }

  //#endregion

  //#region Buttons clicks
  onCalculateRates() {
    if (!this.fieldsAreValid()) {
      return;
    }

    this.selectedOverrideOption = this._defaultOverrideOption.value;

    if (this.height != this._lead.Height_new__c || this.weight != this._lead.Weight_new__c) {
      this.saveAdditionalLeadDetails(this.calculateRates);
    } else {
      this.calculateRates();
    }
  }

  onCalculateNewRates() {
    this.calculateRates();
  }

  //#endregion

  saveAdditionalLeadDetails(callback) {
    this.loading = true;
    let params = {
      leadId: this._lead.Id,
      height: this.height,
      weight: this.weight
    };

    saveAdditionalLevelTermInformation(params)
      .then((result) => {
        this.notifyLeadUpdates(result);

        callback.bind(this)();
      })
      .finally(() => {
        this.loading = false;
      });
  }

  calculateRates() {
    let riskClass =
      this.selectedOverrideOption == this._defaultOverrideOption.value
        ? null
        : this.selectedOverrideOption;

    this.dispatchEvent(
      new CustomEvent("fetchleveltermrates", {
        detail: {
          lead: this._lead,
          amounts: this.coverageOptions[this.coverageBand],
          riskClass: riskClass
        },
        bubbles: true
      })
    );
  }

  notifyLeadUpdates(lead) {
    this.dispatchEvent(
      new CustomEvent("leadupdated", {
        detail: {
          lead: lead
        },
        bubbles: true,
        composed: true
      })
    );
  }

  //#region Fields validation
  fieldsAreValid() {
    this.validateHeight();
    this.validateCoverageBand();
    this.validateWeight();

    return this.heightValid && this.coverageBandValid && this.weightValid;
  }

  validateHeight() {
    this.heightValid = this.height != undefined && this.height != "";
    this.updateFieldClasses(this._heightCombobox, this.heightValid);
  }

  validateCoverageBand() {
    this.coverageBandValid = this.coverageBand != undefined && this.coverageBand != "";
    this.updateFieldClasses(this._coverageBandsCombobox, this.coverageBandValid);
  }

  validateWeight() {
    this.weightValid = this._weightInput.checkValidity();
    this.updateFieldClasses(this._weightInput, this.weightValid);
  }

  //#endregion

  //#region Set custom style rules
  renderedCallback() {
    loadStyle(this, oda);

    this._heightCombobox = this.template.querySelector(".height-combobox");
    this._coverageBandsCombobox = this.template.querySelector(".coverage-bands-combobox");
    this._weightInput = this.template.querySelector(".weight-field");
  }

  updateFieldClasses(field, validField) {
    let classes = field.getAttribute("class");

    if (validField) {
      classes = classes.replace("slds-has-error", "");
    } else {
      if (!classes.includes("slds-has-error")) {
        classes += " slds-has-error";
      }
    }
    field.setAttribute("class", classes);
  }
  //#endregion
}