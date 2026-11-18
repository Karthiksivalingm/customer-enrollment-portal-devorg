/**
 * Web-to-Lead enrollment channel. Before insert only.
 * Experience Cloud and ordinary Leads are skipped (see EnrollmentWebToLeadService).
 */
trigger EnrollmentWebToLeadTrigger on Lead(before insert) {
  EnrollmentWebToLeadService.beforeInsert(Trigger.new);
}
