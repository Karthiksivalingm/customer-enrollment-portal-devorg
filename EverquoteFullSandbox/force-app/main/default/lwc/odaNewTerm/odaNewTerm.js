import { LightningElement, api, track } from "lwc";
import getRates from "@salesforce/apex/ODALeadController.getRates";
import getQuotes from "@salesforce/apex/ODALeadController.getQuotes";
import getQuoteIncludingRiders from "@salesforce/apex/ODALeadController.getQuoteIncludingRiders";
import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { levelTermCoverage, carriersWithProducts } from "c/odaConstants";

export default class OdaNewTerm extends LightningElement {
  @track loading = false;
  riders = [];

  @track rateTableVals = [];
  @track termLengths = [];
  @track selectedRate = {};
  @track selectedFaceAmount = 0;
  @track confirmedRates = [];
  @track confirmedTermLengths = [];

  @track selectedConfirmedRate = {};
  @track riskClassDetails;
  @track buildRiskClass;
  @track overrideRiskClass;

  _productOptions;
  @api product = "";
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
      let productName = this.isLevelTermProduct ? "levelterm" : this.product;
      this._productOptions = carriersWithProducts[this.carrier].products[productName];
    }
  }

  get hasNoSelectedFaceAmount() {
    return !this.selectedFaceAmount;
  }

  get isLaunchEappDisabled() {
    return !this.selectedConfirmedRate.amount;
  }

  get isLevelTermProduct() {
    return this.product.toLowerCase() == "term" || this.product.toLowerCase() == "term19";
  }

  get isSITermProduct() {
    return this.product.toLowerCase() == "siterm";
  }

  get sliderStep() {
    return !!this._productOptions
      ? this._productOptions.increaseStep * this._productOptions.multiplier
      : 1000;
  }

  get sliderMinValue() {
    if (!!this._productOptions) {
      if (this.isLevelTermProduct) {
        return Math.min(
          ...Object.keys(this.coverageOptions).map((key) => {
            return Math.min(...this.coverageOptions[key]);
          })
        );
      }
      return this._productOptions.minCoverageAmount * this._productOptions.multiplier;
    }
    return 0;
  }

  get sliderMaxValue() {
    if (!!this._productOptions) {
      if (this.isLevelTermProduct) {
        return Math.max(
          ...Object.keys(this.coverageOptions).map((key) => {
            return Math.max(...this.coverageOptions[key]);
          })
        );
      }
      return this._productOptions.maxCoverageAmount * this._productOptions.multiplier;
    }
    return 100;
  }

  get coverageOptions() {
    let result = {};
    Object.keys(levelTermCoverage).forEach((key) => {
      if (
        this.lead.Age__c >= levelTermCoverage[key].minAge &&
        this.lead.Age__c <= levelTermCoverage[key].maxAge
      ) {
        result[key] = levelTermCoverage[key].options;
      }
    });

    return result;
  }

  //METHODS

  fetchLevelTermRates(event) {
    this.clearConfirmedRates();
    this.confirmedTermLengths = [];
    this.termLengths = [];
    this.rateTableVals = [];
    this.selectedFaceAmount = 0;
    this.fetchRates(this.lead, this.product, event.detail.amounts, event.detail.riskClass);
  }

  onPriceSelection(event) {
    this.selectedRate = event.detail;
    this.selectedFaceAmount = this.selectedRate.amount;

    // reset confirmed rate
    this.selectedConfirmedRate = {};
  }

  onFaceAmountChange(event) {
    this.selectedFaceAmount = event.detail.value;
    this.clearConfirmedRates();
  }

  onConfirmQuote(_event) {
    this.loading = true;

    let riskClass = this.overrideRiskClass != undefined ? this.overrideRiskClass.code : null;

    if (riskClass === "RTD") {
      riskClass = riskClass + " " + this.overrideRiskClass.text.replace("Table ", "").trim();
    }

    let params = {
      lead: this.lead,
      product: this.product,
      termLengths: this.termLengths,
      faceAmount: this.selectedFaceAmount,
      riskClass: riskClass
    };
    getQuotes(params)
      .then((resultString) => {
        let results = JSON.parse(resultString);

        let amounts = Object.keys(results);
        this.confirmedRates = this.cloneArray(
          amounts.map((amount) => ({
            amount: amount,
            keyVal: Math.random(),
            rates: this.cloneArray(this.parseAmountRates(results[amount]))
          }))
        );

        this.confirmedTermLengths = this.cloneArray(
          results && amounts && amounts.length && results[amounts[0]]
            ? Object.keys(results[amounts[0]])
            : []
        );
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  onClickConfirmedRate(event) {
    this.selectedConfirmedRate = event.detail;
  }

  onLaunchEapp(_event) {
    if (!!this.riders && this.riders.length > 0) {
      (async () => {
        let newQuote = await this.generateNewQuoteIncludingRiders();
        let quoteToUpdate = this.confirmedRates.find(
          (q) => q.amount == this.selectedConfirmedRate.amount
        );
        let qIndex = quoteToUpdate.rates.findIndex(
          (r) => r.termLength == this.selectedConfirmedRate.termLength
        );

        quoteToUpdate.rates[qIndex].quoteId =
          newQuote[this.selectedConfirmedRate.amount][
            this.selectedConfirmedRate.termLength
          ].quote_id;

        this.selectedConfirmedRate.quoteId =
          newQuote[this.selectedConfirmedRate.amount][
            this.selectedConfirmedRate.termLength
          ].quote_id;

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
      quoteId: this.selectedConfirmedRate.quoteId,
      carrier: this.carrier,
      product: this.product,
      faceAmount: this.selectedConfirmedRate.amount
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

  handleLeadLoad() {
    if (this.isSITermProduct) {
      this.fetchRates(this.lead, this.product, []);
    }
  }

  fetchRates(lead, product, amounts, riskClass) {
    this.loading = true;

    let params = {
      lead: lead,
      product: product,
      amounts: amounts,
      riskClass: riskClass
    };

    if (!riskClass) {
      this.buildRiskClass = null;
      this.overrideRiskClass = null;
    }
    getRates(params)
      .then((result) => {
        let json_result = JSON.parse(result);

        this.parseRatesResponse(json_result);
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  clearConfirmedRates() {
    this.confirmedRates = this.cloneArray([]);
  }

  mapTermValues(amounts, termLength) {
    let rateDivider = this.isSITermProduct ? 12 : 1;

    let result = { termLength: termLength };

    if (
      amounts[termLength] == null ||
      (!this.isNullOrUndefined(amounts[termLength].error) &&
        amounts[termLength].error.startsWith("invalid term length for"))
    ) {
      result["price"] = "N/A - Aged Out";
      result["quoteId"] = "";
    } else {
      result["price"] = amounts[termLength].premium
        ? amounts[termLength].premium / 12
        : amounts[termLength] / rateDivider;

      result["quoteId"] = amounts[termLength].quote_id || "";
    }

    return result;
  }

  parseAmountRates(amountRates) {
    return Object.keys(amountRates).map((termLength) =>
      this.mapTermValues(amountRates, termLength)
    );
  }

  updateRiskClassDetails(raw_rates) {
    this.riskClassDetails = {
      overrideOptions: raw_rates["override_risk_class_options"],
      code: raw_rates["risk_class_code"],
      text: raw_rates["risk_class"]
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

  parseRatesResponse(raw_rates) {
    if (Object.values(raw_rates).filter((val) => val != null).length === 0) {
      return;
    }

    let amountMultiplier = this.isSITermProduct ? 1000 : 1;

    let amounts;
    let rawRates;

    if (raw_rates.hasOwnProperty("amounts")) {
      amounts = Object.keys(raw_rates["amounts"]);
      rawRates = raw_rates["amounts"];
      this.updateRiskClassDetails(raw_rates);
    } else {
      amounts = Object.keys(raw_rates);
      rawRates = raw_rates;
    }

    this.rateTableVals = this.cloneArray(
      amounts
        .filter((amount) => !!rawRates[amount])
        .map((amount) => {
          return {
            amount: amount * amountMultiplier,
            keyVal: Math.random(),
            rates: this.parseAmountRates(rawRates[amount])
          };
        })
    );

    this.termLengths =
      !raw_rates || !amounts || !amounts.length ? [] : this.validTermLengths(rawRates[amounts[0]]);
  }

  validTermLengths(amountRates) {
    let allTermLengths = this.cloneArray(Object.keys(amountRates));

    return allTermLengths.filter((term) => amountRates[term] > 0 || amountRates[term] == null);
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
      faceAmount: this.selectedConfirmedRate.amount,
      termLength: this.selectedConfirmedRate.termLength,
      riskClass: this.riskClass,
      riders: this.riders
    };
    this.loading = true;

    let parsedResult = await getQuoteIncludingRiders(params)
      .then((result) => {
        return JSON.parse(result);
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