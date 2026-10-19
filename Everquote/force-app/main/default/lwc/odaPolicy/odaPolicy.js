import findPolicy from "@salesforce/apex/ODAPolicyController.findPolicy";
import leadOutcomeResources from "@salesforce/resourceUrl/leadOutcomeResources";
import { carriersWithProducts } from "c/odaConstants";
import { api, LightningElement, track } from "lwc";

export default class OdaPolicy extends LightningElement {
  aetnaRiskClassOptions = [
    { label: "Preferred", value: "PFD" },
    { label: "Standard", value: "STD" },
    { label: "Modified", value: "MOD" }
  ];

  @track loading = false;
  @track policyNumber = "";
  @track selectedCarrier = "";
  _carrierInstructionsAdded = false;

  @track selectedProduct = "";
  @track recordingPaused = null;
  @track cannotGetPolicyNumber = false;

  @track coverageAmount;
  @track differentCoverageAmount = false;
  _initialCoverageAmount;

  @track quoteId;

  @track amountErrorMessages = [];
  @track validate = false;
  @api leadId;

  @track selectedRiskClass;

  _policyId;
  _policy;
  @api
  get policy() {
    return this._policy;
  }

  set policy(value) {
    if (!!value && value.id) {
      this._policyId = value.id;
      this.selectedCarrier = value.carrier.toLocaleLowerCase();

      this.selectedProduct = value.product.toLocaleLowerCase();
      this.setCoverageAmount(
        value.coverageAmount,
        value.initialCoverageAmount,
        value.differentCoverageAmount
      );

      this.quoteId = value.quoteId;
      this.selectedRiskClass = value.riskClass;
    }

    if (value.validate) {
      this.validate = true;
      this.dispatchPolicyUpdate();
    }

    this._policy = value;
  }

  //#region getters
  get coverageAmountRequired() {
    if (this.selectedCarrier === "reliashield") {
      return false;
    }
    return true;
  }

  get coverageAmountIncreaseStep() {
    let productDetails = this.productDetails();

    if (!!productDetails) {
      return productDetails.increaseStep;
    }
    return 1;
  }

  get minCoverageAmount() {
    let productDetails = this.productDetails();

    if (!!productDetails) {
      return productDetails.minCoverageAmount;
    }
    return 0;
  }

  get maxCoverageAmount() {
    let productDetails = this.productDetails();

    if (!!productDetails) {
      return productDetails.maxCoverageAmount;
    }
    return 0;
  }

  get validCoverageAmount() {
    if (!this.coverageAmountRequired) {
      return true;
    }

    if (this.validate) {
      let coverageAmountAdded =
        !!this.coverageAmount && this.coverageAmount.toString().trim().length > 0;

      if (this.amountErrorMessages.length === 0) {
        if (!coverageAmountAdded) {
          this.amountErrorMessages.push("Coverage amount required");
        }
      }
    }

    return this.amountErrorMessages.length === 0;
  }

  get dropdownDisabled() {
    if (!!this._policy && !this._policy.manuallyAdded) {
      return true;
    }
    return false;
  }

  get callRecordingPausedRadioBtns() {
    return this._policy.componentId;
  }

  get isCoverageAmountDisabled() {
    let isProductSelected = !!this.selectedProduct;

    if (
      !isProductSelected ||
      (isProductSelected && !this.differentCoverageAmount && !this._policy.manuallyAdded)
    ) {
      return true;
    }

    return false;
  }

  get validCarrier() {
    if (this.validate) {
      return !!this.selectedCarrier;
    }
    return true;
  }

  get isAetnaCarrierSelected() {
    return !!this.selectedCarrier && this.selectedCarrier == "aetna";
  }

  get validRiskClass() {
    if (this.validate) {
      if (!this.isAetnaCarrierSelected) {
        return true;
      }
      return !!this.selectedRiskClass;
    }
    return true;
  }

  get validProduct() {
    if (this.validate) {
      return !!this.selectedProduct;
    }
    return true;
  }

  get validPolicyNumber() {
    if (this.validate) {
      if (!this.cannotGetPolicyNumber && this.policyNumber.trim().length === 0) {
        return false;
      }
    }

    return true;
  }

  get validRecordingPausedOption() {
    if (this.validate) {
      if (this.recordingPaused === null || this.recordingPaused === undefined) {
        return false;
      }
    }
    return true;
  }

