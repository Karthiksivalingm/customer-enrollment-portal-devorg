/**
 * Class    : ReferralAccrualBatch
 * Runs as : Scheduled Apex, cron '0 0 10 12 * ?' (10:00 AM ET, 12th of each
 *           month — before PaymentBatchAssembly at 11:00 AM per spec).
 *
 * A-6.7.5 Piece 3 — generates Branch B (Advanced_Commission_6/_9,
 * Partial_Advance_Annual) CR-ana records for months 2 through N. Piece 2
 * (CRAnaReconcileTrigger/Handler) only ever creates the FIRST period's
 * CR-ana for Branch B; every month after that comes from this batch.
 * Branch A (As_Earned) is entirely handled by Piece 2 — this batch never
 * touches it.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * SHARED LOGIC WITH PIECE 2 — DUPLICATED, NOT EXTRACTED: the Admin_Fee
 * calculation (Override_Type__c-driven, same formula reuse rationale as the
 * override branch and CRAnaReconcileHandler) is duplicated here rather than
 * factored into a shared utility class. If the formula assumption in
 * CRAnaReconcileHandler's header (item 4) turns out wrong, both copies need
 * the same fix — worth extracting to a shared class once the formula is
 * confirmed, to avoid the two copies drifting apart.
 *
 * FIELDS NOT YET CONFIRMED — same disclosure pattern as every other class
 * in this build:
 *  1. Upline_Policy__c.Status__c and the exact picklist values 'Cancelled',
 *     'Term', 'Rapid_Disenrollment' — spec names these as the chargeback-
 *     protection check but they've never been confirmed against your org.
 *  2. Commission_Record__c.Payment_Status__c, .Accrual_Source__c,
 *     .Referral_Record__c — same open items as CRAnaReconcileHandler.
 *
 * DEFENSIVE ADDITION (mine, not spec text): the Upline_Policy__c lookup adds
 * a Carrier__c filter alongside Policy_Number__c, since Policy_Number is
 * only unique per-carrier per your own upline dedupe key notes
 * (Upline_Policy_Key__c = NORMALIZE(Carrier Name) + '_' + Policy_Number__c).
 * The spec's pseudocode only shows "WHERE Policy_Number = referral.Policy_Number",
 * which could match the wrong carrier's policy if numbers collide across carriers.
 * ══════════════════════════════════════════════════════════════════════════
 */
