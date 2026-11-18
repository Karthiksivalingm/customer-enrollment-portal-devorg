/**
 * One submitted person. Used in the enrollment request, in the Lead's
 * Enrollment_People__c JSON, on the Lead people panel and on the conversion screen.
 * All people are equal: there is no primary/secondary flag.
 */
public with sharing class EnrollmentPerson {
  /** Server-assigned, stable id within the submission ("P01".."P25"). */
  @AuraEnabled
  public String id;
  @AuraEnabled
  public String firstName;
  @AuraEnabled
  public String lastName;
  @AuraEnabled
  public String email;
  @AuraEnabled
  public String phone;
  /** Role picklist value (a key of ROLE_LABELS). Optional. */
  @AuraEnabled
  public String role;
  /**
   * Legacy free-text job title. New submissions no longer set it; it is kept
   * (read and re-written unchanged) for Leads submitted before Role existed.
   */
  @AuraEnabled
  public String jobTitle;
  /** Display only, set when the JSON is read: the Role label, or the legacy job title. Never stored. */
  @AuraEnabled
  public String roleLabel;
  /** Populated only for display after conversion; never stored in the JSON. */
  @AuraEnabled
  public Id contactId;

  /**
   * Allowed Role values (stored in the JSON) and their labels, in display order.
   * Must match ROLE_OPTIONS in the enrollmentUtils LWC.
   * "AP" keeps the existing picklist API value; it is displayed as "Account Payable".
   */
  public static final Map<String, String> ROLE_LABELS = new Map<String, String>{
    'Primary Contact' => 'Primary Contact',
    'AP' => 'Account Payable',
    'Allocator' => 'Allocator',
    'Broker / Agency Rep' => 'Broker / Agency Rep',
    'Buyer' => 'Buyer',
    'EDI Contact' => 'EDI Contact',
    'Logistics / Traffic' => 'Logistics / Traffic'
  };

  /** The text written to Contact.Title: the Role label, else the legacy job title. */
  public String titleForContact() {
    if (String.isNotBlank(role) && ROLE_LABELS.containsKey(role)) {
      return ROLE_LABELS.get(role);
    }
    return String.isBlank(jobTitle) ? null : jobTitle;
  }
}
