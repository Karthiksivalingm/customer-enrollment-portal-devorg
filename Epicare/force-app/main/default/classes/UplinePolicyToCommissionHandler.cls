public with sharing class UplinePolicyToCommissionHandler {

    /**
     * GO AMS integration API user. Commission_Record__c creation (via
     * Upline_Policy_Created__e) is restricted to this user only — per
     * 26-Aug client call: a Commission_Record__c should ONLY be
     * auto-generated when the Upline_Policy__c is created via the GO AMS
     * enrollment event. Data Loader imports (Carepoint, Claro Insurance,
     * Carrier Direct, Manual) must NOT auto-generate a commission record
     * from policy creation — those sources instead load
     * Commission_Record__c directly and separately (Reconciled, with the
     * real amount from the upline payment statement), which is a
     * completely different flow untouched by this class.
     *
     * This restriction previously existed and was removed at some point
     * ("now runs for all users") — that removal was the root cause of
     * Data Loader imports generating bogus commission records and
     * tripping CommissionRecordTriggerHandler's exception checks.
     */
    private static final String API_USERNAME = 'apiuser@epicare.com';

    /**
     * Fixed lookup from Upline_Source__c + Status__c -> Source_Type__c
     * (a restricted picklist on Commission_Import_Log__c). Free-text
     * concatenation of source + status was throwing "bad picklist value"
     * because most combinations don't match an existing picklist entry.
     *
     * Key format: '<Upline_Source__c>|<Status__c>'
     * Sources that use a single catch-all value regardless of status
     * (Claro Insurance, Carrier Direct, Platform) are looked up by
     * source only via SOURCE_ONLY_MAP as a fallback.
     */
    private static final Map<String, String> SOURCE_STATUS_MAP = new Map<String, String>{
        'Carepoint|Active'                  => 'Carepoint Active Policies',
        'Carepoint|Future'                  => 'Carepoint Future Policies',
        'Carepoint|Rapid_Disenrollment'      => 'Carepoint Disenrollments',
        'Carepoint|Future_Disenrollment'     => 'Carepoint Future Disenrollments',
        'Carepoint|Binder_Payment'           => 'Carepoint Payment Transactions',
        'Carepoint|Cancelled'                => 'Carepoint_Cancellations',
        'Carepoint|Term'                     => 'Carepoint_Terminations',
        'Carepoint|Updated_on_each_import'   => 'Carepoint_Updated_Policies',
        'Carepoint|Not_Register'             => 'Carepoint_Not_Registered',
        'Manual|Active'                      => 'Manual',
        'Manual|Future'                      => 'Manual',
        'Manual|Cancelled'                   => 'Manual',
        'Manual|Term'                        => 'Manual'
    };

    private static final Map<String, String> SOURCE_ONLY_MAP = new Map<String, String>{
        'Claro Insurance' => 'Claro_Insurance_Import',
        'Carrier Direct'  => 'Carrier_Direct_Import',
        'Platform'        => 'Platform_Import',
        'Manual'          => 'Manual'
    };

    /**
     * Bulkified: publishes one Upline_Policy_Created__e per policy, but
     * ONLY when the current running user is the GO AMS integration API
     * user (see API_USERNAME above). Data Loader / manual inserts skip
     * this entirely — no event published, no Commission_Record__c
     * created as a side effect of policy creation.
     *
     * A separate subscriber (UplinePolicyCreatedEventTrigger /
     * UplinePolicyCreatedEventHandler) creates the Commission_Record__c
     * in its own, later transaction — so a validation failure there can
     * never roll back this Upline_Policy__c insert.
     *
     * Commission_Import_Log__c creation is UNCHANGED and still runs for
     * every user/source — it tracks the Upline_Policy__c import batch
     * itself, independent of whether a commission record gets created.
     */
    public static void afterInsert(List<Upline_Policy__c> newUplinePolicies) {
        if (UserInfo.getUserName() == API_USERNAME) {
            List<Upline_Policy_Created__e> eventsToPublish = new List<Upline_Policy_Created__e>();
            for (Upline_Policy__c uPolicy : newUplinePolicies) {
                eventsToPublish.add(new Upline_Policy_Created__e(
                    Upline_Policy__c  = uPolicy.Id,
                    Agent_Code__c     = uPolicy.Agent_Code__c,
                    Agent__c          = uPolicy.Agent__c,
                    Agency__c         = uPolicy.Agency__c,
                    Carrier__c        = uPolicy.Carrier__c,
                    Policy_Number__c  = uPolicy.Policy_Number__c,
                    Effective_Date__c = uPolicy.Effective_Date__c != null
                                            ? String.valueOf(uPolicy.Effective_Date__c)
                                            : null,
                    Premium__c        = uPolicy.Premium__c != null
                                            ? String.valueOf(uPolicy.Premium__c)
                                            : null,
                    Policy_Year__c    = uPolicy.Policy_Year__c != null
                                            ? String.valueOf(uPolicy.Policy_Year__c)
                                            : null,
                    MBI__c            = uPolicy.MBI__c,
                    Upline_Source__c  = uPolicy.Upline_Source__c,
                    Status__c         = uPolicy.Status__c
                ));
            }
            if (!eventsToPublish.isEmpty()) {
                EventBus.publish(eventsToPublish);
            }
        }

        createImportLogs(newUplinePolicies, true);
    }

    /**
     * Runs after update. Same log-creation behavior as afterInsert,
     * counted as "Records_Updated__c" instead of "Records_Created__c".
     * Does NOT touch Commission_Record__c on update — unaffected by
     * today's change since it never created commission records anyway.
     */
    public static void afterUpdate(List<Upline_Policy__c> updatedUplinePolicies) {
        createImportLogs(updatedUplinePolicies, false);
    }

    /**
     * Groups the batch by Upline_Source__c + Status__c, and inserts one
     * Commission_Import_Log__c per group with the count and Completed
     * status. isInsert controls whether the count goes into
     * Records_Created__c or Records_Updated__c.
     *
     * Source_Type__c is a restricted picklist, so the value is resolved
     * via SOURCE_STATUS_MAP first, falling back to SOURCE_ONLY_MAP by
     * source alone (Claro Insurance / Carrier Direct / Platform / Manual
     * use one catch-all value regardless of status). Any combo not
     * covered by either map defaults to 'Manual' rather than throwing
     * or being dropped.
     *
     * At_Risk_Count__c is left at 0 — no source field identified yet.
     */
    private static void createImportLogs(List<Upline_Policy__c> policies, Boolean isInsert) {
        Map<String, Integer> countByGroup = new Map<String, Integer>();
        Map<String, String>  sourceByGroup = new Map<String, String>();
        Map<String, String>  statusByGroup = new Map<String, String>();

        for (Upline_Policy__c p : policies) {
            String source = p.Upline_Source__c;
            String status = p.Status__c;
            String key = source + '|' + status;

            countByGroup.put(key, (countByGroup.containsKey(key) ? countByGroup.get(key) : 0) + 1);
            sourceByGroup.put(key, source);
            statusByGroup.put(key, status);
        }

        List<Commission_Import_Log__c> logsToInsert = new List<Commission_Import_Log__c>();
        for (String key : countByGroup.keySet()) {
            String source = sourceByGroup.get(key);
            String status = statusByGroup.get(key);
            Integer count = countByGroup.get(key);

            String sourceType = SOURCE_STATUS_MAP.get(key);
            if (sourceType == null) {
                sourceType = SOURCE_ONLY_MAP.get(source);
            }
            if (sourceType == null) {
                // Unmapped Upline_Source__c/Status__c combo — default to
                // 'Manual' so the import log is never dropped.
                System.debug(LoggingLevel.WARN,
                    'UplinePolicyToCommissionHandler: no Source_Type__c mapping for '
                    + 'Upline_Source__c=' + source + ', Status__c=' + status
                    + ' — defaulting to Manual (' + count + ' record(s)).');
                sourceType = 'Manual';
            }

            Commission_Import_Log__c logRec = new Commission_Import_Log__c(
                Source_Type__c        = sourceType,
                Processing_Status__c  = 'Completed',
                Import_Date__c        = System.now()
             //   At_Risk_Count__c      = 0
            );

            if (isInsert) {
                logRec.Records_Created__c = count;
                logRec.Records_Updated__c = 0;
            } else {
                logRec.Records_Created__c = 0;
                logRec.Records_Updated__c = count;
            }

            logsToInsert.add(logRec);
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}