({
  getFEComparisonLink: function (component) {
    if (component.get("v.validLead")) {
      let eqLeadUuid = component.get("v.lead.EqLeadUuid__c");

      var action = component.get("c.getFEComparisonToolUrl");
      action.setParams({
        age: component.get("v.lead.Age__c"),
        gender: component.get("v.lead.Gender__c"),
        tobacco: component.get("v.lead.Use_Tobacco__c"),
        eqLeadUuid: eqLeadUuid
      });

      component.set("v.leadLoaded", false);

      action.setCallback(this, function (a) {
        let comparisonToolUrl = a.getReturnValue();

        component.set("v.comparisonToolUrl", comparisonToolUrl);
        component.set("v.leadLoaded", true);
      });

      if (eqLeadUuid == null) {
        component.set(
          "v.errorMessage",
          "Invalid value for Lead Eq Lead Uuid. Please contact your supervisor."
        );
      } else {
        $A.enqueueAction(action);
      }
    }
  }
});