public with sharing class uLabOrderTriggerHandler {

    private static final String OBJECT_NAME = 'uLab_Order__c';

    // ══════════════════════════════════════════════════════════════════════
    // INVOCABLE — called from Flow
    // ══════════════════════════════════════════════════════════════════════

    @InvocableMethod(
        label       = 'Send uLab Order Email Notification'
        description = 'Reads Email Alert config and sends notification. Called from Flow.'
    )
    public static void sendNotification(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return;

        // ── 1. Query records to get status ────────────────────────────────
        List<uLab_Order__c> records = [
            SELECT Id, uAssist_Status__c
            FROM   uLab_Order__c
            WHERE  Id IN :recordIds
        ];

        // ── 2. Load Custom Metadata keyed by MasterLabel ──────────────────
        Map<String, Ulab_Order_Notification__mdt> statusToMdt =
            new Map<String, Ulab_Order_Notification__mdt>();

        for (Ulab_Order_Notification__mdt mdt : [
            SELECT MasterLabel, Email_Alert_Name__c, Email_Template_Name__c
            FROM   Ulab_Order_Notification__mdt
            WHERE  Email_Alert_Name__c    != null
            AND    Email_Template_Name__c != null
        ]) {
            statusToMdt.put(mdt.MasterLabel, mdt);
        }

        // ── 3. Enqueue one queueable per alert type ───────────────────────
        // Group records by alert so we make one Metadata API callout per alert
        Map<String, Set<Id>> alertToRecordIds   = new Map<String, Set<Id>>();
        Map<String, String>  alertToTemplate    = new Map<String, String>();

        for (uLab_Order__c rec : records) {
            Ulab_Order_Notification__mdt mdt = statusToMdt.get(rec.uAssist_Status__c);
            if (mdt == null) {
                System.debug(LoggingLevel.WARN,
                    'uLabOrderTriggerHandler: no metadata for status "'
                    + rec.uAssist_Status__c + '" on record ' + rec.Id);
                continue;
            }

            String alertKey = mdt.Email_Alert_Name__c;
            if (!alertToRecordIds.containsKey(alertKey)) {
                alertToRecordIds.put(alertKey, new Set<Id>());
                alertToTemplate.put(alertKey, mdt.Email_Template_Name__c);
            }
            alertToRecordIds.get(alertKey).add(rec.Id);
        }

        // ── 4. Enqueue one queueable per unique alert ─────────────────────
        for (String alertKey : alertToRecordIds.keySet()) {
            System.enqueueJob(new EmailAlertReaderQueueable(
                alertToRecordIds.get(alertKey),   // record IDs for this alert
                alertKey,                          // Email Alert DeveloperName
                alertToTemplate.get(alertKey),     // EmailTemplate DeveloperName
                OBJECT_NAME                        // object API name
            ));
        }
    }
}