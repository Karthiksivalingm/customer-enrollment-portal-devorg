import { LightningElement, api } from "lwc";

export default class OdaTextArea extends LightningElement {
  _value = "";

  @api
  rows;

  @api
  label;

  @api
  get value() {
    return this._value;
  }

  set value(val) {
    this._value = val;
  }

  onInputChange(event) {
    this._value = event.target.value;
  }
}