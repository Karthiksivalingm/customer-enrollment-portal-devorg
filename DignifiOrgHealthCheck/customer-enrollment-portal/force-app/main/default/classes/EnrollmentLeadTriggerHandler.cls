/**
 * Blocks standard Lead conversion (Convert button, API) for enrollment Leads,
 * because it would create only one Contact. Enrollment Leads must be converted
 * through EnrollmentConversionService. Non-enrollment Leads are not affected.
 */
public with sharing class EnrollmentLeadTriggerHandler {
  public static final String BLOCK_MESSAGE = 'Enrollment Leads must be converted with the Convert Enrollment button so that every submitted person becomes a Contact.';

  public static void beforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeads) {
    if (EnrollmentConversionService.isConversionInProgress()) {
      return;
    }
    for (Lead lead : newLeads) {
      Lead previous = oldLeads.get(lead.Id);
      if (
        lead.IsConverted &&
        previous != null &&
        !previous.IsConverted &&
        String.isNotBlank(lead.Enrollment_Submission_Key__c)
      ) {
        lead.addError(BLOCK_MESSAGE);
      }
    }
  }
}
