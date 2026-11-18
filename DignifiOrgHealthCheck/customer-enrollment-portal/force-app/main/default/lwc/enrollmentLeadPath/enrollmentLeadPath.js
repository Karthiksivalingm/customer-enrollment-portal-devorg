import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import {
  getRecord,
  getFieldValue,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateLeadStatus from "@salesforce/apex/EnrollmentPeopleController.updateLeadStatus";
import EnrollmentConvertModal from "c/enrollmentConvertModal";
import STATUS_FIELD from "@salesforce/schema/Lead.Status";
import IS_CONVERTED_FIELD from "@salesforce/schema/Lead.IsConverted";
import ENROLLMENT_KEY_FIELD from "@salesforce/schema/Lead.Enrollment_Submission_Key__c";

const CONVERTED = "Converted";

/** Path stages; the last one is reached only through the conversion screen. */
const STAGES = [
  { value: "Open - Not Contacted", label: "Open - Not Contacted" },
  { value: "Working - Contacted", label: "Working - Contacted" },
  { value: "Closed - Not Converted", label: "Closed - Not Converted" },
  { value: CONVERTED, label: "Converted" }
];

/**
 * Lead status path for enrollment Leads (styled like the standard Salesforce Path).
 * - First three stages: update Lead.Status through Apex.
 * - Converted: opens enrollmentConvertModal; Lead.Status is never set directly.
 * Renders nothing on Leads that were not created by the enrollment form.
 */
export default class EnrollmentLeadPath extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  record;
  selectedValue;
  isSaving = false;
  isModalOpen = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [STATUS_FIELD, IS_CONVERTED_FIELD, ENROLLMENT_KEY_FIELD]
  })
  wiredLead({ data }) {
    if (data) {
      this.record = data;
      this.selectedValue = undefined;
    }
  }

  get isVisible() {
    return Boolean(
      this.record && getFieldValue(this.record, ENROLLMENT_KEY_FIELD)
    );
  }

  get isConverted() {
    return Boolean(getFieldValue(this.record, IS_CONVERTED_FIELD));
  }

  get currentIndex() {
    if (this.isConverted) {
      return STAGES.length - 1;
    }
    const status = getFieldValue(this.record, STATUS_FIELD);
    return STAGES.findIndex((stage) => stage.value === status);
  }

  get stages() {
    const current = this.currentIndex;
    return STAGES.map((stage, index) => {
      const classes = ["slds-path__item"];
      let assistiveText = "";
      if (this.isConverted || index < current) {
        classes.push("slds-is-complete");
        assistiveText = "Stage complete";
      } else if (index === current) {
        classes.push("slds-is-current");
        assistiveText = "Current stage";
      } else {
        classes.push("slds-is-incomplete");
      }
      const isSelected = stage.value === this.selectedValue;
      if (isSelected) {
        classes.push("slds-is-active");
      }
      if (this.isConverted && index === STAGES.length - 1) {
        classes.push("slds-is-won");
      }
      return {
        ...stage,
        itemClass: classes.join(" "),
        ariaSelected: isSelected || index === current ? "true" : "false",
        tabIndex: index === current ? "0" : "-1",
        assistiveText
      };
    });
  }

  /** The stage the action button will apply. */
  get targetStage() {
    const current = this.currentIndex;
    if (this.selectedValue && this.selectedValue !== STAGES[current]?.value) {
      return STAGES.find((stage) => stage.value === this.selectedValue);
    }
    return STAGES[current + 1];
  }

  /** True when the Converted stage is selected (native label: "Select Converted Status"). */
  get isConvertedSelected() {
    return !this.isConverted && this.selectedValue === CONVERTED;
  }

  get showAction() {
    return this.isConverted || Boolean(this.targetStage);
  }

  get actionLabel() {
    if (this.isConverted) {
      return "Converted";
    }
    if (this.isConvertedSelected) {
      return "Select Converted Status";
    }
    return this.selectedValue &&
      this.selectedValue !== STAGES[this.currentIndex]?.value
      ? "Mark as Current Status"
      : "Mark Status as Complete";
  }

  get actionIcon() {
    return this.actionLabel === "Mark Status as Complete"
      ? "utility:check"
      : undefined;
  }

  get isActionDisabled() {
    return this.isConverted || this.isSaving || !this.targetStage;
  }

  handleSelect(event) {
    event.preventDefault();
    if (this.isConverted) {
      return;
    }
    this.selectedValue = event.currentTarget.dataset.value;
  }

  async handleAction() {
    const target = this.targetStage;
    if (!target) {
      return;
    }
    if (target.value === CONVERTED) {
      if (this.isConvertedSelected) {
        // "Select Converted Status": open our conversion screen (never sets Lead.Status).
        await this.openConversion();
      } else {
        // "Mark Status as Complete" on the last open stage selects Converted, as in the native Path.
        this.selectedValue = CONVERTED;
      }
      return;
    }
    this.isSaving = true;
    try {
      await updateLeadStatus({ leadId: this.recordId, status: target.value });
      this.selectedValue = undefined;
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      this.toast(
        "Status changed",
        `Lead status is now ${target.label}.`,
        "success"
      );
    } catch (error) {
      this.toast(
        "Status not changed",
        (error && error.body && error.body.message) || "Please try again.",
        "error"
      );
    } finally {
      this.isSaving = false;
    }
  }

  async openConversion() {
    if (this.isModalOpen) {
      return; // ignore repeated clicks while the conversion screen is open
    }
    this.isModalOpen = true;
    let result;
    try {
      result = await EnrollmentConvertModal.open({
        size: "large",
        label: "Convert Lead",
        description:
          "Create or select one Account and a Contact for every submitted person",
        recordId: this.recordId
      });
    } finally {
      this.isModalOpen = false;
    }
    this.selectedValue = undefined;
    if (result && result.accountId) {
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      // Go to the Account created (or selected) by the conversion. Reloading the
      // Lead page instead makes Salesforce redirect a converted Lead to its Contact.
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

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
