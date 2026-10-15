import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import getConfirmedQuote from "@salesforce/apex/OdaReliashieldController.getConfirmedQuote";
import getReliashieldComparisonPdfUrl from "@salesforce/apex/OdaReliashieldController.getReliashieldComparisonPdfUrl";
import getRates from "@salesforce/apex/OdaRatesController.getRates";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { api, LightningElement, track } from "lwc";

const randomId = () => Math.random() + "_key";

const clickableColumns = ["essentialAmount", "primeAmount", "eliteAmount"];
export default class OdaNewIdentityTheft extends LightningElement {
  @api product;

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

  @track loading = false;
  @track rates = [];
  @track selectedProduct = "";
  @track reliashield_comparison_pdf = "";

  get isLaunchEappDisabled() {
    if (!!this.selectedProduct) {
      return false;
    }
    return true;
  }

  columns = [
    {
      label: "",
      fieldName: "rowLabel",
      type: "odaCellTable",
      typeAttributes: {
        clickable: false,
        props: { fieldName: "rowLabel" }
      },
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Essential",
      fieldName: "essentialAmount",
      type: "odaCellTable",
      typeAttributes: {
        clickable: true,
        props: { fieldName: "essentialAmount" },
        postfix: "/mo"
      },
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Prime",
      fieldName: "primeAmount",
      type: "odaCellTable",
      typeAttributes: {
        clickable: true,
        props: { fieldName: "primeAmount" },
        postfix: "/mo"
      },
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Elite",
      fieldName: "eliteAmount",
      type: "odaCellTable",
      typeAttributes: {
        clickable: true,
        props: { fieldName: "eliteAmount" },
        postfix: "/mo"
      },
      cellAttributes: { alignment: "left" }
    }
  ];

  rows = [
    { key: "individual", label: "Individual" },
    { key: "family", label: "Family" }
  ];

  handleLeadLoad() {
    this.loading = true;

    const products = [
      "essential-individual",
      "essential-family",
      "prime-individual",
      "prime-family",
      "elite-individual",
      "elite-family"
    ];

    Promise.all(
      products.map((p) => {
        return getRates({
          rateLookup: { lead: this.lead, carrier: "reliashield", product: p }
        });
      })
    )
      .then((result) => {
        const resultsFormatted = result.map((e, i) => ({
          ...JSON.parse(e)[0],
          product: products[i],
          id: randomId()
        }));
        this.rates = this.formatRates(resultsFormatted);
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));

    // Load the URL
    getReliashieldComparisonPdfUrl()
      .then((result) => {
        this.reliashield_comparison_pdf = result;
      })
      .catch((err) => showToastNotification(this, "", err.body.message, toastVariant.error));
  }

  openComparisonImage(_event) {
    if (this.reliashield_comparison_pdf) {
      window.open(this.reliashield_comparison_pdf, "_blank", "noopener,noreferrer");
    } else {
      showToastNotification(
        this,
        "",
        '"reliashield_comparison_pdf" not configured properly.' +
          "Please, contact with support to get it resolved.",
        toastVariant.error
      );
    }
  }

  handleCellClick(dataSource, cellDetail, callback) {
    let selectedProduct = null;
    dataSource = dataSource.map((row) => {
      clickableColumns.forEach((familyKey) => {
        row[familyKey].selected = false;
        if (row[familyKey].id === cellDetail.cellId) {
          row[familyKey].selected = cellDetail.selected;

          selectedProduct = row[familyKey].selected ? row[familyKey] : null;
        }
      });
      return row;
    });
    callback.bind(this)(selectedProduct);
  }

  handleRateCellClick(event) {
    this.handleCellClick(this.rates, event.detail, this.updateSelectedRate);
  }

  updateSelectedRate(productParam) {
    if (productParam && productParam.product) {
      this.selectedProduct = productParam.product;
    } else {
      this.selectedProduct = "";
    }
  }

  onLaunchEapp(_event) {
    this.loading = true;
    getConfirmedQuote({
      quoteRequestData: {
        lead: this.lead,
        faceAmount: null,
        carrier: "reliashield",
        product: this.selectedProduct
      }
    })
      .then((result) => {
        console.log(result);
        getEApp({
          lead: this.lead,
          quoteId: result.quote_id,
          faceAmount: null,
          carrier: "reliashield",
          product: this.selectedProduct
        })
          .then((result) => {
            window.open(result.app_url, "_blank", "noopener,noreferrer");
          })
          .catch((err) => {
            showToastNotification(this, "", err.body.message, toastVariant.error);
          })
          .finally(() => (this.loading = false));
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => (this.loading = false));
  }

  formatRates(parsedResult) {
    const rates = this.rows.map((row) => {
      const { monthly: essentialValue = 0 } =
        parsedResult.find((e) => e.product === `essential-${row.key}`) || {};
      const { monthly: primeValue = 0 } =
        parsedResult.find((e) => e.product === `prime-${row.key}`) || {};
      const { monthly: eliteValue = 0 } =
        parsedResult.find((e) => e.product === `elite-${row.key}`) || {};
      return {
        rowLabel: { value: row.label },
        essentialAmount: {
          value: essentialValue,
          id: randomId(),
          product: `essential-${row.key}`,
          selected: false
        },
        primeAmount: {
          value: primeValue,
          id: randomId(),
          product: `prime-${row.key}`,
          selected: false
        },
        eliteAmount: {
          value: eliteValue,
          id: randomId(),
          product: `elite-${row.key}`,
          selected: false
        }
      };
    });
    return rates;
  }
}