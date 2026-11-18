/**
 * Data for the enrollmentPeoplePanel on the Lead record page.
 * Runs with sharing and USER_MODE: users only see people on Leads (and Contacts)
 * they can already access.
 */
public with sharing class EnrollmentPeopleController {
  public class PanelData {
    @AuraEnabled
    public Boolean isEnrollment = false;
    @AuraEnabled
    public Boolean valid = false;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public Integer expectedCount;
    @AuraEnabled
    public List<EnrollmentPerson> people = new List<EnrollmentPerson>();
    @AuraEnabled
    public Boolean isConverted = false;
    @AuraEnabled
    public Id convertedAccountId;
    @AuraEnabled
    public Boolean canConvert = false;
  }

  @AuraEnabled(cacheable=true)
  public static PanelData getPeople(Id leadId) {
    PanelData data = new PanelData();
    List<Lead> leads = [
      SELECT
        Id,
        IsConverted,
        ConvertedAccountId,
        Enrollment_People__c,
        Enrollment_Person_Count__c,
        Enrollment_Submission_Key__c
      FROM Lead
      WHERE Id = :leadId
      WITH USER_MODE
    ];
    if (
      leads.isEmpty() || String.isBlank(leads[0].Enrollment_Submission_Key__c)
    ) {
      return data;
    }
    Lead lead = leads[0];
    data.isEnrollment = true;
    data.isConverted = lead.IsConverted;
    data.convertedAccountId = lead.ConvertedAccountId;
    data.expectedCount = lead.Enrollment_Person_Count__c == null
      ? null
      : lead.Enrollment_Person_Count__c.intValue();

    EnrollmentPeopleSerializer.ParseResult parsed = EnrollmentPeopleSerializer.parse(
      lead.Enrollment_People__c
    );
    data.valid = parsed.valid;
    data.message = parsed.message;
    data.people = parsed.people;
    if (
      parsed.valid &&
      data.expectedCount != null &&
      data.expectedCount != parsed.people.size()
    ) {
      data.message =
        'The stored person count (' +
        data.expectedCount +
        ') does not match the submitted people (' +
        parsed.people.size() +
        '). Please contact your administrator.';
    }

    if (lead.IsConverted && parsed.valid) {
      Map<String, Id> contactByKey = new Map<String, Id>();
      for (Contact c : [
        SELECT Id, Enrollment_Person_Key__c
        FROM Contact
        WHERE Enrollment_Source_Lead__c = :lead.Id
        WITH USER_MODE
      ]) {
        contactByKey.put(c.Enrollment_Person_Key__c, c.Id);
      }
      for (EnrollmentPerson person : data.people) {
        person.contactId = contactByKey.get(
          EnrollmentConversionService.personKey(lead.Id, person.id)
        );
      }
    }

    data.canConvert =
      !lead.IsConverted &&
      parsed.valid &&
      data.message == null &&
      FeatureManagement.checkPermission(EnrollmentConversionService.PERMISSION);
    return data;
  }

  /**
   * Used by the enrollment Lead path. Sets a NON-converted Lead Status only;
   * the converted stage always goes through EnrollmentConversionService.
   */
  @AuraEnabled
  public static void updateLeadStatus(Id leadId, String status) {
    List<LeadStatus> allowed = [
      SELECT ApiName
      FROM LeadStatus
      WHERE ApiName = :status AND IsConverted = FALSE
      LIMIT 1
    ];
    if (allowed.isEmpty()) {
      throw toAura('This status cannot be selected here.');
    }
    List<Lead> leads = [
      SELECT Id, IsConverted
      FROM Lead
      WHERE Id = :leadId
      WITH USER_MODE
    ];
    if (leads.isEmpty() || leads[0].IsConverted) {
      throw toAura('The status of a converted Lead cannot be changed.');
    }
    try {
      Database.update(
        new Lead(Id = leadId, Status = allowed[0].ApiName),
        AccessLevel.USER_MODE
      );
    } catch (DmlException ex) {
      throw toAura(ex.getDmlMessage(0));
    } catch (Exception ex) {
      throw toAura(ex.getMessage());
    }
  }

  private static AuraHandledException toAura(String message) {
    AuraHandledException ex = new AuraHandledException(message);
    ex.setMessage(message);
    return ex;
  }
}
