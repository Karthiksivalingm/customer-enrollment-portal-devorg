/**
 * Second enrollment channel: the Web-to-Lead enrollment form.
 *
 * The form posts the company to the standard Lead fields, the contacts JSON to
 * Enrollment_W2L_Payload__c (untrusted) and a UUID to Enrollment_Submission_Key__c.
 * Before the Lead is saved, this service validates everything with the same
 * EnrollmentValidator as the Experience Cloud channel, rebuilds the enrollment
 * fields itself (Enrollment_People__c through EnrollmentPeopleSerializer, schema v1),
 * labels the Lead "Web-to-Lead" and clears the payload. Invalid submissions are
 * rejected with addError, so no Lead is created.
 *
 * Leads without a payload or channel value are NOT processed, so Experience Cloud
 * enrollment Leads and ordinary Leads are left exactly as they are. The one
 * exception is the bypass guard (see rejectsDirectEnrollmentFields): in a
 * Web-to-Lead-like execution context, a Lead that carries enrollment fields but no
 * payload is rejected.
 *
 * SECURITY LIMITATION: Salesforce has no documented "Web-to-Lead" execution
 * context (there is no Web-to-Lead Quiddity value). The guard therefore uses
 * runtime facts that a form post cannot set (Quiddity, site network, user type),
 * not form fields. It has not been proven exclusive; see the technical documentation.
 */
