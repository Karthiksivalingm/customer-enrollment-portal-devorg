({
  doInit: function (component, event) {
    component.set("v.quotes", []);
    component.set("v.quoteAvailable", false);
    component.set("v.errorMessages", []);
    component.set("v.quoteLoading", false);

    component.set("v.columns", [
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
    ]);

    component.set("v.resumeColumns", [
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
      },
      {
        label: "Annual Premium",
        fieldName: "yearly_premium",
        type: "currency",
        typeAttributes: { currencyCode: "USD" },
        sortable: true,
        cellAttributes: { alignment: "left" }
      }
    ]);

    // get lead info
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
    });
    $A.enqueueAction(action);
  },

  updateSelectedQuote: function (component, event) {
    // only one row should be selected
    var selectedRows = event.getParam("selectedRows");
    component.set("v.selectedQuote", selectedRows[0]);
    component.set("v.quoteAvailable", true);
  },

  updateSelectedApplication: function (component, event) {
    let selectedRows = event.getParam("selectedRows");
    component.set("v.selectedApplication", selectedRows[0]);
  },

  fetchPreviousApplication: function (component, event) {
    let button = event.getSource();
    button.set("v.disabled", true);
    component.set("v.quoteLoading", true);

    let action = component.get("c.loadPreviousApplication");
    action.setParams({
      lead: component.get("v.lead"),
      product: "sife"
    });
    action.setCallback(this, function (result) {
      let eApp = !result.getReturnValue() ? {} : JSON.parse(result.getReturnValue());
      if (eApp.error) {
        component.set("v.errorMessages", [eApp.error]);
      }

      if (!eApp.app_id) {
        component.set("v.appFetchMessage", "No Application Found");
      } else {
        component.set("v.existingApplications", [eApp]);
        if (eApp.authorization_played) {
          component.set("v.authorizationImplied", true);
        }
      }
      component.set("v.quoteLoading", false);
    });
    $A.enqueueAction(action);
  },

  quoteCall: function (component, event, helper) {
    var button = event.getSource();

    button.set("v.disabled", true);
    component.set("v.quoteLoading", true);

    var action = component.get("c.getQuotes");
    action.setParams({
      lead: component.get("v.lead"),
      product: "sife"
    });
    action.setCallback(this, function (a) {
      let rawQuotes = JSON.parse(a.getReturnValue());
      helper.quoteFormatter(component, event, helper, rawQuotes);
      button.set("v.disabled", false);
      component.set("v.quoteLoading", false);
    });
    $A.enqueueAction(action);
  },

  eAppCall: function (component, event, helper) {
    var button = event.getSource();
    button.set("v.disabled", true);

    var action = component.get("c.getEApp");
    action.setParams({
      lead: component.get("v.lead"),
      quoteId: component.get("v.selectedQuote").quoteId,
      faceAmount: component.get("v.selectedQuote").faceAmount,
      product: "sife",
      bypassUpdate: false
    });
    action.setCallback(this, function (a) {
      $A.get("e.force:refreshView").fire();

      let eApp = a.getReturnValue();
      if (eApp.error) {
        component.set("v.errorMessages", [eApp.error]);
      }
      component.set("v.eApp", eApp);
      window.open(
        component.get("v.eApp.app_url"),
        "_blank",
        "location=yes,height=570,width=520,scrollbars=yes,status=yes"
      );
    });
    $A.enqueueAction(action);
  },

  eAppResumeCall: function (component, event, helper) {
    var button = event.getSource();
    button.set("v.disabled", true);

    var action = component.get("c.resumeEApp");
    action.setParams({
      lead: component.get("v.lead"),
      product: "sife"
    });
    action.setCallback(this, function (a) {
      let eApp = JSON.parse(a.getReturnValue());
      if (eApp.error) {
        component.set("v.errorMessages", [eApp.error]);
      }
      component.set("v.eApp", eApp);
      window.open(
        component.get("v.eApp.app_url"),
        "_blank",
        "location=yes,height=570,width=520,scrollbars=yes,status=yes"
      );
      button.set("v.disabled", false);
    });
    $A.enqueueAction(action);
  }
});