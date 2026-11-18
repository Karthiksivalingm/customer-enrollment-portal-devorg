import { LightningElement, api } from "lwc";
import { COMPANY_FIELDS } from "c/enrollmentUtils";

/**
 * Section A: Company Information.
 * Renders one c-enrollment-field per entry in COMPANY_FIELDS.
 * Data and errors are owned by the parent (c-enrollment-form); this component
 * only displays them and re-fires field events as companychange / companyblur.
 * Country and State / Province options come from the org (countryOptions).
 */
export default class EnrollmentCompanySection extends LightningElement {
  @api company = {};
  @api errors = {};
  /** [{ value, label, states: [{ value, label }] }] */
  @api countryOptions = [];

  get stateOptions() {
    const country = (this.countryOptions || []).find(
      (option) => option.value === this.company.countryCode
    );
    return country && country.states ? country.states : [];
  }

  get fields() {
    return COMPANY_FIELDS.map((config) => {
      let options = [];
      if (config.name === "countryCode") {
        options = this.countryOptions || [];
      } else if (config.name === "stateCode") {
        options = this.stateOptions;
      }
      return {
        key: config.name,
        config,
        options,
        value: this.company[config.name] || "",
        error: this.errors[config.name] || "",
        gridClass: config.fullWidth ? "ep-span-full" : ""
      };
    });
  }

  handleValueChange(event) {
    this.dispatchEvent(
      new CustomEvent("companychange", { detail: event.detail })
    );
  }

  handleFieldBlur(event) {
    this.dispatchEvent(
      new CustomEvent("companyblur", { detail: event.detail })
    );
  }

  @api
  focusField(name) {
    const field = this.template.querySelector(
      `c-enrollment-field[data-name="${name}"]`
    );
    if (field) {
      field.focus();
    }
  }
}
