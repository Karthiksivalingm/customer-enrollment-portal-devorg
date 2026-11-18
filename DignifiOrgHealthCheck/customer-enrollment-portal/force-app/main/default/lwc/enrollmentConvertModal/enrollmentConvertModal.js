import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getConversionPreview from "@salesforce/apex/EnrollmentConversionController.getConversionPreview";
import convertEnrollment from "@salesforce/apex/EnrollmentConversionController.convertEnrollment";
import getCountryOptions from "@salesforce/apex/EnrollmentSubmissionController.getCountryOptions";

import { ROLE_OPTIONS } from "c/enrollmentUtils";

const PERSON_FIELDS = ["firstName", "lastName", "email", "phone", "role"];

function errorText(error) {
  if (error && error.body && error.body.message) {
    return error.body.message;
  }
  return "Something went wrong. Please try again.";
}

/**
 * Convert Enrollment screen. Shows the Account to create and every submitted
 * person (editable), then converts in one server transaction. Closes with
 * { accountId } on success.
 */
export default class EnrollmentConvertModal extends LightningModal {
  @api recordId;

  isLoading = true;
  isConverting = false;
  canConvert = false;
  errorMessage;
  warnings = [];
  account = {};
  people = [];
  countries = [];
  accountMode = "new";
  existingAccountId = null;

  /** Role is optional, so "--None--" lets the user clear it. */
  roleOptions = [
    { label: "--None--", value: "" },
    ...ROLE_OPTIONS.map((option) => ({ ...option }))
  ];

  accountModeOptions = [
    { label: "Create a new Account", value: "new" },
    { label: "Use an existing Account", value: "existing" }
  ];

  get isExistingAccount() {
    return this.accountMode === "existing";
  }

  /** The new-Account fields are hidden (not removed) when an existing Account is used. */
  get accountFieldsClass() {
    return this.isExistingAccount
      ? "slds-hide"
      : "slds-grid slds-wrap slds-gutters_small slds-m-bottom_large";
  }

  handleAccountModeChange(event) {
    this.accountMode = event.detail.value;
    if (!this.isExistingAccount) {
      this.existingAccountId = null;
    }
  }

  handleExistingAccountChange(event) {
    this.existingAccountId = event.detail.recordId || null;
  }

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const [preview, countries] = await Promise.all([
        getConversionPreview({ leadId: this.recordId }),
        getCountryOptions()
      ]);
      this.countries = countries || [];
      this.canConvert = Boolean(preview.canConvert);
      this.errorMessage = preview.canConvert ? undefined : preview.message;
      this.warnings = preview.warnings || [];
      this.account = { ...(preview.account || {}) };
      this.people = (preview.people || []).map((person, index) => ({
        id: person.id,
        position: `Contact ${index + 1}`,
        firstName: person.firstName || "",
        lastName: person.lastName || "",
        email: person.email || "",
        phone: person.phone || "",
        role: person.role || "",
        // Older Leads: free-text job title submitted before Role existed (kept on the Contact if no Role is selected).
        legacyJobTitle: person.role ? "" : person.jobTitle || ""
      }));
    } catch (error) {
      this.errorMessage = errorText(error);
      this.canConvert = false;
    } finally {
      this.isLoading = false;
    }
  }

  get showForm() {
    return !this.isLoading && this.canConvert;
  }

  get hasWarnings() {
    return this.showForm && this.warnings.length > 0;
  }

  get isBusy() {
    return this.isLoading || this.isConverting;
  }

  get convertLabel() {
    return this.isConverting ? "Converting…" : "Convert";
  }

  get countryOptions() {
    return this.countries.map((country) => ({
      label: country.label,
      value: country.value
    }));
  }

  get stateOptions() {
    const country = this.countries.find(
      (option) => option.value === this.account.countryCode
    );
    return country && country.states
      ? country.states.map((state) => ({
          label: state.label,
          value: state.value
        }))
      : [];
  }

  get noStates() {
    return this.stateOptions.length === 0;
  }

  get statePlaceholder() {
    return this.noStates
      ? "Not applicable for this country"
      : "Select a state or province";
  }

  handleAccountChange(event) {
    const field = event.target.dataset.field;
    this.account = { ...this.account, [field]: event.detail.value };
    if (field === "countryCode") {
      this.account = { ...this.account, stateCode: null };
    }
  }

  handlePersonChange(event) {
    const { person: personId, field } = event.target.dataset;
    const value = event.detail.value;
    this.people = this.people.map((person) => {
      if (person.id !== personId) {
        return person;
      }
      return { ...person, [field]: value };
    });
  }

  handleCancel() {
    this.close();
  }

  async handleConvert() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input, lightning-combobox")
    ];
    const allValid = inputs.reduce(
      (valid, input) => input.reportValidity() && valid,
      true
    );
    if (!allValid) {
      this.errorMessage = "Please correct the highlighted fields.";
      return;
    }
    if (this.isExistingAccount && !this.existingAccountId) {
      this.errorMessage = "Please select an existing Account.";
      return;
    }

    this.isConverting = true;
    this.errorMessage = undefined;
    this.disableClose = true;
    try {
      const request = {
        account: this.account,
        existingAccountId: this.isExistingAccount
          ? this.existingAccountId
          : null,
        people: this.people.map((person) => {
          const values = { id: person.id };
          PERSON_FIELDS.forEach((field) => {
            values[field] = person[field];
          });
          return values;
        })
      };
      const result = await convertEnrollment({
        leadId: this.recordId,
        requestJson: JSON.stringify(request)
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: result.alreadyConverted
            ? "Already converted"
            : "Enrollment converted",
          message: result.message,
          variant: result.alreadyConverted ? "info" : "success"
        })
      );
      this.disableClose = false;
      this.close({ accountId: result.accountId });
    } catch (error) {
      this.errorMessage = errorText(error);
      this.disableClose = false;
    } finally {
      this.isConverting = false;
    }
  }
}
