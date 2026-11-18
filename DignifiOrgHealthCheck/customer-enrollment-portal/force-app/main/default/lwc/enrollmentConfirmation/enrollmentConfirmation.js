import { LightningElement, api } from "lwc";

/**
 * Section D: success message shown after the (currently simulated) submission.
 * Moves keyboard focus to its heading when it appears so screen reader users
 * hear the confirmation.
 */
export default class EnrollmentConfirmation extends LightningElement {
  @api companyEmail = "";
  @api peopleCount = 0;

  hasFocused = false;

  get peopleText() {
    const count = Number(this.peopleCount) || 0;
    return count === 1 ? "1 contact" : `${count} contacts`;
  }

  renderedCallback() {
    if (this.hasFocused) {
      return;
    }
    this.hasFocused = true;
    const heading = this.template.querySelector(
      '[data-id="confirmation-heading"]'
    );
    if (heading) {
      heading.focus();
    }
  }
}
