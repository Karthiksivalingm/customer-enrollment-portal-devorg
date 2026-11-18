import { LightningElement, api, wire } from "lwc";
import getPeople from "@salesforce/apex/EnrollmentPeopleController.getPeople";

const BASE_COLUMNS = [
  { label: "Name", fieldName: "fullName", type: "text" },
  { label: "Email", fieldName: "email", type: "email" },
  { label: "Phone", fieldName: "phone", type: "phone" },
  { label: "Role", fieldName: "roleLabel", type: "text" }
];

const CONTACT_COLUMN = {
  label: "Contact",
  fieldName: "contactUrl",
  type: "url",
  typeAttributes: { label: { fieldName: "contactLabel" } }
};

/**
 * Lead record page: read-only list of the people (contacts) submitted with an
 * enrollment Lead. Conversion is done with the separate "Convert Lead" action.
 * Renders nothing on Leads that were not created by the enrollment form.
 */
export default class EnrollmentPeoplePanel extends LightningElement {
  @api recordId;

  data;
  loadError;

  @wire(getPeople, { leadId: "$recordId" })
  wiredPeople(result) {
    if (result.data) {
      this.data = result.data;
      this.loadError = undefined;
    } else if (result.error) {
      this.data = undefined;
      this.loadError = "Contacts could not be loaded.";
    }
  }

  get isEnrollment() {
    return Boolean(this.data && this.data.isEnrollment);
  }

  get people() {
    return (this.data && this.data.people) || [];
  }

  get hasPeople() {
    return this.people.length > 0;
  }

  get cardTitle() {
    return `Roles (${this.people.length})`;
  }

  get message() {
    return this.data && this.data.message;
  }

  get isConverted() {
    return Boolean(this.data && this.data.isConverted);
  }

  get accountUrl() {
    return this.data && this.data.convertedAccountId
      ? `/${this.data.convertedAccountId}`
      : null;
  }

  get columns() {
    return this.isConverted ? [...BASE_COLUMNS, CONTACT_COLUMN] : BASE_COLUMNS;
  }

  get rows() {
    return this.people.map((person) => ({
      id: person.id,
      fullName: [person.firstName, person.lastName].filter(Boolean).join(" "),
      email: person.email,
      phone: person.phone,
      // Server-computed: the Role label, or the legacy free-text job title on older Leads.
      roleLabel: person.roleLabel,
      contactUrl: person.contactId ? `/${person.contactId}` : null,
      contactLabel: person.contactId ? "View Contact" : ""
    }));
  }
}
