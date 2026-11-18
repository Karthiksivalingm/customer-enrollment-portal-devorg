import { createElement } from "lwc";
import EnrollmentForm from "c/enrollmentForm";
import submitEnrollment from "@salesforce/apex/EnrollmentSubmissionController.submitEnrollment";
import getCountryOptions from "@salesforce/apex/EnrollmentSubmissionController.getCountryOptions";

jest.mock(
  "@salesforce/apex/EnrollmentSubmissionController.submitEnrollment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/EnrollmentSubmissionController.getCountryOptions",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

const COUNTRIES = [
  {
    value: "US",
    label: "United States",
    states: [{ value: "CA", label: "California" }]
  },
  { value: "SG", label: "Singapore", states: [] }
];

// Renders are asynchronous in LWC; wait a few microtasks for nested children.
const flushPromises = async () => {
  for (let i = 0; i < 5; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    await Promise.resolve();
  }
};

const VALID_COMPANY = {
  companyName: "Test Company",
  companyEmail: "company@example.org",
  countryCode: "US"
};

function createForm() {
  const element = createElement("c-enrollment-form", { is: EnrollmentForm });
  document.body.appendChild(element);
  getCountryOptions.emit(COUNTRIES);
  return element;
}

function query(element, selector) {
  return element.shadowRoot.querySelector(selector);
}

function personCards(element) {
  return [...element.shadowRoot.querySelectorAll("c-enrollment-person-card")];
}

function typeInto(fieldHost, value) {
  const select = fieldHost.shadowRoot.querySelector("select");
  if (select) {
    select.value = value;
    select.dispatchEvent(new CustomEvent("change"));
    return;
  }
  const input = fieldHost.shadowRoot.querySelector("input");
  input.value = value;
  input.dispatchEvent(new CustomEvent("input"));
}

function companyField(element, name) {
  return query(
    element,
    "c-enrollment-company-section"
  ).shadowRoot.querySelector(`c-enrollment-field[data-name="${name}"]`);
}

function personField(card, name) {
  return card.shadowRoot.querySelector(
    `c-enrollment-field[data-name="${name}"]`
  );
}

async function fillCompany(element, values = VALID_COMPANY) {
  for (const [name, value] of Object.entries(values)) {
    typeInto(companyField(element, name), value);
    // eslint-disable-next-line no-await-in-loop
    await flushPromises();
  }
}

async function fillPerson(card, values) {
  // Role is required; tests that do not choose one get "Buyer".
  for (const [name, value] of Object.entries({ role: "Buyer", ...values })) {
    typeInto(personField(card, name), value);
    // eslint-disable-next-line no-await-in-loop
    await flushPromises();
  }
}

async function click(element, selector) {
  query(element, selector).click();
  await flushPromises();
}

describe("c-enrollment-form", () => {
  beforeAll(() => {
    // jsdom (the test browser) does not implement scrollIntoView; real browsers do.
    Element.prototype.scrollIntoView = jest.fn();
  });

  beforeEach(() => {
    submitEnrollment.mockResolvedValue({ success: true, errors: [] });
  });

  afterEach(() => {
    jest.clearAllMocks();
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("starts on the company step with all nine company fields", async () => {
    const element = createForm();
    await flushPromises();

    expect(query(element, '[data-id="step-heading"]').textContent).toBe(
      "Company information"
    );
    const fields = query(
      element,
      "c-enrollment-company-section"
    ).shadowRoot.querySelectorAll("c-enrollment-field");
    expect(fields).toHaveLength(9);
    expect(query(element, '[data-id="back"]')).toBeNull();
  });

  it("blocks Continue and shows errors when required company fields are empty", async () => {
    const element = createForm();
    await flushPromises();

    await click(element, '[data-id="next"]');

    expect(query(element, '[data-id="error-summary"]').textContent).toContain(
      "3 highlighted fields"
    );
    expect(query(element, '[data-id="step-heading"]').textContent).toBe(
      "Company information"
    );
    const nameInput = companyField(
      element,
      "companyName"
    ).shadowRoot.querySelector("input");
    expect(nameInput.getAttribute("aria-invalid")).toBe("true");
  });

  it("starts with two contacts and only allows removal above two", async () => {
    const element = createForm();
    await flushPromises();
    await fillCompany(element);
    await click(element, '[data-id="next"]');

    expect(query(element, '[data-id="step-heading"]').textContent).toBe(
      "Contacts"
    );
    const removeButton = (card) =>
      card.shadowRoot.querySelector('[data-id="remove-person"]');
    const initial = personCards(element);
    expect(initial).toHaveLength(2);
    expect(initial[0].shadowRoot.textContent).toContain("Contact 1");
    expect(initial[1].shadowRoot.textContent).toContain("Contact 2");
    expect(initial.map(removeButton)).toEqual([null, null]);
    expect(query(element, '[data-id="add-person"]').textContent).toContain(
      "Add contact"
    );

    await click(element, '[data-id="add-person"]');
    expect(personCards(element)).toHaveLength(3);
    expect(query(element, ".ep-people__count").textContent).toContain(
      "3 contacts added"
    );

    removeButton(personCards(element)[1]).click();
    await flushPromises();

    const remaining = personCards(element);
    expect(remaining).toHaveLength(2);
    expect(remaining[1].personNumber).toBe(2);
    expect(remaining.map(removeButton)).toEqual([null, null]);
  });

  it("flags duplicate emails across contacts", async () => {
    const element = createForm();
    await flushPromises();
    await fillCompany(element);
    await click(element, '[data-id="next"]');

    const [first, second] = personCards(element);
    await fillPerson(first, {
      firstName: "A",
      lastName: "One",
      email: "same@example.org"
    });
    await fillPerson(second, {
      firstName: "B",
      lastName: "Two",
      email: "SAME@example.org"
    });
    await click(element, '[data-id="next"]');

    expect(query(element, '[data-id="step-heading"]').textContent).toBe(
      "Contacts"
    );
    expect(query(element, '[data-id="error-summary"]').textContent).toContain(
      "2 highlighted fields"
    );
    expect(personCards(element)[0].errors.email).toContain("already entered");
  });

  it("reviews, edits, and submits to the confirmation screen", async () => {
    const element = createForm();
    await flushPromises();
    await fillCompany(element);
    await click(element, '[data-id="next"]');

    const [first, second] = personCards(element);
    await fillPerson(first, {
      firstName: "A",
      lastName: "One",
      email: "a@example.org"
    });
    await fillPerson(second, {
      firstName: "B",
      lastName: "Two",
      email: "b@example.org"
    });
    await click(element, '[data-id="next"]');

    const review = query(element, "c-enrollment-review");
    expect(review).not.toBeNull();
    expect(
      review.shadowRoot.querySelectorAll('[data-id="review-person"]')
    ).toHaveLength(2);

    // Edit goes back to the company step and keeps the entered data.
    review.shadowRoot.querySelector('[data-id="edit-company"]').click();
    await flushPromises();
    expect(query(element, '[data-id="step-heading"]').textContent).toBe(
      "Company information"
    );
    const nameInput = companyField(
      element,
      "companyName"
    ).shadowRoot.querySelector("input");
    expect(nameInput.value).toBe("Test Company");

    await click(element, '[data-id="next"]');
    await click(element, '[data-id="next"]');
    await click(element, '[data-id="submit"]');

    // One Apex call with exactly the allowed values and a submission key.
    expect(submitEnrollment).toHaveBeenCalledTimes(1);
    const sent = JSON.parse(submitEnrollment.mock.calls[0][0].requestJson);
    expect(sent.submissionKey).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
    );
    expect(sent.company.companyName).toBe("Test Company");
    expect(sent.company.countryCode).toBe("US");
    expect(sent.people).toHaveLength(2);
    expect(sent.people[0]).not.toHaveProperty("key");
    expect(sent.people[1].email).toBe("b@example.org");

    const confirmation = query(element, "c-enrollment-confirmation");
    expect(confirmation).not.toBeNull();
    expect(confirmation.shadowRoot.textContent).toContain(
      "company@example.org"
    );
    expect(confirmation.shadowRoot.textContent).toContain("2 contacts");
    expect(
      confirmation.shadowRoot.querySelector('[data-id="start-new"]')
    ).toBeNull();
  });

  it("shows server validation messages and stays on review when submission fails", async () => {
    submitEnrollment.mockResolvedValue({
      success: false,
      message: "Please correct the following and submit again.",
      errors: ["Country is not valid."]
    });
    const element = createForm();
    await flushPromises();
    await fillCompany(element);
    await click(element, '[data-id="next"]');
    await fillPerson(personCards(element)[0], {
      firstName: "A",
      lastName: "One",
      email: "a@example.org"
    });
    await fillPerson(personCards(element)[1], {
      firstName: "B",
      lastName: "Two",
      email: "b@example.org"
    });
    await click(element, '[data-id="next"]');
    await click(element, '[data-id="submit"]');

    expect(query(element, "c-enrollment-confirmation")).toBeNull();
    const summary = query(element, '[data-id="error-summary"]').textContent;
    expect(summary).toContain("Please correct the following");
    expect(summary).toContain("Country is not valid.");
  });

  it("clears the state when the country changes", async () => {
    const element = createForm();
    await flushPromises();
    typeInto(companyField(element, "countryCode"), "US");
    await flushPromises();
    typeInto(companyField(element, "stateCode"), "CA");
    await flushPromises();
    typeInto(companyField(element, "countryCode"), "SG");
    await flushPromises();

    const stateSelect = companyField(
      element,
      "stateCode"
    ).shadowRoot.querySelector("select");
    expect(stateSelect.disabled).toBe(true);
    expect(stateSelect.value).toBe("");
  });
});
