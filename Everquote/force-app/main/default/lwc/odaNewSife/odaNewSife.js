import { LightningElement, api, track } from "lwc";
import getQuotes from "@salesforce/apex/ODALeadController.getQuotes";
import getRates from "@salesforce/apex/ODALeadController.getRates";
import getEApp from "@salesforce/apex/ODAEAppController.getEApp";
import getQuoteIncludingRiders from "@salesforce/apex/ODALeadController.getQuoteIncludingRiders";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { sifeRiskClassFaceAmounts } from "c/odaConstants";

export default class OdaNewSife extends LightningElement {
  @track loading = false;
  riders = [];

  @api lead;
  @track quotes = [];
  @track confirmedQuotes = [];
  @track selectedQuote = null;
  @track selectedConfirmedQuote = null;
  @track selectedFaceAmount = 0;
  @track riskClass = "";

  @track product = "sife";

  @track sliderMaxValue = 5000;

  carrier = "lumico";
  startAppFailure = "Failed to start E-App.";
  maxRowSelection = 1;
  riskClasses = [
    { value: "Preferred", label: "Preferred" },
    { value: "Standard", label: "Standard" },
    { value: "Modified", label: "Modified" }
  ];
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

  get hasNoQuotes() {
    return !this.quotes || !this.quotes.length;
  }

  get hasNoSelectedQuote() {
    return !this.selectedQuote;
  }

  get hasNoConfirmedQuotes() {
    return !this.confirmedQuotes || !this.confirmedQuotes.length;
  }

  get hasSelectedConfirmedQuote() {
    return !!this.selectedConfirmedQuote;
  }

  get isLaunchEappDisabled() {
    return !this.hasSelectedConfirmedQuote;
  }

  //METHODS

  calculateSliderMaxValue() {
    let options = sifeRiskClassFaceAmounts[this.riskClass].options;

    options.forEach((option) => {
      if (option.minAge <= this.lead.Age__c && this.lead.Age__c <= option.maxAge) {
        this.sliderMaxValue = option.maxFaceAmount;
      }
    });
  }

