/**
 * Apex entry points for the Convert Enrollment screen (c-enrollment-convert-modal).
 */
public with sharing class EnrollmentConversionController {
  @AuraEnabled
  public static EnrollmentConversionService.Preview getConversionPreview(
    Id leadId
  ) {
    try {
      return EnrollmentConversionService.getPreview(leadId);
    } catch (Exception ex) {
      throw toAuraException(ex);
    }
  }

  @AuraEnabled
  public static EnrollmentConversionService.Result convertEnrollment(
    Id leadId,
    String requestJson
  ) {
    try {
      return EnrollmentConversionService.convert(leadId, requestJson);
    } catch (Exception ex) {
      throw toAuraException(ex);
    }
  }

  private static AuraHandledException toAuraException(Exception ex) {
    // Expected problems keep their message; platform errors are prefixed (DML: first error only).
    String detail = ex instanceof DmlException
      ? ((DmlException) ex).getDmlMessage(0)
      : ex.getMessage();
    String message = ex instanceof EnrollmentException
      ? detail
      : 'The enrollment could not be converted: ' + detail;
    System.debug(
      LoggingLevel.ERROR,
      'Enrollment conversion error: ' +
        ex.getTypeName() +
        ': ' +
        ex.getMessage()
    );
    AuraHandledException auraEx = new AuraHandledException(message);
    auraEx.setMessage(message);
    return auraEx;
  }
}
