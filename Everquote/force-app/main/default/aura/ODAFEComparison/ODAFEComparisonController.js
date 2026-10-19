({
  doInit: function (component, event) {
    component.set("v.leadLoaded", false);
    component.set("v.validLead", false);
    component.set("v.errorMessage", null);
    component.set("v.comparisonToolUrl", null);

    // get lead info
    var action = component.get("c.getLeadInfo");
    action.setParam(component);
    $A.enqueueAction(action);
  },

  getLeadInfo: function (component, event, helper) {
    var action = component.get("c.findById");

    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();

      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);

      let validAge = !!lead.Age__c && lead.Age__c >= 50 && lead.Age__c <= 80;
      component.set("v.validAge", validAge);

      helper.getFEComparisonLink(component);
    });
    $A.enqueueAction(action);
  },

  onLeadUpdated: function (component, event) {
    component.set("v.lead", event.getParam("lead"));
    $A.get("e.force:refreshView").fire();
  },

  onValidateLead: function (component, event, helper) {
    component.set("v.validLead", event.getParam("valid"));
    helper.getFEComparisonLink(component);
  },

  openComparisonTool: function (component, event, helper) {
    let comparisonToolUrl = component.get("v.comparisonToolUrl");
    window.open(comparisonToolUrl, "FE Comparison Tool");
  }
});