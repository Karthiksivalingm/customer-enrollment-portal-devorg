import { LightningElement, api, track } from "lwc";
import getRiderRates from "@salesforce/apex/ODALeadController.getRiderRates";
import { showToastNotification, toastVariant } from "c/fireNotification";

export default class OdaRider extends LightningElement {
  constructor(riderProduct) {
    super();
    this.rider.product = riderProduct;
  }

  addPolicyToggleLabel = "Add to Policy?";
  @track errorMessages = [];

  @track rider = {
    product: "",
    additionalPremium: "",
    rateParams: {},
    error: null
  };

  @track checked = false;

  @api product;
  @api age;
  @api tobacco;

  _faceAmount;
  @api
  get faceAmount() {
    return this._faceAmount;
  }

  set faceAmount(value) {
    this._faceAmount = value;
    this.rider.additionalPremium = "";
  }

  @api handleSelectedRidersReset(selectedRiders) {
    this.checked = selectedRiders.findIndex((rider) => rider.product === this.rider.product) != -1;
  }

  get faceAmountText() {
    if (!!this.faceAmount) {
      return parseFloat(this.faceAmount).toLocaleString("en-US", {
        style: "currency",
        currency: "USD"
      });
    }
    return "No face amount selected";
  }

  get addToPolicyDisabled() {
    if (
      !!this.rider.error ||
      this.errorMessages.length > 0 ||
      isNaN(parseFloat(this.rider.additionalPremium))
    ) {
      return true;
    }
    return false;
  }

  get additionalPremiumText() {
    if (!!this.rider.error) {
      return this.rider.error;
    }
    if (!!this.rider.additionalPremium) {
      return parseFloat(this.rider.additionalPremium).toLocaleString("en-US", {
        style: "currency",
        currency: "USD"
      });
    }

    return "";
  }

  calculateRates(params) {
    this.loading = true;
    this.rider.rateParams = params;
    getRiderRates(params)
      .then((result) => {
        let json_result = JSON.parse(result);
        this.rider.error = null;

        if (!!json_result.error) {
        } else {
          this.rider.additionalPremium = json_result["monthly"];
        }

        this.handleRiderValueChanged();
      })
      .catch((err) => {
        if (
          err.body &&
          err.body.exceptionType == "ODABusinessRuleException" &&
          err.body.message.length
        ) {
          this.rider.error = err.body.message;
        } else {
          let errorMessage = `Error while loading ${this.rider.product} rider rates`;
          showToastNotification(this, "", errorMessage, toastVariant.error);
        }
      })
      .finally(() => {
        this.loading = false;
      });
  }

  handleRiderValueChanged() {
    if (this.checked) {
      this.dispatchEvent(
        new CustomEvent("ridervaluechange", {
          detail: {
            rider: this.rider
          }
        })
      );
    }
  }

  handlePolicySelected(event) {
    this.checked = event.detail.checked;
    this.dispatchEvent(
      new CustomEvent("addpolicychange", {
        detail: {
          selected: this.checked,
          rider: this.rider
        }
      })
    );
  }
}