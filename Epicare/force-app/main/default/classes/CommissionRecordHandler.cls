public with sharing class CommissionRecordHandler {
// ── Constants (replace with Custom Setting/Metadata post-MVP) ────────────
    private static final String  STATUS_RECONCILED   = 'Reconciled';
    private static final String  STATUS_ESTIMATED    = 'Estimated';
    private static final String  EXCEPTION_STATUS    = 'Open';
    private static final String  EX_UNDERPAID        = 'Underpaid';
    private static final String  EX_OVERPAID         = 'Overpaid';
    private static final String  EX_UNKNOWN_POLICY   = 'Unknown_Policy';
    private static final String  EX_PAYMENT_MISMATCH = 'Payment Flow Mismatch';
    private static final Decimal TOLERANCE           = 0.50;
    private static final Integer FOLLOWUP_DAYS       = 7;

    @TestVisible
    private static Set<Integer> pendingFlowIndexes = new Set<Integer>();

    public static void handleBeforeInsert(List<Commission_Record__c> newRecords) {

        pendingFlowIndexes.clear();

        Set<Id> appointmentIds = new Set<Id>();
        for (Commission_Record__c cr : newRecords) {
            if (String.isBlank(cr.Payment_Flow__c) && cr.Appointment__c != null) {
                appointmentIds.add(cr.Appointment__c);
            }
        }

        System.debug('### BEFORE INSERT — appointmentIds: ' + appointmentIds);

        if (!appointmentIds.isEmpty()) {

            Map<Id, Appointment__c> appointmentMap = new Map<Id, Appointment__c>(
                [SELECT Id, Payment_Flow__c
                 FROM   Appointment__c
                 WHERE  Id IN :appointmentIds]
            );

            System.debug('### BEFORE INSERT — appointmentMap: ' + appointmentMap);

            for (Integer i = 0; i < newRecords.size(); i++) {
                Commission_Record__c cr = newRecords[i];

                if (String.isBlank(cr.Payment_Flow__c) && cr.Appointment__c != null) {
                    Appointment__c appt = appointmentMap.get(cr.Appointment__c);
                    if (appt == null) continue;

                    cr.Payment_Flow__c = appt.Payment_Flow__c;
                    System.debug('### BEFORE INSERT — stamped index ' + i + ' with: ' + appt.Payment_Flow__c);

                    if (appt.Payment_Flow__c == 'Pending') {
                        pendingFlowIndexes.add(i);
                        System.debug('### BEFORE INSERT — added index ' + i + ' to pendingFlowIndexes');
                    }
                }
            }

            System.debug('### BEFORE INSERT — pendingFlowIndexes final: ' + pendingFlowIndexes);
        }

        // ── NEW: Reject blank Payment_Flow__c after stamp attempt ─────────────
        // If Payment_Flow__c is still blank at this point — either no
        // Appointment was provided, or the Appointment itself has no
        // Payment_Flow__c — block the insert with a validation error.
        for (Commission_Record__c cr : newRecords) {
            if (String.isBlank(cr.Payment_Flow__c)) {
                cr.Payment_Flow__c.addError(
                    'Payment Flow is required. Ensure the related Appointment '
                    + 'has a Payment Flow set before creating a Commission Record.'
                );
            }
        }
    }

    public static void handleAfterInsert(List<Commission_Record__c> newRecords) {

        List<Commission_Exception__c> exceptionsToInsert = new List<Commission_Exception__c>();

        // ── §7.5: Payment_Flow_Mismatch soft-flag ────────────────────────────
        Set<Id> crIds = new Map<Id, Commission_Record__c>(newRecords).keySet();
        System.debug('### AFTER INSERT — crIds: ' + crIds);

        Map<Id, Commission_Record__c> stampedMap = new Map<Id, Commission_Record__c>(
            [SELECT Id, Payment_Flow__c
             FROM   Commission_Record__c
             WHERE  Id IN :crIds]
        );
        System.debug('### AFTER INSERT — stampedMap: ' + stampedMap);

        for (Commission_Record__c cr : newRecords) {
            Commission_Record__c stamped = stampedMap.get(cr.Id);
            System.debug('### AFTER INSERT — cr.Id: ' + cr.Id + ' | stamped: ' + stamped);
            if (stamped != null && stamped.Payment_Flow__c == 'Pending') {
                System.debug('### AFTER INSERT — creating exception for: ' + cr.Id);
                Commission_Exception__c ex = new Commission_Exception__c();
                ex.Commission_Record__c = cr.Id;
                ex.Exception_Type__c    = EX_PAYMENT_MISMATCH;
                exceptionsToInsert.add(ex);
            }
        }

        System.debug('### AFTER INSERT — exceptionsToInsert size: ' + exceptionsToInsert.size());
        pendingFlowIndexes.clear();

        // ── §orig: Reconciliation matching ───────────────────────────────────
        List<Commission_Record__c> reconciledRecords = new List<Commission_Record__c>();
        for (Commission_Record__c rec : newRecords) {
            if (rec.Status__c == STATUS_RECONCILED) {
                reconciledRecords.add(rec);
            }
        }

        if (!reconciledRecords.isEmpty()) {

            Set<String> policyNumbers  = new Set<String>();
            Set<String> paymentPeriods = new Set<String>();
            Set<Id>     agentIds       = new Set<Id>();

            for (Commission_Record__c rec : reconciledRecords) {
                policyNumbers.add(rec.Policy_Number__c);
                paymentPeriods.add(rec.Payment_Period__c);
                agentIds.add(rec.Agent__c);
            }

            Map<String, Commission_Record__c> estimatedByKey =
                new Map<String, Commission_Record__c>();

            for (Commission_Record__c est : [
                SELECT Id,
                       Policy_Number__c,
                       Payment_Period__c,
                       Agent__c,
                       Gross_Amount__c
                FROM   Commission_Record__c
                WHERE  Status__c         = :STATUS_ESTIMATED
                AND    Policy_Number__c  IN :policyNumbers
                AND    Payment_Period__c IN :paymentPeriods
                AND    Agent__c          IN :agentIds
            ]) {
                String key = makeKey(
                    est.Policy_Number__c,
                    est.Payment_Period__c,
                    est.Agent__c
                );
                if (!estimatedByKey.containsKey(key)) {
                    estimatedByKey.put(key, est);
                }
            }

            List<Commission_Record__c> estimatedToUpdate =
                new List<Commission_Record__c>();

            for (Commission_Record__c rec : reconciledRecords) {
                String key = makeKey(
                    rec.Policy_Number__c,
                    rec.Payment_Period__c,
                    rec.Agent__c
                );
                Commission_Record__c estimated = estimatedByKey.get(key);

                if (estimated != null) {
                    Decimal delta = (rec.Gross_Amount__c
                                  - estimated.Gross_Amount__c).abs();

                    if (delta <= TOLERANCE) {
                        estimatedToUpdate.add(new Commission_Record__c(
                            Id        = estimated.Id,
                            Status__c = STATUS_RECONCILED
                        ));
                    } else {
                        String exType = (rec.Gross_Amount__c < estimated.Gross_Amount__c)
                                        ? EX_UNDERPAID
                                        : EX_OVERPAID;
                        exceptionsToInsert.add(
                            buildException(rec, estimated.Gross_Amount__c, exType)
                        );
                    }
                } else {
                    exceptionsToInsert.add(
                        buildException(rec, 0, EX_UNKNOWN_POLICY)
                    );
                }
            }

            if (!estimatedToUpdate.isEmpty()) update estimatedToUpdate;
        }

        System.debug('### AFTER INSERT — final exceptionsToInsert size: '
            + exceptionsToInsert.size());

        if (!exceptionsToInsert.isEmpty()) {
            try {
                insert exceptionsToInsert;
                System.debug('### AFTER INSERT — exceptions inserted successfully');
            } catch (Exception e) {
                System.debug('### AFTER INSERT — exception insert FAILED: '
                    + e.getMessage());
            }
        }
    }

    private static Commission_Exception__c buildException(
            Commission_Record__c rec,
            Decimal              expectedAmount,
            String               exceptionType) {

        return new Commission_Exception__c(
            Commission_Record__c = rec.Id,
            Carrier__c           = rec.Carrier__c,
            Agent__c             = rec.Agent__c,
            Policy_Number__c     = rec.Policy_Number__c,
            Exception_Type__c    = exceptionType,
            Expected_Amount__c   = expectedAmount,
            Actual_Amount__c     = rec.Gross_Amount__c,
            Status__c            = EXCEPTION_STATUS,
            Follow_Up_Date__c    = Date.today().addDays(FOLLOWUP_DAYS)
        );
    }

    private static String makeKey(
            String policyNumber,
            String paymentPeriod,
            Id     agentId) {

        return policyNumber + '|' + paymentPeriod + '|' + String.valueOf(agentId);
    }
    
}