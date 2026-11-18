/**
 * Turns one enrollment form submission into exactly ONE Lead.
 * People are stored on the Lead as JSON (Enrollment_People__c).
 * No Account and no Contact is created here.
 *
 * Security: runs with sharing. The Lead is inserted in SYSTEM_MODE so the site
 * guest user needs no Lead permissions (see the note in submit()); only the
 * fields set in buildLead() are written. Responses never contain record data.
 */
public with sharing class EnrollmentSubmissionService {
  public static final Integer MAX_REQUEST_LENGTH = 64000;
  public static final Long MIN_FILL_MILLIS = 3000;
  public static final String GENERIC_FAILURE = 'We could not submit your enrollment. Please try again in a few minutes.';
  private static final Pattern UUID_PATTERN = Pattern.compile(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  );

  public class Result {
    @AuraEnabled
    public Boolean success = false;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public List<String> errors = new List<String>();
  }

  public static Result submit(String requestJson) {
    if (
      String.isBlank(requestJson) || requestJson.length() > MAX_REQUEST_LENGTH
    ) {
      return failure(
        'The enrollment could not be read. Please refresh the page and try again.'
      );
    }
    EnrollmentRequest request;
    try {
      request = (EnrollmentRequest) JSON.deserialize(
        requestJson,
        EnrollmentRequest.class
      );
    } catch (Exception ex) {
      return failure(
        'The enrollment could not be read. Please refresh the page and try again.'
      );
    }
    if (request == null) {
      return failure(
        'The enrollment could not be read. Please refresh the page and try again.'
      );
    }

    // Likely bots: report success without saving anything, so they learn nothing.
    if (
      String.isNotBlank(request.faxNumber) ||
      request.elapsedMs == null ||
      request.elapsedMs < MIN_FILL_MILLIS
    ) {
      return success();
    }
    if (
      request.submissionKey == null ||
      !UUID_PATTERN.matcher(request.submissionKey).matches()
    ) {
      return failure(
        'The enrollment could not be read. Please refresh the page and try again.'
      );
    }

    List<String> errors = EnrollmentValidator.validateSubmission(request);
    if (!errors.isEmpty()) {
      Result invalid = failure(
        'Please correct the following and submit again.'
      );
      invalid.errors = errors;
      return invalid;
    }

    // Retry / double click: the same submission was already saved.
    if (new SubmissionKeyLookup().exists(request.submissionKey.toLowerCase())) {
      return success();
    }

    // SECURITY REVIEW NOTE - SYSTEM_MODE insert (the class stays "with sharing").
    // Why: the site guest user has no Lead object/field permissions by design
    // (no Lead Read/Create/Edit/Delete), so a USER_MODE insert fails with
    // "Access to entity 'Lead' denied".
    // Scope: one insert of a Lead built entirely by buildLead() from a fixed list
    // of fields, after full server-side validation. The request is deserialized
    // into typed classes, so the browser cannot add or set any other Lead field.
    // Triggers, duplicate rules and the existing duplicate-email check still run.
    // No record id or error detail is returned to the caller.
    Lead lead = buildLead(request);
    Database.DMLOptions options = new Database.DMLOptions();
    options.DuplicateRuleHeader.allowSave = true; // duplicate-rule alerts must not block web submissions
    options.OptAllOrNone = false;
    Database.SaveResult saveResult = Database.insert(
      lead,
      options,
      AccessLevel.SYSTEM_MODE
    );
    if (saveResult.isSuccess()) {
      return success();
    }
    return handleInsertErrors(saveResult.getErrors());
  }

  public static Result genericFailure() {
    return failure(GENERIC_FAILURE);
  }

  @TestVisible
  private static Lead buildLead(EnrollmentRequest request) {
    EnrollmentRequest.Company company = request.company;
    String companyName = EnrollmentValidator.clean(company.companyName);
    List<EnrollmentPerson> people = normalizePeople(request.people);
    return new Lead(
      Company = companyName,
      // No person is "the Lead": the required LastName holds the company name.
      LastName = companyName.left(80),
      Website = EnrollmentValidator.clean(company.website),
      Email = EnrollmentValidator.clean(company.companyEmail),
      Phone = EnrollmentValidator.clean(company.companyPhone),
      Street = EnrollmentValidator.clean(company.street),
      City = EnrollmentValidator.clean(company.city),
      StateCode = EnrollmentValidator.clean(company.stateCode),
      CountryCode = EnrollmentValidator.clean(company.countryCode),
      PostalCode = EnrollmentValidator.clean(company.postalCode),
      LeadSource = 'Web',
      Enrollment_People__c = EnrollmentPeopleSerializer.serialize(people),
      Enrollment_Person_Count__c = people.size(),
      Enrollment_Submission_Key__c = request.submissionKey.toLowerCase(),
      Enrollment_Submitted_At__c = Datetime.now()
    );
  }

  /** Copies only the allowed person fields and assigns stable ids P01..P25. */
  private static List<EnrollmentPerson> normalizePeople(
    List<EnrollmentPerson> people
  ) {
    List<EnrollmentPerson> normalized = new List<EnrollmentPerson>();
    for (Integer i = 0; i < people.size(); i++) {
      EnrollmentPerson source = people[i];
      EnrollmentPerson person = new EnrollmentPerson();
      person.id = 'P' + String.valueOf(i + 1).leftPad(2, '0');
      person.firstName = EnrollmentValidator.clean(source.firstName);
      person.lastName = EnrollmentValidator.clean(source.lastName);
      person.email = EnrollmentValidator.clean(source.email);
      person.phone = EnrollmentValidator.clean(source.phone);
      person.role = EnrollmentValidator.clean(source.role);
      // jobTitle is legacy: new submissions use Role only, so any sent value is ignored.
      normalized.add(person);
    }
    return normalized;
  }

  private static Result handleInsertErrors(List<Database.Error> errors) {
    for (Database.Error err : errors) {
      String message = err.getMessage() == null ? '' : err.getMessage();
      Boolean keyField =
        (err.getFields() != null &&
        err.getFields().contains('Enrollment_Submission_Key__c')) ||
        message.contains('Enrollment_Submission_Key__c');
      if (err.getStatusCode() == StatusCode.DUPLICATE_VALUE && keyField) {
        return success(); // the same submission was already saved (retry or double click)
      }
      if (message.contains('Duplicate record found')) {
        // Existing LeadHandler trigger: a Lead with this email already exists.
        return failure(
          'An enrollment has already been received for this company email. Please contact us if you need to update it.'
        );
      }
      if (
        err.getStatusCode() == StatusCode.FIELD_INTEGRITY_EXCEPTION ||
        err.getStatusCode() ==
        StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST
      ) {
        return failure(
          'Please check the selected country and state / province.'
        );
      }
    }
    System.debug(
      LoggingLevel.ERROR,
      'Enrollment Lead insert failed: ' + describe(errors)
    );
    return genericFailure();
  }

  private static String describe(List<Database.Error> errors) {
    List<String> parts = new List<String>();
    for (Database.Error err : errors) {
      parts.add(err.getStatusCode() + ': ' + err.getMessage());
    }
    return String.join(parts, ' | ');
  }

  private static Result success() {
    Result result = new Result();
    result.success = true;
    result.message = 'Your enrollment has been submitted.';
    return result;
  }

  private static Result failure(String message) {
    Result result = new Result();
    result.success = false;
    result.message = message;
    return result;
  }

  /**
   * SECURITY REVIEW NOTE - the only "without sharing" code in the enrollment backend.
   * Why: guest users cannot see any Lead (secure guest record access), so they
   * cannot detect that their own retry was already saved, and the existing
   * LeadHandler duplicate-email trigger runs before the unique-key index.
   * Scope: one exact-match query on an unguessable UUID; returns only a Boolean;
   * no record data or ids ever leave this class.
   */
  private without sharing class SubmissionKeyLookup {
    public Boolean exists(String submissionKey) {
      return [
          SELECT COUNT()
          FROM Lead
          WHERE Enrollment_Submission_Key__c = :submissionKey
          WITH SYSTEM_MODE
        ] > 0;
    }
  }
}
