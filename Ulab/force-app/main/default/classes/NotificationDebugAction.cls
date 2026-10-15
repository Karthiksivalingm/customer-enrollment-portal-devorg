/**
 * NotificationDebugAction — enhanced with Step 9 showing actual email field values
 */
public with sharing class NotificationDebugAction {

    public class DebugRequest {
        @InvocableVariable(label='Alert Developer Name' required=true)
        public String alertDeveloperName;
        @InvocableVariable(label='Triggering Record Id' required=true)
        public String recordId;
        @InvocableVariable(label='Object API Name' required=true)
        public String objectName;
    }

    public class DebugResult {
        @InvocableVariable(label='Debug Log')
        public String debugLog;
    }

    @InvocableMethod(
        label       = 'Debug Notification Filter'
        description = 'Diagnostic — shows exactly what each suppression rule sees'
        category    = 'Notification'
    )
    public static List<DebugResult> debug(List<DebugRequest> requests) {
        List<DebugResult> results = new List<DebugResult>();
        for (DebugRequest req : requests) {
            DebugResult r = new DebugResult();
            r.debugLog = runDiagnostic(req);
            results.add(r);
        }
        return results;
    }

    private static String runDiagnostic(DebugRequest req) {
        List<String> log = new List<String>();
        log.add('=== NOTIFICATION FILTER DIAGNOSTIC ===');
        log.add('alertDeveloperName : ' + req.alertDeveloperName);
        log.add('recordId           : ' + req.recordId);
        log.add('objectName         : ' + req.objectName);
        log.add('');

        // Step 1: Alert key
        log.add('--- STEP 1: Alert config lookup ---');
        Set<String> knownAlerts = new Set<String>{
            'New_uAssist_Order_Notification',
            'Cloud_uA_In_Progress','Cloud_uA_Mod_Complete',
            'Cloud_uA_On_Hold_TX_Plan','Cloud_uA_On_Hold_Pt_Overview',
            'Cloud_uA_CRTR','Cloud_uA_Rejected','Cloud_uA_Canceled',
            'uAssist_Order_Customer_Notification_In_Progress',
            'UAssist_Order_Customer_Notification_Ready_to_Review',
            'UAssist_Order_Customer_Notification_On_Hold',
            'UAssist_Order_Customer_Notification_Rejected',
            'UAssist_Order_Customer_Modification_Complete'
        };
        log.add(knownAlerts.contains(req.alertDeveloperName)
            ? 'PASS  Alert key found'
            : 'FAIL  Alert key NOT found: "' + req.alertDeveloperName + '"');
        log.add('');

        // Step 2: Schema
        log.add('--- STEP 2: Object schema ---');
        Map<String, Schema.SObjectField> fieldMap;
        try {
            fieldMap = Schema.getGlobalDescribe()
                             .get(req.objectName).getDescribe().fields.getMap();
            log.add('PASS  Object found');
        } catch(Exception e) {
            log.add('FAIL  ' + e.getMessage());
            return String.join(log, '\n');
        }
        log.add('');

        // Step 3: Account lookup fields
        log.add('--- STEP 3: Account lookup fields ---');
        List<String> accountFields = new List<String>();
        for (String fn : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fn).getDescribe();
            if (dfr.getType() == Schema.DisplayType.Reference) {
                for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                    if (ref.getDescribe().getName() == 'Account') {
                        accountFields.add(dfr.getName());
                    }
                }
            }
        }
        log.add(accountFields.isEmpty()
            ? 'WARN  None found'
            : 'PASS  ' + String.join(accountFields, ', '));

        // Show ALL reference fields on the object with their target object
        // This reveals if Account_Name__c is a text/formula field vs a true lookup
        log.add('      All reference (lookup) fields on ' + req.objectName + ':');
        for (String fn : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fn).getDescribe();
            if (dfr.getType() == Schema.DisplayType.Reference) {
                List<String> targets = new List<String>();
                for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                    targets.add(ref.getDescribe().getName());
                }
                log.add('        ' + dfr.getName()
                    + ' (' + dfr.getLabel() + ')'
                    + ' → ' + String.join(targets, ', '));
            }
        }
        // Also show type of Account_Name__c specifically
        // Check both Account_Name__c and Company_Name__c
        for (String checkField : new List<String>{'account_name__c', 'company_name__c'}) {
            if (fieldMap.containsKey(checkField)) {
                Schema.DescribeFieldResult af = fieldMap.get(checkField).getDescribe();
                log.add('      ' + af.getName() + ' field type: ' + af.getType()
                    + ' (Reference = true lookup, String/Formula = stores name as text)');
            }
        }
        log.add('');

        // Step 4: Record + account Id
        log.add('--- STEP 4: Record account lookup values ---');
        Id triggeringAccountId = null;
        if (!accountFields.isEmpty()) {
            try {
                List<SObject> rows = Database.query(
                    'SELECT ' + String.join(accountFields, ', ')
                    + ' FROM ' + req.objectName
                    + ' WHERE Id = \'' + req.recordId + '\' LIMIT 1'
                );
                if (!rows.isEmpty()) {
                    for (String f : accountFields) {
                        Object v = rows[0].get(f);
                        log.add('      ' + f + ' = ' + v);
                        if (v != null && triggeringAccountId == null) {
                            try { triggeringAccountId = (Id)v; } catch(Exception e){}
                        }
                    }
                    log.add('      triggeringAccountId = ' + triggeringAccountId);
                }
            } catch(Exception e) { log.add('FAIL  ' + e.getMessage()); }
        }
        log.add('');

        // ── NEW STEP 9: Show actual email field values on the record ──────
        log.add('--- STEP 9: Actual email field values on record ---');
        log.add('      These are the emails the alert would send to.');
        log.add('      For suppression to work, these must be Salesforce User emails.');
        Map<String, String> configuredFields = new Map<String, String>{
            'Company_Owner_Email__c'    => 'Company Owner Email',
            'Company_Email__c'          => 'Company Email',
            'Submitting_User_Email__c'  => 'Submitting User Email',
            'Related_IS_Email__c'       => 'Related IS Email',
            'Acct_IS_Email__c'          => 'Acct IS Email'
        };
        List<String> existingEmailFields = new List<String>();
        for (String f : configuredFields.keySet()) {
            if (fieldMap.containsKey(f.toLowerCase())) existingEmailFields.add(f);
        }
        // Also include OwnerId
        if (fieldMap.containsKey('ownerid')) existingEmailFields.add('OwnerId');

        if (!existingEmailFields.isEmpty()) {
            try {
                List<SObject> rows = Database.query(
                    'SELECT ' + String.join(existingEmailFields, ', ')
                    + ' FROM ' + req.objectName
                    + ' WHERE Id = \'' + req.recordId + '\' LIMIT 1'
                );
                if (!rows.isEmpty()) {
                    SObject rec = rows[0];
                    for (String f : existingEmailFields) {
                        Object v = rec.get(f);
                        String emailVal = v != null ? String.valueOf(v) : '(null)';
                        Boolean isSfUser = false;

                        if (f == 'OwnerId' && v != null) {
                            // OwnerId — resolve to email address
                            Id ownerId = (Id) v;
                            List<User> uu = [SELECT Email FROM User WHERE Id = :ownerId LIMIT 1];
                            emailVal = uu.isEmpty() ? emailVal : uu[0].Email;
                            isSfUser = true;
                        } else if (v != null) {
                            // Email field — check if a SF User has this email
                            String emailToCheck = emailVal.trim().toLowerCase();
                            List<User> uu = [
                                SELECT Id FROM User
                                WHERE Email = :emailToCheck AND IsActive = true
                                LIMIT 1
                            ];
                            isSfUser = !uu.isEmpty();
                        }

                        log.add('      ' + f + ' = ' + emailVal
                            + (isSfUser ? '  [SF User - suppressable]'
                                        : '  [External - NOT suppressable]'));
                    }
                }
            } catch(Exception e) { log.add('FAIL  ' + e.getMessage()); }
        } else {
            log.add('      WARN: None of the configured email fields exist on this object.');
            log.add('      Check FIELD_MAP in NotificationFilterAction — field API names may be wrong.');
            // Show all email/text fields on the object so user can identify correct names
            log.add('      All Email-type fields on ' + req.objectName + ':');
            for (String fn : fieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fn).getDescribe();
                if (dfr.getType() == Schema.DisplayType.Email
                    || (dfr.getType() == Schema.DisplayType.String
                        && dfr.getName().toLowerCase().contains('email'))) {
                    log.add('        ' + dfr.getName() + ' (' + dfr.getLabel() + ')');
                }
            }
        }
        log.add('');

        // Step 5: Suppression records
        log.add('--- STEP 5: User_Account_Notification__c records ---');
        try {
            List<User_Account_Notification__c> recs = [
                SELECT User__c, User__r.Email, Company__c, Disable_Email__c
                FROM   User_Account_Notification__c
                WHERE  Disable_Email__c = true LIMIT 50
            ];
            if (recs.isEmpty()) {
                log.add('WARN  No suppression records found');
            } else {
                for (User_Account_Notification__c r : recs) {
                    log.add('      User: ' + r.User__r.Email
                        + '  AccountId: ' + r.Company__c
                        + '  TriggeringAccountId: ' + triggeringAccountId
                        + '  Match: ' + (r.Company__c == triggeringAccountId));
                }
            }
        } catch(Exception e) { log.add('FAIL  ' + e.getMessage()); }
        log.add('');

        // Step 6: Field rules
        log.add('--- STEP 6: User_Notification_Preference__c records ---');
        try {
            List<User_Notification_Preference__c> prefs = [
                SELECT User__c, User__r.Email,
                       Object_Name__c, Field_Name__c, Field_Value__c
                FROM   User_Notification_Preference__c LIMIT 50
            ];
            if (prefs.isEmpty()) {
                log.add('WARN  No field rules found');
            } else {
                for (User_Notification_Preference__c p : prefs) {
                    Boolean objMatch = p.Object_Name__c != null &&
                        p.Object_Name__c.toLowerCase() == req.objectName.toLowerCase();

                    // Check actual record field value
                    String actualVal = '(could not read)';
                    if (objMatch && p.Field_Name__c != null
                        && fieldMap.containsKey(p.Field_Name__c.toLowerCase())) {
                        try {
                            List<SObject> rr = Database.query(
                                'SELECT ' + p.Field_Name__c
                                + ' FROM ' + req.objectName
                                + ' WHERE Id = \'' + req.recordId + '\' LIMIT 1'
                            );
                            if (!rr.isEmpty()) {
                                Object vv = rr[0].get(p.Field_Name__c);
                                actualVal = vv != null ? String.valueOf(vv) : '(null)';
                            }
                        } catch(Exception e) { actualVal = 'ERROR: ' + e.getMessage(); }
                    }

                    Boolean valueMatch = actualVal.equalsIgnoreCase(p.Field_Value__c);

                    log.add('      User: '       + p.User__r.Email);
                    log.add('        Object:     ' + p.Object_Name__c + ' | ObjMatch: ' + objMatch);
                    log.add('        Field:      ' + p.Field_Name__c);
                    log.add('        RuleValue:  ' + p.Field_Value__c);
                    log.add('        ActualVal:  ' + actualVal);
                    log.add('        ValueMatch: ' + valueMatch);
                    if (objMatch && valueMatch) {
                        log.add('        >> SHOULD suppress ' + p.User__r.Email);
                        log.add('           BUT only if that email resolves to a SF User in candidate list');
                    }
                }
            }
        } catch(Exception e) { log.add('FAIL  ' + e.getMessage()); }
        log.add('');

        log.add('=== END DIAGNOSTIC ===');
        return String.join(log, '\n');
    }
}