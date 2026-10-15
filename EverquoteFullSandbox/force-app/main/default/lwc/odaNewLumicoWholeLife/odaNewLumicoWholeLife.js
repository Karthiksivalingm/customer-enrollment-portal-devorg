import { LightningElement, api, track } from "lwc";
import getRates from "@salesforce/apex/OdaRatesController.getRates";
import getQuotes from "@salesforce/apex/OdaLumicoQuoteController.getQuotes";
import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { wholeLifeCoverage, carriersWithProducts } from "c/odaConstants";

import { loadStyle } from "lightning/platformResourceLoader";
import oda from "@salesforce/resourceUrl/oda";

export default class OdaNewLumicoWholeLife extends LightningElement {
  constructor() {
    super();
    loadStyle(this, oda)
      .then((_result) => {})
      .catch((_error) => {});
  }

  @track loading = false;
  riders = [];

  @track rates = [];
  @track selectedRate = {};
  @track faceAmount = 0;

  @track quotes = [];
  @track selectedQuote = {};

  @track riskClassDetails;
  @track buildRiskClass;
  @track overrideRiskClass;

  product = "wl";
  carrier = "lumico";

  _lead;

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

  @api
  get lead() {
    return this._lead;
  }

  set lead(value) {
    this._lead = value;
  }

  get hasNoSelectedFaceAmount() {
    return !this.faceAmount;
  }

  get isLaunchEappDisabled() {
    return !!!this.selectedQuote.quoteId;
  }

  get sliderMinValue() {
    return Math.min(
      ...Object.keys(this.coverageOptions).map((key) => {
        return Math.min(...this.coverageOptions[key]);
      })
    );
  }

  get sliderMaxValue() {
    return Math.max(
      ...Object.keys(this.coverageOptions).map((key) => {
        return Math.max(...this.coverageOptions[key]);
      })
    );
  }

  get coverageOptions() {
    let result = {};
    Object.keys(wholeLifeCoverage).forEach((key) => {
      if (
        this.lead.Age__c >= wholeLifeCoverage[key].minAge &&
        this.lead.Age__c <= wholeLifeCoverage[key].maxAge
      ) {
        result[key] = wholeLifeCoverage[key].options;
      }
    });

    return result;
  }

  get sliderStep() {
    let wholeLife = carriersWithProducts[this.carrier].products[this.product];
    let defaultStepValue = wholeLife.increaseStep * wholeLife.multiplier;

    return defaultStepValue;
  }

  //METHODS

  onRateRowSelection(event) {
    let selected = event.detail.selectedRows[0];

    if (!!selected) {
      this.selectedRate = event.detail.selectedRows[0];
      this.faceAmount = this.selectedRate.faceAmount;
    } else {
      // reset selected quote
      this.selectedQuote = {};
    }
  }

  onQuoteRowSelection(event) {
    let selected = event.detail.selectedRows[0];
    if (!!selected) {
      this.selectedQuote = {
        faceAmount: selected.faceAmount,
        quoteId: selected.id,
        monthlyPremium: selected.monthlyPremium
      };
    }
  }

  onFaceAmountChange(event) {
    this.faceAmount = event.detail.value;
    this.clearQuotes();
  }

  onConfirmQuotes(_event) {
    this.loading = true;

    let riskClass = this.overrideRiskClass != undefined ? this.overrideRiskClass.code : null;

    if (riskClass === "RTD") {
      riskClass = riskClass + " " + this.overrideRiskClass.text.replace("Table ", "").trim();
    }

    let params = {
      lead: this.lead,
      carrier: this.carrier,
      product: this.product,
      faceAmount: this.faceAmount,
      riskClass: riskClass
    };

    getQuotes({ quoteRequestData: params })
      .then((result) => {
        this.quotes = this.parseQuotesResponse(result);
        this.selectedQuote = {};
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  onLaunchEapp(_event) {
    if (!!this.riders && this.riders.length > 0) {
      (async () => {
        let newQuote = await this.generateNewQuoteIncludingRiders();
        let newQuoteId = newQuote[this.selectedQuote.faceAmount].quote_id;

        let quoteToUpdate = this.quotes.find((q) => q.faceAmount == this.selectedQuote.faceAmount);

        quoteToUpdate.id = newQuoteId;
        this.selectedQuote.quoteId = newQuoteId;

        this.launchEapp();
      })();
    } else {
      this.launchEapp();
    }
  }

  launchEapp() {
    this.loading = true;
    getEApp({
      lead: this.lead,
      quoteId: this.selectedQuote.quoteId,
      faceAmount: this.selectedQuote.faceAmount,
      carrier: this.carrier,
      product: this.product
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
      .catch((_err) => {
        showToastNotification(this, "", "Unable to launch e-app.", toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  fetchWholeLifeRates(event) {
    this.clearQuotes();

    this.rates = [];
    this.faceAmount = 0;
    this.fetchRates(this.lead, this.product, event.detail.amounts, event.detail.riskClass);
  }

  fetchRates(lead, product, amounts, riskClass) {
    this.loading = true;

    let params = {
      lead: lead,
      carrier: this.carrier,
      product: product,
      amounts: amounts,
      riskClass: riskClass
    };

    if (!riskClass) {
      this.buildRiskClass = null;
      this.overrideRiskClass = null;
    }
    getRates({ rateLookup: params })
      .then((result) => {
        let jsonResult = JSON.parse(result);

        this.rates = this.parseRatesResponse(jsonResult);
        this.updateRiskClassDetails(jsonResult);
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  clearQuotes() {
    this.quotes = this.cloneArray([]);
  }

  updateRiskClassDetails(response) {
    this.riskClassDetails = {
      overrideOptions: response["override_risk_class_options"],
      code: response["risk_class_code"],
      text: response["risk_class"]
    };

    if (this.buildRiskClass) {
      this.overrideRiskClass = {
        code: this.riskClassDetails.code,
        text: this.riskClassDetails.text
      };
    } else {
      this.buildRiskClass = {
        code: this.riskClassDetails.code,
        text: this.riskClassDetails.text
      };
    }
  }

  parseRatesResponse(response) {
    return this.parseQuotesResponse(response.amounts);
  }

  parseQuotesResponse(response) {
    return Object.keys(response).map((amount) => {
      let monthlyPremium = !!response[amount].premium
        ? parseFloat(response[amount].premium) / 12
        : response[amount];

      let annualPremium = !!response[amount].premium
        ? parseFloat(response[amount].premium)
        : response[amount] * 12;

      return {
        faceAmount: amount,
        monthlyPremium: monthlyPremium,
        annualPremium: annualPremium,
        id: response[amount].quote_id ? response[amount].quote_id : Math.random() + "_key"
      };
    });
  }

  handleRidersChange(event) {
    this.riders = event.detail.riders
      .filter((rider) => !!rider.rateParams && !!rider.rateParams.rider)
      .map((rider) => rider.rateParams.rider);
  }

  async generateNewQuoteIncludingRiders() {
    let params = {
      lead: this.lead,
      product: this.product,
      carrier: this.carrier,
      faceAmount: this.selectedQuote.faceAmount,
      riskClass: this.riskClass,
      riders: this.riders
    };
    this.loading = true;

    let parsedResult = await getQuotes({ quoteRequestData: params })
      .then((result) => {
        return result;
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
    return parsedResult;
  }

  cloneArray(arr) {
    return JSON.parse(JSON.stringify(arr));
  }

  isNullOrUndefined(value) {
    return value == null || value == undefined;
  }
}