import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import EnrollmentConvertModal from "c/enrollmentConvertModal";

/**
 * Headless "Convert Lead" record action: opens the existing
 * enrollmentConvertModal and, after a successful conversion, opens the Account.
 */
export default class EnrollmentConvertAction extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  @api
  async invoke() {
    const result = await EnrollmentConvertModal.open({
      size: "large",
      label: "Convert Lead",
      description:
        "Create one Account and a Contact for every submitted person",
      recordId: this.recordId
    });
    if (result && result.accountId) {
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: result.accountId,
          objectApiName: "Account",
          actionName: "view"
        }
      });
    }
  }
}
