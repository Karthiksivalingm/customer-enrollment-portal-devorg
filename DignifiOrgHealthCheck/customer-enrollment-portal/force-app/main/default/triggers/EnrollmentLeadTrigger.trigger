trigger EnrollmentLeadTrigger on Lead(before update) {
  EnrollmentLeadTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
}
