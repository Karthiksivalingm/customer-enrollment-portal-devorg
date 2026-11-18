import {
  COMPANY_FIELDS,
  PERSON_FIELDS,
  ROLE_OPTIONS,
  roleLabel,
  createCompany,
  createPerson,
  validateField,
  validateRecord,
  firstErrorField,
  findDuplicateEmailKeys,
  toSafeUrl
} from "c/enrollmentUtils";

const field = (fields, name) => fields.find((item) => item.name === name);

describe("enrollmentUtils", () => {
  it("creates an empty company with every company field", () => {
    const company = createCompany();
    expect(Object.keys(company)).toEqual(
      COMPANY_FIELDS.map((item) => item.name)
    );
    expect(Object.values(company).every((value) => value === "")).toBe(true);
  });

  it("creates people with unique keys", () => {
    const first = createPerson();
    const second = createPerson();
    expect(first.key).not.toEqual(second.key);
    expect(first.firstName).toBe("");
  });

  it("requires required fields and ignores empty optional fields", () => {
    expect(validateField(field(COMPANY_FIELDS, "companyName"), "   ")).toBe(
      "Company name is required."
    );
    expect(validateField(field(COMPANY_FIELDS, "website"), "")).toBe("");
  });

  it("validates email, phone, and website formats", () => {
    const email = field(COMPANY_FIELDS, "companyEmail");
    const phone = field(COMPANY_FIELDS, "companyPhone");
    const website = field(COMPANY_FIELDS, "website");

    expect(validateField(email, "not-an-email")).not.toBe("");
    expect(validateField(email, "team@example.org")).toBe("");
    expect(validateField(phone, "12-3")).not.toBe("");
    expect(validateField(phone, "+1 (555) 010-0000")).toBe("");
    expect(validateField(website, "not a site")).not.toBe("");
    expect(validateField(website, "www.example.org")).toBe("");
    expect(validateField(website, "https://example.org/about")).toBe("");
  });

  it("enforces max length", () => {
    const firstName = field(PERSON_FIELDS, "firstName");
    expect(validateField(firstName, "a".repeat(41))).toContain("40 characters");
  });

  it("offers Role as a required picklist with the seven roles", () => {
    const role = field(PERSON_FIELDS, "role");
    expect(role.type).toBe("select");
    expect(role.placeholder).toBe("Select Role");
    expect(ROLE_OPTIONS.map((option) => option.label)).toEqual([
      "Primary Contact",
      "Account Payable",
      "Allocator",
      "Broker / Agency Rep",
      "Buyer",
      "EDI Contact",
      "Logistics / Traffic"
    ]);
    expect(roleLabel("AP")).toBe("Account Payable");
    expect(role.required).toBe(true);
    expect(validateField(role, "")).toBe("Role is required.");
    expect(validateField(role, "Buyer")).toBe("");
    expect(validateField(role, "Free text")).toBe("Select a valid Role.");
    expect(field(PERSON_FIELDS, "jobTitle")).toBeUndefined();
  });

  it("returns errors in field order", () => {
    const errors = validateRecord(PERSON_FIELDS, createPerson());
    expect(Object.keys(errors)).toEqual([
      "firstName",
      "lastName",
      "email",
      "role"
    ]);
    expect(firstErrorField(PERSON_FIELDS, errors)).toBe("firstName");
  });

  it("finds duplicate emails case-insensitively", () => {
    const people = [
      { key: "a", email: "Same@Example.org" },
      { key: "b", email: "other@example.org" },
      { key: "c", email: " same@example.org " },
      { key: "d", email: "" }
    ];
    expect([...findDuplicateEmailKeys(people)].sort()).toEqual(["a", "c"]);
  });

  it("only allows http(s) or site-relative URLs", () => {
    expect(toSafeUrl("https://example.org/privacy")).toBe(
      "https://example.org/privacy"
    );
    expect(toSafeUrl("/privacy")).toBe("/privacy");
    // eslint-disable-next-line no-script-url
    expect(toSafeUrl("javascript:alert(1)")).toBeNull();
    expect(toSafeUrl("//evil.example")).toBeNull();
    expect(toSafeUrl("")).toBeNull();
  });
});