  get carrierImage() {
    let imageHtml = "";
    switch (this.selectedCarrier.toLocaleLowerCase()) {
      case "AIG".toLocaleLowerCase():
        imageHtml = `<img src="${leadOutcomeResources + "/images/aig.png"}" /> `;
        break;

      case "Gerber".toLocaleLowerCase():
        imageHtml = `<img src="${leadOutcomeResources + "/images/gerber.png"}" /> `;
        break;

      case "Lumico".toLocaleLowerCase():
        imageHtml = `<img src="${leadOutcomeResources + "/images/lumico.png"}" /> `;
        break;

      case "Reliashield".toLocaleLowerCase():
        imageHtml = `<img src="${leadOutcomeResources + "/images/reliashield.png"}" /> `;
        break;

      default:
        break;
    }
    return imageHtml;
  }

  get isCarrierSelected() {
    if (!!this.selectedCarrier) {
      return true;
    }

    return false;
  }

  get carrierOptions() {
    return Object.keys(carriersWithProducts).map((key) => {
      let carrier = carriersWithProducts[key];
      return { label: carrier.name, value: key };
    });
  }

  get productOptions() {
    if (this.selectedCarrier) {
      let products = carriersWithProducts[this.selectedCarrier].products;

      return Object.keys(products).map((key) => {
        let product = products[key];
        return { label: product.name, value: key };
      });
    }

    return [];
  }

  //#endregion

  //#region events handlers
  onCoverageAmountChange(event) {
    let intValue = parseInt(event.target.value);

    if (!!intValue) {
      this.coverageAmount = intValue;
    } else {
      this.coverageAmount = 0;
      this._coverageAmountInput.value = 0;
    }

    if (event.target.value.startsWith("0")) {
      this._coverageAmountInput.value = this.coverageAmount;
    }

    this.checkCoverageAmountValidity();

    this.dispatchPolicyUpdate();
  }

  onCarrierChange(event) {
    this.selectedCarrier = event.target.value;

    this.resetProperties();

    this._carrierInstructionsAdded = false;
    this.dispatchPolicyUpdate();
  }

  onProductChange(event) {
    this.resetProperties();
    this.selectedProduct = event.target.value;

    // skip find policy
    if (this._policy.manuallyAdded) {
      return;
    }

    this.loadPolicy();
  }

  onRiskClassChange(event) {
    this.selectedRiskClass = event.target.value;
    this.dispatchPolicyUpdate();
  }

  onPolicyNumberChange(event) {
    this.policyNumber = event.target.value;

    this.dispatchPolicyUpdate();
  }

  setCoverageAmount(policyCoverageAmount, initialCoverageAmount, differentCoverageAmount) {
    this.coverageAmount = policyCoverageAmount / this.productDetails().multiplier;

    if (!!initialCoverageAmount) {
      this._initialCoverageAmount = initialCoverageAmount;
    } else {
      this._initialCoverageAmount = this.coverageAmount;
    }

    this.differentCoverageAmount = !!differentCoverageAmount;
  }

  onDifferentCoverageAmountChange(event) {
    this.differentCoverageAmount = event.target.checked;

    if (!this.differentCoverageAmount && !this._policy.manuallyAdded) {
      this.coverageAmount = this._initialCoverageAmount;
      this.checkCoverageAmountValidity();
    }

    this.dispatchPolicyUpdate();
  }

  onRecordingOptionChange(event) {
    this.recordingPaused = event.target.value.toLocaleLowerCase() === "true";
    this.dispatchPolicyUpdate();
  }

  onCannotGetPolicyNumberChange(event) {
    this.cannotGetPolicyNumber = !this.cannotGetPolicyNumber;
    this.policyNumber = "";
    this.dispatchPolicyUpdate();
  }

  //#endregion

  loadPolicy() {
    this.loading = true;
    findPolicy({
      leadId: this.leadId,
      carrier: this.selectedCarrier,
      product: this.selectedProduct
    })
      .then((result) => {
        if (result) {
          this._policyId = result.Id;

          this.setCoverageAmount(
            result.Coverage_Amount__c,
            result.Coverage_Amount__c / this.productDetails().multiplier,
            false
          );
          this.quoteId = result.Quote_Id__c;

          this.dispatchPolicyUpdate();
        }
      })
      .catch((err) => {})
      .finally(() => {
        this.loading = false;
      });
  }

  renderedCallback() {
    this._coverageAmountInput = this.template.querySelector(".coverage-amount");

    if (!!this.selectedCarrier && !this._carrierInstructionsAdded) {
      this.setCarrierInstruction();
    }
  }

  coverageAmountValue() {
    let productDetails = this.productDetails();
    if (!!productDetails) {
      return this.coverageAmount * productDetails.multiplier;
    }
  }

  productDetails() {
    if (!!this.selectedProduct) {
      return carriersWithProducts[this.selectedCarrier].products[this.selectedProduct];
    }
  }

