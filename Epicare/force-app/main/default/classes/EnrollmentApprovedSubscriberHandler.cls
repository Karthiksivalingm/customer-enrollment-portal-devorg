/**
 * Class    : EnrollmentApprovedSubscriberHandler
 * Called by: trigger EnrollmentApprovedSubscriber on Enrollment_Approved__e (after insert)
 *
 * REV 4 — FINAL, end-to-end against Supplemental Requirements:
 *   A-6.7.4  (calc formulas, percentage + fixed-amount paths)
 *   A-6.7.11 (7-step calculation flow)
 *   A-6.7.5  (automatic referral flow, Piece 1 — the post-reconciliation
 *             trigger and ReferralAccrualBatch are separate classes per the
 *             spec's own Build Instructions, not part of this subscriber)
 *
 * Verified against your org by live testing (debug logs, not just spec
 * text): payload validation, Appointment resolution by direct Id, Agent_Code
 * match (non-referral) detection, Product_State composite-key lookup,
 * Missing_Rate exception path — full clean run, no errors, confirmed via
 * debug log apex-07LWB00000RpXFJ2A3.
 *
 * Every other line traces to spec text or facts you confirmed via Object
 * Manager screenshots (Enrollment_Approved__e field list, Referral_Record__c
 * field list, Payment_Type__c picklist values). See prior revisions in this
 * conversation for the line-by-line changelog if needed — this header keeps
 * only what's still open.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * All open items are now closed. Override record Contact__c (Step 7a) is
 * populated from Agreement__c.Agent__c — confirmed Lookup(Contact) on your
 * Agreement__c object, which is the sub-agency owner Contact the spec
 * describes. No remaining unresolved fields in this class.
 *
 * CONFIRMED FIX (live-tested): class declared 'without sharing'. The
 * Agreement__c query in the override branch returned 6 rows when run as an
 * admin user (sandipp@...) but 0 rows when the trigger actually executed as
 * the Automated Process user (apiuser@epicare.com) that processes platform
 * events — identical query, identical bind values, only the running user
 * differed. That's a record-level sharing gap on Agreement__c for the
 * integration user, not a query bug. Declaring the class without sharing
 * makes commission/override calculation independent of whoever's context
 * happens to trigger it, which is the correct behavior for system
 * automation like this regardless of what caused the original gap.
 * ══════════════════════════════════════════════════════════════════════════
 * ══════════════════════════════════════════════════════════════════════════
 * CORRECTED (real behavior change, not a guess): Gross_Amount__c now
 * calculates from Enrollment_Approved__e.Premium__c (the event payload),
 * not Appointment__c.Premium__c (a persisted field the code was previously
 * reading). This matches the spec's actual wording: Step 1 explicitly
 * lists Premium as a payload field to validate ("Validate payload:
 * Agent_Code, NPN, ..., Premium, Policy_Number are non-null"), while
 * Step 2's list of fields to read "from the resolved Appointment__c" does
 * NOT include Premium at all (Payment_Model__c, Commission_Month__c,
 * Advance_Through_Month__c, Payment_Flow__c, Commission_Level__c,
 * Carrier__c, Line_of_Business__c — no Premium__c). The prior
 * Appointment-based approach was inherited from the original code handed
 * over at the start of this project (its own header comment listed
 * Appointment__c.Premium__c as an already-confirmed field), carried
 * forward without being checked against this specific spec wording until
 * a live test failure (a stale Appointment.Premium__c going null) exposed
 * the discrepancy. Event Premium__c is Text(255) — parsed via a new
 * parsePremium() helper. Applies to both the base calculation and the
 * Percentage_Of_Premium override formula (Step 7a), which used the same
 * Appointment field.
 * ══════════════════════════════════════════════════════════════════════════
 *
 * ══════════════════════════════════════════════════════════════════════════
 * REV 5 PATCH NOTES (applied as surgical edits on top of REV 4 — no
 * existing logic removed, only additions/corrections at the specific lines
 * noted below):
 *
 * 1. addMonthsSafe(): Commission_Month__c is a text PICKLIST
 *    ("Current_Month" / "1_Month_Past"), not a numeric offset string. The
 *    old Integer.valueOf() attempt always threw and silently defaulted to
 *    offset 0 (confirmed via debug log: "Invalid integer: Current_Month"
 *    caught on every row), so Payment_Period__c always mirrored
 *    Effective_Date__c regardless of Commission_Month__c. Now maps the
 *    picklist value to an actual start month. ASSUMPTION, NOT CONFIRMED:
 *    "Current_Month" = today's month, "1_Month_Past" = one month back —
 *    matches T1's expected 2026-08 start, but get this confirmed before
 *    trusting T2/T3 period output.
 *
 * 2. newEstimatedRecord(): added cr.Agency__c, cr.Member_Count__c,
 *    cr.Effective_Date__c, cr.Product__c — all four were explicitly
 *    requested in the client's field-population checklist and were not
 *    being set (productMap was even built earlier and never used).
 *    Required threading a new resolvedProductId parameter through
 *    buildEstimatedRecords() and buildMonthlyRecords() down to
 *    newEstimatedRecord() — every other parameter and line in those three
 *    methods is unchanged.
 *
 * 3. buildInvalidPayloadException() / buildUnresolvedAppointmentException():
 *    now take carrierMap and a new npnToContactId map (built once, up
 *    front, from Contact.NPN__c) so Carrier__c and Agent__c can be
 *    populated even before any Appointment is resolved — previously left
 *    null in both builders, which was the client's exact T11 complaint
 *    ("exception created but all context fields empty").
 *
 * 4. upsertReferralRecords() catch block: DML failures were only going to
 *    System.debug, invisible outside a live log capture — very likely why
 *    T6/T7 showed "referral detected, but nothing saved, no visible error."
 *    Now also inserts a Commission_Exception__c (Exception_Type__c =
 *    'Referral_Insert_Failed') carrying the real DML error message.
 *
 * 5. Referral-detection mismatch check: reverted to requiring
 *    appt.Agent_Code__c to be non-null before comparing (i.e. restored the
 *    guard the REV 4 "T6/T7 fix" removed). A live debug log for T2 — an
 *    ORDINARY sale, not a referral — showed appt.Agent_Code__c is ALSO
 *    blank on a normal (non-house) appointment, so the REV 4 version
 *    false-positived a Referral_Record on every ordinary sale where that
 *    field happens to be unpopulated. NOT SILENTLY RESOLVED: putting the
 *    guard back stops the false positive but means T6/T7-style referrals
 *    go undetected again until a reliable field is confirmed to
 *    distinguish "payload Agent_Code differs from the Appointment's real
 *    owner" from "this field is just blank." Flagged inline at the check.
 * ══════════════════════════════════════════════════════════════════════════
 *
 * ══════════════════════════════════════════════════════════════════════════
 * REV 7 (client UAT verification round T26-T38, Aug 27): Sell_Type__c fix.
 * Sell_Type__c is a RESTRICTED picklist whose real API Name for the "New
 * Sale" value is 'New_Sale' (Label "New Sale") — confirmed by the client via
 * Setup/Object Manager. This class was stamping the literal 'New', which is
 * not a valid entry, so every Commission_Record insert DML-failed with
 * INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST whenever the picklist was
 * Restricted (client applied a temporary workaround of un-restricting the
 * picklist to keep testing unblocked; that workaround should be reverted
 * once this fix is deployed). Source__c='Platform' is unaffected — the
 * client's T26-T38 round confirmed that value works correctly as-is.
 * ══════════════════════════════════════════════════════════════════════════
 */
