import { LightningElement, api, wire } from "lwc";
import submitEnrollment from "@salesforce/apex/EnrollmentSubmissionController.submitEnrollment";
import getCountryOptions from "@salesforce/apex/EnrollmentSubmissionController.getCountryOptions";
import {
  COMPANY_FIELDS,
  PERSON_FIELDS,
  MAX_PEOPLE,
  MIN_PEOPLE,
  DUPLICATE_EMAIL_MESSAGE,
  createCompany,
  createPerson,
  validateField,
  validateRecord,
  firstErrorField,
  findDuplicateEmailKeys,
  normalizeValue
} from "c/enrollmentUtils";

const STEP_COMPANY = "company";
const STEP_PEOPLE = "people";
const STEP_REVIEW = "review";
const STEP_SUCCESS = "success";

const STEPS = Object.freeze([
  { value: STEP_COMPANY, label: "Company" },
  { value: STEP_PEOPLE, label: "Contacts" },
  { value: STEP_REVIEW, label: "Review" }
]);

const STEP_CONTENT = Object.freeze({
  [STEP_COMPANY]: {
    title: "Company information",
    description:
      "Tell us about the company you are enrolling. Fields marked with an asterisk (*) are required.",
    nextLabel: "Next"
  },
  [STEP_PEOPLE]: {
    title: "Contacts",
    description:
      "Add each contact who should be included in this enrollment. Everyone you add is treated equally. You can add or remove contacts at any time before you submit.",
    nextLabel: "Review"
  },
  [STEP_REVIEW]: {
    title: "Review",
    description:
      "Check that everything is correct. Use Edit to make changes before you submit.",
    nextLabel: ""
  }
});

const EMPTY_ERRORS = Object.freeze({});
const GENERIC_SUBMIT_ERROR =
  "We could not submit your enrollment. Please check your connection and try again.";

/**
 * Random UUID (v4) identifying this submission. It is sent with every attempt,
 * so a retry or double click can never create a second Lead.
 */
