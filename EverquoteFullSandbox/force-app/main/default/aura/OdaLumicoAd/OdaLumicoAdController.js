({
  doInit: function (component, event) {
    component.set("v.leadLoaded", false);
    component.set("v.validLead", false);
    component.set("v.userHasLifePermissions", false);
    component.set("v.permissionsLoaded", false);

    component.set("v.product", "ad");

    // verifyUserPermissions
    var verifyUserPermissionsAction = component.get("c.verifyUserPermissions");
    verifyUserPermissionsAction.setParam(component);
    $A.enqueueAction(verifyUserPermissionsAction);
  },

  verifyUserPermissions: function (component, event) {
    var action = component.get("c.userHasTheRightSkillsAndLicenses");

    action.setParams({
      leadId: component.get("v.recordId"),
      product: component.get("v.product")
    });
    action.setCallback(this, function (a) {
      let userHasLifePermissions = a.getReturnValue();
      component.set("v.userHasLifePermissions", userHasLifePermissions);
      component.set("v.permissionsLoaded", true);

      if (userHasLifePermissions) {
        // get lead info
        var getLeadInfoAction = component.get("c.getLeadInfo");
        getLeadInfoAction.setParam(component);
        $A.enqueueAction(getLeadInfoAction);
      }
    });
    $A.enqueueAction(action);
  },

  getLeadInfo: function (component) {
    // get lead info
    var action = component.get("c.findById");
    action.setParams({
      leadId: component.get("v.recordId")
    });
    action.setCallback(this, function (a) {
      let lead = a.getReturnValue();
      component.set("v.lead", lead);
      component.set("v.leadLoaded", true);

      let validAge = !!lead.Age__c && lead.Age__c >= 18 && lead.Age__c <= 59;
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