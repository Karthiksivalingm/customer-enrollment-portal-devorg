({
  doInit: function (component, event) {
    component.set("v.leadLoaded", false);

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

      let validAge =
        !!lead.Age__c &&
        lead.Age__c >= component.get("v.minAge") &&
        lead.Age__c <= component.get("v.maxAge");
      component.set("v.validAge", validAge);

      component.set("v.leadLoaded", true);
    });
    $A.enqueueAction(action);
  },

  onLeadUpdated: function (component, event) {
    component.set("v.lead", event.getParam("lead"));

    $A.get("e.force:refreshView").fire();
  }
});