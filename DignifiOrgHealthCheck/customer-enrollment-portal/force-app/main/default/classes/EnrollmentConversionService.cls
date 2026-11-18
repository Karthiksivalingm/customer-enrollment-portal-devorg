/**
 * Converts an enrollment Lead in ONE all-or-nothing transaction:
 *   1. lock the Lead (FOR UPDATE) and stop if it is already converted;
 *   2. insert exactly one Account;
 *   3. insert one Contact per submitted person (unique Enrollment_Person_Key__c);
 *   4. Database.convertLead into that Account and one of those Contacts
 *      (the platform requires one merge target; it is not a "primary" person);
 *   5. re-apply the intended Account/Contact values, undoing org automation that
 *      targets new records (default phone, forced Industry/Description) and any
 *      Lead values the conversion merged in - for enrollment records only.
 * Any failure rolls everything back to the savepoint.
 */
public with sharing class EnrollmentConversionService {
  public static final String PERMISSION = 'Convert_Enrollment_Leads';
  private static Boolean conversionInProgress = false;

  public class AccountInput {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String website;
    @AuraEnabled
    public String phone;
    @AuraEnabled
    public String street;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String stateCode;
    @AuraEnabled
    public String countryCode;
    @AuraEnabled
    public String postalCode;
  }

  public class ConversionRequest {
    public AccountInput account;
    public List<EnrollmentPerson> people;
    /** Optional: convert into this existing Account instead of creating one. */
    public Id existingAccountId;
  }

  public class Preview {
    @AuraEnabled
    public Boolean canConvert = false;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public Boolean isConverted = false;
    @AuraEnabled
    public Id convertedAccountId;
    @AuraEnabled
    public AccountInput account;
    @AuraEnabled
    public List<EnrollmentPerson> people = new List<EnrollmentPerson>();
    @AuraEnabled
    public List<String> warnings = new List<String>();
  }

  public class Result {
    @AuraEnabled
    public Boolean success = false;
    @AuraEnabled
    public Boolean alreadyConverted = false;
    @AuraEnabled
    public Id accountId;
    @AuraEnabled
    public Integer contactCount = 0;
    @AuraEnabled
    public String message;
  }

  /** True only while this service runs Database.convertLead (read by the Lead guard trigger). */
  public static Boolean isConversionInProgress() {
    return conversionInProgress;
  }

  public static String personKey(Id leadId, String personId) {
    return String.valueOf(leadId) + ':' + personId;
  }

  // ------------------------------------------------------------------
  // Preview
  // ------------------------------------------------------------------

  public static Preview getPreview(Id leadId) {
    Preview preview = new Preview();
    Lead lead = queryLead(leadId, false);
    if (lead == null || String.isBlank(lead.Enrollment_Submission_Key__c)) {
      preview.message = 'This Lead was not created by the enrollment form.';
      return preview;
    }
    preview.isConverted = lead.IsConverted;
    preview.convertedAccountId = lead.ConvertedAccountId;
    if (lead.IsConverted) {
      preview.message = 'This enrollment has already been converted.';
      return preview;
    }
    EnrollmentPeopleSerializer.ParseResult parsed = EnrollmentPeopleSerializer.parse(
      lead.Enrollment_People__c
    );
    if (!parsed.valid) {
      preview.message = parsed.message;
      return preview;
    }
    preview.account = accountFromLead(lead);
    preview.people = parsed.people;

    String permissionProblem = permissionProblem();
    if (permissionProblem != null) {
      preview.message = permissionProblem;
      return preview;
    }
    preview.warnings = findWarnings(lead, parsed.people);
    preview.canConvert = true;
    return preview;
  }

  // ------------------------------------------------------------------
  // Conversion
  // ------------------------------------------------------------------

  public static Result convert(Id leadId, String requestJson) {
    String permissionProblem = permissionProblem();
    if (permissionProblem != null) {
      throw new EnrollmentException(permissionProblem);
    }
    ConversionRequest request = parseRequest(requestJson);

    Savepoint sp = Database.setSavepoint();
    try {
      Lead lead = queryLead(leadId, true); // FOR UPDATE: concurrent requests wait here
      if (lead == null || String.isBlank(lead.Enrollment_Submission_Key__c)) {
        throw new EnrollmentException(
          'This Lead was not created by the enrollment form.'
        );
      }
      if (lead.IsConverted) {
        Result already = new Result();
        already.success = true;
        already.alreadyConverted = true;
        already.accountId = lead.ConvertedAccountId;
        already.message = 'This enrollment was already converted.';
        return already;
      }
      EnrollmentPeopleSerializer.ParseResult parsed = EnrollmentPeopleSerializer.parse(
        lead.Enrollment_People__c
      );
      if (!parsed.valid) {
        throw new EnrollmentException(parsed.message);
      }
      List<EnrollmentPerson> people = mergeEdits(parsed.people, request.people);
      AccountInput accountInput = cleanAccount(request.account);
      List<String> errors = EnrollmentValidator.validateConversion(
        accountInput,
        people
      );
      if (!errors.isEmpty()) {
        throw new EnrollmentException(String.join(errors, ' '));
      }

      // Exactly one Account: either the selected existing Account or a new one.
      Boolean createAccount = request.existingAccountId == null;
      Account account;
      if (createAccount) {
        account = intendedAccount(null, accountInput);
        dml(new List<SObject>{ account }, true);
      } else {
        List<Account> selected = [
          SELECT Id
          FROM Account
          WHERE Id = :request.existingAccountId
          WITH USER_MODE
        ];
        if (selected.isEmpty()) {
          throw new EnrollmentException(
            'The selected Account was not found or you do not have access to it.'
          );
        }
        account = selected[0];
      }

      List<Contact> contacts = new List<Contact>();
      for (EnrollmentPerson person : people) {
        contacts.add(
          intendedContact(null, account.Id, lead.Id, accountInput, person)
        );
      }
      dml(contacts, true);

      Database.LeadConvert leadConvert = new Database.LeadConvert();
      leadConvert.setLeadId(lead.Id);
      leadConvert.setAccountId(account.Id);
      leadConvert.setContactId(contacts[0].Id);
      leadConvert.setConvertedStatus(convertedStatus());
      leadConvert.setDoNotCreateOpportunity(true);
      Database.LeadConvertResult convertResult;
      conversionInProgress = true;
      try {
        convertResult = Database.convertLead(leadConvert, false);
      } finally {
        conversionInProgress = false;
      }
      if (!convertResult.isSuccess()) {
        throw new EnrollmentException(
          'Salesforce could not convert the Lead: ' +
          describe(convertResult.getErrors())
        );
      }

      // Re-apply intended values (undo default phone, forced Industry/Description
      // and any Lead values merged into the target Contact).
      List<Contact> corrected = new List<Contact>();
      for (Integer i = 0; i < people.size(); i++) {
        corrected.add(
          intendedContact(
            contacts[i].Id,
            account.Id,
            lead.Id,
            accountInput,
            people[i]
          )
        );
      }
      if (createAccount) {
        // Only a newly created Account is reset; an existing Account is left as it was.
        dml(
          new List<SObject>{ intendedAccount(account.Id, accountInput) },
          false
        );
      }
      dml(corrected, false);

      Result result = new Result();
      result.success = true;
      result.accountId = account.Id;
      result.contactCount = contacts.size();
      result.message =
        (createAccount
          ? 'Created 1 Account and '
          : 'Used the selected Account and created ') +
        contacts.size() +
        (contacts.size() == 1 ? ' Contact.' : ' Contacts.');
      return result;
    } catch (Exception ex) {
      Database.rollback(sp);
      throw ex;
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  private static String permissionProblem() {
    if (!FeatureManagement.checkPermission(PERMISSION)) {
      return 'You do not have permission to convert enrollment Leads.';
    }
    List<UserPermissionAccess> access = [
      SELECT PermissionsConvertLeads
      FROM UserPermissionAccess
      LIMIT 1
    ];
    if (access.isEmpty() || !access[0].PermissionsConvertLeads) {
      return 'You need the Convert Leads permission to convert enrollment Leads.';
    }
    if (
      !Schema.SObjectType.Account.isCreateable() ||
      !Schema.SObjectType.Contact.isCreateable()
    ) {
      return 'You need permission to create Accounts and Contacts to convert enrollment Leads.';
    }
    return null;
  }

  private static Lead queryLead(Id leadId, Boolean lockRecord) {
    List<Lead> leads = lockRecord
      ? [
          SELECT
            Id,
            Company,
            Website,
            Phone,
            Street,
            City,
            StateCode,
            CountryCode,
            PostalCode,
            IsConverted,
            ConvertedAccountId,
            Enrollment_People__c,
            Enrollment_Submission_Key__c
          FROM Lead
          WHERE Id = :leadId
          WITH USER_MODE
          FOR UPDATE
        ]
      : [
          SELECT
            Id,
            Company,
            Website,
            Phone,
            Street,
            City,
            StateCode,
            CountryCode,
            PostalCode,
            IsConverted,
            ConvertedAccountId,
            Enrollment_People__c,
            Enrollment_Submission_Key__c
          FROM Lead
          WHERE Id = :leadId
          WITH USER_MODE
        ];
    return leads.isEmpty() ? null : leads[0];
  }

  private static AccountInput accountFromLead(Lead lead) {
    AccountInput account = new AccountInput();
    account.name = lead.Company;
    account.website = lead.Website;
    account.phone = lead.Phone;
    account.street = lead.Street;
    account.city = lead.City;
    account.stateCode = lead.StateCode;
    account.countryCode = lead.CountryCode;
    account.postalCode = lead.PostalCode;
    return account;
  }

  private static List<String> findWarnings(
    Lead lead,
    List<EnrollmentPerson> people
  ) {
    List<String> warnings = new List<String>();
    Set<String> emails = new Set<String>();
    for (EnrollmentPerson person : people) {
      if (String.isNotBlank(person.email)) {
        emails.add(person.email);
      }
    }
    for (Contact existing : [
      SELECT Email, Account.Name
      FROM Contact
      WHERE Email IN :emails
      WITH USER_MODE
      LIMIT 50
    ]) {
      warnings.add(
        existing.Email +
          ' already exists as a Contact' +
          (existing.Account == null ? '' : ' on ' + existing.Account.Name) +
          '. A new Contact will still be created for this enrollment.'
      );
    }
    if (String.isNotBlank(lead.Company)) {
      Integer sameName = [
        SELECT COUNT()
        FROM Account
        WHERE Name = :lead.Company
        WITH USER_MODE
      ];
      if (sameName > 0) {
        warnings.add(
          'An Account named "' +
            lead.Company +
            '" already exists. You can select it as an existing Account, or create a new one.'
        );
      }
    }
    return warnings;
  }

  private static ConversionRequest parseRequest(String requestJson) {
    try {
      ConversionRequest request = (ConversionRequest) JSON.deserialize(
        requestJson,
        ConversionRequest.class
      );
      if (
        request != null &&
        request.account != null &&
        request.people != null
      ) {
        return request;
      }
    } catch (Exception ex) {
      System.debug(
        LoggingLevel.ERROR,
        'Conversion request could not be read: ' + ex.getMessage()
      );
    }
    throw new EnrollmentException(
      'The conversion details could not be read. Please reopen Convert Enrollment.'
    );
  }

  /** Applies screen edits to the stored people. Every submitted person must be present exactly once. */
  private static List<EnrollmentPerson> mergeEdits(
    List<EnrollmentPerson> stored,
    List<EnrollmentPerson> edits
  ) {
    Map<String, EnrollmentPerson> editsById = new Map<String, EnrollmentPerson>();
    for (EnrollmentPerson edit : edits) {
      if (edit != null && String.isNotBlank(edit.id)) {
        editsById.put(edit.id, edit);
      }
    }
    if (editsById.size() != stored.size() || edits.size() != stored.size()) {
      throw new EnrollmentException(
        'The people on the conversion screen do not match the submitted enrollment. Please reopen Convert Enrollment.'
      );
    }
    List<EnrollmentPerson> merged = new List<EnrollmentPerson>();
    for (EnrollmentPerson original : stored) {
      EnrollmentPerson edit = editsById.get(original.id);
      if (edit == null) {
        throw new EnrollmentException(
          'The people on the conversion screen do not match the submitted enrollment. Please reopen Convert Enrollment.'
        );
      }
      EnrollmentPerson person = new EnrollmentPerson();
      person.id = original.id;
      person.firstName = EnrollmentValidator.clean(edit.firstName);
      person.lastName = EnrollmentValidator.clean(edit.lastName);
      person.email = EnrollmentValidator.clean(edit.email);
      person.phone = EnrollmentValidator.clean(edit.phone);
      person.role = EnrollmentValidator.clean(edit.role);
      // Legacy job title is not editable on the screen; keep the submitted value.
      person.jobTitle = original.jobTitle;
      merged.add(person);
    }
    return merged;
  }

  private static AccountInput cleanAccount(AccountInput input) {
    AccountInput account = new AccountInput();
    account.name = EnrollmentValidator.clean(input.name);
    account.website = EnrollmentValidator.clean(input.website);
    account.phone = EnrollmentValidator.clean(input.phone);
    account.street = EnrollmentValidator.clean(input.street);
    account.city = EnrollmentValidator.clean(input.city);
    account.stateCode = EnrollmentValidator.clean(input.stateCode);
    account.countryCode = EnrollmentValidator.clean(input.countryCode);
    account.postalCode = EnrollmentValidator.clean(input.postalCode);
    return account;
  }

  private static Account intendedAccount(Id accountId, AccountInput input) {
    Account account = new Account(
      Name = input.name,
      Website = input.website,
      Phone = input.phone,
      BillingStreet = input.street,
      BillingCity = input.city,
      BillingStateCode = input.stateCode,
      BillingCountryCode = input.countryCode,
      BillingPostalCode = input.postalCode,
      Industry = null
    );
    if (accountId != null) {
      account.Id = accountId;
    }
    return account;
  }

  private static Contact intendedContact(
    Id contactId,
    Id accountId,
    Id leadId,
    AccountInput address,
    EnrollmentPerson person
  ) {
    Contact contact = new Contact(
      AccountId = accountId,
      FirstName = person.firstName,
      LastName = person.lastName,
      Email = person.email,
      Phone = person.phone,
      Title = person.titleForContact(), // Role label, or legacy job title
      MobilePhone = null,
      Description = null,
      LeadSource = 'Web',
      MailingStreet = address.street,
      MailingCity = address.city,
      MailingStateCode = address.stateCode,
      MailingCountryCode = address.countryCode,
      MailingPostalCode = address.postalCode,
      Enrollment_Person_Key__c = personKey(leadId, person.id),
      Enrollment_Source_Lead__c = leadId
    );
    if (contactId != null) {
      contact.Id = contactId;
    }
    return contact;
  }

  /** Insert or update in USER_MODE; duplicate-rule alerts are allowed (duplicates are handled by unique keys). */
  private static void dml(List<SObject> records, Boolean isInsert) {
    Database.DMLOptions options = new Database.DMLOptions();
    options.DuplicateRuleHeader.allowSave = true;
    options.OptAllOrNone = true;
    if (isInsert) {
      Database.insert(records, options, AccessLevel.USER_MODE);
    } else {
      Database.update(records, options, AccessLevel.USER_MODE);
    }
  }

  private static String convertedStatus() {
    List<LeadStatus> statuses = [
      SELECT MasterLabel
      FROM LeadStatus
      WHERE IsConverted = TRUE
      ORDER BY SortOrder
      LIMIT 1
    ];
    if (statuses.isEmpty()) {
      throw new EnrollmentException('No converted Lead Status is configured.');
    }
    return statuses[0].MasterLabel;
  }

  private static String describe(List<Database.Error> errors) {
    List<String> parts = new List<String>();
    for (Database.Error err : errors) {
      parts.add(err.getMessage());
    }
    return String.join(parts, ' ');
  }
}
