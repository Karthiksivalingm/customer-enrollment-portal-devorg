/**
 * Reads and writes the Lead.Enrollment_People__c JSON:
 *   {"schemaVersion":1,"people":[{"id":"P01","firstName":...,"role":"AP"}, ...]}
 * "role" was added without a version change: older Leads have no "role" and may
 * have a free-text "jobTitle", which is read and preserved as is.
 * Parsing never throws; invalid data is reported through ParseResult.
 */
public with sharing class EnrollmentPeopleSerializer {
  public static final Integer SCHEMA_VERSION = 1;
  public static final Integer MAX_FIELD_LENGTH = 131072;

  private class Payload {
    public Integer schemaVersion;
    public List<EnrollmentPerson> people;
  }

  public class ParseResult {
    @AuraEnabled
    public Boolean valid = false;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public List<EnrollmentPerson> people = new List<EnrollmentPerson>();
  }

  public static String serialize(List<EnrollmentPerson> people) {
    Payload payload = new Payload();
    payload.schemaVersion = SCHEMA_VERSION;
    payload.people = new List<EnrollmentPerson>();
    for (EnrollmentPerson source : people) {
      EnrollmentPerson copy = new EnrollmentPerson();
      copy.id = source.id;
      copy.firstName = source.firstName;
      copy.lastName = source.lastName;
      copy.email = source.email;
      copy.phone = source.phone;
      copy.role = source.role;
      copy.jobTitle = source.jobTitle; // legacy value only; omitted when null
      payload.people.add(copy);
    }
    String value = JSON.serialize(payload, true);
    if (value.length() > MAX_FIELD_LENGTH) {
      throw new EnrollmentException(
        'The submitted people exceed the storage limit.'
      );
    }
    return value;
  }

  public static ParseResult parse(String value) {
    ParseResult result = new ParseResult();
    if (String.isBlank(value)) {
      result.message = 'No submitted people are stored on this Lead.';
      return result;
    }
    Payload payload;
    try {
      payload = (Payload) JSON.deserialize(value, Payload.class);
    } catch (Exception ex) {
      result.message = 'The submitted people data could not be read. Please contact your administrator.';
      return result;
    }
    if (payload == null || payload.schemaVersion != SCHEMA_VERSION) {
      result.message = 'The submitted people data uses an unsupported format. Please contact your administrator.';
      return result;
    }
    if (payload.people == null || payload.people.isEmpty()) {
      result.message = 'No submitted people are stored on this Lead.';
      return result;
    }
    Set<String> ids = new Set<String>();
    for (EnrollmentPerson person : payload.people) {
      if (
        person == null ||
        String.isBlank(person.id) ||
        ids.contains(person.id) ||
        String.isBlank(person.lastName) ||
        String.isBlank(person.email)
      ) {
        result.message = 'The submitted people data is incomplete. Please contact your administrator.';
        return result;
      }
      ids.add(person.id);
      person.roleLabel = person.titleForContact();
    }
    result.valid = true;
    result.people = payload.people;
    return result;
  }
}