function generateSubmissionKey() {
  const cryptoApi = typeof window !== "undefined" ? window.crypto : undefined;
  if (cryptoApi && typeof cryptoApi.randomUUID === "function") {
    return cryptoApi.randomUUID();
  }
  const bytes = new Uint8Array(16);
  if (cryptoApi && typeof cryptoApi.getRandomValues === "function") {
    cryptoApi.getRandomValues(bytes);
  } else {
    for (let i = 0; i < bytes.length; i += 1) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join(
    ""
  );
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/**
 * The enrollment form "controller" component.
 *
 * Design pattern: this component is the single owner of the form data
 * (company, people) and of the validation errors. Child components only
 * display what they are given and send events back up. This keeps one source
 * of truth, so the Review step always shows exactly what will be submitted.
 */
export default class EnrollmentForm extends LightningElement {
  step = STEP_COMPANY;
  steps = STEPS;
  company = createCompany();
  people = [createPerson(), createPerson()];
  companyErrors = {};
  peopleErrors = {};
  errorSummary = "";
  announcement = "";
  isSubmitting = false;
  submittedEmail = "";
  submittedPeopleCount = 0;
  errorDetails = [];
  countryOptions = [];
  countryLoadError = false;

  // Submission protection (not shown in the template).
  submissionKey = generateSubmissionKey();
  formStartedAt = Date.now();
  honeypotValue = "";

  // Focus request to apply after the next render. Not used in the template,
  // so changing it does not cause a re-render.
  pendingFocus = null;

  /** Country and State / Province options from the org's State and Country Picklists. */
  @wire(getCountryOptions)
  wiredCountries({ data, error }) {
    if (data) {
      this.countryOptions = data;
      this.countryLoadError = false;
    } else if (error) {
      this.countryOptions = [];
      this.countryLoadError = true;
    }
  }

  get hasErrorDetails() {
    return this.errorDetails.length > 0;
  }

  // ---------- Public API ----------

  /** Moves focus to the current step heading (used by the page's navigation). */
  @api
  focusForm() {
    const heading = this.template.querySelector('[data-id="step-heading"]');
    if (heading) {
      // The page handles scrolling, so do not let focus() jump the page.
      heading.focus({ preventScroll: true });
    }
  }

  // ---------- Step state ----------

  get isCompanyStep() {
    return this.step === STEP_COMPANY;
  }

  get isPeopleStep() {
    return this.step === STEP_PEOPLE;
  }

  get isReviewStep() {
    return this.step === STEP_REVIEW;
  }

  get isSuccessStep() {
    return this.step === STEP_SUCCESS;
  }

  get showBack() {
    return this.isPeopleStep || this.isReviewStep;
  }

  get stepTitle() {
    return STEP_CONTENT[this.step] ? STEP_CONTENT[this.step].title : "";
  }

  get stepDescription() {
    return STEP_CONTENT[this.step] ? STEP_CONTENT[this.step].description : "";
  }

  get nextLabel() {
    return STEP_CONTENT[this.step] ? STEP_CONTENT[this.step].nextLabel : "";
  }

  get submitLabel() {
    return this.isSubmitting ? "Submitting…" : "Submit";
  }

  // ---------- People state ----------

  get peopleView() {
    return this.people.map((person, index) => ({
      key: person.key,
      person,
      number: index + 1,
      errors: this.peopleErrors[person.key] || EMPTY_ERRORS
    }));
  }

  get canRemovePeople() {
    return this.people.length > MIN_PEOPLE;
  }

  get isAddDisabled() {
    return this.people.length >= MAX_PEOPLE;
  }

  get peopleCountText() {
    const count = this.people.length;
    const added = count === 1 ? "1 contact added" : `${count} contacts added`;
    if (count >= MAX_PEOPLE) {
      return `${added}. You have reached the maximum of ${MAX_PEOPLE} contacts.`;
    }
    return `${added}. You can add up to ${MAX_PEOPLE} contacts.`;
  }

  // ---------- Lifecycle ----------

  renderedCallback() {
    if (!this.pendingFocus) {
      return;
    }
    const request = this.pendingFocus;
    this.pendingFocus = null;
    this.applyFocus(request);
  }

  applyFocus(request) {
    if (request.type === "heading") {
      const heading = this.template.querySelector('[data-id="step-heading"]');
      if (heading) {
        heading.focus({ preventScroll: true });
        heading.scrollIntoView({ block: "center", behavior: "smooth" });
      }
    } else if (request.type === "companyField") {
      const section = this.template.querySelector(
        "c-enrollment-company-section"
      );
      if (section) {
        section.focusField(request.name);
      }
    } else if (
      request.type === "personField" ||
      request.type === "personFirst"
    ) {
      const card = this.template.querySelector(
        `c-enrollment-person-card[data-key="${request.key}"]`
      );
      if (card && request.type === "personField") {
        card.focusField(request.name);
      } else if (card) {
        card.focusFirstField();
      }
    } else if (request.type === "addButton") {
      const button = this.template.querySelector('[data-id="add-person"]');
      if (button) {
        button.focus();
      }
    }
  }

  goToStep(step) {
    this.step = step;
    this.errorSummary = "";
    this.errorDetails = [];
    this.pendingFocus = { type: "heading" };
  }

  showErrorSummary(count) {
    this.errorSummary =
      count === 1
        ? "Please correct the highlighted field before continuing."
        : `Please correct the ${count} highlighted fields before continuing.`;
  }

  // ---------- Company handlers ----------

  handleCompanyChange(event) {
    const { name, value } = event.detail;
    this.company = { ...this.company, [name]: value };
    // States belong to a country, so a new country clears the state.
    if (name === "countryCode" && this.company.stateCode) {
      this.company = { ...this.company, stateCode: "" };
    }
    // Once a field shows an error, re-check it as the customer types so the
    // message disappears as soon as the value is fixed.
    if (this.companyErrors[name]) {
      this.setCompanyError(name, value);
    }
  }

  handleCompanyBlur(event) {
    const { name, value } = event.detail;
    // Only check format on blur; "required" messages appear on Continue,
    // so customers are not interrupted while tabbing through the form.
    if (normalizeValue(value) || this.companyErrors[name]) {
      this.setCompanyError(name, value);
    }
  }

  setCompanyError(name, value) {
    const field = COMPANY_FIELDS.find((item) => item.name === name);
    const message = field ? validateField(field, value) : "";
    const errors = { ...this.companyErrors };
    if (message) {
      errors[name] = message;
    } else {
      delete errors[name];
    }
    this.companyErrors = errors;
  }

  validateCompany() {
    this.companyErrors = validateRecord(COMPANY_FIELDS, this.company);
    const count = Object.keys(this.companyErrors).length;
    if (count) {
      this.showErrorSummary(count);
      this.pendingFocus = {
        type: "companyField",
        name: firstErrorField(COMPANY_FIELDS, this.companyErrors)
      };
    }
    return count === 0;
  }

  // ---------- People handlers ----------

  handlePersonChange(event) {
    const { key, name, value } = event.detail;
    this.people = this.people.map((person) => {
      if (person.key !== key) {
        return person;
      }
      return { ...person, [name]: value };
    });
    const personErrors = this.peopleErrors[key];
    if (personErrors && personErrors[name]) {
      this.setPersonError(key, name, value);
    }
  }

  handlePersonBlur(event) {
    const { key, name, value } = event.detail;
    const personErrors = this.peopleErrors[key];
    if (normalizeValue(value) || (personErrors && personErrors[name])) {
      this.setPersonError(key, name, value);
    }
  }

  setPersonError(key, name, value) {
    const field = PERSON_FIELDS.find((item) => item.name === name);
    const message = field ? validateField(field, value) : "";
    const personErrors = { ...(this.peopleErrors[key] || {}) };
    if (message) {
      personErrors[name] = message;
    } else {
      delete personErrors[name];
    }
    this.peopleErrors = { ...this.peopleErrors, [key]: personErrors };
  }

  handleAddPerson() {
    if (this.people.length >= MAX_PEOPLE) {
      return;
    }
    const person = createPerson();
    this.people = [...this.people, person];
    this.announcement = `Contact ${this.people.length} added.`;
    this.pendingFocus = { type: "personFirst", key: person.key };
  }

  handleRemovePerson(event) {
    const { key } = event.detail;
    if (this.people.length <= MIN_PEOPLE) {
      return;
    }
    const removedNumber =
      this.people.findIndex((person) => person.key === key) + 1;
    this.people = this.people.filter((person) => person.key !== key);

    const errors = { ...this.peopleErrors };
    delete errors[key];
    this.peopleErrors = errors;

    const remaining = this.people.length;
    this.announcement = `Contact ${removedNumber} removed. ${remaining} ${remaining === 1 ? "contact" : "contacts"} remaining.`;
    // The removed card's button no longer exists, so move focus somewhere predictable.
    this.pendingFocus = { type: "addButton" };
  }

  validatePeople() {
    const duplicateKeys = findDuplicateEmailKeys(this.people);
    const allErrors = {};
    let count = 0;
    let firstInvalid = null;

    this.people.forEach((person) => {
      const errors = validateRecord(PERSON_FIELDS, person);
      if (!errors.email && duplicateKeys.has(person.key)) {
        errors.email = DUPLICATE_EMAIL_MESSAGE;
      }
      const errorCount = Object.keys(errors).length;
      if (errorCount) {
        allErrors[person.key] = errors;
        count += errorCount;
        if (!firstInvalid) {
          firstInvalid = {
            key: person.key,
            name: firstErrorField(PERSON_FIELDS, errors)
          };
        }
      }
    });

    this.peopleErrors = allErrors;
    if (count) {
      this.showErrorSummary(count);
      this.pendingFocus = { type: "personField", ...firstInvalid };
    }
    return count === 0;
  }

  // ---------- Navigation handlers ----------

  handleNext() {
    if (this.isCompanyStep && this.validateCompany()) {
      this.goToStep(STEP_PEOPLE);
    } else if (this.isPeopleStep && this.validatePeople()) {
      this.goToStep(STEP_REVIEW);
    }
  }

  handleBack() {
    if (this.isReviewStep) {
      this.goToStep(STEP_PEOPLE);
    } else if (this.isPeopleStep) {
      this.goToStep(STEP_COMPANY);
    }
  }

  handleEdit(event) {
    const { step } = event.detail;
    if (step === STEP_COMPANY || step === STEP_PEOPLE) {
      this.goToStep(step);
    }
  }

  async handleSubmit() {
    if (this.isSubmitting) {
      return;
    }
    // Re-check everything one last time before submitting.
    this.step = STEP_COMPANY;
    if (!this.validateCompany()) {
      return;
    }
    this.step = STEP_PEOPLE;
    if (!this.validatePeople()) {
      return;
    }
    this.step = STEP_REVIEW;

    this.isSubmitting = true;
    this.errorSummary = "";
    this.errorDetails = [];
    try {
      const result = await submitEnrollment({
        requestJson: JSON.stringify(this.buildRequest())
      });
      if (result && result.success) {
        this.submittedEmail = normalizeValue(this.company.companyEmail);
        this.submittedPeopleCount = this.people.length;
        this.step = STEP_SUCCESS;
      } else {
        this.errorSummary = (result && result.message) || GENERIC_SUBMIT_ERROR;
        this.errorDetails = (result && result.errors) || [];
      }
    } catch {
      this.errorSummary = GENERIC_SUBMIT_ERROR;
    } finally {
      this.isSubmitting = false;
    }
  }

  /** Only the allowed values are sent; the client-side "key" of each person is dropped. */
  buildRequest() {
    const company = {};
    COMPANY_FIELDS.forEach((field) => {
      company[field.name] = normalizeValue(this.company[field.name]);
    });
    return {
      submissionKey: this.submissionKey,
      elapsedMs: Date.now() - this.formStartedAt,
      faxNumber: this.honeypotValue,
      company,
      people: this.people.map((person) => {
        const values = {};
        PERSON_FIELDS.forEach((field) => {
          values[field.name] = normalizeValue(person[field.name]);
        });
        return values;
      })
    };
  }

  handleHoneypot(event) {
    this.honeypotValue = event.target.value;
  }
}
