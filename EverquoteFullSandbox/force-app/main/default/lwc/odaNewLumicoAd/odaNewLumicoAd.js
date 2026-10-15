import { LightningElement, api, track } from "lwc";
import getRates from "@salesforce/apex/OdaRatesController.getRates";
import getQuotes from "@salesforce/apex/OdaLumicoQuoteController.getQuotes";
import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { carriersWithProducts } from "c/odaConstants";
export default class OdaLumicoAd extends LightningElement {
  @track selectedRate;
  @track selectedQuote;
  @track faceAmount;
  @track rates = [];
  @track quotes = [];
  @track loading = false;

  @track product = "ad";
  carrier = "lumico";

  _lead;
  @api
  get lead() {
    return this._lead;
  }

  set lead(value) {
    this._lead = value;
    if (this._lead && this._lead.Id) {
      this.handleLeadLoad();
    }
  }

  faceAmountMinValue = 100000;
  faceAmountMaxValue = 250000;
  faceAmountStepValue = 25000;

  columns = [
    {
      label: "Face Amount",
      fieldName: "faceAmount",
      type: "currency",
      typeAttributes: { currencyCode: "USD" },
      sortable: true,
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Monthly Premium",
      fieldName: "monthlyPremium",
      type: "currency",
      typeAttributes: { currencyCode: "USD" },
      sortable: true,
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Annual Premium",
      fieldName: "annualPremium",
      type: "currency",
      typeAttributes: { currencyCode: "USD" },
      sortable: true,
      cellAttributes: { alignment: "left" }
    }
  ];

  //GETTERS & SETTERS

  get hasNoSelectedRate() {
    if (!!this.selectedRate) {
      return false;
    }
    return true;
  }

  get isLaunchEappDisabled() {
    return !this.selectedQuote;
  }

  get headingMessage() {
    let productName = carriersWithProducts[this.carrier].products[this.product].name;
    return `${productName} - Begin a New Application`;
  }

  onRateRowSelection(event) {
    this.selectedRate = event.detail.selectedRows[0];
    this.faceAmount = this.selectedRate.faceAmount;
  }

  onConfirmedQuoteSelection(event) {
    this.selectedQuote = event.detail.selectedRows[0];
  }

  onConfirmQuote(_event) {
    this.loading = true;
    getQuotes({
      quoteRequestData: {
        lead: this.lead,
        faceAmount: this.faceAmount,
        carrier: this.carrier,
        product: this.product
      }
    })
      .then((results) => {
        this.quotes = this.formatQuotes(results);
        this.selectedQuote = null;
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));
  }

  onLaunchEapp() {
    this.loading = true;
    getEApp({
      lead: this.lead,
      quoteId: this.selectedQuote.id,
      carrier: this.carrier,
      product: this.product,
      faceAmount: this.selectedQuote.faceAmount
    })
      .then((result) => {
        if (!result || result.error) {
          showToastNotification(
            this,
            "",
            !result ? "Failed to start E-App" : result.error,
            toastVariant.error
          );
          return;
        }
        window.open(
          result.app_url,
          "_blank",
          "location=yes,height=570,width=520,scrollbars=yes,status=yes"
        );
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  handleLeadLoad() {
    this.loading = true;
    getRates({
      rateLookup: {
        lead: this.lead,
        carrier: this.carrier,
        product: this.product
      }
    })
      .then((result) => {
        this.rates = this.formatRates(JSON.parse(result));
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));
  }

  onFaceAmountChange(event) {
    this.faceAmount = event.detail.value;
  }

  formatRates(result) {
    return result.map((rate) => {
      return {
        faceAmount: rate.face_amount,
        monthlyPremium: rate.monthly,
        annualPremium: rate.annually,
        id: Math.random() + "_key"
      };
    });
  }

  formatQuotes(result) {
    return Object.keys(result).map((option) => {
      let parsed = result[option];

      return {
        faceAmount: option,
        monthlyPremium: Math.floor(parsed.premium * 0.0834 * 100) / 100,
        annualPremium: parsed.premium,
        id: parsed.quote_id
      };
    });
  }
}