({
  doInit: function (component, event, helper) {
    var newLifeLead = {
      sobjectType: "Lead",
      FirstName: "",
      LastName: "",
      Gender__c: "",
      Date_of_Birth__c: "",
      State: "",
      Phone: "",
      Email: "",
      Major_Condition_Past_Year__c: "",
      Oda_New_Lead_Source__c: ""
    };

    component.set("v.leadSaving", false);
    component.set("v.errorMessages", []);
    component.set("v.newLifeLead", newLifeLead);

    // get lead info
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      var errors = a.getError();
      if (errors.length > 0) {
        return;
      }

      let lead = a.getReturnValue();
      helper.originalLead.Email = lead.Email;
      helper.originalLead.Phone = helper.formatPhone(lead.Phone);
      helper.originalLead.Street = lead.Street;
      helper.originalLead.State = lead.State;
      helper.originalLead.City = lead.City;
      helper.originalLead.PostalCode = lead.PostalCode;
      helper.originalLead.OriginalEqLeadUuid__c = lead.EqLeadUuid__c;

      component.set("v.newLifeLead", newLifeLead);
    });
    $A.enqueueAction(action);
  },

  saveNewLead: function (component, event, helper) {
    var lead = component.get("v.newLifeLead");
    lead.Phone = helper.formatPhone(lead.Phone);

    lead.Status = "Contacted";
    lead.LeadSource = "Referral";
    lead.OriginalEqLeadUuid__c = helper.originalLead.OriginalEqLeadUuid__c;

    var validationErrors = helper.validateLeadData(lead);
    if (validationErrors.length > 0) {
      helper.showErrors(validationErrors);
      return;
    }

    component.set("v.leadSaving", true);

    var action = component.get("c.createNewLifeLead");
    // action.setParams({ newLifeLead: component.get("v.newLifeLead") });
    action.setParams({ newLifeLead: lead });
    action.setCallback(this, function (result) {
      component.set("v.leadSaving", false);

      var apiErrors = result.getError();
      var apiErrorStrs = [];
      if (apiErrors.length > 0) {
        apiErrors.forEach(apiError => {
          if (apiError.fieldErrors) {
            var fieldErrors = apiError.fieldErrors;
            for (var prop in fieldErrors) {
              if (fieldErrors.hasOwnProperty(prop)) {
                apiErrorStrs.push(fieldErrors[prop][0].message + ". ");
              }
            }
          } else if (apiError.message && apiError.stackTrace) {
            apiErrorStrs.push(apiError.message + " - " + apiError.stackTrace + ". ");
          }
        })

        helper.showErrors(apiErrorStrs);
        return;
      }

      var leadId = result.getReturnValue();
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        recordId: leadId,
        slideDevName: "related"
      });
      navEvt.fire();
    });
    $A.enqueueAction(action);
  },

  onLeadSourceChange: function (component, event, helper) {
    // Event handler for change in lead source. 
    // Retains values already entered in the form when the lead source selection changes,
    // except when the referral option is selected, in which case the address, phone number 
    // and email address are changed to the that of the referral lead. 
    var newLifeLead = component.get("v.newLifeLead");
    var selectedValue = event.getSource().get('v.value')
    if (selectedValue == "Referral from this lead") {
      helper.originalLead.Oda_New_Lead_Source__c = newLifeLead.Oda_New_Lead_Source__c;
      newLifeLead = helper.originalLead
    }
    component.set("v.newLifeLead", newLifeLead);
  }
});