  onRiskClassChange(event) {
    this.loading = true;

    this.clearConfirmedQuotes();
    this.quotes = this.cloneArray([]);
    this.riskClass = event.detail.value;
    this.calculateSliderMaxValue();

    if (this.riskClass == "Preferred" && this.lead.Age__c > 80) {
      showToastNotification(this, "", "No rate found for those parameters", toastVariant.error);
      this.loading = false;
      return;
    }

    getRates({
      lead: this.lead,
      product: this.product,
      riskClass: this.riskClass
    })
      .then((results) => {
        let parsedResults = JSON.parse(results);
        let processedResults = this.formatQuotesOrRates(parsedResults);

        this.quotes = this.cloneArray(processedResults.quotes);
      })
      .catch((err) => {
        showToastNotification(this, "", this.errorMessage(err), toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  onQuoteRowSelection(event) {
    let selectedRows = event.detail.selectedRows;
    this.selectedQuote = selectedRows && selectedRows.length ? selectedRows[0] : null;
    this.selectedFaceAmount = !this.selectedQuote ? 0 : this.selectedQuote.faceAmount;
  }

  onFaceAmountChange(event) {
    this.clearConfirmedQuotes();
    this.selectedFaceAmount = event.detail.value;
  }

  onConfirmQuote(event) {
    this.loading = true;
    getQuotes({
      lead: this.lead,
      product: this.product,
      faceAmount: this.selectedFaceAmount,
      riskClass: this.riskClass
    })
      .then((results) => {
        let parsedResults = JSON.parse(results);
        let formattedResults = this.formatQuotesOrRates(parsedResults);

        let errors = this.quotesWithErrors(formattedResults.quotes);
        if (errors.length) {
          this.showQuotesErrors(errors);
        } else {
          this.confirmedQuotes = this.cloneArray(formattedResults.quotes);
        }
      })
      .catch((err) => {
        showToastNotification(this, "", this.errorMessage(err), toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  onConfirmedQuoteSelection(event) {
    let selectedRows = event.detail.selectedRows;

    this.selectedConfirmedQuote = selectedRows && selectedRows.length ? selectedRows[0] : null;
  }

  onLaunchEapp(event) {
    if (!!this.riders && this.riders.length > 0) {
      (async () => {
        let newQuote = await this.generateNewQuoteIncludingRiders();
        let formattedResult = this.formatQuotesOrRates(newQuote);

        if (formattedResult.error && formattedResult.error.length) {
          showToastNotification(this, "", formattedResult.error[0], toastVariant.error);
        } else {
          let newQuote = formattedResult.quotes[0];
          this.updateSelectedConfirmedQuote(newQuote.faceAmount, newQuote);

          this.launchEapp();
        }
      })();
    } else {
      this.launchEapp();
    }
  }

  launchEapp() {
    this.loading = true;
    getEApp({
      lead: this.lead,
      quoteId: this.selectedConfirmedQuote.quoteId,
      faceAmount: this.selectedConfirmedQuote.faceAmount,
      carrier: this.carrier,
      product: this.product
    })
      .then((result) => {
        if (!result || result.error) {
          showToastNotification(
            this,
            "",
            !result ? this.startAppFailure : result.error,
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

  async generateNewQuoteIncludingRiders() {
    let params = {
      lead: this.lead,
      product: this.product,
      faceAmount: this.selectedConfirmedQuote.faceAmount,
      riskClass: this.riskClass,
      riders: this.riders
    };

    this.loading = true;
    let parsedResult = await getQuoteIncludingRiders(params)
      .then((result) => {
        return JSON.parse(result);
      })
      .catch((err) => {
        showToastNotification(this, "", this.errorMessage(err), toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
    return parsedResult;
  }

  updateSelectedConfirmedQuote(faceAmount, newQuote) {
    let oldQuoteIndex = this.confirmedQuotes.findIndex((q) => q.faceAmount === faceAmount);

    this.confirmedQuotes[oldQuoteIndex] = newQuote;
    this.selectedConfirmedQuote.quoteId = newQuote.quoteId;
  }

  formatQuotesOrRates(quoteItems) {
    let formattedQuotes = Object.keys(quoteItems).map((option) => {
      let parsed =
        typeof quoteItems[option] === "string"
          ? JSON.parse(quoteItems[option])
          : quoteItems[option];
      return {
        faceAmount: option,
        monthlyPremium: parsed.premium ? parsed.premium / 12 : null,
        annualPremium: parsed.premium,
        quoteId: !parsed.quote_id ? Math.random() + "_key" : parsed.quote_id,
        quoteError: parsed.error
      };
    });

    formattedQuotes.sort((a, b) => a.faceAmount - b.faceAmount);

    return {
      quotes: formattedQuotes
    };
  }

  handleRidersChange(event) {
    this.riders = event.detail.riders
      .filter((rider) => !!rider.rateParams && !!rider.rateParams.rider)
      .map((rider) => rider.rateParams.rider);
  }

  clearConfirmedQuotes() {
    this.confirmedQuotes = this.cloneArray([]);
  }

  cloneArray(arr) {
    return JSON.parse(JSON.stringify(arr));
  }

  errorMessage(err) {
    return err.body && err.body.message ? err.body.message : err;
  }

  quotesWithErrors(quotes) {
    return quotes
      .filter((quote) => quote.quoteError && quote.quoteError.length)
      .map((quote) => quote);
  }

  showQuotesErrors(quotesErrors) {
    quotesErrors.forEach((quote) => {
      let errorMessage = `Error while processing quote with face amount ${quote.faceAmount}:  ${quote.quoteError}`;
      showToastNotification(this, "", errorMessage, toastVariant.error);
    });
  }
}