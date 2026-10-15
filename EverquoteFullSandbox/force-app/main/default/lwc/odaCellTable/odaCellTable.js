import { LightningElement, api } from "lwc";

export default class OdaCellTable extends LightningElement {
  @api props;
  @api clickable;
  @api postfix;

  get displayedValue() {
    const parsedNumericValue = parseFloat(this.props.value);
    let parsedValue = isNaN(parsedNumericValue)
      ? this.props.value
      : parsedNumericValue.toLocaleString("en-US", {
          style: "currency",
          currency: "USD"
        });
    // Adding the postfix to any value parsed
    if (parsedValue) {
      parsedValue = parsedValue + (this.postfix || "");
    }
    return parsedValue;
  }

  get cellClass() {
    let cssClass = "cell ";

    if (!this.clickable) {
      return cssClass;
    }

    cssClass += "clickable ";
    if (this.props.selected) {
      cssClass += "active ";
    }
    return cssClass;
  }

  handleCellClick(e) {
    if (!this.clickable) {
      return;
    }

    const event = CustomEvent("cellclick", {
      composed: true,
      bubbles: true,
      cancelable: true,
      detail: {
        cellId: this.props.id,
        selected: !this.props.selected
      }
    });
    this.dispatchEvent(event);
  }
}