import { track, api } from "lwc";

import OdaRider from "c/odaRider";

export default class OdaDcRider extends OdaRider {
  constructor() {
    super("DC");
  }

  @track noOfChildren;
  @track benefitAmount;

  @api product;

  _quote;
  @api
  get quote() {
    return this._quote;
  }

  set quote(value) {
    this.noOfChildren = "";
    this.benefitAmount = "";
    this.rider.additionalPremium = "";

    this._quote = value;
  }

  get numberOfChildrenOptions() {
    let length = 8;

    let options = Array.from({ length }, (_, i) => i + 1).map((item) => ({
      value: item.toString(),
      label: item.toString()
    }));

    return options;
  }

  get isDropdownDisabled() {
    if (!!this.quote && Object.keys(this.quote).length > 0) {
      return false;
    }

    return true;
  }

  get isCalculateDisabled() {
    if (!this.noOfChildren || !this.benefitAmount) {
      return true;
    }

    return false;
  }

  get benefitAmountOptions() {
    let minAmount = 2000;
    let maxAmount = 10000;

    let options = [];
    let amount = minAmount;
    while (amount <= maxAmount) {
      options.push({
        value: amount.toString(),
        label: amount.toLocaleString("en-US", { style: "currency", currency: "USD" })
      });
      amount += 1000;
    }
    return options;
  }

  onCalculateRates() {
    let params = {
      age: this.age,
      product: this.product,
      face_amount: this.faceAmount,
      rider: { product: this.rider.product, amount: this.benefitAmount, units: this.noOfChildren }
    };

    this.calculateRates(params);
  }

  onNumberOfChildrenChange(event) {
    this.noOfChildren = event.detail.value;
    this.rider.additionalPremium = "";
    this.handleRiderValueChanged();
  }

  onBenefitAmountChange(event) {
    this.benefitAmount = event.detail.value;
    this.rider.additionalPremium = "";
    this.handleRiderValueChanged();
  }
}