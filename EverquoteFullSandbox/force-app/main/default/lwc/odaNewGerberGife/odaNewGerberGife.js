import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import getConfirmedQuotes from "@salesforce/apex/OdaGerberController.getConfirmedQuotes";
import getRates from "@salesforce/apex/OdaRatesController.getRates";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { carriersWithProducts } from "c/odaConstants";
import { api, LightningElement, track } from "lwc";


export default class OdaNewGerberGife extends LightningElement {
  @track faceAmount;
  @track rates = [];
  @track quotes = [];
  @track selectedQuote;
  @track loading = false;

  product = "gife";
  carrier = "gerber";
  invalidFaceAmountMessage = `Invalid face amount value. Please select a face amount that
  is a multiple of $1000s.`;

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

  // instead of using the hard-coded values, we should
  // use the one from odaConstant. See odaNewTerm. line 67.
  get sliderStep() {
    let gife = carriersWithProducts[this.carrier].products[this.product];
    let defaultStepValue = gife.increaseStep * gife.multiplier;

    return defaultStepValue;
  }

  get sliderMinValue() {
    let gife = carriersWithProducts[this.carrier].products[this.product];
    return gife.minCoverageAmount * gife.multiplier;
  }

  get sliderMaxValue() {
    let gife = carriersWithProducts[this.carrier].products[this.product];
    return gife.maxCoverageAmount * gife.multiplier;
  }

  paymentMethods = ["monthlyAch", "monthly", "semiAnnually"];

  columns = [
    {
      label: "Face Amount",
      fieldName: "faceAmount",
      type: "odaCellTable",
      typeAttributes: {
        clickable: false,
        props: { fieldName: "faceAmount" }
      },
      cellAttributes: { alignment: "left" }
    },

    {
      label: "Monthly Premium ACH",
      fieldName: "monthlyAch",
      type: "odaCellTable",
      typeAttributes: {
        clickable: true,
        props: { fieldName: "monthlyAch" }
      },
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Monthly Premium Credit Card",
      fieldName: "monthly",
      type: "odaCellTable",
      typeAttributes: {
        clickable: true,
        props: { fieldName: "monthly" }
      },
      cellAttributes: { alignment: "left" }
    }
  ];

  get hasNoSelectedRate() {
    if (!!this.faceAmount) {
      return false;
    }
    return true;
  }

  get isLaunchEappDisabled() {
    return !this.selectedQuote;
  }

  onConfirmQuote(_event) {
    // show error message on confirmQuotes button clicked.
    // if this.faceAmount is not multiple of $1000s then
    // showToastNotification(this, "", err.body.message, toastVariant.error);
    // we need to provide an error message.
    let gife = carriersWithProducts[this.carrier].products[this.product];
    let multiplier = gife.multiplier;
    if (this.faceAmount % multiplier == 0) {
      this.loading = true;
      getConfirmedQuotes({
        quoteRequestData: {
          lead: this.lead,
          faceAmount: this.faceAmount,
          carrier: this.carrier,
          product: this.product
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
    } else {
      showToastNotification(this, "", this.invalidFaceAmountMessage, toastVariant.error);
    }
  }

  onLaunchEapp(_event) {
    this.loading = true;
    getEApp({
      lead: this.lead,
      quoteId: this.selectedQuote.id,
      faceAmount: this.selectedQuote.faceAmount,
      carrier: this.carrier,
      product: this.product
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

    getRates({ rateLookup: { lead: this.lead, carrier: this.carrier, product: this.product } })
      .then((result) => {
        this.rates = this.formatQuotesOrRates(JSON.parse(result));
      })
      .catch((err) => showToastNotification(this, "", err.body.message, toastVariant.error))
      .finally(() => (this.loading = false));
  }

  onFaceAmountChange(event) {
    this.faceAmount = event.detail.value;
  }

  handleQuoteCellClick(event) {
    this.handleCellClick(this.quotes, event.detail, this.updateSelectedQuote);
  }

  updateSelectedQuote(quote, paymentMethod) {
    this.selectedQuote = null;
    if (!!quote && !!paymentMethod) {
      this.selectedQuote = {
        id: quote.id,
        faceAmount: quote.faceAmount.value,
        paymentMethod: paymentMethod
      };
    }
  }

  handleCellClick(dataSource, cellDetail, callback) {
    let selectedRow = null;
    let selectedPaymentMethod = null;
    dataSource.forEach((row) => {
      this.paymentMethods.forEach((method) => {
        row[method].selected = false;
        if (row[method].id === cellDetail.cellId) {
          row[method].selected = cellDetail.selected;

          selectedPaymentMethod = row[method].selected ? method : null;
          selectedRow = row[method].selected ? row : null;
        }
      });
    });

    dataSource = [...dataSource];
    callback.bind(this)(selectedRow, selectedPaymentMethod);
  }

  handleRateCellClick(event) {
    this.handleCellClick(this.rates, event.detail, this.updateSelectedRate);
  }

  updateSelectedRate(rate) {
    this.faceAmount = !!rate ? rate.faceAmount.value : null;
  }

  formatQuotesOrRates(parsedResult) {
    return parsedResult.map((item) => {
      return {
        faceAmount: { value: item["face_amount"] },
        monthlyAch: {
          value: item["monthly_ach"],
          id: Math.random() + "_key",
          selected: false
        },
        monthly: {
          value: item["monthly"],
          id: Math.random() + "_key",
          selected: false
        },

        semiAnnually: {
          value: item["semi_annually"],
          id: Math.random() + "_key",
          selected: false
        },
        id: !item["quote_id"] ? Math.random() + "_key" : item["quote_id"]
      };
    });
  }
}