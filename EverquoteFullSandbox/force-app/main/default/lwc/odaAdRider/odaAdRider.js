import { api, track } from "lwc";
import OdaRider from "c/odaRider";

export default class OdaAdRider extends OdaRider {
  constructor() {
    super("AD");
  }

  @api amountRange;

  @track benefitAmount;

  _benefitAmountInput;

  get benefitAmountValid() {
    return this.errorMessages.length == 0;
  }

  get isCalculateDisabled() {
    if (!!this.faceAmount && !!this.benefitAmount && this.benefitAmountValid) {
      return false;
    }

    return true;
  }

  get isBenefitAmountDisabled() {
    if (!!this.faceAmount) {
      return false;
    }
    return true;
  }

  onADCalculateRates() {
    let params = {
      age: this.age,
      product: this.product,
      faceAmount: this.faceAmount,
      rider: { product: this.rider.product, amount: this.benefitAmount * 1000 }
    };

    this.calculateRates(params);
  }

  onBenefitAmountChange(event) {
    this.rider.additionalPremium = "";

    let intValue = parseInt(event.target.value);

    if (!!intValue) {
      this.benefitAmount = intValue;
    } else {
      this.benefitAmount = 0;
      this._benefitAmountInput.value = 0;
    }

    if (event.target.value.startsWith("0")) {
      this._benefitAmountInput.value = this.benefitAmount;
    }

    this.checkBenefitAmountValidity();
    this.handleRiderValueChanged();
  }

  renderedCallback() {
    this._benefitAmountInput = this.template.querySelector(".benefit-amount");
  }

  checkBenefitAmountValidity() {
    let newErrors = [];

    if (this.amountRange.min > this.benefitAmount || this.benefitAmount > this.amountRange.max) {
      newErrors.push("Outside of face amount ranges.");
    }
    if (this.benefitAmount > parseInt(this.faceAmount) / 1000) {
      newErrors.push("Rider benefit above face amount.");
    }

    this.errorMessages = newErrors;

    this.updateFieldClasses(this._benefitAmountInput, this.benefitAmountValid);
  }

  updateFieldClasses(field, validField) {
    let classes = field.getAttribute("class");
    let errorClasses = ["slds-has-error", "benefit-amount-error"];

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
}