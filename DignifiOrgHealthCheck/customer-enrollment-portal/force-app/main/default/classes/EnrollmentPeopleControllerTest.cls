@IsTest
private class EnrollmentPeopleControllerTest {
  @IsTest
  static void returnsPeopleForEnrollmentLead() {
    System.runAs(EnrollmentTestFactory.createUser(true)) {
      Lead lead = EnrollmentTestFactory.submit(
        EnrollmentTestFactory.request(2)
      );
      EnrollmentPeopleController.PanelData data = EnrollmentPeopleController.getPeople(
        lead.Id
      );
      Assert.isTrue(data.isEnrollment);
      Assert.isTrue(data.valid, '' + data.message);
      Assert.areEqual(2, data.people.size());
      Assert.isTrue(data.canConvert);
    }
  }

  @IsTest
  static void ignoresNormalLeadsAndReportsBadData() {
    Lead normal = new Lead(
      LastName = 'Normal',
      Company = 'Normal Co',
      Email = 'n.' + EnrollmentTestFactory.uniqueSuffix() + '@example.com'
    );
    Lead broken = new Lead(
      LastName = 'Broken',
      Company = 'Broken Co',
      Email = 'b.' + EnrollmentTestFactory.uniqueSuffix() + '@example.com',
      Enrollment_Submission_Key__c = EnrollmentTestFactory.newUuid(),
      Enrollment_People__c = '{not valid json'
    );
    System.runAs(EnrollmentTestFactory.createUser(true)) {
      insert new List<Lead>{ normal, broken };
      Assert.isFalse(
        EnrollmentPeopleController.getPeople(normal.Id).isEnrollment
      );
      EnrollmentPeopleController.PanelData data = EnrollmentPeopleController.getPeople(
        broken.Id
      );
      Assert.isTrue(data.isEnrollment);
      Assert.isFalse(data.valid);
      Assert.isNotNull(data.message, 'A readable message instead of raw JSON');
      Assert.isFalse(data.canConvert);
    }
  }
}
