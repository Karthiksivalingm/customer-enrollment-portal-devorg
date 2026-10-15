({
  doInit: function (component, event) {
    if (
      event.getSource().getName != undefined &&
      event.getSource().getName() == "cOdaLumicoWholeLife"
    ) {
      // Skip reloading when refreshView is triggered from onLeadUpdated
      return;
    }

    component.set("v.validLead", false);

    component.set("v.product", "wl");

    // get lead info
    var action = component.get("c.getLeadInfo");
    action.setParam(component);
    $A.enqueueAction(action);
  },

  getLeadInfo: function (component) {
    component.set("v.leadLoaded", false);
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);

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