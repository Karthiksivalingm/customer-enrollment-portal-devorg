/**
 * ExpirationAlertController
 * Apex controller for the Expiration Alerts LWC(s):
 *   - expirationAlerts / expirationAlertsModal (internal, uses recordId
 *     from the Contact record page) -> getExpirationAlerts(contactId)
 *   - expirationAlertsIndicator (Experience Cloud badge, no recordId
 *     available - resolves the logged-in portal user's own Contact)
 *     -> getExpirationAlertsForCurrentUser()
 *
 * Both entry points share the same underlying query/severity logic via
 * buildAlertsForContact(), so the rules below apply identically no matter
 * which one is called.
 *
 * ============================================================================
 * RULES
 * ============================================================================
 *  - Critical     : expiration date is within CRITICAL_WINDOW_DAYS (2)
 *                    -> "{Label} will expire in {N} day(s)."
 *  - Warning      : expiration date is within WARNING_WINDOW_DAYS (60 / ~2mo)
 *                    -> same message, less urgent color
 *  - Anything already expired, further out than WARNING_WINDOW_DAYS, or
 *    blank (null), is NOT returned - the alert list only ever shows
 *    UPCOMING expirations, never past ones.
 *
 * ============================================================================
 * SERVICE-BASED GROUP FILTERING (NEW)
 * ============================================================================
 *  - The 'service' group (DCW 1 / DCW 2 - "ATC Documents Expiring") only
 *    shows when the Contact's Service__c = 'ATC'.
 *  - The 'hah' group (HAH Certificate - "HAH Documents Expiring") only
 *    shows when the Contact's Service__c = 'HAH'.
 *  - The 'certification' and 'document' groups are NOT filtered by
 *    Service__c - they always show for every Contact, regardless of
 *    their Service value.
 *
 * Fields tracked (label -> API name), grouped the way the UI shows them:
 *
 *   Certifications Expiring:
 *     Article 9 Certification        -> Article_9_Expiration_Date__c
 *     CPR Certification Card         -> CPR_Expiration_Date__c
 *     First Aid Certification Card   -> FA_Expiration_Date__c
 *     Criminal History Disclosure    -> Criminal_History_Disclosure_Expiration_D__c
 *     Fingerprint Card               -> Fingerprint_Card_Expiration_Date__c
 *
 *   Documents Expiring:
 *     Driver's License           -> Driver_s_License_Expiration_Date__c
 *     Vehicle Registration       -> Vehicle_Registration_Expiration_Date__c
 *     Liability Insurance        -> Vehicle_Insurance_Expiration_Date__c
 *
 *   Service Certificates Expiring (only if Service__c = 'ATC'):
 *     DCW 1 Certificate          -> DCW1_Expiration_Date__c
 *     DCW 2 Certificate          -> DCW2_Expiration_Date__c
 *
 *   HAH Documents Expiring (only if Service__c = 'HAH'):
 *     HAH Certificate            -> Habilitation_Certificate_Expiry_Date__c
 */
