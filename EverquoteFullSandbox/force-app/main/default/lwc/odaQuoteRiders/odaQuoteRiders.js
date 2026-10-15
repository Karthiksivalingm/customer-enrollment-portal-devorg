import { api, LightningElement, track } from "lwc";

export default class OdaQuoteRiders extends LightningElement {
  @track selectedRiders = [];

  @api product;
  @api lead;

  _quote;
  @api
  get quote() {
    return this._quote;
  }

  set quote(value) {
    this._quote = value;
    this.resetSelectedRiders();
  }

  get basePremium() {
    if (!!this._quote) {
      return this._quote.monthlyPremium || this._quote._price;
    }
  }

  get basePremiumText() {
    if (!!this.basePremium) {
      return parseFloat(this.basePremium).toLocaleString("en-US", {
        style: "currency",
        currency: "USD",
        maximumFractionDigits: 2
      });
    }

    return "";
  }

  get faceAmount() {
    if (!!this.quote) {
      return this.quote.faceAmount || this.quote.amount;
    }
  }

  get termLength() {
    if (!!this.quote) {
      return this.quote.termLength;
    }
  }

  get isDcRiderVisible() {
    return ["siterm", "term", "term19", "wl"].findIndex((item) => item === this.product) != -1;
  }

  get isAdRiderVisible() {
    return (
      ["siterm", "term", "term19", "sife", "wl"].findIndex((item) => item === this.product) != -1
    );
  }

  get isWpRiderVisible() {
    return ["siterm", "term", "term19"].findIndex((item) => item === this.product) != -1;
  }

  get amountRange() {
    switch (this.product) {
      case "sife":
        return { min: 1, max: 30 };

      case "siterm":
        return { min: 25, max: 250 };

      case "wl":
        return { min: 30, max: 250 };

      default:
        return { min: 50, max: 250 };
    }
  }

  get totalMonthlyPremium() {
    let ridersSum = this.selectedRiders
      .filter((rider) => !!rider.additionalPremium)
      .map((rider) => {
        return parseFloat(rider.additionalPremium);
      })
      .reduce((a, b) => a + b, 0);

    if (!!this.basePremium && !!ridersSum) {
      return (parseFloat(this.basePremium) + ridersSum).toLocaleString("en-US", {
        style: "currency",
        currency: "USD"
      });
    } else {
      let sum = parseFloat(this.basePremium) || ridersSum;
      return sum.toLocaleString("en-US", { style: "currency", currency: "USD" });
    }
  }

  get selectedRidersElements() {
    let order = ["DC", "AD", "WP"];

    return order
      .map((product) => {
        let rider = this.selectedRiders.find((rider) => rider.product === product);
        if (rider) {
          return {
            product: rider.product,
            name: rider.product + " Rider Premium",
            value: parseFloat(rider.additionalPremium).toLocaleString("en-US", {
              style: "currency",
              currency: "USD"
            }),
            key: Math.random(),
            id: rider.product.toLocaleLowerCase() + "-rider-premium"
          };
        }
      })
      .filter((item) => !!item);
  }

  handleSelectedRiderChange(event) {
    if (event.detail.selected) {
      this.removeRiderFromSelected(event.detail.rider.product);
      this.selectedRiders.push(event.detail.rider);
    } else {
      this.removeRiderFromSelected(event.detail.rider.product);
    }

    this.notifySelectedRidersChange();
  }

  removeRiderFromSelected(riderProduct) {
    this.selectedRiders = this.cloneArray(this.selectedRiders)
      .filter((rider) => rider.product !== riderProduct)
      .map((rider) => rider);
  }

  handleRiderValueChanged(event) {
    let updatedRider = this.selectedRiders.find(
      (rider) => rider.product === event.detail.riderProduct
    );

    if (updatedRider) {
      updatedRider.value = event.detail.value;
    }

    this.notifySelectedRidersChange();
  }

  resetSelectedRiders() {
    this.selectedRiders = [];
    let ridersSelector = ["c-oda-dc-rider", "c-oda-ad-rider", "c-oda-wp-rider"];

    ridersSelector.forEach((selector, _) => {
      let riderComponent = this.template.querySelector(selector);
      if (!!riderComponent) {
        riderComponent.handleSelectedRidersReset(this.selectedRiders);
      }
    });
  }

  notifySelectedRidersChange() {
    this.dispatchEvent(
      new CustomEvent("riderschange", {
        detail: {
          riders: this.selectedRiders
        }
      })
    );
  }

  cloneArray(arr) {
    return JSON.parse(JSON.stringify(arr));
  }
}