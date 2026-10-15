({
  doInit: function (component, event) {
    if (event.getSource().getName != undefined && event.getSource().getName() == "cODALevelTerm") {
      // Skip reloading
      return;
    }
    component.set("v.leadLoaded", false);
    component.set("v.validLead", false);

    // get lead info
    var action = component.get("c.getLeadInfo");
    action.setParam(component);
    $A.enqueueAction(action);
  },

  getLeadInfo: function (component) {
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);

      if (
        !!lead.State &&
        ["DE", "MT", "ND", "SD", "FL", "CA"].indexOf(lead.State.toUpperCase()) != -1
      ) {
        component.set("v.product", "term");
      } else {
        component.set("v.product", "term19");
      }

      // validate lead age
      var action = component.get("c.validateLeadAge");
      action.setParam(component);
      $A.enqueueAction(action);
    });
    $A.enqueueAction(action);
  },

  validateLeadAge: function (component, event) {
    let lead = component.get("v.lead");

    let validAge =
      !!lead.Age__c &&
      lead.Age__c >= component.get("v.minAge") &&
      lead.Age__c <= component.get("v.maxAge");

    component.set("v.validAge", validAge);
  },

  onLeadUpdated: function (component, event) {
    component.set("v.lead", event.getParam("lead"));

    // validate lead age
    var action = component.get("c.validateLeadAge");
    action.setParam(component);
    $A.enqueueAction(action);

    $A.get("e.force:refreshView").fire();
  },

  onValidateLead: function (component, event, helper) {
    component.set("v.validLead", event.getParam("valid"));
  }
});