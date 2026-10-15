import { LightningElement, api, track } from "lwc";

export default class OdaRateTableRow extends LightningElement {
  @api index;
  @api selectedRate = {};
  @track _rateTable;

  @api
  get rateTable() {
    return this._rateTable;
  }

  set rateTable(value) {
    this._rateTable = value;
  }

  get amount() {
    return this._rateTable.amount;
  }

  get rates() {
    return this._rateTable.rates;
  }

  onItemSelection(event) {
    this.dispatchEvent(
      new CustomEvent("selection", {
        detail: event.detail
      })
    );
  }
}