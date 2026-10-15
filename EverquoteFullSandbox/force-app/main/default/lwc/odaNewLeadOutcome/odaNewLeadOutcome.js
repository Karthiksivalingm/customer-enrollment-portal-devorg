import getById from "@salesforce/apex/ODALeadOutcomeController.getById";
import getLeadOutcomeOptions from "@salesforce/apex/ODALeadOutcomeController.getLeadOutcomeOptions";
import updateLeadOutcome from "@salesforce/apex/ODALeadOutcomeController.updateLeadOutcome";
import leadOutcomeResources from "@salesforce/resourceUrl/leadOutcomeResources";
import CalloutOptionsAllowMergeFieldsInBody from "@salesforce/schema/NamedCredential.CalloutOptionsAllowMergeFieldsInBody";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { loadStyle } from "lightning/platformResourceLoader";
import { api, LightningElement, track } from "lwc";

export default class OdaLeadOutcome extends LightningElement {
  constructor() {
    super();
    this.template.addEventListener("modalclosed", this.handleModalClose);
    this.template.addEventListener("cancel", this.handleModalCancel);
  }

  leadOutcomesPolicyRequired = [
    "App. Complete - SALE",
    "App. Complete - Referred",
    "App. Complete - Declined"
  ];

  @api leadId;
  @track isModalOpen = false;
  @track loading = false;
  @track lead;
  @track leadOutcomeOptions = [];
  @track newLeadOutcome;
  leadOutcomeCombobox;

  renderedCallback() {
    this.leadOutcomeCombobox = this.template.querySelector(".lead-outcome-combobox");
  }

  get leadLoaded() {
    return !!this.lead;
  }

  get placeholder() {
    if (this.lead.Lead_Outcome__c === "App. Complete - No Policy Number") {
      return this.lead.Lead_Outcome__c;
    } else {
      ("Choose one...");
    }
  }

  get leadOutcomeValue() {
    return this.lead.Lead_Outcome__c;
  }

  onLeadOutcomeChange(event) {
    this.newLeadOutcome = event.detail.value;
    if (this.leadOutcomesPolicyRequired.indexOf(this.newLeadOutcome) != -1) {
      this.isModalOpen = true;
    } else {
      this.saveLeadOutcome();
    }
  }

  connectedCallback() {
    this.loadLeadOutcomeOptions();
    this.loadLead();
    this.loadStyles();
  }

  loadLead() {
    if (this.leadId) {
      getById({ leadId: this.leadId }).then((result) => {
        this.lead = result;
      });
    }
  }

  loadLeadOutcomeOptions() {
    getLeadOutcomeOptions().then((result) => {
      this.leadOutcomeOptions = JSON.parse(result).filter(
        (option) => option.value !== "App. Complete - No Policy Number"
      );
    });
  }

  loadStyles() {
    Promise.all([loadStyle(this, leadOutcomeResources + "/css/style.css")])
      .then(() => {})
      .catch((error) => {});
  }

  handleModalClose(event) {
    this.isModalOpen = false;
    if (
      (event.detail.missingPolicyNumbers && event.detail.totalPolicyCount === 1) ||
      (event.detail.missingPolicyNumbers && this.newLeadOutcome === "App. Complete - Declined")
    ) {
      this.newLeadOutcome = "App. Complete - No Policy Number";
    }
    this.saveLeadOutcome();
  }

  handleModalCancel(_event) {
    this.isModalOpen = false;
    this.leadOutcomeCombobox.value = this.lead.Lead_Outcome__c;
  }

  saveLeadOutcome() {
    this.loading = true;
    updateLeadOutcome({
      leadId: this.leadId,
      leadOutcome: this.newLeadOutcome
    })
      .then((result) => {
        this.lead = result;

        this.notifyLeadOutcomeUpdated();
      })
      .catch((err) => {
        if (err.body.pageErrors && err.body.pageErrors.length > 0) {
          let error = err.body.pageErrors[0];
          showToastNotification(this, error.statusCode, error.message, toastVariant.error);
        } else {
          showToastNotification(this, "", err, toastVariant.error);
        }
      })
      .finally(() => {
        this.loading = false;
      });
  }

  notifyLeadOutcomeUpdated() {
    this.dispatchEvent(new CustomEvent("leadupdated", {}));
  }
}