({
  doInit: function (component, event) {
    component.set("v.product", "siterm");
    component.set("v.leadLoaded", false);
    component.set("v.validLead", false);

    // get lead info
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);

      let validAge = !!lead.Age__c && lead.Age__c >= 18 && lead.Age__c <= 65;
      component.set("v.validAge", validAge);
    });
    $A.enqueueAction(action);
  },

  onLeadUpdated: function (component, event) {
    component.set("v.lead", event.getParam("lead"));
    $A.get("e.force:refreshView").fire();
  },
  onValidateLead: function (component, event, helper) {
    component.set("v.validLead", event.getParam("valid"));
  }
});