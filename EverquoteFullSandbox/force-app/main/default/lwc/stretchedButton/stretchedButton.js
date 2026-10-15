import { LightningElement, api } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import oda from "@salesforce/resourceUrl/oda";

export default class StretchedButton extends LightningElement {
  @api isDisabled = false;
  @api variant;
  @api iconName;
  @api label;
  @api classes;

  variantMap = {
    success: "slds-button_success  ",
    brand: "slds-button_brand ",
    destructive: "slds-button_destructive ",
    pumpkin: "slds-button_neutral pumpkin "
  };

  resolvedVariants = {
    success: "success",
    brand: "brand",
    destructive: "destructive",
    pumpkin: "success"
  };

  get resolvedClasses() {
    return (
      "slds-button slds-button_stretch  " +
      (this.isDisabled ? this.variantMap.brand : this.variantMap[this.variant] || "") +
      " " +
      (this.classes || "")
    );
  }

  get buttonLabel() {
    return "  " + this.label;
  }

  get resolvedVariant() {
    return this.resolvedVariants[this.variant] || "neutral";
  }

  get isIconVisible() {
    return this.iconName != undefined && this.iconName.length;
  }

  onClick(event) {
    this.dispatchEvent(
      new CustomEvent("selection", {
        detail: {
          event: event
        }
      })
    );
  }
}