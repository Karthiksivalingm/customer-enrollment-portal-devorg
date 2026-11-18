import { LightningElement, api } from "lwc";

/**
 * Customer Enrollment Portal page.
 *
 * This is the only component exposed to Experience Builder. Drag it onto the
 * Home page; it renders the header, welcome section, enrollment form, and footer.
 * The @api properties below appear in Builder's property panel (see the
 * targetConfig in enrollmentPortal.js-meta.xml).
 */
export default class EnrollmentPortal extends LightningElement {
  @api brandName;
  @api supportEmail;
  @api supportPhone;
  @api privacyPolicyUrl;
  @api termsUrl;
}