  checkCoverageAmountValidity() {
    let newErrors = [];
    let productDetails = this.productDetails();
    if (
      productDetails.minCoverageAmount > this.coverageAmount ||
      this.coverageAmount > productDetails.maxCoverageAmount
    ) {
      newErrors.push("Outside of product coverage amount range.");
    }

    this.amountErrorMessages = newErrors;
    if (this.coverageAmountRequired) {
      this.updateFieldClasses(this._coverageAmountInput, this.validCoverageAmount);
    }
  }

  resetProperties() {
    this.policyNumber = "";
    this.coverageAmount = null;
    this.differentCoverageAmount = false;
    this.selectedRiskClass = null;
    if (this.coverageAmountRequired) {
      this.updateFieldClasses(this._coverageAmountInput, true);
    }
    this.amountErrorMessages = [];

    this.selectedProduct = null;
  }

  updateFieldClasses(field, validField) {
    if (!field) {
      return;
    }
    let classes = field.getAttribute("class");
    let errorClasses = ["slds-has-error", "coverage-amount-error"];

    if (validField) {
      errorClasses.forEach((cls, _) => {
        classes = classes.replace(cls, "");
      });
    } else {
      errorClasses.forEach((cls, _) => {
        if (!classes.includes(cls)) {
          classes += " " + cls;
        }
      });
    }
    field.setAttribute("class", classes);
  }

  setCarrierInstruction() {
    let html = this.instructions[this.selectedCarrier];
    html = html.replace("{image_placeholder}", this.carrierImage);
    this.addInstructionsElement(html);
    this._carrierInstructionsAdded = true;
  }

  addInstructionsElement(html) {
    let container = this.template.querySelector("div.carrier-instructions-container");
    if (container == null) {
      return;
    }
    var template = document.createElement("template");
    template.innerHTML = html.trim();

    // remove existing childNodes
    while (container.hasChildNodes()) {
      container.removeChild(container.firstChild);
    }

    container.appendChild(template.content.firstChild);
  }

  validPolicy() {
    let isPolicyValid =
      this.validCarrier &&
      this.validProduct &&
      this.validCoverageAmount &&
      this.validPolicyNumber &&
      this.validRecordingPausedOption &&
      this.validRiskClass;
    return isPolicyValid;
  }

  dispatchPolicyUpdate() {
    const policyUpdatedEvent = new CustomEvent("policyupdated", {
      detail: {
        componentId: this._policy.componentId,
        policyNumber: this.policyNumber,
        cannotGetPolicyNumber: this.cannotGetPolicyNumber,
        recordingWasPaused: this.recordingPaused,
        carrier: this.selectedCarrier,
        product: this.selectedProduct,
        quoteId: this.quoteId,
        coverageAmount: this.coverageAmountValue(),
        differentCoverageAmount: this.differentCoverageAmount,
        initialCoverageAmount: this._initialCoverageAmount,
        id: !!this._policyId ? this._policyId : null,
        manuallyAdded: this._policy.manuallyAdded,
        riskClass: this.selectedRiskClass,
        valid: this.validPolicy()
      }
    });
    this.dispatchEvent(policyUpdatedEvent);
  }

  //#region privates
  _coverageAmountInput;

  instructions = {
    lumico: `<div> <p> To find the Lumico policy number, navigate to the e-app window, select the “Show” button next to “Agent Summary” in the bottom-right.
          The policy number will be visible in the sidebar. If you need to re-open the e-app window, please close this window and utilize the Resume Previous Application feature on the SIFE or Term Quote page.
          </p>
          {image_placeholder}
          </div>`,
    aig: `<div><p>To find the AIG policy number, go to this link:
        <a href="https://www-115.aig.com/guaranteedlife" target="_blank">https://www-115.aig.com/guaranteedlife</a>.
         Navigate to your ”dashboard” and select “Completed Applications”. Copy and paste the policy number in the 4th column for this application</p>
         {image_placeholder}
          </div>`,
    gerber: `<div><p>To find the Gerber policy number, go to this link:
          <a href="http://www.gerberlifeagency.com/" target="_blank">www.gerberlifeagency.com</a>.
          Navigate to your ”My Customers” and select “My Case Statuses”. Copy and paste the policy number in the 1st column for this application.</p>
           {image_placeholder}
            </div>`,
    aetna: `<div></div>`,
    reliashield: `<div><p>You should be able to immediately see the member ID upon completing a sale. Please copy the member ID into the <b>Policy Number</b> input field.</p>
            {image_placeholder}
            </div>`
  };

  recordingOptions = [
    { label: "Yes, I paused the recording", value: true },
    { label: "No, I forgot", value: false }
  ];

  //#endregion
}