public with sharing class EnrollmentWebToLeadService {
  public static final String CHANNEL = 'Web-to-Lead';
  public static final String LEAD_SOURCE = 'Web';
  public static final String REJECTED_PREFIX = 'Enrollment submission rejected: ';
  public static final String DIRECT_FIELDS_MESSAGE = 'Enrollment data must be submitted through the enrollment form payload.';
  /** Placeholder Web-to-Lead stores when a required standard field is not posted. */
  private static final String NOT_PROVIDED = '[not provided]';
  private static final Integer MAX_ERRORS_IN_MESSAGE = 10;
  private static final Pattern UUID_PATTERN = Pattern.compile(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  );

  /** Tests cannot run in the Web-to-Lead context; this lets them exercise the guard. */
  @TestVisible
  private static Boolean simulateWebToLeadContext = false;

  /** Shape of the posted payload: the existing schema v1 envelope. Unknown properties are ignored. */
  private class Payload {
    public Integer schemaVersion;
    public List<EnrollmentPerson> people;
  }

  public static void beforeInsert(List<Lead> leads) {
    Boolean webToLeadContext;
    for (Lead lead : leads) {
      if (isWebToLeadSubmission(lead)) {
        process(lead);
      } else if (hasEnrollmentData(lead)) {
        if (webToLeadContext == null) {
          webToLeadContext = isWebToLeadContext();
        }
        if (webToLeadContext) {
          // Bypass attempt: enrollment fields posted directly, without the payload.
          lead.addError(REJECTED_PREFIX + DIRECT_FIELDS_MESSAGE);
        }
      }
      // Anything else (Experience Cloud and ordinary Leads) is not touched.
    }
  }

  /** A Lead the Web-to-Lead form created: it carries the payload (or the channel label). */
  private static Boolean isWebToLeadSubmission(Lead lead) {
    return String.isNotBlank(lead.Enrollment_W2L_Payload__c) ||
      lead.Enrollment_Channel__c == CHANNEL;
  }

  private static Boolean hasEnrollmentData(Lead lead) {
    return String.isNotBlank(lead.Enrollment_Submission_Key__c) ||
      String.isNotBlank(lead.Enrollment_People__c) ||
      lead.Enrollment_Person_Count__c != null ||
      lead.Enrollment_Submitted_At__c != null;
  }

  /**
   * Best available server-side signal for a Web-to-Lead insert: a synchronous or
   * undefined request, outside any Experience site, not run by a guest user.
   * Experience Cloud submissions run in a site (network set, guest or site user);
   * the Lightning UI, APIs, anonymous Apex and tests have their own Quiddity values.
   */
  @TestVisible
  private static Boolean isWebToLeadContext() {
    if (simulateWebToLeadContext) {
      return true;
    }
    Quiddity context = Request.getCurrent().getQuiddity();
    Boolean webLikeContext =
      context == null ||
      context == Quiddity.SYNCHRONOUS ||
      context == Quiddity.UNDEFINED;
    return webLikeContext &&
      Network.getNetworkId() == null &&
      UserInfo.getUserType() != 'Guest';
  }

  private static void process(Lead lead) {
    List<String> errors = new List<String>();
    EnrollmentRequest request = buildRequest(lead, errors);
    if (errors.isEmpty()) {
      errors.addAll(EnrollmentValidator.validateSubmission(request));
    }
    String peopleJson;
    if (errors.isEmpty()) {
      try {
        peopleJson = EnrollmentPeopleSerializer.serialize(request.people);
      } catch (EnrollmentException ex) {
        errors.add(ex.getMessage());
      }
    }
    if (!errors.isEmpty()) {
      lead.addError(REJECTED_PREFIX + summarize(errors));
      return;
    }

    EnrollmentRequest.Company company = request.company;
    // Same values the Experience Cloud channel writes; everything posted for these
    // fields is replaced by validated, server-built values.
    lead.Company = company.companyName;
    lead.LastName = company.companyName.left(80);
    lead.Website = company.website;
    lead.Email = company.companyEmail;
    lead.Phone = company.companyPhone;
    lead.Street = company.street;
    lead.City = company.city;
    lead.StateCode = company.stateCode;
    lead.CountryCode = company.countryCode;
    lead.PostalCode = company.postalCode;
    lead.LeadSource = LEAD_SOURCE;
    lead.Enrollment_People__c = peopleJson;
    lead.Enrollment_Person_Count__c = request.people.size();
    lead.Enrollment_Submission_Key__c = request.submissionKey.toLowerCase();
    lead.Enrollment_Submitted_At__c = Datetime.now();
    lead.Enrollment_Channel__c = CHANNEL;
    lead.Enrollment_W2L_Payload__c = null;
  }

  /** Builds the typed request the existing validator expects. Adds structural errors. */
  private static EnrollmentRequest buildRequest(
    Lead lead,
    List<String> errors
  ) {
    EnrollmentRequest request = new EnrollmentRequest();

    String key = EnrollmentValidator.clean(lead.Enrollment_Submission_Key__c);
    if (key == null) {
      errors.add('Submission key is required.');
    } else if (!UUID_PATTERN.matcher(key).matches()) {
      errors.add('Submission key is not valid.');
    }
    request.submissionKey = key;

    EnrollmentRequest.Company company = new EnrollmentRequest.Company();
    company.companyName = withoutPlaceholder(lead.Company);
    company.website = EnrollmentValidator.clean(lead.Website);
    company.companyEmail = EnrollmentValidator.clean(lead.Email);
    company.companyPhone = EnrollmentValidator.clean(lead.Phone);
    company.street = EnrollmentValidator.clean(lead.Street);
    company.city = EnrollmentValidator.clean(lead.City);
    company.stateCode = EnrollmentValidator.clean(lead.StateCode);
    company.countryCode = EnrollmentValidator.clean(lead.CountryCode);
    company.postalCode = EnrollmentValidator.clean(lead.PostalCode);
    request.company = company;

    request.people = readPeople(lead.Enrollment_W2L_Payload__c, errors);
    return request;
  }

  /** Reads the untrusted payload into typed people, then keeps only the allowed fields. */
  private static List<EnrollmentPerson> readPeople(
    String payloadJson,
    List<String> errors
  ) {
    if (String.isBlank(payloadJson)) {
      errors.add('Contacts are missing.');
      return null;
    }
    Payload payload;
    try {
      payload = (Payload) JSON.deserialize(payloadJson, Payload.class);
    } catch (Exception ex) {
      errors.add('Contacts could not be read.');
      return null;
    }
    if (
      payload == null ||
      payload.schemaVersion != EnrollmentPeopleSerializer.SCHEMA_VERSION
    ) {
      errors.add('Contacts use an unsupported format.');
      return null;
    }
    List<EnrollmentPerson> people = payload.people == null
      ? new List<EnrollmentPerson>()
      : payload.people;
    if (people.size() < EnrollmentValidator.MIN_SUBMISSION_CONTACTS) {
      errors.add(
        'At least ' +
          EnrollmentValidator.MIN_SUBMISSION_CONTACTS +
          ' contacts are required.'
      );
      return null;
    }
    if (people.size() > EnrollmentValidator.MAX_PEOPLE) {
      errors.add(
        'A maximum of ' +
          EnrollmentValidator.MAX_PEOPLE +
          ' contacts can be submitted.'
      );
      return null;
    }
    return normalizePeople(people);
  }

  /**
   * Copies only the contact fields the Experience channel stores and assigns the
   * server ids P01..P25. Posted ids, jobTitle, contactId and anything else are dropped.
   */
  private static List<EnrollmentPerson> normalizePeople(
    List<EnrollmentPerson> people
  ) {
    List<EnrollmentPerson> normalized = new List<EnrollmentPerson>();
    for (Integer i = 0; i < people.size(); i++) {
      EnrollmentPerson source = people[i];
      if (source == null) {
        normalized.add(null); // reported by the validator as "details are missing"
        continue;
      }
      EnrollmentPerson person = new EnrollmentPerson();
      person.id = 'P' + String.valueOf(i + 1).leftPad(2, '0');
      person.firstName = EnrollmentValidator.clean(source.firstName);
      person.lastName = EnrollmentValidator.clean(source.lastName);
      person.email = EnrollmentValidator.clean(source.email);
      person.phone = EnrollmentValidator.clean(source.phone);
      person.role = EnrollmentValidator.clean(source.role);
      normalized.add(person);
    }
    return normalized;
  }

  private static String withoutPlaceholder(String value) {
    String cleaned = EnrollmentValidator.clean(value);
    return cleaned == NOT_PROVIDED ? null : cleaned;
  }

  private static String summarize(List<String> errors) {
    List<String> shown = new List<String>();
    for (Integer i = 0; i < errors.size() && i < MAX_ERRORS_IN_MESSAGE; i++) {
      shown.add(errors[i]);
    }
    if (errors.size() > MAX_ERRORS_IN_MESSAGE) {
      shown.add('(' + (errors.size() - MAX_ERRORS_IN_MESSAGE) + ' more)');
    }
    return String.join(shown, ' ');
  }
}