public without sharing class ReferralAccrualBatch implements Database.Batchable<SObject>, Schedulable {

    private static final String PM_ADVANCED_COMMISSION_6  = 'Advanced_Commission_6';
    private static final String PM_ADVANCED_COMMISSION_9  = 'Advanced_Commission_9';
    private static final String PM_PARTIAL_ADVANCE_ANNUAL = 'Partial_Advance_Annual';
    private static final Set<String> BRANCH_B_MODELS = new Set<String>{
        PM_ADVANCED_COMMISSION_6, PM_ADVANCED_COMMISSION_9, PM_PARTIAL_ADVANCE_ANNUAL
    };

    private static final String REFERRAL_STATUS_VERIFIED = 'Verified';
    private static final Set<String> CANCELLED_POLICY_STATUSES = new Set<String>{
        'Cancelled', 'Term', 'Rapid_Disenrollment'
    };

    private static final String COMPENSATION_TYPE_COMMISSION = 'Commission';
    private static final String PAYMENT_STATUS_PENDING       = 'Pending';
    private static final String ACCRUAL_SOURCE_BATCH          = 'Advance_Accrual_Batch';

    private static final String OVERRIDE_TYPE_FIXED_AMOUNT   = 'Fixed Amount';
    private static final String OVERRIDE_TYPE_PCT_COMMISSION = 'Percentage Of Commission';
    private static final String OVERRIDE_TYPE_PCT_PREMIUM    = 'Percentage Of Premium';

    // ── Schedulable ─────────────────────────────────────────────────────
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ReferralAccrualBatch(), 200);
    }

    // ── Batchable ───────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Policy_Number__c, Carrier__c, Writing_Agent__c, Referring_Agent__c,
                   Payment_Model_Snapshot__c, Advance_Through_Month_Snapshot__c,
                   Effective_Date__c, Agreement__c, Agreement__r.Override_Type__c,
                   Agreement__r.Override_Amount__c, Agreement__r.Override_Percentage__c
            FROM   Referral_Record__c
            WHERE  Status__c = :REFERRAL_STATUS_VERIFIED
            AND    Payment_Model_Snapshot__c IN :BRANCH_B_MODELS
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Referral_Record__c> referrals = (List<Referral_Record__c>) scope;
        String targetPeriod = formatPaymentPeriod(Date.today().addMonths(-1)); // accrue month N-1

        // ── Chargeback protection: skip referrals whose Upline_Policy is
        // Cancelled/Term/Rapid_Disenrollment. Matched by Carrier + Policy_Number
        // (defensive addition — see header).
        Set<String> policyKeys = new Set<String>();
        for (Referral_Record__c ref : referrals) {
            policyKeys.add(ref.Carrier__c + '_' + ref.Policy_Number__c);
        }
        Map<String, Upline_Policy__c> policyByKey = new Map<String, Upline_Policy__c>();
        if (!policyKeys.isEmpty()) {
            for (Upline_Policy__c up : [
                SELECT Id, Carrier__c, Policy_Number__c, Status__c
                FROM   Upline_Policy__c
                WHERE  Policy_Number__c IN :extractPolicyNumbers(referrals)
            ]) {
                policyByKey.put(up.Carrier__c + '_' + up.Policy_Number__c, up);
            }
        }

        // ── Existence check: skip referrals that already have a CR-ana for
        // this target period.
        Set<Id> referralIds = new Set<Id>();
        for (Referral_Record__c ref : referrals) referralIds.add(ref.Id);
        Set<Id> referralsAlreadyAccrued = new Set<Id>();
        for (Commission_Record__c existing : [
            SELECT Referral_Record__c FROM Commission_Record__c
            WHERE  Referral_Record__c IN :referralIds AND Payment_Period__c = :targetPeriod
        ]) {
            referralsAlreadyAccrued.add(existing.Referral_Record__c);
        }

        // ── Paired CR-house lookup, keyed by Writing_Agent + Policy_Number +
        // target_period (spec: "Contact = referral.Writing_Agent"; CR-house's
        // Contact is stored on Agent__c per Piece 1's convention).
        Set<Id> writingAgentIds = new Set<Id>();
        for (Referral_Record__c ref : referrals) {
            if (ref.Writing_Agent__c != null) writingAgentIds.add(ref.Writing_Agent__c);
        }
        Map<String, Commission_Record__c> crHouseByKey = new Map<String, Commission_Record__c>();
        if (!writingAgentIds.isEmpty()) {
            for (Commission_Record__c cr : [
                SELECT Id, Agent__c, Policy_Number__c, Payment_Period__c, Gross_Amount__c,
                       Compensation_Type__c, Appointment__c, Policy_Year__c
                FROM   Commission_Record__c
                WHERE  Agent__c IN :writingAgentIds
                AND    Payment_Period__c = :targetPeriod
                AND    Compensation_Type__c = :COMPENSATION_TYPE_COMMISSION
            ]) {
                crHouseByKey.put(cr.Agent__c + '_' + cr.Policy_Number__c, cr);
            }
        }

        // ── Appointment premiums, only if a Percentage_Of_Premium admin fee
        // needs computing.
        Set<Id> appointmentIdsNeedingPremium = new Set<Id>();
        for (Referral_Record__c ref : referrals) {
            if (ref.Agreement__c != null && ref.Agreement__r.Override_Type__c == OVERRIDE_TYPE_PCT_PREMIUM) {
                Commission_Record__c cr = crHouseByKey.get(ref.Writing_Agent__c + '_' + ref.Policy_Number__c);
                if (cr != null && cr.Appointment__c != null) appointmentIdsNeedingPremium.add(cr.Appointment__c);
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

        // ── Build CR-ana records.
        List<Commission_Record__c> crAnaRecords = new List<Commission_Record__c>();
        for (Referral_Record__c ref : referrals) {
            if (referralsAlreadyAccrued.contains(ref.Id)) continue; // idempotent

            Upline_Policy__c policy = policyByKey.get(ref.Carrier__c + '_' + ref.Policy_Number__c);
            if (policy != null && CANCELLED_POLICY_STATUSES.contains(policy.Status__c)) continue; // chargeback protection

            Integer maxAdvanceMonthCount = ref.Payment_Model_Snapshot__c == PM_ADVANCED_COMMISSION_6 ? 6
                : ref.Payment_Model_Snapshot__c == PM_ADVANCED_COMMISSION_9 ? 9
                : ref.Advance_Through_Month_Snapshot__c != null ? Integer.valueOf(ref.Advance_Through_Month_Snapshot__c) : 0;

            if (ref.Effective_Date__c == null || maxAdvanceMonthCount <= 0) continue;
            String maxAdvancePeriod = formatPaymentPeriod(ref.Effective_Date__c.addMonths(maxAdvanceMonthCount));
            if (targetPeriod > maxAdvancePeriod) continue; // advance fully covered

            Commission_Record__c crHouse = crHouseByKey.get(ref.Writing_Agent__c + '_' + ref.Policy_Number__c);
            if (crHouse == null) continue; // no paired CR-house reconciled for this period yet

            Decimal adminFee = calculateAdminFee(ref, crHouse, premiumByAppointmentId);

            Commission_Record__c crAna = new Commission_Record__c();
            crAna.Contact__c             = ref.Referring_Agent__c;
            crAna.Policy_Number__c       = ref.Policy_Number__c;
            crAna.Payment_Period__c      = targetPeriod;
            crAna.Compensation_Type__c   = COMPENSATION_TYPE_COMMISSION;
            crAna.Payment_Flow__c        = 'Referral';
            crAna.Payment_Model__c       = ref.Payment_Model_Snapshot__c;
            crAna.Gross_Amount__c        = crHouse.Gross_Amount__c;
            crAna.Admin_Fee__c           = adminFee;
            crAna.Status__c              = 'Reconciled';
            crAna.Payment_Status__c      = PAYMENT_STATUS_PENDING; // CONFIRM field exists — see header
            crAna.Referral_Record__c     = ref.Id;
            crAna.Original_Commission__c = crHouse.Id;
            crAna.Accrual_Source__c      = ACCRUAL_SOURCE_BATCH; // CONFIRM field/picklist value exist — see header
            crAna.Policy_Year__c         = crHouse.Policy_Year__c;
            crAnaRecords.add(crAna);
        }

        if (!crAnaRecords.isEmpty()) {
            insert crAnaRecords;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // No follow-up action specified by spec.
    }

    // ─────────────────────────────────────────────────────────────────────

    private static Set<String> extractPolicyNumbers(List<Referral_Record__c> referrals) {
        Set<String> policyNumbers = new Set<String>();
        for (Referral_Record__c ref : referrals) {
            if (ref.Policy_Number__c != null) policyNumbers.add(ref.Policy_Number__c);
        }
        return policyNumbers;
    }

    private static String formatPaymentPeriod(Date d) {
        String mm = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        return d.year() + '-' + mm;
    }

    // Duplicated from CRAnaReconcileHandler — see header note on why.
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