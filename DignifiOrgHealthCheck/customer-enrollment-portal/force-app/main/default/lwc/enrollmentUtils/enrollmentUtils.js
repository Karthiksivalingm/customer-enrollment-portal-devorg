/**
 * Shared field definitions, validation rules, and helpers for the enrollment form.
 *
 * This is a "service" module: it has no HTML template. Other components import
 * from it with:  import { COMPANY_FIELDS } from 'c/enrollmentUtils';
 *
 * Max lengths match the standard Salesforce Lead/Contact field lengths, so the
 * values the UI accepts will fit the records the backend creates later.
 * The backend will repeat this validation on the server; client-side checks
 * only give the customer fast feedback and are never trusted on their own.
 */

export const MAX_PEOPLE = 25;
/** The form always shows at least this many contacts. */
export const MIN_PEOPLE = 2;

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PHONE_PATTERN = /^\+?[0-9\s().-]{7,25}$/;
const MIN_PHONE_DIGITS = 7;
const WEBSITE_PATTERN =
  /^(https?:\/\/)?([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}(:\d{1,5})?([/?#]\S*)?$/i;

export const COMPANY_FIELDS = Object.freeze([
  {
    name: "companyName",
    label: "Company name",
    type: "text",
    required: true,
    maxLength: 255,
    autocomplete: "organization"
  },
  {
    name: "website",
    label: "Website",
    type: "text",
    inputMode: "url",
    maxLength: 255,
    autocomplete: "url",
    validator: "website"
  },
  {
    name: "companyEmail",
    label: "Company email",
    type: "email",
    inputMode: "email",
    required: true,
    maxLength: 80,
    autocomplete: "email",
    validator: "email"
  },
  {
    name: "companyPhone",
    label: "Company phone",
    type: "tel",
    inputMode: "tel",
    maxLength: 40,
    autocomplete: "tel",
    validator: "phone"
  },
  {
    name: "street",
    label: "Address",
    type: "text",
    maxLength: 255,
    autocomplete: "address-line1",
    fullWidth: true
  },
  {
    name: "city",
    label: "City",
    type: "text",
    maxLength: 40,
    autocomplete: "address-level2"
  },
  // Country and State use the org's State and Country Picklists (ISO codes),
  // because Salesforce rejects free-text values when those picklists are enabled.
  {
    name: "countryCode",
    label: "Country",
    type: "select",
    required: true,
    placeholder: "Select a country",
    autocomplete: "country"
  },
  {
    name: "stateCode",
    label: "State / Province",
    type: "select",
    placeholder: "Select a state or province",
    emptyPlaceholder: "Not applicable for this country",
    autocomplete: "address-level1"
  },
  {
    name: "postalCode",
    label: "Postal code",
    type: "text",
    maxLength: 20,
    autocomplete: "postal-code"
  }
]);

/**
 * Contact Role options. "value" is what is stored in the Lead JSON; it must match
 * EnrollmentPerson.ROLE_LABELS in Apex (the server rejects any other value).
 * "AP" keeps the existing picklist API value; it is displayed as "Account Payable".
 */
export const ROLE_OPTIONS = Object.freeze([
  { value: "Primary Contact", label: "Primary Contact" },
  { value: "AP", label: "Account Payable" },
  { value: "Allocator", label: "Allocator" },
  { value: "Broker / Agency Rep", label: "Broker / Agency Rep" },
  { value: "Buyer", label: "Buyer" },
  { value: "EDI Contact", label: "EDI Contact" },
  { value: "Logistics / Traffic", label: "Logistics / Traffic" }
]);

// Person fields use autocomplete "off" so the browser does not fill the
// visitor's own details into every person card.
export const PERSON_FIELDS = Object.freeze([
  {
    name: "firstName",
    label: "First name",
    type: "text",
    required: true,
    maxLength: 40,
    autocomplete: "off"
  },
  {
    name: "lastName",
    label: "Last name",
    type: "text",
    required: true,
    maxLength: 80,
    autocomplete: "off"
  },
  {
    name: "email",
    label: "Email",
    type: "email",
    inputMode: "email",
    required: true,
    maxLength: 80,
    autocomplete: "off",
    validator: "email"
  },
  {
    name: "phone",
    label: "Phone",
    type: "tel",
    inputMode: "tel",
    maxLength: 40,
    autocomplete: "off",
    validator: "phone"
  },
  {
    name: "role",
    label: "Role",
    type: "select",
    required: true,
    placeholder: "Select Role",
    options: ROLE_OPTIONS,
    autocomplete: "off",
    fullWidth: true
  }
]);

/** Returns the display label for a stored Role value (empty when not set or unknown). */
export function roleLabel(value) {
  const match = ROLE_OPTIONS.find((option) => option.value === value);
  return match ? match.label : "";
}

export const DUPLICATE_EMAIL_MESSAGE =
  "This email is already entered for another contact.";

let personSequence = 0;

/** Returns an empty company object with one property per company field. */
export function createCompany() {
  return COMPANY_FIELDS.reduce((company, field) => {
    company[field.name] = "";
    return company;
  }, {});
}

/**
 * Returns an empty person. The "key" is a client-side identifier used only to
 * track the card in the UI (for:each key, remove); it is never sent as data.
 */
export function createPerson() {
  personSequence += 1;
  const person = PERSON_FIELDS.reduce(
    (result, field) => {
      result[field.name] = "";
      return result;
    },
    { key: `person-${personSequence}` }
  );
  return person;
}

export function normalizeValue(value) {
  return typeof value === "string" ? value.trim() : "";
}

function countDigits(value) {
  return (value.match(/\d/g) || []).length;
}

/** Returns an error message for one field, or an empty string when valid. */
export function validateField(field, rawValue) {
  const value = normalizeValue(rawValue);

  if (!value) {
    return field.required ? `${field.label} is required.` : "";
  }
  if (
    field.options &&
    !field.options.some((option) => option.value === value)
  ) {
    return `Select a valid ${field.label}.`;
  }
  if (field.maxLength && value.length > field.maxLength) {
    return `${field.label} must be ${field.maxLength} characters or fewer.`;
  }
  if (field.validator === "email" && !EMAIL_PATTERN.test(value)) {
    return "Enter a valid email address, for example name@company.com.";
  }
  if (
    field.validator === "phone" &&
    (!PHONE_PATTERN.test(value) || countDigits(value) < MIN_PHONE_DIGITS)
  ) {
    return "Enter a valid phone number using digits, spaces, +, -, or ( ).";
  }
  if (field.validator === "website" && !WEBSITE_PATTERN.test(value)) {
    return "Enter a valid website address, for example www.company.com.";
  }
  return "";
}

/** Validates every field of a record. Returns { fieldName: message } for errors only. */
export function validateRecord(fields, record) {
  const errors = {};
  fields.forEach((field) => {
    const message = validateField(field, record ? record[field.name] : "");
    if (message) {
      errors[field.name] = message;
    }
  });
  return errors;
}

/** Returns the name of the first field (in display order) that has an error. */
export function firstErrorField(fields, errors) {
  const match = fields.find((field) => errors[field.name]);
  return match ? match.name : null;
}

/** Returns the keys of every person whose email is also used by another person. */
export function findDuplicateEmailKeys(people) {
  const firstKeyByEmail = new Map();
  const duplicateKeys = new Set();

  people.forEach((person) => {
    const email = normalizeValue(person.email).toLowerCase();
    if (!email) {
      return;
    }
    if (firstKeyByEmail.has(email)) {
      duplicateKeys.add(person.key);
      duplicateKeys.add(firstKeyByEmail.get(email));
    } else {
      firstKeyByEmail.set(email, person.key);
    }
  });
  return duplicateKeys;
}

/** Accepts only absolute http(s) URLs or site-relative paths for links set in Builder. */
export function toSafeUrl(value) {
  const url = normalizeValue(value);
  if (/^https?:\/\//i.test(url)) {
    return url;
  }
  if (url.startsWith("/") && !url.startsWith("//")) {
    return url;
  }
  return null;
}