public without sharing class EnrollmentApprovedSubscriberHandler {

    // Real, confirmed Override_Type__c values (Package 0.1 rule — no guessed literals)
    private static final String OVERRIDE_TYPE_FIXED_AMOUNT   = 'Fixed Amount';
    private static final String OVERRIDE_TYPE_PCT_COMMISSION = 'Percentage Of Commission';
    private static final String OVERRIDE_TYPE_PCT_PREMIUM    = 'Percentage Of Premium';

    // Agreement_Type__c values the override query is scoped to (spec 7a step 2-3).
    // Confirmed literal API names from your org — includes the parenthetical
    // text, which is part of the actual stored value here, not just a label.
    private static final Set<String> AGREEMENT_TYPES_FOR_OVERRIDE_QUERY = new Set<String>{
        'Override_Fixed (MAPD/ACA)', 'Override_Percentage (Life/Supp)', 'Referral_Fee'
    };
    private static final String AGREEMENT_TYPE_EPA = 'EPA';

    // Payment_Type__c values on Product_State__c — CORRECTED via live query,
    // overriding the earlier Package 2.7-note-based assumption. Confirmed
    // directly: a Product_State__c record inserted with Payment_Type__c =
    // 'Fixed Amount' (space) read back as 'Fixed_Amount' (underscore) when
    // queried by this handler — meaning the stored/comparison value uses an
    // underscore, whatever the picklist's display label shows. This is why
    // every Fixed-Amount Gross_Amount__c came back as 0 — the string
    // comparison never matched. Percentage is unaffected; that comparison
    // was already correct.
    private static final String PAYMENT_TYPE_PERCENTAGE   = 'Percentage';
    private static final String PAYMENT_TYPE_FIXED_AMOUNT = 'Fixed_Amount';

    // Product_State__c.Levels__c value used for the base seller commission
    // calculation — confirmed real field (PICKLIST), replacing the
    // Commission_Level__c (STRING) field this code originally matched on.
    // NOT separately confirmed: the exact literal value stored for the
    // agent-level picklist entry is 'Agent' — inferred from the client's
    // document showing "Levels: Agent" as the row label. If the real
    // picklist entry uses different casing or wording, this constant needs
    // to match it exactly.
    private static final String PRODUCT_STATE_LEVEL_AGENT = 'Agent';

    // Payment_Model__c values (confirmed real picklist values, see prior audit)
    private static final String PM_AS_EARNED_PMPM        = 'As_Earned_PMPM';
    private static final String PM_AS_EARNED_PPPM         = 'As_Earned_PPPM';
    private static final String PM_ADVANCED_COMMISSION_6  = 'Advanced_Commission_6';
    private static final String PM_ADVANCED_COMMISSION_9  = 'Advanced_Commission_9';
    private static final String PM_PARTIAL_ADVANCE_ANNUAL = 'Partial_Advance_Annual';
    private static final String PM_MANUAL                 = 'Manual';

    // A-6.7.4: "ACA / Medicare pass-through — Gross from carrier statement,
    // no formula calculation at enrollment." Only applies when NO
    // Product_State__c is configured for the Carrier+LOB+Level — if one IS
    // configured (as every live-tested Medicare scenario in this org has
    // been so far), that takes priority and calculates normally. This
    // preserves 100% of already-tested behavior; pass-through only
    // activates for genuinely unconfigured ACA/Medicare combinations,
    // which previously incorrectly fell into Missing_Rate.
    private static final Set<String> PASS_THROUGH_LOBS = new Set<String>{ 'ACA', 'Medicare' };

    // Referral_Type__c values (A-6.7.5)
    private static final String REFERRAL_TYPE_PARTNER          = 'Referral_Partner';
    private static final String REFERRAL_TYPE_AGENT_SALE       = 'Referral_Agent_Sale';
    private static final String REFERRAL_TYPE_OUT_OF_APPT      = 'Out_of_Appointment';
    private static final String AGENT_PROFILE_TYPE_REFERRAL    = 'Referral_Agent';
    private static final String REFERRAL_STATUS_PENDING_VERIFY = 'Pending_Verification';

    // REV 5: Commission_Month__c picklist values, used by the fixed
    // calculateFirstPaymentMonth() below (REV 10; was addMonthsSafe() prior).
    private static final String COMMISSION_MONTH_CURRENT   = 'Current_Month';
    private static final String COMMISSION_MONTH_ONE_PAST  = '1_Month_Past';
    // REV 10 (client regression round, T39-T48): the other 3 real
    // Commission_Month__c picklist values — previously unhandled entirely,
    // silently falling into the "unrecognized value" branch with no offset
    // applied at all.
    private static final String COMMISSION_MONTH_TWO_PAST   = '2_Months_Past';
    private static final String COMMISSION_MONTH_THREE_PAST = '3_Months_Past';
    private static final String COMMISSION_MONTH_15_DAYS    = '15_Days';

    public static void handleAfterInsert(List<Enrollment_Approved__e> events) {
        // ── Carrier / Product name → Id maps ─────────────────────────────
        Set<String> carrierNames = new Set<String>();
        Set<String> productNames = new Set<String>();
        // REV 5: collect NPNs up front so exception builders can resolve
        // Agent__c even before any Appointment is resolved.
        Set<String> allNpns = new Set<String>();
        for (Enrollment_Approved__e event : events) {
            if (event.Carrier__c != null) carrierNames.add(event.Carrier__c);
            if (event.Product__c != null) productNames.add(event.Product__c);
            if (event.NPN__c != null) allNpns.add(event.NPN__c);
        }

        Map<String, Carrier__c> carrierByName = new Map<String, Carrier__c>();
        for (Carrier__c c : [SELECT Id, Name, Carrier_Code__c FROM Carrier__c WHERE Name IN :carrierNames]) {
            carrierByName.put(c.Name, c);
        }
        Map<String, Id> carrierMap = new Map<String, Id>();
        for (Carrier__c c : carrierByName.values()) carrierMap.put(c.Name, c.Id);

        Map<String, Id> productMap = new Map<String, Id>();
        for (Product__c p : [SELECT Id, Name FROM Product__c WHERE Name IN :productNames]) {
            productMap.put(p.Name, p.Id);
        }

        // REV 5: NPN → Contact Id map, used by the exception builders below
        // so Agent__c can be populated on Invalid_Payload / Unresolved_Appointment
        // exceptions even though no Appointment has been resolved at that point.
        Map<String, Id> npnToContactId = new Map<String, Id>();
        if (!allNpns.isEmpty()) {
            for (Contact c : [SELECT Id, NPN__c FROM Contact WHERE NPN__c IN :allNpns]) {
                npnToContactId.put(c.NPN__c, c.Id);
            }
        }

        // ── STEP 1: Validate payload — Agent_Code, NPN, (Appointment_ID OR
        // Carrier+LOB), Premium, Policy_Number all non-null. Events failing
        // this get a Commission_Exception and are excluded from resolution
        // entirely (spec Step 1, first paragraph, ahead of the
        // Appointment-resolution sub-step).
        List<Commission_Exception__c> exceptions = new List<Commission_Exception__c>();
        List<Enrollment_Approved__e> validEvents = new List<Enrollment_Approved__e>();
        for (Enrollment_Approved__e event : events) {
            if (isPayloadValid(event)) {
                validEvents.add(event);
            } else {
                // REV 5: pass carrierMap/npnToContactId so Carrier__c/Agent__c
                // get populated instead of staying null.
                exceptions.add(buildInvalidPayloadException(event, carrierMap, npnToContactId));
            }
        }

        // ── STEP 1 (cont.)/2: Resolve Appointment for every valid event.
        // Fallback uses NPN + Carrier + LOB (NOT Agent_Code — class header item 2).
        List<Id> resolvedApptIds = resolveAppointmentIds(validEvents, carrierMap);

        // Still-unresolved events → Commission_Exception, dropped from further processing.
        for (Integer i = 0; i < validEvents.size(); i++) {
            if (resolvedApptIds[i] == null) {
                // REV 5: pass carrierMap/npnToContactId, same as above.
                exceptions.add(buildUnresolvedAppointmentException(validEvents[i], carrierMap, npnToContactId));
            }
        }

        Set<Id> appointmentIds = new Set<Id>();
        for (Id apptId : resolvedApptIds) {
            if (apptId != null) appointmentIds.add(apptId);
        }
        if (appointmentIds.isEmpty()) {
            if (!exceptions.isEmpty()) insert exceptions;
            return;
        }

        // ── STEP 2 (cont.): Re-query Appointment__c with fields this rewrite needs.
        Map<Id, Appointment__c> appointmentMap = new Map<Id, Appointment__c>([
            SELECT Id, Payment_Flow__c, Payment_Model__c, Commission_Month__c,
                   Advance_Through_Month__c, Effective_Date__c, Line_of_Business__c,
                   Renewal_Date__c, Carrier__c, Agent__c, Agency__c, State_s__c,
                   Premium__c, Member_Count__c, Agent_Code__c, Commission_Level__c
            FROM   Appointment__c
            WHERE  Id IN :appointmentIds
        ]);

        // ── STEP 4/7a: Agreement__c by sub-agency, LOB IN (lob, 'All'),
        // Agreement_Type__c scoped to override/referral-fee types, EPA excluded.
        Set<Id> agencyIds = new Set<Id>();
        for (Appointment__c appt : appointmentMap.values()) {
            if (appt.Agency__c != null) agencyIds.add(appt.Agency__c);
        }
        // Keyed by Agency Id → list of matching Agreements (a sub-agency can
        // have multiple Agreements across different LOBs, or one LOB-specific
        // plus one 'All' — spec 7a requires processing every match).
        Map<Id, List<Agreement__c>> agreementsByAgency = new Map<Id, List<Agreement__c>>();
        System.debug('DIAGNOSTIC agencyIds: ' + agencyIds);
        if (!agencyIds.isEmpty()) {
            for (Agreement__c ag : [
                SELECT Id, Agency__c, LOB__c, Override_Type__c, Override_Percentage__c,
                       Override_Amount__c, Status__c, Agreement_Type__c, Agent__c
                FROM   Agreement__c
                WHERE  Agency__c IN :agencyIds
                AND    Status__c = 'Active'
                AND    Agreement_Type__c IN :AGREEMENT_TYPES_FOR_OVERRIDE_QUERY
                AND    Agreement_Type__c != :AGREEMENT_TYPE_EPA
            ]) {
                if (!agreementsByAgency.containsKey(ag.Agency__c)) {
                    agreementsByAgency.put(ag.Agency__c, new List<Agreement__c>());
                }
                agreementsByAgency.get(ag.Agency__c).add(ag);
            }
        }

        // ── STEP 3: Product_State__c — resolved by Carrier + Line_of_Business +
        // Level + State.
        //
        // CORRECTED (client QA, T1/T13): the real field storing "Agent" /
        // "Agency" / "Epicare" is Levels__c (PICKLIST) — NOT
        // Commission_Level__c (STRING), which this code originally matched
        // on. Commission_Level__c does exist on both objects, but came back
        // blank on every real Appointment and Product_State record checked,
        // which is exactly why every real Product_State collapsed into the
        // same composite-key map entry and the last one processed silently
        // won ("picks the last one it finds" — T1 got Epicare's 35% instead
        // of Agent's 30%). The base seller calculation always means the
        // Agent-level rate by definition (per spec: "agent share" vs.
        // "Epicare share" are always Level=Agent / Level=Epicare
        // respectively, never read dynamically) — so this now matches
        // Levels__c = 'Agent' directly rather than reading any level value
        // off the Appointment at all.
        //
        // ALSO ADDED (T13, NY-specific rates): State__c is a MULTIPICKLIST
        // on Product_State__c, so a single record can apply to several
        // states at once. Resolution now prefers a Product_State whose
        // State__c list includes the Appointment's own state
        // (Appointment__c.State_s__c), falling back to a state-agnostic
        // record (blank State__c) if no state-specific match exists.
        // ASSUMPTION, not separately confirmed: blank State__c means
        // "applies to all states" — matches your document's "All states
        // (default)" label, but if there's a literal sentinel value instead
        // (e.g. an explicit "All" picklist entry) this fallback needs
        // adjusting to check for that value instead of blank.
        Set<Id> carrierIds = new Set<Id>();
        for (Appointment__c appt : appointmentMap.values()) {
            if (appt.Carrier__c != null) carrierIds.add(appt.Carrier__c);
        }
        Map<Id, Product_State__c> productStateById = new Map<Id, Product_State__c>();
        // Key: Carrier_LOB_Level (no state) -> candidate records, resolved by state in Apex below.
        Map<String, List<Product_State__c>> productStateCandidatesByKey = new Map<String, List<Product_State__c>>();
        if (!carrierIds.isEmpty()) {
            for (Product_State__c ps : [
                SELECT Id, Carrier__c, Line_of_Business__c, Levels__c, State__c,
                       Payment_Type__c, Year_1_Percentage__c, Fixed_Rate__c
                FROM   Product_State__c
                WHERE  Carrier__c IN :carrierIds
                AND    Levels__c = :PRODUCT_STATE_LEVEL_AGENT
            ]) {
                productStateById.put(ps.Id, ps);
                String key = ps.Carrier__c + '_' + ps.Line_of_Business__c;
                if (!productStateCandidatesByKey.containsKey(key)) {
                    productStateCandidatesByKey.put(key, new List<Product_State__c>());
                }
                productStateCandidatesByKey.get(key).add(ps);
            }
        }

        // ── STEP 6 (Renewal_Schedule__c) — year 2+ source. Bulk-fetched and
        // matched in Apex to stay bulk-safe.
        Map<Id, List<Renewal_Schedule__c>> renewalSchedulesByProductState =
            new Map<Id, List<Renewal_Schedule__c>>();
        if (!productStateById.isEmpty()) {
            for (Renewal_Schedule__c rs : [
                SELECT Id, Product_State__c, Percentage__c, Fixed_Rate__c,
                       Year_From__c, Year_To__c, Sort_Order__c
                FROM   Renewal_Schedule__c
                WHERE  Product_State__c IN :productStateById.keySet()
                AND    Schedule_Type__c = 'Renewal'
                AND    Active__c = true
                ORDER BY Sort_Order__c ASC
            ]) {
                if (!renewalSchedulesByProductState.containsKey(rs.Product_State__c)) {
                    renewalSchedulesByProductState.put(rs.Product_State__c, new List<Renewal_Schedule__c>());
                }
                renewalSchedulesByProductState.get(rs.Product_State__c).add(rs);
            }
        }

        // ── Upline_Policy__c lookup by Carrier + Policy_Number__c ─────────
        Set<String> policyNumbers = new Set<String>();
        for (Enrollment_Approved__e event : validEvents) {
            if (event.Policy_Number__c != null) policyNumbers.add(event.Policy_Number__c);
        }
        // REV 10: now stores the full record (not just Id) so
        // Effective_Date__c can be read below — it's the confirmed correct
        // base date for the Payment_Period calculation (client regression
        // round T39-T48: "the subscriber doesn't seem to be picking up
        // Upline_Policy__c.Effective_Date__c"), replacing Appointment's own
        // Effective_Date__c, which was never the right field for this.
        Map<String, Upline_Policy__c> uplinePolicyByCarrierAndPolicyNumber = new Map<String, Upline_Policy__c>();
        if (!policyNumbers.isEmpty()) {
            for (Upline_Policy__c up : [
                SELECT Id, Carrier__c, Policy_Number__c, Effective_Date__c
                FROM   Upline_Policy__c
                WHERE  Policy_Number__c IN :policyNumbers
            ]) {
                uplinePolicyByCarrierAndPolicyNumber.put(
                    String.valueOf(up.Carrier__c) + '_' + up.Policy_Number__c, up);
            }
        }

        // ── Agent_Code resolution — REDESIGNED to use Contact.Agent_Code__c
        // directly, confirmed to exist via live describe. This replaces the
        // Appointment.Agent_Code__c-based approach entirely, for two reasons:
        //
        // 1. T6 root cause: Appointment.Agent_Code__c is unreliable — blank
        //    on Manuel's house Appointment AND on Ana's own ordinary-sale
        //    Appointment (confirmed via two separate live debug logs). No
        //    inequality check built on that field can ever work correctly.
        //
        // 2. The spec's own wording is "payload.Agent_Code ==
        //    Appointment.owner.Agent_Code" — literally the OWNING CONTACT's
        //    Agent_Code, not a value redundantly stored on the Appointment
        //    itself. Appointment.Agent_Code__c was never the field the spec
        //    actually describes; Contact.Agent_Code__c is.
        //
        // This also removes a long-standing limitation flagged earlier in
        // this project: Referring_Agent__c used to resolve blank for any
        // referring agent with no Appointment of their own, since resolution
        // went through an Appointment join. Resolving directly from Contact
        // removes that dependency entirely.
        Set<Id> apptOwnerContactIds = new Set<Id>();
        for (Appointment__c a : appointmentMap.values()) {
            if (a.Agent__c != null) apptOwnerContactIds.add(a.Agent__c);
        }
        Map<Id, String> ownerAgentCodeByContactId = new Map<Id, String>();
        if (!apptOwnerContactIds.isEmpty()) {
            for (Contact c : [SELECT Id, Agent_Code__c FROM Contact WHERE Id IN :apptOwnerContactIds]) {
                ownerAgentCodeByContactId.put(c.Id, c.Agent_Code__c);
            }
        }

        Set<String> payloadAgentCodes = new Set<String>();
        for (Enrollment_Approved__e event : validEvents) {
            if (event.Agent_Code__c != null) payloadAgentCodes.add(event.Agent_Code__c);
        }
        Map<String, Contact> referringContactByAgentCode = new Map<String, Contact>();
        Map<String, String> referringAgentProfileTypeByAgentCode = new Map<String, String>();
        if (!payloadAgentCodes.isEmpty()) {
            for (Contact c : [
                SELECT Id, Agent_Code__c, Agent_Profile_Type__c
                FROM   Contact
                WHERE  Agent_Code__c IN :payloadAgentCodes
            ]) {
                referringContactByAgentCode.put(c.Agent_Code__c, c);
                referringAgentProfileTypeByAgentCode.put(c.Agent_Code__c, c.Agent_Profile_Type__c);
            }
        }

        // ── STEP 7: Build Estimated Commission_Record__c(s) per event, and
        // stage override + referral candidates for the follow-up passes.
        List<Commission_Record__c> commissionRecords = new List<Commission_Record__c>();
        List<OverrideCandidate> overrideCandidates = new List<OverrideCandidate>();
        List<ReferralCandidate> referralCandidates = new List<ReferralCandidate>();

        for (Integer i = 0; i < validEvents.size(); i++) {
            Enrollment_Approved__e event = validEvents[i];
            Id apptId = resolvedApptIds[i];
            if (apptId == null) continue;

            Appointment__c appt = appointmentMap.get(apptId);
            if (appt == null) continue;

            String productStateKey = appt.Carrier__c + '_' + appt.Line_of_Business__c;
            List<Product_State__c> productStateCandidates = productStateCandidatesByKey.get(productStateKey);
            Id productStateId = resolveBestProductState(productStateCandidates, appt.State_s__c);
            Product_State__c ps = productStateId != null
                ? productStateById.get(productStateId) : null;

            Integer policyYear = calculatePolicyYear(appt.Effective_Date__c);
            Decimal monthlyAmount;
            Decimal appliedRate; // for Commission_Rate__c reporting — whichever rate was actually applied (Year 1 or renewal)

            if (ps == null) {
                if (PASS_THROUGH_LOBS.contains(appt.Line_of_Business__c)) {
                    // Pass-through: no rate configured is expected for these
                    // LOBs, not an error. Gross_Amount__c stays null until the
                    // carrier statement arrives at reconciliation.
                    monthlyAmount = null;
                    appliedRate = null;
                } else {
                    // STEP 3 exception: no Product_State resolvable for this Carrier.
                    exceptions.add(buildMissingRateException(event, appt));
                    continue;
                }
            } else {
                // Year-1 vs year-2+ rate source
                String paymentType = ps.Payment_Type__c;
                Decimal percentageRate = ps.Year_1_Percentage__c;
                Decimal fixedRate = ps.Fixed_Rate__c;
                if (policyYear > 1 && renewalSchedulesByProductState.containsKey(productStateId)) {
                    Renewal_Schedule__c matched = matchRenewalSchedule(
                        renewalSchedulesByProductState.get(productStateId), policyYear);
                    if (matched != null) {
                        percentageRate = matched.Percentage__c;
                        fixedRate      = matched.Fixed_Rate__c;
                    }
                }
                monthlyAmount = calculateAmount(paymentType, percentageRate, fixedRate,
                    parsePremium(event.Premium__c), appt.Member_Count__c);
                // Commission_Rate__c (a PERCENT field) only makes sense for the
                // Percentage path — Fixed Amount has no analogous rate to report.
                appliedRate = paymentType == PAYMENT_TYPE_PERCENTAGE ? percentageRate : null;
            }

            // REV 10: resolve the Upline_Policy record BEFORE computing the
            // first payment month — its Effective_Date__c is now the base
            // date the calculation needs (moved up from where it used to
            // be resolved, right after this calc).
            Upline_Policy__c matchedUplinePolicy = appt.Carrier__c != null && event.Policy_Number__c != null
                ? uplinePolicyByCarrierAndPolicyNumber.get(String.valueOf(appt.Carrier__c) + '_' + event.Policy_Number__c)
                : null;
            Id uplinePolicyId = matchedUplinePolicy != null ? matchedUplinePolicy.Id : null;

            // First payment month = Effective_Date + Commission_Month__c offset.
            //
            // REV 10 (client regression round, T39-T48): base date is now
            // Upline_Policy__c.Effective_Date__c, confirmed correct by the
            // client's own tests — this class was previously reading
            // Appointment__c.Effective_Date__c instead, which is a
            // different object/date entirely and never matched. Falls back
            // to Appointment's Effective_Date__c only when no Upline_Policy
            // match exists at all — the client's tests always create one,
            // so this fallback path is UNCONFIRMED, kept only to preserve
            // prior behavior for the no-Upline_Policy case rather than
            // producing a null base date.
            Date basePaymentDate = matchedUplinePolicy != null && matchedUplinePolicy.Effective_Date__c != null
                ? matchedUplinePolicy.Effective_Date__c
                : appt.Effective_Date__c;
            Date firstPaymentMonth = calculateFirstPaymentMonth(basePaymentDate, appt.Commission_Month__c);

            // REV 5: resolve Product__c Id from productMap (was built earlier
            // but never used) and thread it through to the record builders.
            Id resolvedProductId = event.Product__c != null ? productMap.get(event.Product__c) : null;

            List<Commission_Record__c> estimatedForEvent = buildEstimatedRecords(
                appt, event, ps, firstPaymentMonth, monthlyAmount, policyYear, uplinePolicyId, appliedRate,
                resolvedProductId, basePaymentDate);
            commissionRecords.addAll(estimatedForEvent);

            // Stage override candidates — one per matching Agreement, to be
            // expanded to M records (M = estimatedForEvent.size()) once seller
            // records have Ids (Original_Commission__c needs a real lookup).
            if (appt.Agency__c != null && agreementsByAgency.containsKey(appt.Agency__c)) {
                for (Agreement__c ag : agreementsByAgency.get(appt.Agency__c)) {
                    if (ag.LOB__c != appt.Line_of_Business__c && ag.LOB__c != 'All') continue;
                    overrideCandidates.add(new OverrideCandidate(appt, event, ag, monthlyAmount, estimatedForEvent));
                }
            }

            // Referral detection — Agent_Code mismatch vs the Appointment
            // OWNER's own Agent_Code (SOW Part G.7), not an Is_House_NPN__c
            // flag.
            //
            // REDESIGNED (resolves T6): both the REV 4 and REV 5 versions of
            // this check compared against Appointment__c.Agent_Code__c
            // directly — confirmed unreliable via two separate live logs
            // (blank on Manuel's house Appointment AND on Ana's own ordinary
            // Appointment), so neither a guarded nor unguarded inequality
            // check on that field could ever work correctly. The spec's own
            // wording is "payload.Agent_Code == Appointment.owner.Agent_Code"
            // — the OWNING CONTACT's Agent_Code, confirmed to exist as its
            // own real field (Contact.Agent_Code__c), not a value meant to
            // be duplicated onto the Appointment. This now compares against
            // that Contact-level value instead, via ownerAgentCodeByContactId
            // (built above from appt.Agent__c). No null-guard needed on the
            // owner side — Apex's != handles a null ownerAgentCode safely,
            // and a genuinely blank Contact.Agent_Code__c would legitimately
            // still count as "differs from the payload," same reasoning as
            // the original REV 4 fix, just grounded in the correct field
            // this time.
            String ownerAgentCode = appt.Agent__c != null
                ? ownerAgentCodeByContactId.get(appt.Agent__c) : null;
            if (event.Agent_Code__c != null
                && event.Agent_Code__c != ownerAgentCode) {
                referralCandidates.add(new ReferralCandidate(appt, event, carrierByName));
            }
        }

        if (!exceptions.isEmpty()) insert exceptions;
        if (commissionRecords.isEmpty()) return;

        insert commissionRecords; // never blocked, per original design principle

        // ── Override records (7a) — M per Agreement, now that seller record
        // Ids exist for Original_Commission__c.
        List<Commission_Record__c> overrideRecords = buildOverrideRecords(overrideCandidates);
        if (!overrideRecords.isEmpty()) {
            insert overrideRecords;
        }

        // ── Referral_Record__c upsert (7b / Piece 1). CR-ana for the
        // referring agent is deliberately NOT created here — that's Piece 2
        // (post-reconciliation trigger) and Piece 3 (ReferralAccrualBatch).
        upsertReferralRecords(referralCandidates, referringContactByAgentCode, referringAgentProfileTypeByAgentCode);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Appointment resolution (STEP 1/2) — NPN + Carrier + LOB fallback
    // ─────────────────────────────────────────────────────────────────────

    // T12 fix: (Id) casting a malformed string (wrong length/format) throws
    // an unhandled System.StringException — this used to crash the entire
    // trigger execution for the whole batch, not just this event, and could
    // silently drop every sibling event published alongside the bad one.
    // Now caught and treated as "not found", falling through to the NPN
    // fallback exactly like a null Appointment_ID__c already does.
    private static Id safeIdCast(String rawId) {
        if (rawId == null) return null;
        try {
            return (Id) rawId;
        } catch (Exception e) {
            return null;
        }
    }

    private static List<Id> resolveAppointmentIds(List<Enrollment_Approved__e> events,
            Map<String, Id> carrierMap) {
        List<Id> resolved = new List<Id>();
        for (Enrollment_Approved__e event : events) {
            resolved.add(safeIdCast(event.Appointment_ID__c));
        }

        // Spec: "If Appointment_ID is null OR NOT FOUND, resolve by NPN +
        // Carrier + LOB." A populated-but-invalid/deleted Id must also fall
        // through to the NPN path — verify every directly-supplied Id actually
        // resolves before treating it as final.
        Set<Id> suppliedIds = new Set<Id>();
        for (Id apptId : resolved) {
            if (apptId != null) suppliedIds.add(apptId);
        }
        Set<Id> confirmedExistingIds = new Set<Id>();
        if (!suppliedIds.isEmpty()) {
            for (Appointment__c appt : [SELECT Id FROM Appointment__c WHERE Id IN :suppliedIds]) {
                confirmedExistingIds.add(appt.Id);
            }
        }
        for (Integer i = 0; i < resolved.size(); i++) {
            if (resolved[i] != null && !confirmedExistingIds.contains(resolved[i])) {
                resolved[i] = null; // supplied but not found — falls through to NPN fallback below
            }
        }

        // NPN + Carrier + LOB fallback for events still unresolved. Spec is
        // explicit this must be NPN, not Agent_Code: in a referral sale the
        // payload's Agent_Code is the REFERRING agent, who may not own an
        // Appointment for that Carrier+LOB at all — the payload NPN is the
        // writing number and always maps to the Appointment owner.
        //
        // INTERPRETATION FLAG: the spec's own referral example ties NPN to the
        // Contact ("Manuel Depool NPN 19950086"), not to the Appointment
        // record itself, so this joins through the Appointment's Agent__r
        // (Contact) NPN rather than assuming an Appointment.NPN__c field. If
        // your org actually stores NPN directly on Appointment__c, swap
        // Agent__r.NPN__c below for that field instead.
        Set<String> npns = new Set<String>();
        for (Integer i = 0; i < events.size(); i++) {
            if (resolved[i] == null && events[i].NPN__c != null) {
                npns.add(events[i].NPN__c);
            }
        }

        if (!npns.isEmpty()) {
            Map<String, Id> fallbackMap = new Map<String, Id>();
            for (Appointment__c appt : [
                SELECT Id, Agent__r.NPN__c, Carrier__c, Line_of_Business__c
                FROM   Appointment__c
                WHERE  Agent__r.NPN__c IN :npns
            ]) {
                String key = appt.Agent__r.NPN__c + '_' + appt.Carrier__c + '_' + appt.Line_of_Business__c;
                fallbackMap.put(key, appt.Id);
            }

            for (Integer i = 0; i < events.size(); i++) {
                if (resolved[i] != null) continue;
                Enrollment_Approved__e event = events[i];
                if (event.NPN__c == null) continue;
                Id carrierId = carrierMap.get(event.Carrier__c);
                String key = event.NPN__c + '_' + carrierId + '_' + event.LOB__c;
                if (fallbackMap.containsKey(key)) {
                    resolved[i] = fallbackMap.get(key);
                }
            }
        }

        return resolved;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Step 1 payload validation
    // ─────────────────────────────────────────────────────────────────────

    private static Boolean isPayloadValid(Enrollment_Approved__e event) {
        Boolean hasAppointmentPath = event.Appointment_ID__c != null
            || (event.Carrier__c != null && event.LOB__c != null);
        return event.Agent_Code__c != null
            && event.NPN__c != null
            && hasAppointmentPath
            && event.Premium__c != null
            && event.Policy_Number__c != null;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Commission_Exception__c builders (Step 1 + Step 3)
    // ─────────────────────────────────────────────────────────────────────

    // T11 fix: previously only Exception_Type__c was set — every other field
    // was blank, making a logged exception undiagnosable (client's exact
    // complaint). Now populates every confirmed real field on
    // Commission_Exception__c (Policy_Number__c, Carrier__c, Agent__c,
    // Payload__c) that's actually available at each call site — Carrier__c
    // is a lookup, so it's only set where a resolved Appointment (and thus
    // its Carrier__c Id) is available; Payload__c always captures the raw
    // event fields as text regardless, so nothing is undiagnosable even when
    // a lookup can't be resolved.
    //
    // REV 5: now takes carrierMap and npnToContactId (both built once, up
    // front, in handleAfterInsert) so Carrier__c and Agent__c CAN be
    // populated here too — previously these two builders left both null
    // because no Appointment existed yet at this point in the flow.
    private static Commission_Exception__c buildInvalidPayloadException(
            Enrollment_Approved__e event, Map<String, Id> carrierMap, Map<String, Id> npnToContactId) {
        Commission_Exception__c ex = new Commission_Exception__c();
        ex.Exception_Type__c = 'Invalid_Payload';
        ex.Policy_Number__c  = event.Policy_Number__c;
        ex.Carrier__c        = event.Carrier__c != null ? carrierMap.get(event.Carrier__c) : null;
        ex.Agent__c          = event.NPN__c != null ? npnToContactId.get(event.NPN__c) : null;
        ex.Payload__c        = dumpEventPayload(event);
        return ex;
    }

    private static Commission_Exception__c buildUnresolvedAppointmentException(
            Enrollment_Approved__e event, Map<String, Id> carrierMap, Map<String, Id> npnToContactId) {
        Commission_Exception__c ex = new Commission_Exception__c();
        ex.Exception_Type__c = 'Unresolved_Appointment';
        ex.Policy_Number__c  = event.Policy_Number__c;
        ex.Carrier__c        = event.Carrier__c != null ? carrierMap.get(event.Carrier__c) : null;
        ex.Agent__c          = event.NPN__c != null ? npnToContactId.get(event.NPN__c) : null;
        ex.Payload__c        = dumpEventPayload(event);
        return ex;
    }

    private static Commission_Exception__c buildMissingRateException(
            Enrollment_Approved__e event, Appointment__c appt) {
        Commission_Exception__c ex = new Commission_Exception__c();
        ex.Exception_Type__c = 'Missing_Rate';
        ex.Policy_Number__c  = event.Policy_Number__c;
        ex.Carrier__c        = appt.Carrier__c; // resolved Appointment available here, unlike the two builders above
        ex.Agent__c          = appt.Agent__c;
        ex.Payload__c        = dumpEventPayload(event);
        return ex;
    }

    // Plain-text dump of the raw event for Payload__c (TEXTAREA) — gives full
    // diagnosability on every exception regardless of what could or couldn't
    // be resolved, per T11/T12's complaint that a logged exception carried no
    // usable context.
    private static String dumpEventPayload(Enrollment_Approved__e event) {
        return 'Agent_Code=' + event.Agent_Code__c
            + ' | NPN=' + event.NPN__c
            + ' | Appointment_ID=' + event.Appointment_ID__c
            + ' | Carrier=' + event.Carrier__c
            + ' | LOB=' + event.LOB__c
            + ' | Premium=' + event.Premium__c
            + ' | Policy_Number=' + event.Policy_Number__c;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Policy year / renewal schedule matching
    // ─────────────────────────────────────────────────────────────────────

    private static Integer calculatePolicyYear(Date effectiveDate) {
        Integer policyYear = 1;
        if (effectiveDate != null && effectiveDate.year() < Date.today().year()) {
            policyYear = Date.today().year() - effectiveDate.year() + 1;
        }
        return policyYear;
    }

    private static Renewal_Schedule__c matchRenewalSchedule(
            List<Renewal_Schedule__c> schedules, Integer policyYear) {
        for (Renewal_Schedule__c rs : schedules) {
            Boolean fromOk = rs.Year_From__c != null && policyYear >= Integer.valueOf(rs.Year_From__c);
            Boolean toOk = rs.Year_To__c == null || policyYear <= Integer.valueOf(rs.Year_To__c);
            if (fromOk && toOk) {
                return rs; // list is already Sort_Order__c ASC, first match wins
            }
        }
        return null;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Amount calculation (A-6.7.4)
    // ─────────────────────────────────────────────────────────────────────
    //
    // T1/T2/T3/T4/T13 fix: Year_1_Percentage__c (and the renewal
    // equivalent) is stored as a whole-number percentage — e.g. 30 meaning
    // 30%, confirmed directly from the client's real Ameritas Dental /
    // PrimeStar Individual Dental Product_State data (500 x 30% = $150,
    // which only comes out right when the stored 30 is divided by 100).
    // The earlier /100-less version matched the org's own fabricated test
    // Product_State records only because those happened to be entered as
    // decimal fractions (0.05, 0.08) rather than whole numbers — an
    // artifact of how test data was set up, not a confirmed convention.
    // Real production data settles this: divide by 100.

    // T13 fix: State__c is a MULTIPICKLIST — a single Product_State record
    // can list several states. Prefers a record whose State__c includes the
    // Appointment's own state; falls back to a state-agnostic record (blank
    // State__c) if no state-specific match exists. See the STEP 3 comment
    // above for the "blank means all states" assumption this relies on.
    // REV 8 fix (client T26-T38 UAT round, Finding 2): a matching state used
    // to win immediately on the FIRST candidate found, which made the result
    // depend on arbitrary SOQL return order. Confirmed real-world case:
    // appointment a02WB00000QL0ZuYAL (State_s__c='NY') had TWO
    // Product_State__c candidates whose State__c list both included 'NY' —
    // a0AWB00000AAStK2AX (single-state, NY only, 28%) and a duplicate
    // all-49-states record that had NY accidentally added to its list
    // (30%). Depending on which one SOQL happened to return first, the
    // engine silently applied either rate — no code change caused this, a
    // new duplicate/overlapping Product_State record did, but the method
    // had no defense against that scenario. Now scans every candidate and
    // keeps the MOST SPECIFIC match (fewest total states listed on that
    // record) rather than the first one encountered — a single-state
    // override record now always wins over a broad multi-state list that
    // happens to also include that state, regardless of query order.
    private static Id resolveBestProductState(List<Product_State__c> candidates, String apptState) {
        if (candidates == null || candidates.isEmpty()) return null;

        Set<String> appointmentStates = new Set<String>();
        if (String.isNotBlank(apptState)) {
            for (String state : apptState.split(';')) {
                if (String.isNotBlank(state)) {
                    appointmentStates.add(state.trim());
                }
            }
        }

        Id stateAgnosticFallbackId = null;
        Id bestStateMatchId = null;
        Integer bestStateMatchCount = null; // # of states listed on the current best match — lower = more specific

        for (Product_State__c ps : candidates) {
            if (String.isBlank(ps.State__c)) {
                if (stateAgnosticFallbackId == null) stateAgnosticFallbackId = ps.Id;
                continue;
            }
            if (String.isNotBlank(apptState)) {
                List<String> listedStates = ps.State__c.split(';');
                for (String listedState : listedStates) {
                    if (String.isNotBlank(listedState) && appointmentStates.contains(listedState.trim())) {
                        if (bestStateMatchCount == null || listedStates.size() < bestStateMatchCount) {
                            bestStateMatchId = ps.Id;
                            bestStateMatchCount = listedStates.size();
                        }
                        break;
                    }
                }
            }
        }
        if (bestStateMatchId != null) return bestStateMatchId; // most specific state-level match wins
        return stateAgnosticFallbackId; // no state-specific match — use the default record, if any
    }

    private static Decimal calculateAmount(String paymentType, Decimal percentageRate,
            Decimal fixedRate, Decimal premium, Decimal memberCount) {
        if (paymentType == PAYMENT_TYPE_PERCENTAGE) {
            if (percentageRate == null || premium == null) return 0;
            return premium * percentageRate / 100;
        } else if (paymentType == PAYMENT_TYPE_FIXED_AMOUNT) {
            if (fixedRate == null || memberCount == null) return 0;
            return fixedRate * memberCount;
        }
        return 0;
    }

    // Enrollment_Approved__e.Premium__c is Text(255), confirmed via Object
    // Manager. Parses to Decimal for use in the calculation; returns null
    // (not 0) on a blank or non-numeric value, so calculateAmount()'s own
    // null-check governs the outcome rather than this silently defaulting
    // the commission amount to zero.
    private static Decimal parsePremium(String rawPremium) {
        if (String.isBlank(rawPremium)) return null;
        try {
            return Decimal.valueOf(rawPremium.trim());
        } catch (Exception e) {
            return null; // non-numeric Premium__c value on the event — treat as absent
        }
    }

    // REV 10 REPLACES REV 5 (client regression round, T39-T48): the REV 5
    // version fixed the Integer.valueOf() crash but built Current_Month and
    // 1_Month_Past entirely around Date.today() — never touching the base
    // date at all outside the fallback branch. That's exactly why the
    // client's T42/T43/T48 (Current_Month) landed on the processing month
    // and T44 (1_Month_Past) landed one month before that, regardless of
    // any effective date. It also never handled 2_Months_Past,
    // 3_Months_Past, or 15_Days at all — those fell straight into the
    // "unrecognized value" branch with no offset applied, which is why
    // T45/T46/T39/T40/T41/T47 all landed on January of the appointment's
    // effective year (that branch's Effective_Date__c fallback, on the
    // WRONG object's date — see the base-date fix at the call site).
    //
    // CONFIRMED FORMULA (client-provided, all 5 values):
    //   Expected_Payment_Date__c = first day of month(Effective_Date + offset)
    //   Current_Month     → +0 months
    //   1_Month_Past      → +1 month
    //   2_Months_Past     → +2 months
    //   3_Months_Past     → +3 months
    //   15_Days           → +15 days
    //
    // NOT SILENTLY RESOLVED: the client's own 4 example rows for 15_Days
    // don't all agree with this formula — T40 (day 1) and T41 (day 15)
    // match it exactly, but T39 and T47 (both day 25) show an expected
    // result one month earlier than +15 days actually produces (day 25 +
    // 15 = day 9 of the NEXT month, but their "expected" column stays on
    // the same month). Built exactly to their stated formula rather than
    // reverse-engineering a different rule to force all 4 examples to
    // match — flagged back to the client to confirm which is right.
    private static Date calculateFirstPaymentMonth(Date baseEffectiveDate, String commissionMonthValue) {
        if (baseEffectiveDate == null) {
            return Date.newInstance(Date.today().year(), Date.today().month(), 1);
        }

        Date offsetDate;
        if (commissionMonthValue == COMMISSION_MONTH_CURRENT) {
            offsetDate = baseEffectiveDate;
        } else if (commissionMonthValue == COMMISSION_MONTH_ONE_PAST) {
            offsetDate = baseEffectiveDate.addMonths(1);
        } else if (commissionMonthValue == COMMISSION_MONTH_TWO_PAST) {
            offsetDate = baseEffectiveDate.addMonths(2);
        } else if (commissionMonthValue == COMMISSION_MONTH_THREE_PAST) {
            offsetDate = baseEffectiveDate.addMonths(3);
        } else if (commissionMonthValue == COMMISSION_MONTH_15_DAYS) {
            offsetDate = baseEffectiveDate.addDays(15);
        } else {
            // Unrecognized/blank Commission_Month__c value — no offset,
            // same safe non-throwing fallback as before.
            offsetDate = baseEffectiveDate;
        }
        return Date.newInstance(offsetDate.year(), offsetDate.month(), 1); // first day of month
    }

    private static String formatPaymentPeriod(Date monthDate) {
        String mm = monthDate.month() < 10 ? '0' + monthDate.month() : String.valueOf(monthDate.month());
        return monthDate.year() + '-' + mm;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Estimated record generation, by Payment_Model__c (A-6.7.11 Step 5/6)
    // ─────────────────────────────────────────────────────────────────────

    // REV 5: added resolvedProductId parameter, threaded through to
    // newEstimatedRecord() below.
    // REV 11 (client's follow-up on the T39-T48 fix): added
    // policyEffectiveDate parameter, also threaded through to
    // newEstimatedRecord() — this is basePaymentDate from the caller
    // (Upline_Policy__c.Effective_Date__c, falling back to Appointment's
    // only when no Upline_Policy match exists), needed to fix
    // Commission_Record__c.Effective_Date__c below, which was still
    // stamping from Appointment__c.Effective_Date__c even after the
    // Payment_Period__c calculation itself was corrected to use the right
    // source. NOTE: the Partial_Advance_Annual branch's own
    // effectiveMonth/advanceMonths math a few lines below still uses
    // appt.Effective_Date__c on purpose — that's tied to
    // Appointment.Advance_Through_Month__c, a different field with a
    // different confirmed meaning, and wasn't part of what the client
    // flagged. Not touched.
    private static List<Commission_Record__c> buildEstimatedRecords(Appointment__c appt,
            Enrollment_Approved__e event, Product_State__c ps, Date firstPaymentMonth,
            Decimal monthlyAmount, Integer policyYear, Id uplinePolicyId, Decimal appliedRate,
            Id resolvedProductId, Date policyEffectiveDate) {
        List<Commission_Record__c> records = new List<Commission_Record__c>();
        String paymentModel = appt.Payment_Model__c;

        if (paymentModel == PM_AS_EARNED_PMPM || paymentModel == PM_AS_EARNED_PPPM) {
            records.addAll(buildMonthlyRecords(appt, event, ps, firstPaymentMonth, monthlyAmount,
                12, policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate));

        } else if (paymentModel == PM_ADVANCED_COMMISSION_6) {
            records.addAll(buildMonthlyRecords(appt, event, ps, firstPaymentMonth, monthlyAmount,
                6, policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate));

        } else if (paymentModel == PM_ADVANCED_COMMISSION_9) {
            records.addAll(buildMonthlyRecords(appt, event, ps, firstPaymentMonth, monthlyAmount,
                9, policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate));

        } else if (paymentModel == PM_PARTIAL_ADVANCE_ANNUAL) {
            Integer effectiveMonth = appt.Effective_Date__c != null ? appt.Effective_Date__c.month() : 1;
            Integer advanceThroughMonth = appt.Advance_Through_Month__c != null
                ? appt.Advance_Through_Month__c.intValue() : 0;
            Integer advanceMonths = advanceThroughMonth - effectiveMonth + 1;

            if (advanceMonths > 0) {
                // 1 advance record covering advanceMonths worth. Payment_Period__c
                // stays in plain YYYY-MM format — REV 1 appended " (Advance)",
                // which would break every downstream Payment_Period__c match
                // (existence checks, batch queries). If you need to flag a
                // record as the advance record, add a dedicated boolean/picklist
                // field instead of overloading Payment_Period__c.
                Commission_Record__c advanceRecord = newEstimatedRecord(appt, event, ps,
                    firstPaymentMonth, monthlyAmount != null ? monthlyAmount * advanceMonths : null,
                    policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate);
                records.add(advanceRecord);
                // remaining as-earned months
                Date remainingStart = firstPaymentMonth.addMonths(advanceMonths);
                Integer remainingCount = 12 - advanceMonths;
                if (remainingCount > 0) {
                    records.addAll(buildMonthlyRecords(appt, event, ps, remainingStart, monthlyAmount,
                        remainingCount, policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate));
                }
            } else {
                // as-earned only, full 12 months
                records.addAll(buildMonthlyRecords(appt, event, ps, firstPaymentMonth, monthlyAmount,
                    12, policyYear, uplinePolicyId, appliedRate, resolvedProductId, policyEffectiveDate));
            }

        } else if (paymentModel == PM_MANUAL) {
            // No records created for Manual, per spec.
        }
        // Unrecognized/blank Payment_Model__c: no records — explicit no-op,
        // matches "None" behavior rather than silently defaulting.

        return records;
    }

    // REV 5: added resolvedProductId parameter, threaded through to
    // newEstimatedRecord() below.
    // REV 11: added policyEffectiveDate parameter, also threaded through.
    private static List<Commission_Record__c> buildMonthlyRecords(Appointment__c appt,
            Enrollment_Approved__e event, Product_State__c ps, Date startMonth,
            Decimal monthlyAmount, Integer count, Integer policyYear, Id uplinePolicyId, Decimal appliedRate,
            Id resolvedProductId, Date policyEffectiveDate) {
        List<Commission_Record__c> records = new List<Commission_Record__c>();
        for (Integer m = 0; m < count; m++) {
            Date monthDate = startMonth.addMonths(m);
            records.add(newEstimatedRecord(appt, event, ps, monthDate, monthlyAmount, policyYear, uplinePolicyId,
                appliedRate, resolvedProductId, policyEffectiveDate));
        }
        return records;
    }

    // REV 5: added resolvedProductId parameter and four new field
    // assignments at the bottom (Agency__c, Member_Count__c,
    // Effective_Date__c, Product__c).
    // REV 11 (client's follow-up on the T39-T48 fix): added
    // policyEffectiveDate parameter — cr.Effective_Date__c below was still
    // stamping appt.Effective_Date__c even after REV 10 corrected the
    // Payment_Period__c/Expected_Payment_Date__c calculation to use
    // Upline_Policy__c.Effective_Date__c instead. Client reproduced this
    // explicitly (VERIFY-08-EFFDATE): set the Upline_Policy's
    // Effective_Date__c to 2026-10-25 and the Appointment's to a
    // deliberately different 2025-05-20 — all 12 generated
    // Commission_Records came back with the Appointment's 2025-05-20, not
    // the Policy's 2026-10-25. Now uses the same policyEffectiveDate this
    // class already resolves at the call site (Upline_Policy's date,
    // falling back to Appointment's only when no Upline_Policy match
    // exists), so this field is finally consistent with the date source
    // that already drives the payment calculations themselves.
    private static Commission_Record__c newEstimatedRecord(Appointment__c appt,
            Enrollment_Approved__e event, Product_State__c ps, Date monthDate, Decimal amount,
            Integer policyYear, Id uplinePolicyId, Decimal appliedRate, Id resolvedProductId,
            Date policyEffectiveDate) {
        Commission_Record__c cr = new Commission_Record__c();
        cr.Appointment__c           = appt.Id;
        cr.Agent__c                 = appt.Agent__c;
        cr.Status__c                = 'Estimated';
        cr.Payment_Flow__c          = appt.Payment_Flow__c;
        cr.Agent_Code__c            = event.Agent_Code__c;
        cr.Policy_Number__c         = event.Policy_Number__c;
        cr.LOB__c                   = appt.Line_of_Business__c;
        cr.Payment_Model__c         = appt.Payment_Model__c;
        cr.Commission_Month__c      = appt.Commission_Month__c;
        cr.Policy_Year__c           = policyYear;
        cr.Compensation_Type__c     = 'Commission';
        cr.Payment_Period__c        = formatPaymentPeriod(monthDate);
        cr.Expected_Payment_Date__c = monthDate;
        cr.Gross_Amount__c          = amount;
        // Product__c: REV 5 — re-enabled. REV 4 deliberately left this unset
        // per an earlier scoping decision (Package 2.8), but the client's
        // field-population checklist explicitly asked for it — see below.
        cr.Upline_Policy__c         = uplinePolicyId;

        // ── New fields added per client QA (T1 report), each confirmed to
        // exist via a live describe before being referenced here:
        cr.Carrier__c        = appt.Carrier__c;             // REFERENCE — confirmed
        cr.Premium__c        = parsePremium(event.Premium__c); // CURRENCY — confirmed; same parsed value used in the calculation itself
        cr.Commission_Rate__c = appliedRate;                 // PERCENT — confirmed; null for Fixed Amount records, no equivalent rate to report
        // Source__c confirmed working ('Platform'), reconfirmed in the
        // T26-T38 UAT round. Sell_Type__c's real restricted-picklist API
        // Name for the "New Sale" value is 'New_Sale' (Label "New Sale"),
        // confirmed via the client's Setup/Object Manager screenshot in that
        // same round — the previous literal 'New' is not a valid entry and
        // was DML-failing every insert with
        // INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST whenever the picklist was
        // Restricted.
        cr.Source__c         = 'Platform';
        cr.Sell_Type__c      = 'New_Sale';
        // Payment_Status__c — confirmed real value from the referral CR-ana
        // path (Piece 2/3), reused here for consistency.
        cr.Payment_Status__c = 'Pending';

        // REV 5: previously unset — client's field-population checklist
        // explicitly asked for Agency__c, Member_Count__c, Effective_Date__c,
        // and Product__c, none of which were being written.
        cr.Agency__c         = appt.Agency__c;
        cr.Member_Count__c   = appt.Member_Count__c;
        // REV 11 FIX: was appt.Effective_Date__c — now policyEffectiveDate
        // (Upline_Policy__c.Effective_Date__c). See class-level note above.
        cr.Effective_Date__c = policyEffectiveDate;
        cr.Product__c        = resolvedProductId;
                
        // FIX: Partial Advance Annual requires Advance Through Month
    // on the Commission Record. Copy it from the Appointment.
    // No change to other payment models.
    if (appt.Payment_Model__c == PM_PARTIAL_ADVANCE_ANNUAL) {
        cr.Advance_Through_Month__c = appt.Advance_Through_Month__c;
    }

        return cr;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Override branch (Step 7a) — M records per matching Agreement
    // ─────────────────────────────────────────────────────────────────────

    private class OverrideCandidate {
        Appointment__c appt;
        Enrollment_Approved__e event;
        Agreement__c agreement;
        Decimal baseCommissionAmount;
        List<Commission_Record__c> sellerRecords; // same order as periods, Ids populated after insert
        OverrideCandidate(Appointment__c appt, Enrollment_Approved__e event, Agreement__c agreement,
                Decimal baseCommissionAmount, List<Commission_Record__c> sellerRecords) {
            this.appt = appt;
            this.event = event;
            this.agreement = agreement;
            this.baseCommissionAmount = baseCommissionAmount;
            this.sellerRecords = sellerRecords;
        }
    }

    private static List<Commission_Record__c> buildOverrideRecords(List<OverrideCandidate> candidates) {
        List<Commission_Record__c> overrides = new List<Commission_Record__c>();

        for (OverrideCandidate oc : candidates) {
            // REV 6 FIX: overrideAmount used to be computed ONCE per
            // candidate using oc.baseCommissionAmount (the flat per-month
            // rate), then stamped onto every override record regardless of
            // that record's actual seller amount. This was invisible for
            // every payment model where every seller record shares the same
            // Gross_Amount__c (As_Earned, Advanced_Commission_6/9) — but
            // Partial_Advance_Annual's advance record is a multi-month lump
            // sum with a DIFFERENT Gross_Amount__c than the remaining
            // monthly records, and that record was getting under-credited
            // (T4 debug log: $1680 advance seller record produced only a
            // $28 override — the flat monthly rate's 10% — instead of the
            // correct $168). Now computed per sellerCr, using that record's
            // own Gross_Amount__c as the base for the
            // Percentage_Of_Commission case. Fixed_Amount and
            // Percentage_Of_Premium overrides are unaffected by this change
            // since neither depends on the per-record commission amount.
            //
            // M = same number of periods as the seller's records for this event.
            for (Commission_Record__c sellerCr : oc.sellerRecords) {
                Decimal overrideAmount = calculateOverrideAmount(
                    oc.agreement, sellerCr.Gross_Amount__c, parsePremium(oc.event.Premium__c));
                if (overrideAmount == null) continue; // unrecognized Override_Type__c — no record for this seller period

                Commission_Record__c overrideRecord = new Commission_Record__c();
                overrideRecord.Appointment__c        = oc.appt.Id;
                // Confirmed: Agreement__c.Agent__c is Lookup(Contact) — this is
                // the sub-agency owner Contact the spec describes as "from
                // Agreement.Agency__c owner." No Account-owner dereference
                // needed; Agreement__c carries it directly.
                //
                // T1 fix: previously only Contact__c was set. Client's
                // verification query checks Agent__r.LastName, which stayed
                // null on override records as a result — not a data bug, a
                // field-name mismatch between what this code populates and
                // what the client's query checks. Setting both now so
                // existing reporting works without abandoning the earlier
                // confirmed Contact__c design.
                overrideRecord.Contact__c            = oc.agreement.Agent__c;
                overrideRecord.Agent__c              = oc.agreement.Agent__c;
                overrideRecord.Agency__c              = oc.appt.Agency__c;
                overrideRecord.Status__c              = 'Estimated';
                overrideRecord.Compensation_Type__c   = 'Override';
                overrideRecord.Payment_Flow__c        = oc.appt.Payment_Flow__c; // inherited from seller
                overrideRecord.Agent_Code__c          = oc.event.Agent_Code__c;
                overrideRecord.Policy_Number__c       = oc.event.Policy_Number__c;
                overrideRecord.LOB__c                 = oc.appt.Line_of_Business__c;
                overrideRecord.Payment_Period__c      = sellerCr.Payment_Period__c;
                overrideRecord.Gross_Amount__c         = overrideAmount;
                overrideRecord.Admin_Fee__c           = 0;
                overrideRecord.Agreement__c           = oc.agreement.Id;
                overrideRecord.Original_Commission__c = sellerCr.Id; // requires seller records already inserted
                // Same new-field additions as the base commission record —
                // see newEstimatedRecord() for the confirmation notes.
                overrideRecord.Carrier__c             = oc.appt.Carrier__c;
                overrideRecord.Premium__c             = parsePremium(oc.event.Premium__c);
                overrideRecord.Source__c              = 'Platform';
                overrideRecord.Payment_Status__c      = 'Pending';
                overrides.add(overrideRecord);
            }
        }
        return overrides;
    }

    // Same whole-number-percentage fix as calculateAmount() above — spec
    // text for this formula explicitly shows "/100" too: "Override_Amount
    // = seller's Gross_Amount x Agreement.Override_Percentage__c / 100".
    private static Decimal calculateOverrideAmount(Agreement__c ag, Decimal baseCommissionAmount, Decimal premium) {
        if (ag.Override_Type__c == OVERRIDE_TYPE_FIXED_AMOUNT && ag.Override_Amount__c != null) {
            return ag.Override_Amount__c;
        } else if (ag.Override_Type__c == OVERRIDE_TYPE_PCT_COMMISSION && ag.Override_Percentage__c != null) {
            return baseCommissionAmount * ag.Override_Percentage__c / 100;
        } else if (ag.Override_Type__c == OVERRIDE_TYPE_PCT_PREMIUM && ag.Override_Percentage__c != null
            && premium != null) {
            return premium * ag.Override_Percentage__c / 100;
        }
        return null; // e.g. Referral_Fee type agreements, which don't drive this branch
    }

    // ─────────────────────────────────────────────────────────────────────
    // Referral_Record__c upsert (A-6.7.5, Piece 1 / Phase 1 fields only)
    // ─────────────────────────────────────────────────────────────────────

    private class ReferralCandidate {
        Appointment__c appt;
        Enrollment_Approved__e event;
        Map<String, Carrier__c> carrierByName;
        ReferralCandidate(Appointment__c appt, Enrollment_Approved__e event, Map<String, Carrier__c> carrierByName) {
            this.appt = appt;
            this.event = event;
            this.carrierByName = carrierByName;
        }
    }

    // REV 9: derives Referral_Record__c.Advance_Through_Month_Snapshot__c.
    // The two fixed-count Advanced models always advance exactly that many
    // months by definition (same constants already used in
    // buildEstimatedRecords() to decide record count), so no Appointment
    // field read is needed for them. Partial_Advance_Annual's advance
    // length varies per Appointment, so it still reads
    // Advance_Through_Month__c directly, same as before this fix.
    private static Decimal resolveAdvanceThroughMonthSnapshot(Appointment__c appt) {
        if (appt.Payment_Model__c == PM_ADVANCED_COMMISSION_6) return 6;
        if (appt.Payment_Model__c == PM_ADVANCED_COMMISSION_9) return 9;
        if (appt.Payment_Model__c == PM_PARTIAL_ADVANCE_ANNUAL) return appt.Advance_Through_Month__c;
        return null; // As_Earned/Manual/etc. — no advance
    }

    private static void upsertReferralRecords(List<ReferralCandidate> candidates,
            Map<String, Contact> referringContactByAgentCode,
            Map<String, String> referringAgentProfileTypeByAgentCode) {
        if (candidates.isEmpty()) return;

        List<Referral_Record__c> referrals = new List<Referral_Record__c>();
        for (ReferralCandidate rc : candidates) {
            Carrier__c carrier = rc.event.Carrier__c != null ? rc.carrierByName.get(rc.event.Carrier__c) : null;
            String carrierCode = carrier != null && carrier.Carrier_Code__c != null
                ? carrier.Carrier_Code__c : (carrier != null ? String.valueOf(carrier.Id) : '');
            Contact referringAgent = referringContactByAgentCode.get(rc.event.Agent_Code__c);
            String referringAgentProfileType = referringAgentProfileTypeByAgentCode.get(rc.event.Agent_Code__c);

            Referral_Record__c ref = new Referral_Record__c();
            ref.External_Id__c    = rc.event.Policy_Number__c + '_' + rc.event.Agent_Code__c + '_' + carrierCode;
            ref.Referring_Agent__c = referringAgent != null ? referringAgent.Id : null;
            ref.Writing_Agent__c   = rc.appt.Agent__c;
            ref.Referral_Type__c   = determineReferralType(rc.event, referringAgentProfileType);
            // No Client_Name__c source field exists on Enrollment_Approved__e —
            // confirmed via Object Manager. Left unpopulated; the field on
            // Referral_Record__c exists, there's just no payload data feeding it
            // yet. If GO AMS starts sending insured name (directly, or via
            // Contact_Id__c/Agent_Contact_ID__c — neither of which are in the
            // spec doc — worth checking what those resolve to), wire it in here.
            ref.Policy_Number__c   = rc.event.Policy_Number__c;
            ref.Carrier__c         = carrier != null ? carrier.Id : null;
            ref.Line_of_Business__c = rc.appt.Line_of_Business__c;
            ref.Effective_Date__c  = rc.appt.Effective_Date__c;
            ref.Status__c          = REFERRAL_STATUS_PENDING_VERIFY;
            ref.Payment_Model_Snapshot__c = rc.appt.Payment_Model__c;
            // REV 9 fix (client T26-T38 UAT round, Finding 3): this used to
            // only stamp a value for Partial_Advance_Annual, reading
            // appt.Advance_Through_Month__c directly — every
            // Advanced_Commission_6/9 referral came through null. Client
            // confirmed T33/T36 (both Advanced_Commission_6) should show 6.
            // That value is inherent to the payment model itself (spec Step
            // 5: Advanced_Commission_6/9 always produce exactly 6/9
            // records) rather than something that needs a separate
            // Appointment field read, so the two fixed-count Advanced
            // models are now derived directly from Payment_Model__c.
            // Partial_Advance_Annual keeps reading
            // appt.Advance_Through_Month__c exactly as before (its advance
            // length is variable, genuinely needs that field). As_Earned/
            // Manual remain null — they don't advance.
            ref.Advance_Through_Month_Snapshot__c = resolveAdvanceThroughMonthSnapshot(rc.appt);
            ref.Appointment__c     = rc.appt.Id;
            if (ref.Referral_Type__c == REFERRAL_TYPE_PARTNER) {
                ref.Supabase_Referral_Id__c = rc.event.Referral_Partner_Id__c;
            }
            referrals.add(ref);
        }

        // ── Idempotency + Duplicate Rule bypass. Database.upsert() does NOT
        // support a DMLOptions parameter — that overload doesn't exist on the
        // Database class, only on insert()/update(). To get both idempotency
        // (upsert-by-External_Id__c semantics) AND the bypass, split into a
        // manual query + separate insert/update calls instead of a single
        // Database.upsert().
        Set<String> externalIds = new Set<String>();
        for (Referral_Record__c ref : referrals) externalIds.add(ref.External_Id__c);

        Map<String, Id> existingIdByExternalId = new Map<String, Id>();
        for (Referral_Record__c existing : [
            SELECT Id, External_Id__c FROM Referral_Record__c WHERE External_Id__c IN :externalIds
        ]) {
            existingIdByExternalId.put(existing.External_Id__c, existing.Id);
        }

        List<Referral_Record__c> toInsert = new List<Referral_Record__c>();
        List<Referral_Record__c> toUpdate = new List<Referral_Record__c>();
        for (Referral_Record__c ref : referrals) {
            Id existingId = existingIdByExternalId.get(ref.External_Id__c);
            if (existingId != null) {
                ref.Id = existingId;
                toUpdate.add(ref);
            } else {
                toInsert.add(ref);
            }
        }

        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.duplicateRuleHeader.allowSave = true; // bypass, per spec: "Integration-bypassed for the subscriber (upsert)"

        // REV 5: failures were previously only written to System.debug,
        // which is invisible outside a live log capture — very likely why
        // T6/T7 showed "referral detected correctly, but nothing saved, no
        // error visible anywhere." Now also inserts a Commission_Exception__c
        // carrying the real DML error message so the next failure is
        // diagnosable from the object itself, without needing a fresh debug
        // log. Original behavior (never let this block the trigger) unchanged.
        try {
            if (!toInsert.isEmpty()) Database.insert(toInsert, dmlOptions);
            if (!toUpdate.isEmpty()) Database.update(toUpdate, dmlOptions);
        } catch (Exception e) {
            // Referral creation is a side-effect, not core to commission
            // creation — never let an insert-time issue here block the trigger.
            System.debug('Referral_Record__c upsert error: ' + e.getMessage());
            Commission_Exception__c ex = new Commission_Exception__c();
            ex.Exception_Type__c = 'Referral_Insert_Failed';
            ex.Payload__c = 'Message: ' + e.getMessage()
                + ' | Line: ' + e.getLineNumber()
                + ' | Records attempted: ' + referrals.size()
                + ' | StackTrace: ' + e.getStackTraceString();
            try {
                insert ex;
            } catch (Exception logEx) {
                System.debug('Referral_Record__c upsert error, and failed to log it: '
                    + e.getMessage() + ' / ' + logEx.getMessage());
            }
        }
    }

    private static String determineReferralType(Enrollment_Approved__e event, String referringAgentProfileType) {
        if (event.Referral_Partner_Id__c != null) {
            return REFERRAL_TYPE_PARTNER;
        } else if (referringAgentProfileType == AGENT_PROFILE_TYPE_REFERRAL) {
            return REFERRAL_TYPE_AGENT_SALE;
        }
        return REFERRAL_TYPE_OUT_OF_APPT;
    }
}