import { api, LightningElement } from "lwc";

export default class OdaSlider extends LightningElement {
  @api minValue;
  @api maxValue;
  @api step;
  @api isDisabled;
  @api value;

  get minValueText() {
    return this.currencyValue(this.minValue);
  }

  get maxValueText() {
    return this.currencyValue(this.maxValue);
  }

  currencyValue(value) {
    return parseFloat(value).toLocaleString("en-US", {
      style: "currency",
      currency: "USD"
    });
  }

  onValueChange(event) {
    this.dispatchEvent(
      new CustomEvent("slidervaluechange", {
        detail: {
          value: event.target.value
        }
      })
    );
  }
}