import { LightningElement, api } from "lwc";

const DEFAULT_BRAND = "Your Company";

/**
 * Site header: branding placeholder only. The page has a single entry point
 * (the enrollment form directly below), so there is no navigation menu.
 */
export default class EnrollmentHeader extends LightningElement {
  @api brandName;

  get brandLabel() {
    return this.brandName || DEFAULT_BRAND;
  }
}
