import { LightningElement, track, api } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import oda from "@salesforce/resourceUrl/oda";
import pauseRecording from "@salesforce/apex/ODALeadController.pauseRecording";
import resumeRecording from "@salesforce/apex/ODALeadController.resumeRecording";
import { showToastNotification, toastVariant } from "c/fireNotification";

export default class odaCallRecordingRedaction extends LightningElement {
  constructor() {
    super();
    this.template.addEventListener("modalclosed", this.handleConfirmationModalClose);
  }

  @track isModalOpen = false;
  @track isConfirmationModalOpen = false;

  @track loading;

  @api leadId;

  pauseRecording() {
    this.loading = true;
    pauseRecording({ leadId: this.leadId })
      .then((result) => {
        console.log(result);

        this.isModalOpen = true;
      })
      .catch((err) => {
        console.log(err);
        showToastNotification(this, "", "Unable to pause recording!", toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
        console.log("stop spinner");
      });
  }

  resumeRecording() {
    this.isConfirmationModalOpen = true;
  }

  handleConfirmationModalClose(event) {
    if (event.detail) {
      this.loading = true;
      resumeRecording({ leadId: this.leadId })
        .then((result) => {
          this.isConfirmationModalOpen = false;
        })
        .catch((err) => {
          console.log(err);
          showToastNotification(this, "", "Unable to resume recording.", toastVariant.error);
        })
        .finally(() => {
          this.isModalOpen = false;
          this.loading = false;
        });
    } else {
      this.isConfirmationModalOpen = false;
    }
  }

  connectedCallback() {
    loadStyle(this, oda);
  }
}