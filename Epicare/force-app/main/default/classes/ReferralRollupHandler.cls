/**
 * Class    : ReferralRollupHandler
 * Called by: trigger ReferralRollupTrigger on Commission_Record__c (after insert, after update)
 *
 * A-6.7.5 Phase 3 — maintains the rollup fields on Referral_Record__c
 * whenever a linked CR-ana (Commission_Record__c.Referral_Record__c != null)
 * is created or its Status__c changes:
 *   - Total_CR_Ana_Created__c    = count of all CR-ana linked to the parent
 *   - Total_CR_Ana_Amount_Paid__c = sum of Net_Amount__c where Status__c = 'Paid'
 *   - Latest_CR_Ana_Period__c    = max Payment_Period__c among linked CR-ana
 *
 * ══════════════════════════════════════════════════════════════════════════
 * DECISION MADE ON YOUR "BEST PRACTICE" INSTRUCTION — flagged, not hidden:
 * Total_CR_Ana_Amount_Paid__c sums Net_Amount__c (Gross_Amount__c -
 * Admin_Fee__c), not Gross_Amount__c. Spec just says "Amount Paid" without
 * specifying which; Net_Amount__c is what the referring agent actually
 * receives after the admin fee, which matches the accounting model section
 * ("Epicare pays the referring agent house.Gross_Amount - Admin_Fee") and
 * an agent-facing "amount paid" reporting field. If this should be Gross
 * instead, it's a one-line swap in calculateRollups() below.
 *
 * FIELDS NOT YET CONFIRMED — same disclosure pattern as every other class in
 * this build: Total_CR_Ana_Created__c, Total_CR_Ana_Amount_Paid__c,
 * Latest_CR_Ana_Period__c are all spec-named but never checked against your
 * org (unlike Accrual_Source__c/Referral_Record__c/Payment_Status__c on
 * Commission_Record__c, which Piece 2 testing already confirmed).
 *
 * NOTE ON TRIGGER COUNT: this is a second trigger on Commission_Record__c
 * (alongside CRAnaReconcileTrigger and your existing CSV-import validation
 * trigger). Salesforce allows multiple triggers per object/event with no
 * guaranteed order between them, which is fine here since this trigger only
 * reads Commission_Record__c and writes to a different object
 * (Referral_Record__c) — no ordering dependency with the others. If your
 * team prefers a single dispatcher trigger per object instead of three
 * separate ones, this logic can be folded into that pattern later.
 * ══════════════════════════════════════════════════════════════════════════
 */
public without sharing class ReferralRollupHandler {

    private static final String STATUS_PAID = 'Paid';

    public static void handleTrigger(List<Commission_Record__c> newRecords, Boolean isInsert,
            Boolean isUpdate, Map<Id, Commission_Record__c> oldMap) {

        // ── Collect Referral_Record__c Ids affected by this transaction:
        // any new CR-ana (insert), or any CR-ana whose Status__c changed (update).
        Set<Id> affectedReferralIds = new Set<Id>();
        for (Commission_Record__c cr : newRecords) {
            if (cr.Referral_Record__c == null) continue;
            if (isInsert) {
                affectedReferralIds.add(cr.Referral_Record__c);
            } else if (isUpdate) {
                Commission_Record__c old = oldMap.get(cr.Id);
                if (old.Status__c != cr.Status__c) {
                    affectedReferralIds.add(cr.Referral_Record__c);
                }
            }
        }
        if (affectedReferralIds.isEmpty()) return;

        Map<Id, RollupValues> rollupsByReferralId = calculateRollups(affectedReferralIds);

        List<Referral_Record__c> toUpdate = new List<Referral_Record__c>();
        for (Id referralId : affectedReferralIds) {
            RollupValues rv = rollupsByReferralId.get(referralId);
            Referral_Record__c ref = new Referral_Record__c(Id = referralId);
            ref.Total_CR_Ana_Created__c     = rv != null ? rv.totalCreated : 0;
            ref.Total_CR_Ana_Amount_Paid__c = rv != null ? rv.totalAmountPaid : 0;
            ref.Latest_CR_Ana_Period__c     = rv != null ? rv.latestPeriod : null;
            toUpdate.add(ref);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private class RollupValues {
        Integer totalCreated = 0;
        Decimal totalAmountPaid = 0;
        String latestPeriod;
    }

    private static Map<Id, RollupValues> calculateRollups(Set<Id> referralIds) {
        Map<Id, RollupValues> result = new Map<Id, RollupValues>();
        for (Id id : referralIds) result.put(id, new RollupValues());

        // Count + latest period across ALL linked CR-ana, any status.
        for (AggregateResult ar : [
            SELECT Referral_Record__c refId, COUNT(Id) cnt, MAX(Payment_Period__c) latest
            FROM   Commission_Record__c
            WHERE  Referral_Record__c IN :referralIds
            GROUP BY Referral_Record__c
        ]) {
            Id refId = (Id) ar.get('refId');
            RollupValues rv = result.get(refId);
            rv.totalCreated = (Integer) ar.get('cnt');
            rv.latestPeriod = (String) ar.get('latest');
        }

        // Sum of Net_Amount__c, Paid CR-ana only.
        for (AggregateResult ar : [
            SELECT Referral_Record__c refId, SUM(Net_Amount__c) totalPaid
            FROM   Commission_Record__c
            WHERE  Referral_Record__c IN :referralIds
            AND    Status__c = :STATUS_PAID
            GROUP BY Referral_Record__c
        ]) {
            Id refId = (Id) ar.get('refId');
            RollupValues rv = result.get(refId);
            Decimal sum = (Decimal) ar.get('totalPaid');
            rv.totalAmountPaid = sum != null ? sum : 0;
        }

        return result;
    }
}