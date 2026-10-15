/**
 * Class    : CRAnaReconcileHandler
 * Called by: trigger CRAnaReconcileTrigger on Commission_Record__c (after update)
 *
 * A-6.7.5 Piece 2 — creates the referring agent's Commission_Record
 * ("CR-ana") when a referred sale's house record ("CR-house") transitions to
 * Status__c = Reconciled. Branch A (As_Earned) creates a CR-ana every time.
 * Branch B (Advanced/Partial) only creates the FIRST period's CR-ana here —
 * remaining months come from ReferralAccrualBatch (Piece 3, not built yet).
 *
 * NEEDS CONFIRMATION before deploy:
 *  - Commission_Record__c.Payment_Status__c — spec-named, never confirmed
 *    live in your org (not in any Object Manager screenshot or debug log so far)
 *  - Commission_Record__c.Accrual_Source__c — spec-named as a NEW build
 *    item, not yet live-tested; may need its picklist value activated,
 *    same as Missing_Rate did
 *  - Commission_Record__c.Referral_Record__c — inferred lookup name (same
 *    convention as the confirmed .Agreement__c field), not yet live-tested
 *  - Admin_Fee formula for Referral_Fee Agreements — spec never states the
 *    formula, only "from Agreement." Reused the same Override_Type__c logic
 *    as the override branch since the schema is shared — confirm this is
 *    actually how Referral_Fee Agreements are meant to be read.
 *
 * Added beyond literal spec text: filters to Compensation_Type__c =
 * 'Commission' so an Override record reconciling for the same house
 * Contact+Policy_Number can't spuriously trigger a CR-ana.
 */
