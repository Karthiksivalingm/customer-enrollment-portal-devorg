/*
 * Web-to-Lead enrollment form (second enrollment channel).
 *
 * Mirrors the Experience Cloud form (enrollmentForm + enrollmentUtils): same
 * steps, labels, validation rules, Role options and 2-25 contacts. On Submit it
 * fills a standard Salesforce Web-to-Lead form and posts it:
 *   - company fields       -> standard Lead fields (company, email, phone, ...)
 *   - submission key UUID  -> Enrollment_Submission_Key__c (custom field id)
 *   - contacts             -> Enrollment_W2L_Payload__c as {"schemaVersion":1,"people":[...]}
 * Salesforce (EnrollmentWebToLeadService) validates everything again; the checks
 * here only give the visitor fast feedback and are never trusted.
 */
(function () {
  "use strict";

  // ---------- Configuration (EnrollmentDev) ----------

  /**
   * Thank-you page next to this form. Salesforce Web-to-Lead returns an empty page
   * (no redirect) when retURL uses the host "localhost" (verified), so local
   * testing uses 127.0.0.1 instead. A real website domain is used as is.
   */
  function thankYouUrl() {
    const url = new URL("thank-you.html", window.location.href);
    if (url.hostname === "localhost") {
      url.hostname = "127.0.0.1";
    }
    return url.href;
  }

  const CONFIG = Object.freeze({
    endpoint:
      "https://webto.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8",
    orgId: "00Dfj00000LNKYD",
    // Custom field ids (15 characters) from the EnrollmentDev org.
    fieldIds: Object.freeze({
      submissionKey: "00Nfj00005epNc9", // Lead.Enrollment_Submission_Key__c
      payload: "00Nfj00005fnVN4" // Lead.Enrollment_W2L_Payload__c
    }),
    returnUrl: thankYouUrl()
  });

  // ---------- Rules shared with the Experience Cloud form (enrollmentUtils) ----------
  const MAX_PEOPLE = 25;
  const MIN_PEOPLE = 2;
  const MIN_FILL_MILLIS = 3000;
  const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  const PHONE_PATTERN = /^\+?[0-9\s().-]{7,25}$/;
  const MIN_PHONE_DIGITS = 7;
  const WEBSITE_PATTERN =
    /^(https?:\/\/)?([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}(:\d{1,5})?([/?#]\S*)?$/i;
  const DUPLICATE_EMAIL_MESSAGE =
    "This email is already entered for another contact.";

  const ROLE_OPTIONS = Object.freeze([
    { value: "Primary Contact", label: "Primary Contact" },
    { value: "AP", label: "Account Payable" },
    { value: "Allocator", label: "Allocator" },
    { value: "Broker / Agency Rep", label: "Broker / Agency Rep" },
    { value: "Buyer", label: "Buyer" },
    { value: "EDI Contact", label: "EDI Contact" },
    { value: "Logistics / Traffic", label: "Logistics / Traffic" }
  ]);

  const COMPANY_FIELDS = Object.freeze([
    { name: "companyName", label: "Company name", type: "text", required: true, maxLength: 255, autocomplete: "organization" },
    { name: "website", label: "Website", type: "text", inputMode: "url", maxLength: 255, autocomplete: "url", validator: "website" },
    { name: "companyEmail", label: "Company email", type: "email", inputMode: "email", required: true, maxLength: 80, autocomplete: "email", validator: "email" },
    { name: "companyPhone", label: "Company phone", type: "tel", inputMode: "tel", maxLength: 40, autocomplete: "tel", validator: "phone" },
    { name: "street", label: "Address", type: "text", maxLength: 255, autocomplete: "address-line1", fullWidth: true },
    { name: "city", label: "City", type: "text", maxLength: 40, autocomplete: "address-level2" },
    { name: "countryCode", label: "Country", type: "select", required: true, placeholder: "Select a country", autocomplete: "country" },
    { name: "stateCode", label: "State / Province", type: "select", placeholder: "Select a state or province", emptyPlaceholder: "Not applicable for this country", autocomplete: "address-level1" },
    { name: "postalCode", label: "Postal code", type: "text", maxLength: 20, autocomplete: "postal-code" }
  ]);

  const PERSON_FIELDS = Object.freeze([
    { name: "firstName", label: "First name", type: "text", required: true, maxLength: 40, autocomplete: "off" },
    { name: "lastName", label: "Last name", type: "text", required: true, maxLength: 80, autocomplete: "off" },
    { name: "email", label: "Email", type: "email", inputMode: "email", required: true, maxLength: 80, autocomplete: "off", validator: "email" },
    { name: "phone", label: "Phone", type: "tel", inputMode: "tel", maxLength: 40, autocomplete: "off", validator: "phone" },
    { name: "role", label: "Role", type: "select", required: true, placeholder: "Select Role", options: ROLE_OPTIONS, autocomplete: "off", fullWidth: true }
  ]);

  const STEPS = Object.freeze([
    { value: "company", label: "Company" },
    { value: "people", label: "Contacts" },
    { value: "review", label: "Review" }
  ]);

  const STEP_CONTENT = Object.freeze({
    company: {
      title: "Company information",
      description:
        "Tell us about the company you are enrolling. Fields marked with an asterisk (*) are required.",
      nextLabel: "Next"
    },
    people: {
      title: "Contacts",
      description:
        "Add each contact who should be included in this enrollment. Everyone you add is treated equally. You can add or remove contacts at any time before you submit.",
      nextLabel: "Review"
    },
    review: {
      title: "Review",
      description:
        "Check that everything is correct. Use Edit to make changes before you submit.",
      nextLabel: "Submit enrollment"
    }
  });

  const COUNTRIES = Array.isArray(window.EP_COUNTRIES) ? window.EP_COUNTRIES : [];

  // ---------- Helpers ----------

  function normalizeValue(value) {
    return typeof value === "string" ? value.trim() : "";
  }

  function countDigits(value) {
    return (value.match(/\d/g) || []).length;
  }

  /** Same messages as enrollmentUtils.validateField. */
  function validateField(field, rawValue) {
    const value = normalizeValue(rawValue);
    if (!value) {
      return field.required ? `${field.label} is required.` : "";
    }
    if (field.options && !field.options.some((option) => option.value === value)) {
      return `Select a valid ${field.label}.`;
    }
    if (field.maxLength && value.length > field.maxLength) {
      return `${field.label} must be ${field.maxLength} characters or fewer.`;
    }
    if (field.validator === "email" && !EMAIL_PATTERN.test(value)) {
      return "Enter a valid email address, for example name@company.com.";
    }
    if (field.validator === "phone" && (!PHONE_PATTERN.test(value) || countDigits(value) < MIN_PHONE_DIGITS)) {
      return "Enter a valid phone number using digits, spaces, +, -, or ( ).";
    }
    if (field.validator === "website" && !WEBSITE_PATTERN.test(value)) {
      return "Enter a valid website address, for example www.company.com.";
    }
    return "";
  }

  /** Random UUID (v4) for this submission; reused if the visitor submits again. */
  function generateSubmissionKey() {
    if (window.crypto && typeof window.crypto.randomUUID === "function") {
      return window.crypto.randomUUID();
    }
    const bytes = new Uint8Array(16);
    window.crypto.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
  }

  let personSequence = 0;
  function createPerson() {
    personSequence += 1;
    const person = { key: `person-${personSequence}` };
    PERSON_FIELDS.forEach((field) => {
      person[field.name] = "";
    });
    return person;
  }

  function createCompany() {
    const company = {};
    COMPANY_FIELDS.forEach((field) => {
      company[field.name] = "";
    });
    return company;
  }

  function el(tag, attrs, children) {
    const node = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([name, value]) => {
      if (value === undefined || value === null || value === false) {
        return;
      }
      if (name === "className") {
        node.className = value;
      } else if (name === "text") {
        node.textContent = value;
      } else if (name.startsWith("on")) {
        node.addEventListener(name.slice(2), value);
      } else {
        node.setAttribute(name, value === true ? "" : value);
      }
    });
    (children || []).forEach((child) => {
      if (child) {
        node.appendChild(child);
      }
    });
    return node;
  }

  function errorIcon() {
    const ns = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(ns, "svg");
    svg.setAttribute("class", "ep-field__error-icon");
    svg.setAttribute("viewBox", "0 0 20 20");
    svg.setAttribute("aria-hidden", "true");
    svg.innerHTML =
      '<circle cx="10" cy="10" r="9" fill="currentColor"></circle>' +
      '<rect x="9" y="5" width="2" height="6.5" rx="1" fill="#ffffff"></rect>' +
      '<circle cx="10" cy="14.5" r="1.25" fill="#ffffff"></circle>';
    return svg;
  }

  // ---------- State ----------

  const state = {
    step: "company",
    company: createCompany(),
    people: [createPerson(), createPerson()],
    submissionKey: generateSubmissionKey(),
    startedAt: Date.now(),
    submitting: false
  };

  /** Rendered field controls, keyed "company:name" or "<personKey>:name". */
  const controls = new Map();

  const $ = (id) => document.getElementById(id);

  function announce(message) {
    $("announcement").textContent = "";
    window.setTimeout(() => {
      $("announcement").textContent = message;
    }, 50);
  }

  // ---------- Fields ----------

  function countryOptions() {
    return COUNTRIES.map((c) => ({ value: c.value, label: c.label }));
  }

  function stateOptions(countryCode) {
    const country = COUNTRIES.find((c) => c.value === countryCode);
    return country ? country.states : [];
  }

  function fillSelect(select, field, options, value) {
    select.textContent = "";
    const empty = options.length === 0;
    select.appendChild(
      el("option", {
        value: "",
        text: empty && field.emptyPlaceholder ? field.emptyPlaceholder : field.placeholder || "Select"
      })
    );
    options.forEach((option) => {
      const node = el("option", { value: option.value, text: option.label });
      if (option.value === value) {
        node.selected = true;
      }
      select.appendChild(node);
    });
    select.disabled = empty;
  }

  /**
   * Builds one labelled field (same markup as c-enrollment-field) and registers
   * it so errors can be shown and focus moved later.
   */
  function buildField(scope, field, value, options, onChange) {
    const id = `${scope}-${field.name}`;
    const errorId = `${id}-error`;
    const label = el("label", { className: "ep-field__label", for: id, text: field.label });
    label.appendChild(
      field.required
        ? el("span", { className: "ep-field__required", "aria-hidden": "true", text: "*" })
        : el("span", { className: "ep-field__optional", text: "(optional)" })
    );

    let control;
    if (field.type === "select") {
      control = el("select", {
        id,
        className: "ep-field__input ep-field__select",
        name: field.name,
        autocomplete: field.autocomplete,
        required: field.required
      });
      fillSelect(control, field, options || field.options || [], value);
      control.addEventListener("change", () => onChange(control.value, false));
    } else {
      control = el("input", {
        id,
        className: "ep-field__input",
        name: field.name,
        type: field.type,
        maxlength: field.maxLength,
        autocomplete: field.autocomplete,
        inputmode: field.inputMode,
        required: field.required
      });
      control.value = value || "";
      control.addEventListener("input", () => onChange(control.value, false));
    }
    control.addEventListener("blur", () => onChange(control.value, true));

    const error = el("p", { id: errorId, className: "ep-field__error ep-hidden" });
    const wrapper = el("div", { className: field.fullWidth ? "ep-field ep-span-full" : "ep-field" }, [
      label,
      control,
      error
    ]);

    const entry = {
      field,
      control,
      showError(message) {
        error.textContent = "";
        if (message) {
          error.appendChild(errorIcon());
          error.appendChild(el("span", { text: message }));
          error.classList.remove("ep-hidden");
          control.classList.add("ep-field__input--invalid");
          control.setAttribute("aria-invalid", "true");
          control.setAttribute("aria-describedby", errorId);
        } else {
          error.classList.add("ep-hidden");
          control.classList.remove("ep-field__input--invalid");
          control.setAttribute("aria-invalid", "false");
          control.removeAttribute("aria-describedby");
        }
        entry.error = message || "";
      },
      error: ""
    };
    controls.set(`${scope}:${field.name}`, entry);
    return wrapper;
  }

  /** Live feedback like the Experience form: format on blur, clear errors as the user types. */
  function fieldFeedback(entry, value, isBlur, extraCheck) {
    const message = validateField(entry.field, value) || (extraCheck ? extraCheck() : "");
    if (isBlur) {
      entry.showError(normalizeValue(value) ? message : entry.error ? message : "");
    } else if (entry.error) {
      entry.showError(message);
    }
  }

  // ---------- Step: company ----------

  function renderCompany() {
    const container = $("step-company");
    container.textContent = "";
    COMPANY_FIELDS.forEach((field) => {
      let options;
      if (field.name === "countryCode") {
        options = countryOptions();
      } else if (field.name === "stateCode") {
        options = stateOptions(state.company.countryCode);
      }
      container.appendChild(
        buildField("company", field, state.company[field.name], options, (value, isBlur) => {
          state.company[field.name] = value;
          const entry = controls.get(`company:${field.name}`);
          if (field.name === "countryCode") {
            state.company.stateCode = "";
            const stateEntry = controls.get("company:stateCode");
            fillSelect(stateEntry.control, stateEntry.field, stateOptions(value), "");
            stateEntry.showError("");
          }
          fieldFeedback(entry, value, isBlur);
        })
      );
    });
  }

  function validateCompany() {
    let first = null;
    COMPANY_FIELDS.forEach((field) => {
      const entry = controls.get(`company:${field.name}`);
      const message = validateField(field, state.company[field.name]);
      entry.showError(message);
      if (message && !first) {
        first = entry;
      }
    });
    return first;
  }

  // ---------- Step: contacts ----------

  function duplicateEmailKeys() {
    const firstKeyByEmail = new Map();
    const duplicates = new Set();
    state.people.forEach((person) => {
      const email = normalizeValue(person.email).toLowerCase();
      if (!email) {
        return;
      }
      if (firstKeyByEmail.has(email)) {
        duplicates.add(person.key);
        duplicates.add(firstKeyByEmail.get(email));
      } else {
        firstKeyByEmail.set(email, person.key);
      }
    });
    return duplicates;
  }

  function displayName(person) {
    return [normalizeValue(person.firstName), normalizeValue(person.lastName)].filter(Boolean).join(" ");
  }

  function renderPeople() {
    const container = $("people");
    container.textContent = "";
    [...controls.keys()].filter((k) => !k.startsWith("company:")).forEach((k) => controls.delete(k));

    state.people.forEach((person, index) => {
      const number = index + 1;
      const subtitle = el("p", { className: "ep-person__subtitle", text: displayName(person) });
      const heading = el("div", { className: "ep-person__heading" }, [
        el("h3", { className: "ep-person__title", text: `Contact ${number}` }),
        subtitle
      ]);
      const header = el("div", { className: "ep-person__header" }, [
        el("span", { className: "ep-person__badge", "aria-hidden": "true", text: String(number) }),
        heading
      ]);
      if (state.people.length > MIN_PEOPLE) {
        const name = displayName(person);
        header.appendChild(
          el(
            "button",
            {
              type: "button",
              className: "ep-button ep-button--danger-ghost ep-button--small",
              "aria-label": name ? `Remove contact ${number}, ${name}` : `Remove contact ${number}`,
              onclick: () => removePerson(person.key)
            },
            [el("span", { text: "Remove" })]
          )
        );
      }

      const grid = el("div", { className: "ep-grid" });
      PERSON_FIELDS.forEach((field) => {
        grid.appendChild(
          buildField(person.key, field, person[field.name], null, (value, isBlur) => {
            person[field.name] = value;
            if (field.name === "firstName" || field.name === "lastName") {
              subtitle.textContent = displayName(person);
            }
            const entry = controls.get(`${person.key}:${field.name}`);
            fieldFeedback(entry, value, isBlur, () =>
              field.name === "email" && duplicateEmailKeys().has(person.key) ? DUPLICATE_EMAIL_MESSAGE : ""
            );
            if (field.name === "email") {
              // Clear a "duplicate email" error on other cards once the clash is gone.
              const duplicates = duplicateEmailKeys();
              state.people.forEach((other) => {
                const otherEntry = controls.get(`${other.key}:email`);
                if (other !== person && otherEntry && otherEntry.error === DUPLICATE_EMAIL_MESSAGE && !duplicates.has(other.key)) {
                  otherEntry.showError(validateField(otherEntry.field, other.email));
                }
              });
            }
          })
        );
      });

      container.appendChild(
        el("article", { className: "ep-person", "data-key": person.key, "aria-label": `Contact ${number}` }, [header, grid])
      );
    });

    const count = state.people.length;
    $("add-person").disabled = count >= MAX_PEOPLE;
    const added = `${count} ${count === 1 ? "contact" : "contacts"} added`;
    $("people-count").textContent =
      count >= MAX_PEOPLE
        ? `${added}. You have reached the maximum of ${MAX_PEOPLE} contacts.`
        : `${added}. You can add up to ${MAX_PEOPLE} contacts.`;
  }

  function addPerson() {
    if (state.people.length >= MAX_PEOPLE) {
      return;
    }
    const person = createPerson();
    state.people.push(person);
    renderPeople();
    announce(`Contact ${state.people.length} added.`);
    const entry = controls.get(`${person.key}:firstName`);
    if (entry) {
      entry.control.focus();
    }
  }

  function removePerson(key) {
    if (state.people.length <= MIN_PEOPLE) {
      return;
    }
    const number = state.people.findIndex((p) => p.key === key) + 1;
    state.people = state.people.filter((p) => p.key !== key);
    renderPeople();
    announce(`Contact ${number} removed.`);
  }

  function validatePeople() {
    let first = null;
    const duplicates = duplicateEmailKeys();
    state.people.forEach((person) => {
      PERSON_FIELDS.forEach((field) => {
        const entry = controls.get(`${person.key}:${field.name}`);
        let message = validateField(field, person[field.name]);
        if (!message && field.name === "email" && duplicates.has(person.key)) {
          message = DUPLICATE_EMAIL_MESSAGE;
        }
        entry.showError(message);
        if (message && !first) {
          first = entry;
        }
      });
    });
    return first;
  }

  // ---------- Step: review ----------

  function reviewRow(label, value, full) {
    return el("div", { className: full ? "ep-review__row ep-review__row--full" : "ep-review__row" }, [
      el("dt", { className: "ep-review__term", text: label }),
      el("dd", {
        className: value ? "ep-review__value" : "ep-review__value ep-review__value--empty",
        text: value || "Not provided"
      })
    ]);
  }

  function reviewBlock(title, editLabel, editStep, content) {
    return el("section", { className: "ep-review__block" }, [
      el("div", { className: "ep-review__block-header" }, [
        el("h3", { className: "ep-review__block-title", text: title }),
        el("button", {
          type: "button",
          className: "ep-button ep-button--ghost ep-button--small",
          "aria-label": editLabel,
          text: "Edit",
          onclick: () => goToStep(editStep)
        })
      ]),
      content
    ]);
  }

  function renderReview() {
    const container = $("step-review");
    container.textContent = "";
    const country = COUNTRIES.find((c) => c.value === state.company.countryCode);
    const stateOption = country ? country.states.find((s) => s.value === state.company.stateCode) : null;

    const companyList = el("dl", { className: "ep-review__list" });
    COMPANY_FIELDS.forEach((field) => {
      let value = normalizeValue(state.company[field.name]);
      if (field.name === "countryCode") {
        value = country ? country.label : "";
      } else if (field.name === "stateCode") {
        value = stateOption ? stateOption.label : "";
      }
      companyList.appendChild(reviewRow(field.label, value, field.fullWidth));
    });
    container.appendChild(reviewBlock("Company information", "Edit company information", "company", companyList));

    const peopleList = el("ul", { className: "ep-review__people" });
    state.people.forEach((person, index) => {
      const details = el("dl", { className: "ep-review__person-details" });
      PERSON_FIELDS.filter((f) => f.name !== "firstName" && f.name !== "lastName").forEach((field) => {
        let value = normalizeValue(person[field.name]);
        if (field.options) {
          const option = field.options.find((o) => o.value === value);
          value = option ? option.label : "";
        }
        details.appendChild(reviewRow(field.label, value, false));
      });
      peopleList.appendChild(
        el("li", { className: "ep-review__person" }, [
          el("p", { className: "ep-review__person-name" }, [
            el("span", { className: "ep-review__person-badge", "aria-hidden": "true", text: String(index + 1) }),
            el("span", { text: displayName(person) })
          ]),
          details
        ])
      );
    });
    container.appendChild(
      reviewBlock(`Contacts (${state.people.length})`, "Edit contacts", "people", peopleList)
    );
  }

  // ---------- Steps and navigation ----------

  function renderSteps() {
    const current = STEPS.findIndex((s) => s.value === state.step);
    const list = $("steps");
    list.textContent = "";
    STEPS.forEach((step, index) => {
      const complete = index < current;
      const isCurrent = index === current;
      const marker = el("span", { className: "ep-steps__marker", "aria-hidden": "true" });
      if (complete) {
        marker.innerHTML =
          '<svg class="ep-steps__check" viewBox="0 0 20 20" focusable="false"><path fill="currentColor" d="M8.1 14.6 3.8 10.3l1.4-1.4 2.9 2.9 6.7-6.7 1.4 1.4-8.1 8.1Z"></path></svg>';
      } else {
        marker.textContent = String(index + 1);
      }
      list.appendChild(
        el(
          "li",
          {
            className: `ep-steps__item${complete ? " ep-steps__item--complete" : ""}${isCurrent ? " ep-steps__item--current" : ""}`,
            "aria-current": isCurrent ? "step" : null
          },
          [
            marker,
            el("span", { className: "ep-steps__label", text: step.label }),
            el("span", { className: "ep-sr-only", text: complete ? "Completed" : isCurrent ? "Current step" : "Not started" })
          ]
        )
      );
    });
    $("steps-summary").textContent = `Step ${current + 1} of ${STEPS.length}: ${STEPS[current].label}`;
  }

  function showErrorSummary(message) {
    $("error-summary-text").textContent = message || "";
    $("error-summary").classList.toggle("ep-hidden", !message);
  }

  function render() {
    const content = STEP_CONTENT[state.step];
    renderSteps();
    $("step-title").textContent = content.title;
    $("step-description").textContent = content.description;
    $("step-company").classList.toggle("ep-hidden", state.step !== "company");
    $("step-people").classList.toggle("ep-hidden", state.step !== "people");
    $("step-review").classList.toggle("ep-hidden", state.step !== "review");
    if (state.step === "review") {
      renderReview();
    }
    $("back").classList.toggle("ep-hidden", state.step === "company");
    $("back").disabled = state.submitting;
    $("next").disabled = state.submitting;
    $("next").textContent = state.submitting ? "Submitting…" : content.nextLabel;
  }

  function goToStep(step) {
    state.step = step;
    showErrorSummary("");
    render();
    const embed = window.EPEmbed;
    if (embed && embed.embedded) {
      // In an iframe the host page owns scrolling (see embed.js / embed-demo.html).
      $("step-title").focus({ preventScroll: true });
      embed.notify("step", { step });
    } else {
      $("step-title").focus();
      $("step-title").scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }

  function failValidation(firstInvalid) {
    showErrorSummary("Please correct the highlighted fields.");
    firstInvalid.control.focus();
  }

  function handleNext() {
    if (state.step === "company") {
      const firstInvalid = validateCompany();
      if (firstInvalid) {
        failValidation(firstInvalid);
        return;
      }
      goToStep("people");
    } else if (state.step === "people") {
      const firstInvalid = validatePeople();
      if (firstInvalid) {
        failValidation(firstInvalid);
        return;
      }
      goToStep("review");
    } else {
      submit();
    }
  }

  function handleBack() {
    const index = STEPS.findIndex((s) => s.value === state.step);
    if (index > 0) {
      goToStep(STEPS[index - 1].value);
    }
  }

  // ---------- Submit (standard Web-to-Lead post) ----------

  /** The contacts in the existing schema v1 format. Salesforce assigns the ids. */
  function buildPayload() {
    return JSON.stringify({
      schemaVersion: 1,
      people: state.people.map((person) => {
        const values = {};
        PERSON_FIELDS.forEach((field) => {
          values[field.name] = normalizeValue(person[field.name]);
        });
        return values;
      })
    });
  }

  function submit() {
    if (state.submitting) {
      return;
    }
    // Re-check everything before posting (fields keep their state between steps).
    if (validateCompany()) {
      goToStep("company");
      failValidation(validateCompany());
      return;
    }
    if (validatePeople()) {
      goToStep("people");
      failValidation(validatePeople());
      return;
    }

    // Likely bot: show the thank-you page without posting anything.
    if ($("fax-number").value || Date.now() - state.startedAt < MIN_FILL_MILLIS) {
      window.location.href = CONFIG.returnUrl;
      return;
    }

    const company = state.company;
    const companyName = normalizeValue(company.companyName);
    const values = {
      oid: CONFIG.orgId,
      retURL: CONFIG.returnUrl,
      company: companyName,
      last_name: companyName.slice(0, 80), // Salesforce sets this again server-side
      email: normalizeValue(company.companyEmail),
      phone: normalizeValue(company.companyPhone),
      URL: normalizeValue(company.website),
      street: normalizeValue(company.street),
      city: normalizeValue(company.city),
      zip: normalizeValue(company.postalCode),
      country_code: normalizeValue(company.countryCode),
      state_code: normalizeValue(company.stateCode),
      lead_source: "Web",
      [CONFIG.fieldIds.submissionKey]: state.submissionKey,
      [CONFIG.fieldIds.payload]: buildPayload()
    };

    const form = $("w2l-form");
    form.textContent = "";
    form.action = CONFIG.endpoint;
    Object.entries(values).forEach(([name, value]) => {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = name;
      input.value = value;
      form.appendChild(input);
    });

    state.submitting = true;
    render();
    form.submit();
  }

  // ---------- Start ----------

  $("next").addEventListener("click", handleNext);
  $("back").addEventListener("click", handleBack);
  $("add-person").addEventListener("click", addPerson);
  if (COUNTRIES.length === 0) {
    showErrorSummary("The country list could not be loaded. Please refresh the page.");
  }
  renderCompany();
  renderPeople();
  render();
})();
