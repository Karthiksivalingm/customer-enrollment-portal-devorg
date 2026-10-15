import { api } from "lwc";
import OdaRider from "c/odaRider";

export default class OdaWpRider extends OdaRider {
  constructor() {
    super("WP");
  }

  @api termLength;

  get termLengthText() {
    if (!!this.termLength) {
      return "Term " + this.termLength;
    }
    return "No term length selected";
  }

  get isCalculateDisabled() {
    if (this.faceAmount) {
      return false;
    }

    return true;
  }

  onWpCalculateRates() {
    let params = {
      age: this.age,
      product: this.product,
      termLength: this.termLength,
      tobacco: this.tobacco,
      faceAmount: this.faceAmount,
      rider: { product: this.rider.product, amount: 0 }
    };

    this.calculateRates(params);
  }
}