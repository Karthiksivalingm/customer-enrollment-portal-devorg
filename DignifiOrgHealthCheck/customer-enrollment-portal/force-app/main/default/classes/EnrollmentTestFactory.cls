/**
 * Test data helpers for the customer enrollment tests.
 */
@IsTest
public class EnrollmentTestFactory {
  private static Integer counter = 0;

  public static String uniqueSuffix() {
    counter++;
    return counter + '.' + Datetime.now().getTime();
  }

  /** A System Administrator user with the enrollment permission sets (optionally without the converter set). */
  /** An admin-profile user with NO enrollment permission sets (no access to the enrollment fields). */
  public static User createUserWithoutEnrollmentAccess() {
    Profile admin = [
      SELECT Id
      FROM Profile
      WHERE PermissionsModifyAllData = TRUE AND UserType = 'Standard'
      ORDER BY CreatedDate
      LIMIT 1
    ];
    User user = new User(
      ProfileId = admin.Id,
      LastName = 'No Enrollment Access',
      Email = 'no.access@example.com',
      Username = 'no.access.' + uniqueSuffix() + '@example.com',
      Alias = 'noacc',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert user;
    return user;
  }

  public static User createUser(Boolean withConverterPermission) {
    Profile admin = [
      SELECT Id
      FROM Profile
      WHERE PermissionsModifyAllData = TRUE AND UserType = 'Standard'
      ORDER BY CreatedDate
      LIMIT 1
    ];
    String suffix = uniqueSuffix();
    User user = new User(
      ProfileId = admin.Id,
      LastName = 'Enrollment Tester',
      Email = 'enrollment.tester@example.com',
      Username = 'enrollment.tester.' + suffix + '@example.com',
      Alias = 'enrtest',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert user;

    List<String> names = new List<String>{ 'Enrollment_Submission' };
    if (withConverterPermission) {
      names.add('Enrollment_Converter');
    }
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    for (PermissionSet ps : [
      SELECT Id
      FROM PermissionSet
      WHERE Name IN :names
    ]) {
      assignments.add(
        new PermissionSetAssignment(
          AssigneeId = user.Id,
          PermissionSetId = ps.Id
        )
      );
    }
    insert assignments;
    return user;
  }

  public static EnrollmentPerson person(
    String firstName,
    String lastName,
    String phone
  ) {
    EnrollmentPerson p = new EnrollmentPerson();
    p.firstName = firstName;
    p.lastName = lastName;
    p.email =
      firstName.toLowerCase() +
      '.' +
      lastName.toLowerCase() +
      '.' +
      uniqueSuffix() +
      '@example.com';
    p.phone = phone;
    p.role = 'Buyer';
    return p;
  }

  public static EnrollmentRequest request(Integer peopleCount) {
    EnrollmentRequest request = new EnrollmentRequest();
    request.submissionKey = newUuid();
    request.elapsedMs = 60000;
    request.company = new EnrollmentRequest.Company();
    request.company.companyName = 'Enrollment Test Company ' + uniqueSuffix();
    request.company.website = 'www.example.com';
    request.company.companyEmail = 'company.' + uniqueSuffix() + '@example.com';
    request.company.companyPhone = '+1 555 0100';
    request.company.street = '1 Test Street';
    request.company.city = 'San Francisco';
    request.company.stateCode = 'CA';
    request.company.countryCode = 'US';
    request.company.postalCode = '94105';
    request.people = new List<EnrollmentPerson>();
    for (Integer i = 1; i <= peopleCount; i++) {
      // Every second person has no phone, to verify blank phones stay blank.
      request.people.add(
        person(
          'Person' + i,
          'Tester' + i,
          Math.mod(i, 2) == 0
            ? null
            : '+1 555 01' + String.valueOf(i).leftPad(2, '0')
        )
      );
    }
    return request;
  }

  public static String newUuid() {
    String hex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
    return hex.substring(0, 8) +
      '-' +
      hex.substring(8, 12) +
      '-4' +
      hex.substring(13, 16) +
      '-a' +
      hex.substring(17, 20) +
      '-' +
      hex.substring(20, 32);
  }

  /** Submits through the real service and returns the created Lead. */
  public static Lead submit(EnrollmentRequest request) {
    EnrollmentSubmissionService.Result result = EnrollmentSubmissionController.submitEnrollment(
      JSON.serialize(request)
    );
    System.assert(
      result.success,
      'Submission should succeed: ' + result.message + ' ' + result.errors
    );
    return [
      SELECT Id, IsConverted, Enrollment_People__c, Enrollment_Person_Count__c
      FROM Lead
      WHERE Enrollment_Submission_Key__c = :request.submissionKey.toLowerCase()
    ];
  }

  /** Builds a conversion request from the preview, exactly as the conversion screen does. */
  public static String conversionRequestJson(
    EnrollmentConversionService.Preview preview
  ) {
    EnrollmentConversionService.ConversionRequest request = new EnrollmentConversionService.ConversionRequest();
    request.account = preview.account;
    request.people = preview.people;
    return JSON.serialize(request);
  }
}
