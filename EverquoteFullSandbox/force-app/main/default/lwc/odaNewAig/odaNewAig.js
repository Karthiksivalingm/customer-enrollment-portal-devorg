import getRates from "@salesforce/apex/OdaRatesController.getRates";
import getConfirmedQuotes from "@salesforce/apex/ODAAigController.getConfirmedQuotes";

import { LightningElement, track, api } from "lwc";
import getEApp from "@salesforce/apex/ODAEAppController.getEApp";

import { showToastNotification, toastVariant } from "c/fireNotification";

export default class OdaNewAig extends LightningElement {
  @track selectedRate;
  @track selectedQuote;
  @track faceAmount;
  @track rates = [];
  @track quotes = [];
  @track loading = false;

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

  faceAmountMinValue = 5000;
  faceAmountMaxValue = 25000;
  faceAmountStepValue = 1000;
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
    },
    {
      label: "Max payment Age",
      fieldName: "maxPaymentAge",
      type: "number",
      sortable: true,
      cellAttributes: { alignment: "left" }
    }
  ];

  get hasNoSelectedRate() {
    if (!!this.selectedRate) {
      return false;
    }
    return true;
  }

  get isLaunchEappDisabled() {
    return !this.selectedQuote;
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
    getConfirmedQuotes({
      quoteRequestData: {
        lead: this.lead,
        faceAmount: this.faceAmount,
        carrier: "aig",
        product: "giwl"
      }
    })
      .then((result) => {
        this.quotes = this.formatQuotesOrRates(result);
        this.selectedQuote = null;
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));
  }

  onLaunchEapp(event) {
    this.loading = true;
    getEApp({
      lead: this.lead,
      quoteId: this.selectedQuote.id,
      faceAmount: this.selectedQuote.faceAmount,
      carrier: "aig",
      product: "giwl"
    })
      .then((result) => {
        window.open(result.app_url, "_blank", "noopener,noreferrer");
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));
  }

  handleLeadLoad() {
    this.loading = true;
    getRates({ rateLookup: { lead: this.lead, carrier: "aig", product: "giwl" } })
      .then((result) => {
        let parsedResult = JSON.parse(result);

        this.rates = this.formatQuotesOrRates(parsedResult);
      })
      .catch((err) => showToastNotification(this, "", err.body.message, toastVariant.error))
      .finally(() => (this.loading = false));
  }

  onFaceAmountChange(event) {
    this.faceAmount = event.detail.value;
  }

  formatQuotesOrRates(parsedResult) {
    return Object.keys(parsedResult).map((option) => {
      let parsed =
        typeof parsedResult[option] === "string"
          ? JSON.parse(parsedResult[option])
          : parsedResult[option];
      return {
        faceAmount: option,
        monthlyPremium: parsed.monthly || parseFloat(parsed.premium) * 0.0834,
        annualPremium: parsed.annual || parseFloat(parsed.premium),
        maxPaymentAge: parsed.max_payment_age,
        id: !parsed.quote_id ? Math.random() + "_key" : parsed.quote_id
      };
    });
  }
}