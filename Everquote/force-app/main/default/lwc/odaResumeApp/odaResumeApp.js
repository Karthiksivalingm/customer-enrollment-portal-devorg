import { LightningElement, api, track } from "lwc";
import openPreviousApplication from "@salesforce/apex/ODAEAppController.openPreviousApplication";
import loadPreviousApplications from "@salesforce/apex/ODAEAppController.loadPreviousApplications";
import { showToastNotification, toastVariant } from "c/fireNotification";
import { carriersWithProducts } from "c/odaConstants";

export default class OdaResumeApp extends LightningElement {
  @track loading = false;

  //EXTERNALLY AVAILABLE PROPS
  @api lead;
  @api mode = "";
  @api product = "";
  @api carrier = "";

  //PROPS
  tableMessageOverride = "";
  @track existingApps = [];
  @track selectedApp;

  //CONSTS
  tableMessageDefault = "No Application Loaded";
  tableMessageLoadFailure = "Failed to load previous application.";
  resumeAppFailure = "Failed to resume E-App.";

  _commonColumns = [
    {
      label: "Created Date",
      fieldName: "created_at",
      type: "date",
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Last App Page Seen",
      fieldName: "last_app_page_seen",
      type: "text",
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Face Amount",
      fieldName: "face_amount",
      type: "currency",
      typeAttributes: { currencyCode: "USD" },
      sortable: true,
      cellAttributes: { alignment: "left" }
    },
    {
      label: "Monthly Premium",
      fieldName: "monthly_premium",
      type: "currency",
      typeAttributes: { currencyCode: "USD" },
      sortable: true,
      cellAttributes: { alignment: "left" }
    }
  ];

  _columnsSife = [
    {
      label: "Rate Class",
      fieldName: "rate_class",
      type: "text",
      sortable: true,
      cellAttributes: { alignment: "left" }
    }
  ];
  _columnsTerm = [
    {
      label: "Term Length",
      fieldName: "term_length",
      type: "number",
      sortable: true,
      cellAttributes: { alignment: "left" }
    }
  ];

  get shouldDisplayTableMessage() {
    return this.tableMessage !== this.tableMessageDefault || !this.existingApps.length;
  }

  get tableMessage() {
    return this.tableMessageOverride && this.tableMessageOverride.length
      ? this.tableMessageOverride
      : this.tableMessageDefault;
  }

  get isResumePreviousAppDisabled() {
    return !this.selectedApp;
  }

  get resumeMessage() {
    let productName =
      this.product === "ad"
        ? `${carriersWithProducts[this.carrier].products[this.product].name} -`
        : "";
    return `${productName} Resume Previous Application`;
  }

  get columns() {
    if (this.mode === "term") {
      let commonColumns = Array.from(this._commonColumns);
      let lastCommon = commonColumns.pop();
      commonColumns = commonColumns.concat(this._columnsTerm);
      commonColumns.push(lastCommon);
      return commonColumns;
    } else if (this.mode == "sife") {
      return Array.from(this._commonColumns).concat(this._columnsSife);
    } else {
      return Array.from(this._commonColumns);
    }
  }

  //METHODS
  fetchPreviousApplication(_event) {
    this.loading = true;
    this.selectedApp = null;
    this.existingApps = [];

    loadPreviousApplications({
      lead: this.lead,
      carrier: this.carrier,
      product: this.product
    })
      .then((result) => {
        this.parsePreviousEAppsResponse(result);
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  onRowSelection(event) {
    let selectedRows = event.detail.selectedRows;
    if (selectedRows && selectedRows.length) {
      this.selectedApp = selectedRows[0];
    } else {
      this.selectedApp = null;
    }
  }

  onResumePreviousApp(_event) {
    this.loading = true;
    openPreviousApplication({
      lead: this.lead,
      carrier: this.carrier,
      product: this.product,
      quoteId: this.selectedApp.quote_id
    })
      .then((result) => {
        if (!result || result.error) {
          let errorMessage = !result ? this.resumeAppFailure : result.error;
          showToastNotification(this, "", errorMessage, toastVariant.error);
        } else {
        }

        this.openPreviousApp(result.app_url);
      })
      .catch((err) => {
        showToastNotification(this, "", err.body.message, toastVariant.error);
      })
      .finally(() => {
        this.loading = false;
      });
  }

  openPreviousApp(appUrl) {
    window.open(appUrl, "_blank", "location=yes,height=570,width=520,scrollbars=yes,status=yes");
  }

  parsePreviousEAppsResponse(result) {
    if (result.length === 0) {
      this.tableMessageOverride = "No Application Found";
    }

    let sortedDesc = result.sort((a, b) => {
      if (Date.parse(a.created_at) > Date.parse(b.created_at)) return -1;
      return Date.parse(a.created_at) < Date.parse(b.created_at) ? 1 : 0;
    });

    this.existingApps = this.cloneObject(sortedDesc);
  }

  parseEAppResponse(result) {}

  cloneObject(arr) {
    return JSON.parse(JSON.stringify(arr));
  }
}