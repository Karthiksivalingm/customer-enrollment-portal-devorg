import { LightningElement, api } from "lwc";
import { normalizeValue, toSafeUrl } from "c/enrollmentUtils";

const DEFAULT_BRAND = "Your Company";
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/**
 * Site footer. Contact details and legal links are configured in Experience
 * Builder (properties on c-enrollment-portal). Until they are set, clearly
 * marked placeholders are shown instead of invented contact data.
 */
export default class EnrollmentFooter extends LightningElement {
  @api brandName;
  @api supportEmail;
  @api supportPhone;
  @api privacyPolicyUrl;
  @api termsUrl;

  get brandLabel() {
    return this.brandName || DEFAULT_BRAND;
  }

  get currentYear() {
    return new Date().getFullYear();
  }

  get emailHref() {
    const email = normalizeValue(this.supportEmail);
    return EMAIL_PATTERN.test(email) ? `mailto:${email}` : null;
  }

  get phoneHref() {
    const digits = normalizeValue(this.supportPhone).replace(/[^\d+]/g, "");
    return digits.length >= 7 ? `tel:${digits}` : null;
  }

  get privacyHref() {
    return toSafeUrl(this.privacyPolicyUrl);
  }

  get termsHref() {
    return toSafeUrl(this.termsUrl);
  }
}
