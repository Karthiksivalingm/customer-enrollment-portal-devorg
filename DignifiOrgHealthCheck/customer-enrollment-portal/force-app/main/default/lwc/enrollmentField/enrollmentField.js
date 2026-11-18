import { LightningElement, api } from "lwc";

/**
 * Reusable, accessible form field: label + native input + help text + error.
 *
 * It is "presentational": it does not store or validate data itself.
 * The parent passes in the field definition, the current value, and any error,
 * and listens for the events this component fires:
 *   - valuechange  { name, value }  on every keystroke
 *   - fieldblur    { name, value }  when the input loses focus
 *
 * The label, input, help text, and error all live inside this component's
 * template, so the label "for" and "aria-describedby" ids resolve correctly
 * (ids cannot point across shadow DOM boundaries).
 */
export default class EnrollmentField extends LightningElement {
  @api field = {};
  @api value = "";
  @api error = "";
  /** For type "select": [{ value, label }]. */
  @api options = [];

  get hasError() {
    return Boolean(this.error);
  }

  get isSelect() {
    return this.field.type === "select";
  }

  get controlId() {
    return this.isSelect ? "field-select" : "field-input";
  }

  get inputType() {
    return this.field.type || "text";
  }

  get inputClass() {
    return this.hasError
      ? "ep-field__input ep-field__input--invalid"
      : "ep-field__input";
  }

  get selectClass() {
    return `${this.inputClass} ep-field__select`;
  }

  get selectOptions() {
    const current = this.value || "";
    return (this.options || []).map((option) => ({
      value: option.value,
      label: option.label,
      selected: option.value === current
    }));
  }

  get isSelectDisabled() {
    return !this.options || this.options.length === 0;
  }

  get selectPlaceholder() {
    if (this.isSelectDisabled && this.field.emptyPlaceholder) {
      return this.field.emptyPlaceholder;
    }
    return this.field.placeholder || "Select";
  }

  get ariaInvalid() {
    return this.hasError ? "true" : "false";
  }

  get describedBy() {
    const ids = [];
    if (this.field.helpText) {
      ids.push("field-help");
    }
    if (this.hasError) {
      ids.push("field-error");
    }
    return ids.length ? ids.join(" ") : undefined;
  }

  handleInput(event) {
    this.dispatchEvent(
      new CustomEvent("valuechange", {
        detail: { name: this.field.name, value: event.target.value }
      })
    );
  }

  handleBlur(event) {
    this.dispatchEvent(
      new CustomEvent("fieldblur", {
        detail: { name: this.field.name, value: event.target.value }
      })
    );
  }

  /** Lets a parent move keyboard focus to this field (for example, the first invalid field). */
  @api
  focus() {
    const input = this.template.querySelector("input, select");
    if (input) {
      input.focus();
    }
  }
}