public with sharing class ExpirationAlertController {

    private static final Integer CRITICAL_WINDOW_DAYS = 2;
    private static final Integer WARNING_WINDOW_DAYS = 60;

    private static final String SERVICE_FIELD_API_NAME = 'Service__c';
    private static final String SERVICE_VALUE_ATC = 'ATC';
    private static final String SERVICE_VALUE_HAH = 'HAH';

    // Master config: one row per tracked field. Add/remove/relabel here only.
    private static final List<FieldConfig> FIELD_CONFIG = new List<FieldConfig>{
        new FieldConfig('Article 9 Certification', 'Article_9_Expiration_Date__c', 'certification'),
        new FieldConfig('CPR Certification Card', 'CPR_Expiration_Date__c', 'certification'),
        new FieldConfig('First Aid Certification Card', 'FA_Expiration_Date__c', 'certification'),
        new FieldConfig('Criminal History Disclosure', 'Criminal_History_Disclosure_Expiration_D__c', 'certification'),
        new FieldConfig('Fingerprint Card', 'Fingerprint_Card_Expiration_Date__c', 'certification'),

        new FieldConfig('Driver\'s License', 'Driver_s_License_Expiration_Date__c', 'document'),
        new FieldConfig('Vehicle Registration', 'Vehicle_Registration_Expiration_Date__c', 'document'),
        new FieldConfig('Liability Insurance', 'Vehicle_Insurance_Expiration_Date__c', 'document'),

        new FieldConfig('DCW 1 Certificate', 'DCW1_Expiration_Date__c', 'service'),
        new FieldConfig('DCW 2 Certificate', 'DCW2_Expiration_Date__c', 'service'),
        new FieldConfig('HAH Certificate', 'Habilitation_Certificate_Expiry_Date__c', 'hah')
    };

    /**
     * Internal entry point: returns alerts for the given Contact record Id.
     * Used by the record-page LWCs (expirationAlerts / expirationAlertsModal),
     * which get recordId automatically from the Contact record page.
     */
    @AuraEnabled(cacheable=true)
    public static List<ExpirationAlert> getExpirationAlerts(String contactId) {
        return buildAlertsForContact(contactId);
    }

    /**
     * Experience Cloud entry point: no contactId needed. Resolves the
     * Contact behind the CURRENTLY LOGGED IN portal user (via
     * User.ContactId) and returns their alerts. Used by the
     * expirationAlertsIndicator badge component, which can sit on any
     * community page (Home, My Personal Information, etc.) - not just a
     * Contact record page - so it has no recordId to work with.
     *
     * Returns an empty list (not an error) if the running user isn't a
     * Contact-based community user (e.g. an internal admin previewing the
     * page), so the badge simply won't appear for them.
     */
    @AuraEnabled(cacheable=true)
    public static List<ExpirationAlert> getExpirationAlertsForCurrentUser() {
        Id currentContactId = getCurrentUserContactId();
        if (currentContactId == null) {
            return new List<ExpirationAlert>();
        }
        return buildAlertsForContact(currentContactId);
    }

    private static Id getCurrentUserContactId() {
        List<User> currentUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        return currentUser.isEmpty() ? null : currentUser[0].ContactId;
    }

    /**
     * Shared logic used by both public entry points above. Returns one
     * ExpirationAlert per tracked field that is Critical or Warning (i.e.
     * an UPCOMING expiration), after applying the Service__c-based group
     * filter described above. Fields with no date set (null), already
     * expired (in the past), or further out than WARNING_WINDOW_DAYS, are
     * simply omitted.
     */
    private static List<ExpirationAlert> buildAlertsForContact(Id contactId) {
        List<ExpirationAlert> alerts = new List<ExpirationAlert>();

        if (contactId == null) {
            return alerts;
        }

        try {
            // Build the dynamic field list for the query from FIELD_CONFIG,
            // so adding a field to the config above is the only edit needed.
            // Service__c is added explicitly since it drives group
            // filtering below but isn't itself a tracked expiration field.
            Set<String> fieldNames = new Set<String>{ 'Id', SERVICE_FIELD_API_NAME };
            for (FieldConfig fc : FIELD_CONFIG) {
                fieldNames.add(fc.apiName);
            }

            String query = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') +
                            ' FROM Contact WHERE Id = :contactId WITH USER_MODE LIMIT 1';

            List<SObject> results = Database.query(query);
            if (results.isEmpty()) {
                return alerts;
            }
            SObject con = results[0];

            String serviceValue = (String) con.get(SERVICE_FIELD_API_NAME);

            Date today = Date.today();

            for (FieldConfig fc : FIELD_CONFIG) {

                // Service-based group filtering: the 'service' (ATC) group
                // only shows for Service__c = 'ATC'; the 'hah' group only
                // shows for Service__c = 'HAH'. Certifications/Documents
                // groups are untouched by this check.
                if (fc.groupName == 'service' && serviceValue != SERVICE_VALUE_ATC) {
                    continue;
                }
                if (fc.groupName == 'hah' && serviceValue != SERVICE_VALUE_HAH) {
                    continue;
                }

                Object rawValue = con.get(fc.apiName);
                if (rawValue == null) {
                    continue; // no date on file - nothing to alert on
                }

                Date expirationDate = (Date) rawValue;
                Integer daysRemaining = today.daysBetween(expirationDate);

                String severity;
                String message;

               if (daysRemaining < 0) {
    continue; // already expired - only upcoming expirations are shown
} else if (daysRemaining <= CRITICAL_WINDOW_DAYS) {
    severity = 'critical';
    if (daysRemaining == 0) {
        message = fc.label + ' expires today.';
    } else if (daysRemaining == 1) {
        message = fc.label + ' will expire tomorrow.';
    } else {
        message = fc.label + ' will expire in ' + daysRemaining + ' days.';
    }
} else if (daysRemaining <= WARNING_WINDOW_DAYS) {
    severity = 'warning';
    message = fc.label + ' will expire in ' + daysRemaining + ' days.';
} else {
    continue; // outside the warning window - not shown
}
                alerts.add(new ExpirationAlert(
                    fc.label,
                    fc.apiName,
                    fc.groupName,
                    expirationDate,
                    daysRemaining,
                    severity,
                    message
                ));
            }

            // Most urgent first: critical, then warning; within the same
            // severity, soonest first.
            alerts.sort();

            return alerts;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException('Error retrieving expiration alerts: ' + e.getMessage());
            ex.setMessage('Error retrieving expiration alerts: ' + e.getMessage());
            throw ex;
        }
    }

    private class FieldConfig {
        String label;
        String apiName;
        String groupName;

        FieldConfig(String label, String apiName, String groupName) {
            this.label = label;
            this.apiName = apiName;
            this.groupName = groupName;
        }
    }

    public class ExpirationAlert implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String groupName;
        @AuraEnabled public Date expirationDate;
        @AuraEnabled public Integer daysRemaining;
        @AuraEnabled public String severity;   // 'critical' | 'warning'
        @AuraEnabled public String message;

        public ExpirationAlert(
            String label,
            String fieldApiName,
            String groupName,
            Date expirationDate,
            Integer daysRemaining,
            String severity,
            String message
        ) {
            this.label = label;
            this.fieldApiName = fieldApiName;
            this.groupName = groupName;
            this.expirationDate = expirationDate;
            this.daysRemaining = daysRemaining;
            this.severity = severity;
            this.message = message;
        }

        private Integer severityRank() {
            if (severity == 'critical') return 0;
            return 1; // warning
        }

        public Integer compareTo(Object other) {
            ExpirationAlert that = (ExpirationAlert) other;
            Integer rankDiff = this.severityRank() - that.severityRank();
            if (rankDiff != 0) {
                return rankDiff;
            }
            return this.daysRemaining - that.daysRemaining;
        }
    }
}