public without sharing class CRAnaReconcileHandler {

    private static final String PM_AS_EARNED_PMPM        = 'As_Earned_PMPM';
    private static final String PM_AS_EARNED_PPPM         = 'As_Earned_PPPM';
    private static final String PM_ADVANCED_COMMISSION_6  = 'Advanced_Commission_6';
    private static final String PM_ADVANCED_COMMISSION_9  = 'Advanced_Commission_9';
    private static final String PM_PARTIAL_ADVANCE_ANNUAL = 'Partial_Advance_Annual';

    private static final Set<String> BRANCH_A_MODELS = new Set<String>{ PM_AS_EARNED_PMPM, PM_AS_EARNED_PPPM };
    private static final Set<String> BRANCH_B_MODELS = new Set<String>{
        PM_ADVANCED_COMMISSION_6, PM_ADVANCED_COMMISSION_9, PM_PARTIAL_ADVANCE_ANNUAL
    };

    private static final String REFERRAL_STATUS_VERIFIED    = 'Verified';
    private static final String COMPENSATION_TYPE_COMMISSION = 'Commission';
    private static final String STATUS_RECONCILED           = 'Reconciled';
    private static final String ACCRUAL_SOURCE_STATEMENT     = 'Statement_Reconciled';
    private static final String PAYMENT_STATUS_PENDING       = 'Pending';

    private static final String OVERRIDE_TYPE_FIXED_AMOUNT   = 'Fixed Amount';
    private static final String OVERRIDE_TYPE_PCT_COMMISSION = 'Percentage Of Commission';
    private static final String OVERRIDE_TYPE_PCT_PREMIUM    = 'Percentage Of Premium';

    public static void handleAfterUpdate(List<Commission_Record__c> newRecords, Map<Id, Commission_Record__c> oldMap) {
        // ── Identify CR-house records that just transitioned to Reconciled.
        List<Commission_Record__c> transitioned = new List<Commission_Record__c>();
        for (Commission_Record__c cr : newRecords) {
            Commission_Record__c old = oldMap.get(cr.Id);
            if (cr.Status__c == STATUS_RECONCILED
                && old.Status__c != STATUS_RECONCILED
                && cr.Compensation_Type__c == COMPENSATION_TYPE_COMMISSION) {
                transitioned.add(cr);
            }
        }
        if (transitioned.isEmpty()) return;

        // ── Bulk-fetch matching Verified Referral_Records, keyed by
        // Writing_Agent + Policy_Number. CR-house's Contact is stored on
        // Agent__c (same field Piece 1 stamps), matching Writing_Agent__c.
        Set<Id> agentIds = new Set<Id>();
        Set<String> policyNumbers = new Set<String>();
        for (Commission_Record__c cr : transitioned) {
            if (cr.Agent__c != null) agentIds.add(cr.Agent__c);
            if (cr.Policy_Number__c != null) policyNumbers.add(cr.Policy_Number__c);
        }

        Map<String, Referral_Record__c> referralByKey = new Map<String, Referral_Record__c>();
        if (!agentIds.isEmpty() && !policyNumbers.isEmpty()) {
            for (Referral_Record__c ref : [
                SELECT Id, Writing_Agent__c, Policy_Number__c, Payment_Model_Snapshot__c,
                       Effective_Date__c, Referring_Agent__c, Agreement__c,
                       Agreement__r.Override_Type__c, Agreement__r.Override_Amount__c,
                       Agreement__r.Override_Percentage__c
                FROM   Referral_Record__c
                WHERE  Writing_Agent__c IN :agentIds
                AND    Policy_Number__c IN :policyNumbers
                AND    Status__c = :REFERRAL_STATUS_VERIFIED
            ]) {
                String key = ref.Writing_Agent__c + '_' + ref.Policy_Number__c;
                referralByKey.put(key, ref);
            }
        }
        if (referralByKey.isEmpty()) return; // none of these transitions are referred sales

        // ── Determine candidates: Branch A always, Branch B only on the
        // first accrual period (matches Referral_Record.Effective_Date).
        List<CrAnaCandidate> candidates = new List<CrAnaCandidate>();
        for (Commission_Record__c cr : transitioned) {
            String key = cr.Agent__c + '_' + cr.Policy_Number__c;
            Referral_Record__c ref = referralByKey.get(key);
            if (ref == null) continue;

            String model = ref.Payment_Model_Snapshot__c;
            if (BRANCH_A_MODELS.contains(model)) {
                candidates.add(new CrAnaCandidate(cr, ref));
            } else if (BRANCH_B_MODELS.contains(model)) {
                String firstAccrualPeriod = formatPaymentPeriod(ref.Effective_Date__c);
                if (cr.Payment_Period__c == firstAccrualPeriod) {
                    candidates.add(new CrAnaCandidate(cr, ref));
                }
                // else: later months — handled by ReferralAccrualBatch (Piece 3), not here.
            }
            // Unrecognized Payment_Model_Snapshot__c: no candidate, explicit no-op.
        }
        if (candidates.isEmpty()) return;

        // ── Idempotency: skip any (Referral_Record, Payment_Period) that
        // already has a CR-ana.
        Set<Id> referralIds = new Set<Id>();
        for (CrAnaCandidate c : candidates) referralIds.add(c.referral.Id);

        Set<String> existingKeys = new Set<String>();
        for (Commission_Record__c existing : [
            SELECT Referral_Record__c, Payment_Period__c
            FROM   Commission_Record__c
            WHERE  Referral_Record__c IN :referralIds
        ]) {
            existingKeys.add(existing.Referral_Record__c + '_' + existing.Payment_Period__c);
        }

        // ── Bulk-fetch Appointment Premiums, only needed if any Referral_Fee
        // Agreement uses Percentage_Of_Premium for the admin fee calc.
        Set<Id> appointmentIdsNeedingPremium = new Set<Id>();
        for (CrAnaCandidate c : candidates) {
            if (c.referral.Agreement__c != null
                && c.referral.Agreement__r.Override_Type__c == OVERRIDE_TYPE_PCT_PREMIUM) {
                if (c.crHouse.Appointment__c != null) appointmentIdsNeedingPremium.add(c.crHouse.Appointment__c);
            }
        }
        Map<Id, Decimal> premiumByAppointmentId = new Map<Id, Decimal>();
        if (!appointmentIdsNeedingPremium.isEmpty()) {
            for (Appointment__c appt : [
                SELECT Id, Premium__c FROM Appointment__c WHERE Id IN :appointmentIdsNeedingPremium
            ]) {
                premiumByAppointmentId.put(appt.Id, appt.Premium__c);
            }
        }

        // ── Build and insert CR-ana records.
        List<Commission_Record__c> crAnaRecords = new List<Commission_Record__c>();
        for (CrAnaCandidate c : candidates) {
            String key = c.referral.Id + '_' + c.crHouse.Payment_Period__c;
            if (existingKeys.contains(key)) continue;

            Decimal adminFee = calculateAdminFee(c.referral, c.crHouse, premiumByAppointmentId);

            Commission_Record__c crAna = new Commission_Record__c();
            crAna.Contact__c            = c.referral.Referring_Agent__c;
            crAna.Policy_Number__c      = c.referral.Policy_Number__c;
            crAna.Payment_Period__c     = c.crHouse.Payment_Period__c;
            crAna.Compensation_Type__c  = COMPENSATION_TYPE_COMMISSION;
            crAna.Payment_Flow__c       = 'Referral';
            crAna.Payment_Model__c      = c.referral.Payment_Model_Snapshot__c;
            crAna.Gross_Amount__c       = c.crHouse.Gross_Amount__c;
            crAna.Admin_Fee__c          = adminFee;
            crAna.Status__c             = STATUS_RECONCILED; // born directly Reconciled, per spec Option B
            crAna.Payment_Status__c     = PAYMENT_STATUS_PENDING; // confirm field exists
            crAna.Referral_Record__c    = c.referral.Id;
            crAna.Original_Commission__c = c.crHouse.Id;
            crAna.Accrual_Source__c     = ACCRUAL_SOURCE_STATEMENT; // confirm field/value exist
            crAna.Policy_Year__c        = c.crHouse.Policy_Year__c; // copied from paired CR-house
            crAnaRecords.add(crAna);
        }

        if (!crAnaRecords.isEmpty()) {
            insert crAnaRecords;
        }
    }

    // ─────────────────────────────────────────────────────────────────────

    private class CrAnaCandidate {
        Commission_Record__c crHouse;
        Referral_Record__c referral;
        CrAnaCandidate(Commission_Record__c crHouse, Referral_Record__c referral) {
            this.crHouse = crHouse;
            this.referral = referral;
        }
    }

    private static String formatPaymentPeriod(Date d) {
        if (d == null) return null;
        String mm = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        return d.year() + '-' + mm;
    }

    // Admin_Fee formula reused from the override branch — inference, not a
    // spec-stated formula. See header note.
    private static Decimal calculateAdminFee(Referral_Record__c referral, Commission_Record__c crHouse,
            Map<Id, Decimal> premiumByAppointmentId) {
        if (referral.Agreement__c == null) return 0;
        String overrideType = referral.Agreement__r.Override_Type__c;

        if (overrideType == OVERRIDE_TYPE_FIXED_AMOUNT && referral.Agreement__r.Override_Amount__c != null) {
            return referral.Agreement__r.Override_Amount__c;
        } else if (overrideType == OVERRIDE_TYPE_PCT_COMMISSION && referral.Agreement__r.Override_Percentage__c != null) {
            return crHouse.Gross_Amount__c != null
                ? crHouse.Gross_Amount__c * referral.Agreement__r.Override_Percentage__c : 0;
        } else if (overrideType == OVERRIDE_TYPE_PCT_PREMIUM && referral.Agreement__r.Override_Percentage__c != null) {
            Decimal premium = crHouse.Appointment__c != null
                ? premiumByAppointmentId.get(crHouse.Appointment__c) : null;
            return premium != null ? premium * referral.Agreement__r.Override_Percentage__c : 0;
        }
        return 0;
    }
}