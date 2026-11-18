/**
 * Entry point for the public enrollment form (c-enrollment-form).
 * Returns only a success flag and messages - never record ids or record data.
 */
public with sharing class EnrollmentSubmissionController {
  @AuraEnabled
  public static EnrollmentSubmissionService.Result submitEnrollment(
    String requestJson
  ) {
    try {
      return EnrollmentSubmissionService.submit(requestJson);
    } catch (Exception ex) {
      System.debug(
        LoggingLevel.ERROR,
        'Enrollment submission error: ' +
          ex.getTypeName() +
          ': ' +
          ex.getMessage()
      );
      return EnrollmentSubmissionService.genericFailure();
    }
  }

  /** Country and state options from the org's State and Country Picklists (schema data only). */
  @AuraEnabled(cacheable=true)
  public static List<EnrollmentAddressOptions.Option> getCountryOptions() {
    return EnrollmentAddressOptions.getCountries();
  }
}
