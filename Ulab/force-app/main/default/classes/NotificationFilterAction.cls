/**
 * NotificationFilterAction
 * ─────────────────────────────────────────────────────────────────────────────
 * Applies suppression rules to a given list of candidate emails.
 *
 * Recipients are fully resolved by EmailAlertReaderQueueable via the Metadata
 * SOAP API and passed in through FilterRequest.candidateEmails. There is no
 * longer any hardcoded per-alert recipient or field config here.
 *
 * Additionally, this class adds any email-type fields found directly on the
 * triggering record (e.g. Company_Owner_Email__c, Submitting_User_Email__c)
 * into the candidate pool dynamically — no static field map needed.
 *
 * Suppression rules applied (in order):
 *   1. Global suppression  — User.Disable_All_Emails__c = true
 *   2. Account suppression — User_Account_Notification__c with Disable_Email__c = true
 *   3. Field-level rules   — User_Notification_Preference__c matching object + field + value
 */
public with sharing class NotificationFilterAction {

    // ══════════════════════════════════════════════════════════════════════
    // INPUT / OUTPUT
    // ══════════════════════════════════════════════════════════════════════

    public class FilterRequest {
        @InvocableVariable(label='Alert Developer Name' required=true)
        public String alertDeveloperName;

        @InvocableVariable(label='Triggering Record Id' required=true)
        public String recordId;

        @InvocableVariable(label='Object API Name' required=true)
        public String objectName;

        // Candidate emails resolved from Email Alert by EmailAlertReaderQueueable
        // (users, roles, groups, additional emails — all already resolved to addresses)
        public List<String> candidateEmails;
    }

    public class FilterResult {
        @InvocableVariable(label='Recipient Emails')
        public List<String> recipientEmails;

        @InvocableVariable(label='Suppressed Emails')
        public List<String> suppressedEmails;
    }

    // ══════════════════════════════════════════════════════════════════════
    // ENTRY POINT
    // ══════════════════════════════════════════════════════════════════════

    @InvocableMethod(
        label       = 'Get uLabs Email Recipients'
        description = 'Applies suppression rules to candidate emails from Email Alert.'
        category    = 'Notification'
    )
    public static List<FilterResult> getRecipients(List<FilterRequest> requests) {
        List<FilterResult> results = new List<FilterResult>();
        for (FilterRequest req : requests) {
            results.add(process(req));
        }
        return results;
    }

    // ══════════════════════════════════════════════════════════════════════
    // MAIN PROCESS
    // ══════════════════════════════════════════════════════════════════════

    private static FilterResult process(FilterRequest req) {
        FilterResult result     = new FilterResult();
        result.recipientEmails  = new List<String>();
        result.suppressedEmails = new List<String>();

        // ── Step 1: Seed candidate emails from Email Alert ─────────────────
        // These are already resolved (users, roles, groups, additional emails)
        // by EmailAlertReaderQueueable reading the Metadata SOAP API.
        Set<String> candidateEmails = new Set<String>();

        if (req.candidateEmails != null) {
            for (String e : req.candidateEmails) {
                if (String.isNotBlank(e)) candidateEmails.add(e.trim().toLowerCase());
            }
        }

        // ── Step 2: Add emails from record's own email-type fields ─────────
        // Dynamically discovers all email-type fields on the object and reads
        // their values from the record — no hardcoded field list needed.
        Set<String> emailFields = getEmailTypeFields(req.objectName);

        if (!emailFields.isEmpty() && String.isNotBlank(req.recordId)) {
            // Also pull OwnerId so we can resolve the account owner's email
            emailFields.add('OwnerId');
            Map<String, Object> recordValues = fetchRecordFields(
                req.recordId, req.objectName, emailFields
            );

            // Resolve OwnerId → email
            Object ownerId = recordValues.get('ownerid');
            if (ownerId != null) {
                String ownerEmail = getUserEmail((Id) ownerId);
                if (String.isNotBlank(ownerEmail)) {
                    candidateEmails.add(ownerEmail.trim().toLowerCase());
                }
            }

            // Add all email-type field values directly
            for (String field : emailFields) {
                if (field.equalsIgnoreCase('OwnerId')) continue;
                Object val = recordValues.get(field.toLowerCase());
                if (val != null && String.isNotBlank(String.valueOf(val))) {
                    candidateEmails.add(String.valueOf(val).trim().toLowerCase());
                }
            }
        }

        System.debug(LoggingLevel.INFO,
            'NotificationFilterAction: candidateEmails after record field merge ('
            + candidateEmails.size() + '): ' + candidateEmails);

        if (candidateEmails.isEmpty()) return result;

        // ── Step 3: Apply suppression rules ───────────────────────────────
        Map<String, Id> emailToUserId = resolveEmailsToUserIds(candidateEmails);
        Set<Id> userIdSet             = new Set<Id>(emailToUserId.values());
        Set<Id> globalSuppressed      = getGloballySuppressedUsers(userIdSet);
        Map<Id, Set<Id>> acctSupp     = getAccountSuppressions(userIdSet);
        Map<Id, List<User_Notification_Preference__c>> fieldRules =
            getFieldRules(userIdSet, req.objectName);

        Id triggeringAccountId = resolveTriggeringAccount(req.recordId, req.objectName);

        // Pre-fetch record field values needed for field-level suppression rules
        Map<String, String> recFieldValues = new Map<String, String>();
        if (!fieldRules.isEmpty()) {
            Set<String> ruleFields = new Set<String>();
            for (List<User_Notification_Preference__c> rules : fieldRules.values()) {
                for (User_Notification_Preference__c r : rules) {
                    ruleFields.add(r.Field_Name__c);
                }
            }
            Map<String, Object> raw = fetchRecordFields(req.recordId, req.objectName, ruleFields);
            for (String f : raw.keySet()) {
                Object v = raw.get(f);
                recFieldValues.put(f.toLowerCase(), v != null ? String.valueOf(v) : '');
            }
        }

        // ── Step 4: Classify each candidate as sent or suppressed ──────────
        for (String email : candidateEmails) {
            if (String.isBlank(email)) continue;

            Id      userId   = emailToUserId.get(email);
            Boolean suppress = false;

            if (userId != null) {
                // Rule 1 — global suppression
                if (globalSuppressed.contains(userId)) {
                    suppress = true;
                    System.debug(LoggingLevel.INFO,
                        'NotificationFilterAction: globally suppressed → ' + email);
                }

                // Rule 2 — account-level suppression
                if (!suppress && triggeringAccountId != null
                        && acctSupp.containsKey(userId)
                        && acctSupp.get(userId).contains(triggeringAccountId)) {
                    suppress = true;
                    System.debug(LoggingLevel.INFO,
                        'NotificationFilterAction: account-suppressed for account '
                        + triggeringAccountId + ' → ' + email);
                }

                // Rule 3 — field-level suppression
                if (!suppress && fieldRules.containsKey(userId)) {
                    for (User_Notification_Preference__c rule : fieldRules.get(userId)) {
                        String actual = recFieldValues.get(rule.Field_Name__c.toLowerCase());
                        if (String.isNotBlank(actual)
                                && actual.equalsIgnoreCase(rule.Field_Value__c)) {
                            suppress = true;
                            System.debug(LoggingLevel.INFO,
                                'NotificationFilterAction: field-rule suppressed'
                                + ' | field=' + rule.Field_Name__c
                                + ' value=' + rule.Field_Value__c
                                + ' → ' + email);
                            break;
                        }
                    }
                }
            }
            // External emails (no userId match) are never suppressed

            if (suppress) {
                result.suppressedEmails.add(email);
            } else {
                result.recipientEmails.add(email);
            }
        }

        System.debug(LoggingLevel.INFO,
            'NotificationFilterAction: recipientEmails  → ' + result.recipientEmails);
        System.debug(LoggingLevel.INFO,
            'NotificationFilterAction: suppressedEmails → ' + result.suppressedEmails);

        return result;
    }

    // ══════════════════════════════════════════════════════════════════════
    // DYNAMIC EMAIL FIELD DISCOVERY
    // Returns all Email display-type field API names on the given object.
    // ══════════════════════════════════════════════════════════════════════

    private static Set<String> getEmailTypeFields(String objectName) {
        Set<String> fields = new Set<String>();
        if (String.isBlank(objectName)) return fields;
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) return fields;
            for (Schema.SObjectField f : objType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if (dfr.getType() == Schema.DisplayType.Email && dfr.isAccessible()) {
                    fields.add(dfr.getName());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'NotificationFilterAction: getEmailTypeFields error → ' + e.getMessage());
        }
        System.debug(LoggingLevel.INFO,
            'NotificationFilterAction: discovered email fields on '
            + objectName + ' → ' + fields);
        return fields;
    }

    // ══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════

    private static String getUserEmail(Id userId) {
        List<User> users = [
            SELECT Email FROM User
            WHERE Id = :userId AND IsActive = true
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0].Email;
    }

    private static Map<String, Id> resolveEmailsToUserIds(Set<String> emails) {
        Map<String, Id> result = new Map<String, Id>();
        if (emails.isEmpty()) return result;
        for (User u : [
            SELECT Id, Email FROM User
            WHERE Email IN :emails AND IsActive = true
        ]) {
            if (u.Email != null) result.put(u.Email.trim().toLowerCase(), u.Id);
        }
        return result;
    }

    private static Set<Id> getGloballySuppressedUsers(Set<Id> userIds) {
        Set<Id> result = new Set<Id>();
        if (userIds.isEmpty()) return result;
        for (User u : [
            SELECT Id FROM User
            WHERE Id IN :userIds AND Disable_All_Emails__c = true
        ]) {
            result.add(u.Id);
        }
        return result;
    }

    private static Map<Id, Set<Id>> getAccountSuppressions(Set<Id> userIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        if (userIds.isEmpty()) return result;
        for (User_Account_Notification__c r : [
            SELECT User__c, Company__c FROM User_Account_Notification__c
            WHERE  User__c IN :userIds AND Disable_Email__c = true
        ]) {
            if (!result.containsKey(r.User__c)) result.put(r.User__c, new Set<Id>());
            result.get(r.User__c).add(r.Company__c);
        }
        return result;
    }

    private static Map<Id, List<User_Notification_Preference__c>> getFieldRules(
        Set<Id> userIds, String objectName
    ) {
        Map<Id, List<User_Notification_Preference__c>> result =
            new Map<Id, List<User_Notification_Preference__c>>();
        if (userIds.isEmpty()) return result;
        String objectNameLower = objectName != null ? objectName.toLowerCase() : '';
        for (User_Notification_Preference__c p : [
            SELECT User__c, Object_Name__c, Field_Name__c, Field_Value__c
            FROM   User_Notification_Preference__c
            WHERE  User__c IN :userIds
        ]) {
            if (p.Object_Name__c == null) continue;
            if (p.Object_Name__c.toLowerCase() != objectNameLower) continue;
            if (!result.containsKey(p.User__c)) {
                result.put(p.User__c, new List<User_Notification_Preference__c>());
            }
            result.get(p.User__c).add(p);
        }
        return result;
    }

    private static Id resolveTriggeringAccount(String recordId, String objectName) {
        if (objectName.equalsIgnoreCase('Account')) {
            try { return (Id) recordId; } catch (Exception e) { return null; }
        }
        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe().get(objectName)
                           .getDescribe().fields.getMap();
        } catch (Exception e) { return null; }

        Set<String> accountLookupFields = new Set<String>();
        Set<String> accountNameFields   = new Set<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            Schema.DisplayType dtype = dfr.getType();
            if (dtype == Schema.DisplayType.Reference) {
                for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                    if (ref.getDescribe().getName() == 'Account') {
                        accountLookupFields.add(dfr.getName());
                        break;
                    }
                }
            } else if ((dtype == Schema.DisplayType.String
                        || dtype == Schema.DisplayType.TextArea)
                       && (dfr.getName().toLowerCase().contains('account')
                           || dfr.getName().toLowerCase().contains('company'))) {
                accountNameFields.add(dfr.getName());
            }
        }

        if (!accountLookupFields.isEmpty()) {
            try {
                String soql = 'SELECT '
                    + String.join(new List<String>(accountLookupFields), ', ')
                    + ' FROM ' + objectName
                    + ' WHERE Id = :recordId LIMIT 1';
                List<SObject> rows = Database.query(soql);
                if (!rows.isEmpty()) {
                    for (String f : accountLookupFields) {
                        Object val = rows[0].get(f);
                        if (val != null) {
                            try { return (Id) val; } catch (Exception e) {}
                        }
                    }
                }
            } catch (Exception e) {}
        }

        if (!accountNameFields.isEmpty()) {
            try {
                String soql = 'SELECT '
                    + String.join(new List<String>(accountNameFields), ', ')
                    + ' FROM ' + objectName
                    + ' WHERE Id = :recordId LIMIT 1';
                List<SObject> rows = Database.query(soql);
                if (!rows.isEmpty()) {
                    for (String f : accountNameFields) {
                        Object val = rows[0].get(f);
                        if (val == null) continue;
                        String accountName = String.valueOf(val).trim();
                        if (String.isBlank(accountName)) continue;
                        List<Account> accts = [
                            SELECT Id FROM Account
                            WHERE Name = :accountName LIMIT 1
                        ];
                        if (!accts.isEmpty()) return accts[0].Id;
                    }
                }
            } catch (Exception e) {}
        }
        return null;
    }

    private static Map<String, Object> fetchRecordFields(
        String recordId, String objectName, Set<String> fieldNames
    ) {
        Map<String, Object> result = new Map<String, Object>();
        if (fieldNames.isEmpty() || String.isBlank(recordId)) return result;
        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe().get(objectName)
                           .getDescribe().fields.getMap();
        } catch (Exception e) { return result; }

        Set<String> valid = new Set<String>();
        for (String f : fieldNames) {
            if (String.isNotBlank(f)
                    && fieldMap.containsKey(f.toLowerCase())
                    && fieldMap.get(f.toLowerCase()).getDescribe().isAccessible()) {
                valid.add(f);
            }
        }
        if (valid.isEmpty()) return result;
        try {
            String soql = 'SELECT '
                + String.join(new List<String>(valid), ', ')
                + ' FROM ' + objectName
                + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> rows = Database.query(soql);
            if (!rows.isEmpty()) {
                for (String f : valid) result.put(f.toLowerCase(), rows[0].get(f));
            }
        } catch (Exception e) {}
        return result;
    }
}