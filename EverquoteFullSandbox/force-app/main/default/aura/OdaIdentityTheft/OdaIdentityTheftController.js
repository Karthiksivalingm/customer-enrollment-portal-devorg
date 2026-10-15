({
  doInit: function (component, event) {
    // get lead info
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);
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