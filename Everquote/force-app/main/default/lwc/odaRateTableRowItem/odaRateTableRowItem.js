import { LightningElement, api, track } from "lwc";

export default class OdaRateTableRowItem extends LightningElement {
  @api amount;
  @api termLength;
  @api selectedRate = {};
  @api quoteId;

  _price;

  @api
  get price() {
    return this._price;
  }

  set price(value) {
    this._price = value;
  }

  get isActive() {
    let active =
      this.amount === this.selectedRate.amount &&
      this.termLength === this.selectedRate.termLength &&
      this._price === this.selectedRate._price;

    return active;
  }

  get hasNumber() {
    return this._price && this._price > 0;
  }

  get cellClass() {
    return this.hasNumber ? "clickable" : "";
  }

  onSelection(event) {
    if (!this.hasNumber) {
      return;
    }

    let detail = {
      amount: this.amount,
      _price: this._price,
      termLength: this.termLength,
      quoteId: this.quoteId
    };

    this.dispatchEvent(
      new CustomEvent("selection", {
        detail: detail
      })
    );
  }
}