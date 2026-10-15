/**
 * ContactCertificationExpirationHandler
 *
 * Replaces the Flow-based "Auto-Calculate Certification Expiration Dates"
 * design with equivalent Apex logic. For each of the 5 auto-calculated
 * certifications, when the corresponding Issuance Date field changes (or
 * is set on insert), this computes Expiration Date = Issuance Date +
 * (validity years for that cert, looked up from
 * Certification_Validity_Rule__mdt) and writes it directly onto the
 * Contact record before it saves.
 *
 * Driver's License, Vehicle Registration, and Vehicle Insurance remain
 * manual-entry fields and are intentionally NOT touched by this class.
 *
 * ============================================================================
 * PREREQUISITES (must already exist before this class will compile/run)
 * ============================================================================
 *  - Contact fields: Article_9_Issuance_Date__c, CPR_Issuance_Date__c,
 *    FA_Issuance_Date__c, Criminal_History_Issuance_Date__c,
 *    Fingerprint_Card_Issuance_Date__c  (all Date type)
 *  - Custom Metadata Type: Certification_Validity_Rule__mdt with a
 *    Validity_Years__c (Number) field, and one record per cert whose
 *    DeveloperName matches CERT_RULES below (Article_9, CPR, FA,
 *    Criminal_History, Fingerprint_Card)
 */
public with sharing class ContactCertificationExpirationHandler {

    // One row per auto-calculated certification: which Issuance Date field
    // drives the calculation, which Expiration Date field gets written,
    // and which Custom Metadata record (by DeveloperName) supplies the
    // validity-years count for that cert.
    private class CertRule {
        String issuanceField;
        String expirationField;
        String metadataDeveloperName;

        CertRule(String issuanceField, String expirationField, String metadataDeveloperName) {
            this.issuanceField = issuanceField;
            this.expirationField = expirationField;
            this.metadataDeveloperName = metadataDeveloperName;
        }
    }

    private static final List<CertRule> CERT_RULES = new List<CertRule>{
        new CertRule('Article_9_Issuance_Date__c', 'Article_9_Expiration_Date__c', 'Article_9'),
        new CertRule('CPR_Issuance_Date__c', 'CPR_Expiration_Date__c', 'CPR'),
        new CertRule('FA_Issuance_Date__c', 'FA_Expiration_Date__c', 'FA'),
        new CertRule('Criminal_History_Issuance_Date__c', 'Criminal_History_Disclosure_Expiration_D__c', 'Criminal_History'),
        new CertRule('Fingerprint_Card_Issuance_Date__c', 'Fingerprint_Card_Expiration_Date__c', 'Fingerprint_Card')
    };

    /**
     * Entry point, called from the trigger for both before-insert and
     * before-update. oldMap is null on insert (nothing to compare against
     * - any populated Issuance Date is treated as "changed").
     */
    public static void calculateExpirationDates(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        Map<String, Decimal> validityYearsByDeveloperName = getValidityYearsByDeveloperName();

        for (Contact con : newContacts) {
            Contact oldCon = (oldMap != null) ? oldMap.get(con.Id) : null;

            for (CertRule rule : CERT_RULES) {
                Date issuanceDate = (Date) con.get(rule.issuanceField);

                if (issuanceDate == null) {
                    continue; // nothing to calculate from
                }

                Boolean issuanceChanged;
                if (oldCon == null) {
                    issuanceChanged = true; // insert: any populated date counts as new
                } else {
                    Date oldIssuanceDate = (Date) oldCon.get(rule.issuanceField);
                    issuanceChanged = issuanceDate != oldIssuanceDate;
                }

                if (!issuanceChanged) {
                    continue;
                }

                Decimal validityYears = validityYearsByDeveloperName.get(rule.metadataDeveloperName);
                if (validityYears == null) {
                    // No Custom Metadata rule configured for this cert -
                    // skip rather than guess or throw, so a missing config
                    // record doesn't block the whole save.
                    continue;
                }

                Date expirationDate = addYearsSafely(issuanceDate, Integer.valueOf(validityYears));
                con.put(rule.expirationField, expirationDate);
            }
        }
    }

    /**
     * Queries all Certification_Validity_Rule__mdt records once per
     * transaction (Custom Metadata reads don't count against SOQL limits,
     * but there's no need to repeat the query per-Contact regardless).
     */
    private static Map<String, Decimal> getValidityYearsByDeveloperName() {
        Map<String, Decimal> result = new Map<String, Decimal>();

        for (Certification_Validity_Rule__mdt rule : [
            SELECT DeveloperName, Validitity_years__c
            FROM Certification_Validity_Rule__mdt
        ]) {
            result.put(rule.DeveloperName, rule.Validitity_years__c);
        }

        return result;
    }

    /**
     * Adds N years to a date. Handles the Feb 29 issuance-date edge case:
     * if the calculated year isn't a leap year, falls back to Feb 28
     * instead of throwing (Date.newInstance(year, 2, 29) errors outright
     * on a non-leap year).
     */
    private static Date addYearsSafely(Date startDate, Integer yearsToAdd) {
        Integer targetYear = startDate.year() + yearsToAdd;
        Integer month = startDate.month();
        Integer day = startDate.day();

        if (month == 2 && day == 29 && !Date.isLeapYear(targetYear)) {
            day = 28;
        }

        return Date.newInstance(targetYear, month, day);
    }
}