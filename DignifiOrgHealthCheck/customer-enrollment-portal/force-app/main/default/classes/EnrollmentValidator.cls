/**
 * Server-side validation shared by enrollment submission and conversion.
 * Mirrors the enrollment form rules; the client-side checks are never trusted.
 * Max lengths match the standard Lead/Account/Contact fields.
 */
public with sharing class EnrollmentValidator {
  public static final Integer MAX_PEOPLE = 25;
  /** Enrollment submissions must include at least this many contacts. */
  public static final Integer MIN_SUBMISSION_CONTACTS = 2;

  private static final Pattern EMAIL_PATTERN = Pattern.compile(
    '^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$'
  );
  private static final Pattern PHONE_PATTERN = Pattern.compile(
    '^\\+?[0-9\\s().-]{7,25}$'
  );
  private static final Pattern WEBSITE_PATTERN = Pattern.compile(
    '(?i)^(https?://)?([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}(:\\d{1,5})?([/?#]\\S*)?$'
  );
  private static final Pattern CONTROL_PATTERN = Pattern.compile(
    '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]'
  );
  private static final Integer MIN_PHONE_DIGITS = 7;

  /** Trims a value; returns null for blank values. */
  public static String clean(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.length() == 0 ? null : trimmed;
  }

  public static List<String> validateSubmission(EnrollmentRequest request) {
    List<String> errors = new List<String>();
    if (request.company == null) {
      errors.add('Company information is required.');
    } else {
      EnrollmentRequest.Company company = request.company;
      checkText(errors, 'Company name', company.companyName, 255, true, null);
      checkText(
        errors,
        'Website',
        company.website,
        255,
        false,
        WEBSITE_PATTERN
      );
      checkText(
        errors,
        'Company email',
        company.companyEmail,
        80,
        true,
        EMAIL_PATTERN
      );
      checkPhone(errors, 'Company phone', company.companyPhone);
      checkText(errors, 'Address', company.street, 255, false, null);
      checkText(errors, 'City', company.city, 40, false, null);
      checkText(errors, 'Postal code', company.postalCode, 20, false, null);
      checkAddressCodes(errors, company.countryCode, company.stateCode, true);
    }
    validatePeople(errors, request.people);
    // Role is required on new submissions (both channels). Not checked on
    // conversion, so Leads submitted before Role was required can still convert.
    if (request.people != null && request.people.size() <= MAX_PEOPLE) {
      for (Integer i = 0; i < request.people.size(); i++) {
        EnrollmentPerson person = request.people[i];
        if (person != null && clean(person.role) == null) {
          errors.add('Contact ' + (i + 1) + ': Role is required.');
        }
      }
    }
    if (
      request.people != null &&
      !request.people.isEmpty() &&
      request.people.size() < MIN_SUBMISSION_CONTACTS
    ) {
      errors.add(
        'At least ' + MIN_SUBMISSION_CONTACTS + ' contacts are required.'
      );
    }
    return errors;
  }

  public static List<String> validateConversion(
    EnrollmentConversionService.AccountInput account,
    List<EnrollmentPerson> people
  ) {
    List<String> errors = new List<String>();
    if (account == null) {
      errors.add('Account information is required.');
    } else {
      checkText(errors, 'Account name', account.name, 255, true, null);
      checkText(
        errors,
        'Website',
        account.website,
        255,
        false,
        WEBSITE_PATTERN
      );
      checkPhone(errors, 'Phone', account.phone);
      checkText(errors, 'Street', account.street, 255, false, null);
      checkText(errors, 'City', account.city, 40, false, null);
      checkText(errors, 'Postal code', account.postalCode, 20, false, null);
      checkAddressCodes(errors, account.countryCode, account.stateCode, false);
    }
    validatePeople(errors, people);
    return errors;
  }

  public static void validatePeople(
    List<String> errors,
    List<EnrollmentPerson> people
  ) {
    if (people == null || people.isEmpty()) {
      errors.add('At least one contact is required.');
      return;
    }
    if (people.size() > MAX_PEOPLE) {
      errors.add('A maximum of ' + MAX_PEOPLE + ' contacts can be submitted.');
      return;
    }
    Set<String> emails = new Set<String>();
    for (Integer i = 0; i < people.size(); i++) {
      EnrollmentPerson person = people[i];
      String prefix = 'Contact ' + (i + 1) + ': ';
      if (person == null) {
        errors.add(prefix + 'details are missing.');
        continue;
      }
      checkText(
        errors,
        prefix + 'First name',
        person.firstName,
        40,
        true,
        null
      );
      checkText(errors, prefix + 'Last name', person.lastName, 80, true, null);
      checkText(
        errors,
        prefix + 'Email',
        person.email,
        80,
        true,
        EMAIL_PATTERN
      );
      checkPhone(errors, prefix + 'Phone', person.phone);
      String role = clean(person.role);
      if (role != null && !EnrollmentPerson.ROLE_LABELS.containsKey(role)) {
        errors.add(prefix + 'Role is not valid.');
      }
      // Legacy job title (older Leads only); it is copied to Contact.Title (128 characters).
      checkText(
        errors,
        prefix + 'Job title',
        person.jobTitle,
        128,
        false,
        null
      );
      String email = clean(person.email);
      if (email != null) {
        String normalized = email.toLowerCase();
        if (emails.contains(normalized)) {
          errors.add(prefix + 'Email is already used for another contact.');
        }
        emails.add(normalized);
      }
    }
  }

  private static void checkText(
    List<String> errors,
    String label,
    String value,
    Integer maxLength,
    Boolean required,
    Pattern format
  ) {
    String cleaned = clean(value);
    if (cleaned == null) {
      if (required) {
        errors.add(label + ' is required.');
      }
      return;
    }
    if (cleaned.length() > maxLength) {
      errors.add(label + ' must be ' + maxLength + ' characters or fewer.');
      return;
    }
    if (CONTROL_PATTERN.matcher(cleaned).find()) {
      errors.add(label + ' contains invalid characters.');
      return;
    }
    if (format != null && !format.matcher(cleaned).matches()) {
      errors.add(label + ' is not in a valid format.');
    }
  }

  private static void checkPhone(
    List<String> errors,
    String label,
    String value
  ) {
    String cleaned = clean(value);
    if (cleaned == null) {
      return;
    }
    if (
      cleaned.length() > 40 ||
      !PHONE_PATTERN.matcher(cleaned).matches() ||
      countDigits(cleaned) < MIN_PHONE_DIGITS
    ) {
      errors.add(label + ' is not a valid phone number.');
    }
  }

  private static void checkAddressCodes(
    List<String> errors,
    String countryCode,
    String stateCode,
    Boolean countryRequired
  ) {
    String country = clean(countryCode);
    String state = clean(stateCode);
    if (country == null) {
      if (countryRequired) {
        errors.add('Country is required.');
      }
      if (state != null) {
        errors.add('State / Province requires a country.');
      }
      return;
    }
    if (!EnrollmentAddressOptions.isValidCountry(country)) {
      errors.add('Country is not valid.');
      return;
    }
    if (
      state != null && !EnrollmentAddressOptions.isValidState(country, state)
    ) {
      errors.add('State / Province is not valid for the selected country.');
    }
  }

  private static Integer countDigits(String value) {
    Integer digits = 0;
    for (Integer i = 0; i < value.length(); i++) {
      if (value.substring(i, i + 1).isNumeric()) {
        digits++;
      }
    }
    return digits;
  }
}
