import { LightningElement, api } from "lwc";
import { PERSON_FIELDS, normalizeValue } from "c/enrollmentUtils";

/**
 * Section B: one card per person.
 * Every person card is identical - "Person 1", "Person 2" is only a position
 * number for the customer's convenience, not a primary/secondary hierarchy.
 *
 * Events (all include the person's key so the parent knows which card changed):
 *   personchange { key, name, value }
 *   personblur   { key, name, value }
 *   remove       { key }
 */
export default class EnrollmentPersonCard extends LightningElement {
  @api person = {};
  @api personNumber = 1;
  @api errors = {};
  @api canRemove = false;

  get title() {
    return `Contact ${this.personNumber}`;
  }

  get displayName() {
    return [
      normalizeValue(this.person.firstName),
      normalizeValue(this.person.lastName)
    ]
      .filter(Boolean)
      .join(" ");
  }

  get removeLabel() {
    const name = this.displayName;
    return name
      ? `Remove contact ${this.personNumber}, ${name}`
      : `Remove contact ${this.personNumber}`;
  }

  get fields() {
    return PERSON_FIELDS.map((config) => ({
      key: config.name,
      config,
      value: this.person[config.name] || "",
      error: this.errors[config.name] || "",
      options: config.options || [],
      gridClass: config.fullWidth ? "ep-span-full" : ""
    }));
  }

  handleValueChange(event) {
    this.dispatchEvent(
      new CustomEvent("personchange", {
        detail: { key: this.person.key, ...event.detail }
      })
    );
  }

  handleFieldBlur(event) {
    this.dispatchEvent(
      new CustomEvent("personblur", {
        detail: { key: this.person.key, ...event.detail }
      })
    );
  }

  handleRemove() {
    this.dispatchEvent(
      new CustomEvent("remove", { detail: { key: this.person.key } })
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

  @api
  focusFirstField() {
    this.focusField(PERSON_FIELDS[0].name);
  }
}
