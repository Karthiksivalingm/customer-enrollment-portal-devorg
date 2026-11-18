import { LightningElement, api } from "lwc";

/**
 * Progress indicator for the enrollment steps.
 * steps: [{ value, label }], currentStep: the value of the active step.
 */
export default class EnrollmentStepIndicator extends LightningElement {
  @api steps = [];
  @api currentStep;

  get currentIndex() {
    return this.steps.findIndex((step) => step.value === this.currentStep);
  }

  get summary() {
    const index = this.currentIndex;
    if (index < 0) {
      return "";
    }
    return `Step ${index + 1} of ${this.steps.length}: ${this.steps[index].label}`;
  }

  get items() {
    const current = this.currentIndex;
    return this.steps.map((step, index) => {
      let status = "upcoming";
      if (index < current) {
        status = "complete";
      } else if (index === current) {
        status = "current";
      }
      return {
        key: step.value,
        label: step.label,
        number: index + 1,
        isComplete: status === "complete",
        ariaCurrent: status === "current" ? "step" : undefined,
        className: `ep-steps__item ep-steps__item--${status}`,
        statusText:
          status === "complete"
            ? ", completed"
            : status === "current"
              ? ", current step"
              : ", not started"
      };
    });
  }
}
