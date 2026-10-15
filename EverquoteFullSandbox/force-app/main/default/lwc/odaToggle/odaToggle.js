import { api, LightningElement } from "lwc";

export default class OdaToggle extends LightningElement {
  _isDisabled = false;

  @api label;
  @api checked;

  @api
  get isDisabled() {
    return this._isDisabled;
  }

  set isDisabled(value) {
    if (value && this.checked) {
      this.handleToggleChange({ target: { checked: false } });
    }
    this._isDisabled = value;
  }

  handleToggleChange(event) {
    this.dispatchEvent(
      new CustomEvent("togglechange", {
        detail: {
          checked: event.target.checked
        }
      })
    );
  }
}