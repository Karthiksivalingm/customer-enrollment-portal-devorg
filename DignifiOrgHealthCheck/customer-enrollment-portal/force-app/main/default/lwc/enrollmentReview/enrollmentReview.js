import { LightningElement, api } from "lwc";
import {
  COMPANY_FIELDS,
  PERSON_FIELDS,
  normalizeValue,
  roleLabel
} from "c/enrollmentUtils";

const NOT_PROVIDED = "Not provided";
const NAME_FIELDS = new Set(["firstName", "lastName"]);

function toRow(field, record, displayValue) {
  const value =
    displayValue === undefined
      ? normalizeValue(record[field.name])
      : displayValue;
  return {
    key: field.name,
    label: field.label,
    value: value || NOT_PROVIDED,
    valueClass: value
      ? "ep-review__value"
      : "ep-review__value ep-review__value--empty",
    rowClass: field.fullWidth
      ? "ep-review__row ep-review__row--full"
      : "ep-review__row"
  };
}

/**
 * Section C: read-only summary of everything entered.
 * Fires "edit" with { step: 'company' | 'people' } so the parent can go back.
 */
export default class EnrollmentReview extends LightningElement {
  @api company = {};
  @api people = [];
  /** Used to show country and state names instead of ISO codes. */
  @api countryOptions = [];

  get companyRows() {
    const country = (this.countryOptions || []).find(
      (option) => option.value === this.company.countryCode
    );
    const state =
      country && country.states
        ? country.states.find(
            (option) => option.value === this.company.stateCode
          )
        : null;
    return COMPANY_FIELDS.map((field) => {
      if (field.name === "countryCode") {
        return toRow(field, this.company, country ? country.label : "");
      }
      if (field.name === "stateCode") {
        return toRow(field, this.company, state ? state.label : "");
      }
      return toRow(field, this.company);
    });
  }

  get peopleHeading() {
    const count = this.people.length;
    return `Contacts (${count})`;
  }

  get personRows() {
    return this.people.map((person, index) => ({
      key: person.key,
      number: index + 1,
      fullName: [
        normalizeValue(person.firstName),
        normalizeValue(person.lastName)
      ]
        .filter(Boolean)
        .join(" "),
      details: PERSON_FIELDS.filter(
        (field) => !NAME_FIELDS.has(field.name)
      ).map((field) => {
        // Picklist fields (Role) show the option label, not the stored value.
        if (field.options) {
          return toRow(field, person, roleLabel(person[field.name]));
        }
        return toRow(field, person);
      })
    }));
  }

  handleEditCompany() {
    this.dispatchEvent(
      new CustomEvent("edit", { detail: { step: "company" } })
    );
  }

  handleEditPeople() {
    this.dispatchEvent(new CustomEvent("edit", { detail: { step: "people" } }));
  }
}
