/**
 * Class    : PaymentBatchAssembly
 * Runs as : Scheduled Apex, cron '0 0 11 12 * ?' (11:00 AM ET, 12th of each
 *           month — after ReferralAccrualBatch at 10:00 AM per spec).
 *
 * A-6.7.5 — "PaymentBatchAssembly packages ALL Reconciled CR-ana (Branch A +
 * Branch B) into Referral-type Payment_Batches per referring Contact. Also
 * packages pending overrides." This is a NEW class — Payment_Batch__c and
 * its manual approval flow (Draft→Submitted→Approved→Paid) already existed
 * in your org (confirmed via Object Manager describe), but nothing
 * auto-assembles Referral-type batches into it yet. This is that assembly.
 *
 * ══════════════════════════════════════════════════════════════════════════
 * SCHEMA — everything below is confirmed directly from your org's describe
 * output (Execute Anonymous, not spec text or inference):
 *   Payment_Batch__c.Batch_Type__c    Picklist [Monthly_Cycle, Referral,
 *                                      Chargeback, Correction]
 *   Payment_Batch__c.Status__c        Picklist [Draft, Submitted, Approved,
 *                                      Paid, Rejected]
 *   Payment_Batch__c.Payment_Period__c  Text
 *   Payment_Batch__c.Total_Gross__c, .Total_Net__c   Currency (stored, not
 *                                      formula — must be computed here)
 *   Payment_Batch__c.Record_Count__c  Number (stored, computed here)
 *   Commission_Record__c.Payment_Batch__c → Payment_Batch__c  (confirmed lookup)
 *
 * DECISIONS MADE, FLAGGED — the spec describes the outcome ("package
 * Reconciled CR-ana + pending overrides into batches per Contact") but not
 * the exact inclusion criteria or field values. Every guess below is
 * isolated to one line so it's easy to correct:
 *  1. CR-ana inclusion: Compensation_Type__c='Commission', Payment_Flow__c=
 *     'Referral', Status__c='Reconciled', Payment_Batch__c=null (not
 *     already batched). Directly spec-stated ("ALL Reconciled CR-ana").
 *  2. Override inclusion: Compensation_Type__c='Override', Status__c=
 *     'Estimated', Payment_Batch__c=null. "Pending" isn't defined further
 *     by the spec — Estimated is Piece 1's creation status for overrides
 *     and the most literal reading of "pending" (not yet reconciled/paid).
 *     If overrides should also require Status__c='Reconciled' like CR-ana,
 *     this filter needs changing.
 *  3. Grouping key: Contact__c — both CR-ana (referring agent) and override
 *     records (sub-agency owner) use this same field, confirmed via Piece 1
 *     and Piece 2 testing, so "per referring Contact" naturally covers both
 *     record types together without extra logic.
 *  4. New batch's Payment_Period__c: set to the current month
 *     (Date.today()), since the assembly packages "ALL" outstanding
 *     records regardless of which period they individually belong to, not
 *     one period's worth — this represents "the period this batch was
 *     assembled," not the underlying commission periods.
 *  5. Line_of_Business__c left null on the new batch — a referral batch can
 *     span multiple LOBs per Contact, and the spec gives no rule for
 *     collapsing them into one picklist value.
 *  6. New batch starts at Status__c='Draft' — matches the picklist's first
 *     value and the existing manual approval flow's presumed starting
 *     point (Director reviews a Draft/newly-assembled batch, then submits).
 *
 * VOLUME NOTE: this does one bounded query per record type and groups
 * in-memory by Contact, rather than chunked Database.Batchable execution —
 * chunking by arbitrary batches of 200 could split one Contact's records
 * across chunks and create duplicate Payment_Batches for the same Contact
 * in the same run. If monthly referral volume ever exceeds what a single
 * transaction can handle (~10K records is the rough SOQL/DML safe ceiling),
 * this needs restructuring to batch by Contact rather than by record count.
 * ══════════════════════════════════════════════════════════════════════════
 */
public without sharing class PaymentBatchAssembly implements Schedulable {

    private static final String BATCH_TYPE_REFERRAL = 'Referral';
    private static final String BATCH_STATUS_DRAFT   = 'Draft';

    private static final String COMPENSATION_TYPE_COMMISSION = 'Commission';
    private static final String COMPENSATION_TYPE_OVERRIDE   = 'Override';
    private static final String PAYMENT_FLOW_REFERRAL         = 'Referral';
    private static final String STATUS_RECONCILED            = 'Reconciled';
    private static final String STATUS_ESTIMATED              = 'Estimated';

    public void execute(SchedulableContext sc) {
        assemble();
    }

    public void assemble() {
        // ── Gather unbatched CR-ana (spec: "ALL Reconciled CR-ana, Branch A + Branch B") ──
        List<Commission_Record__c> crAnaCandidates = [
            SELECT Id, Contact__c, Gross_Amount__c, Net_Amount__c
            FROM   Commission_Record__c
            WHERE  Compensation_Type__c = :COMPENSATION_TYPE_COMMISSION
            AND    Payment_Flow__c = :PAYMENT_FLOW_REFERRAL
            AND    Status__c = :STATUS_RECONCILED
            AND    Payment_Batch__c = null
            AND    Contact__c != null
        ];

        // ── Gather unbatched pending overrides — see header item 2 for the
        // Status__c='Estimated' assumption.
        List<Commission_Record__c> overrideCandidates = [
            SELECT Id, Contact__c, Gross_Amount__c, Net_Amount__c
            FROM   Commission_Record__c
            WHERE  Compensation_Type__c = :COMPENSATION_TYPE_OVERRIDE
            AND    Status__c = :STATUS_ESTIMATED
            AND    Payment_Batch__c = null
            AND    Contact__c != null
        ];

        // ── Group both sets by Contact__c — the spec's "per referring Contact"
        // packaging key, shared by both record types (see header item 3).
        Map<Id, List<Commission_Record__c>> recordsByContact = new Map<Id, List<Commission_Record__c>>();
        for (Commission_Record__c cr : crAnaCandidates) {
            addToGroup(recordsByContact, cr.Contact__c, cr);
        }
        for (Commission_Record__c cr : overrideCandidates) {
            addToGroup(recordsByContact, cr.Contact__c, cr);
        }
        if (recordsByContact.isEmpty()) return;

        // ── Build one Payment_Batch__c per Contact, with totals computed here
        // since Total_Gross__c/Total_Net__c/Record_Count__c are stored fields,
        // not rollup formulas.
        String currentPeriod = formatPaymentPeriod(Date.today());
        List<Payment_Batch__c> newBatches = new List<Payment_Batch__c>();
        List<Id> contactIdsInOrder = new List<Id>(recordsByContact.keySet());

        for (Id contactId : contactIdsInOrder) {
            List<Commission_Record__c> records = recordsByContact.get(contactId);
            Decimal totalGross = 0;
            Decimal totalNet = 0;
            for (Commission_Record__c cr : records) {
                if (cr.Gross_Amount__c != null) totalGross += cr.Gross_Amount__c;
                if (cr.Net_Amount__c != null) totalNet += cr.Net_Amount__c;
            }

            Payment_Batch__c batch = new Payment_Batch__c();
            batch.Batch_Type__c    = BATCH_TYPE_REFERRAL;
            batch.Status__c        = BATCH_STATUS_DRAFT;
            batch.Payment_Period__c = currentPeriod;
            batch.Total_Gross__c   = totalGross;
            batch.Total_Net__c     = totalNet;
            batch.Record_Count__c  = records.size();
            newBatches.add(batch);
        }
        insert newBatches;

        // ── Link each Commission_Record to its new batch. newBatches and
        // contactIdsInOrder are parallel lists (same insertion order).
        List<Commission_Record__c> toUpdate = new List<Commission_Record__c>();
        for (Integer i = 0; i < contactIdsInOrder.size(); i++) {
            Id batchId = newBatches[i].Id;
            for (Commission_Record__c cr : recordsByContact.get(contactIdsInOrder[i])) {
                toUpdate.add(new Commission_Record__c(Id = cr.Id, Payment_Batch__c = batchId));
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void addToGroup(Map<Id, List<Commission_Record__c>> groupMap, Id key, Commission_Record__c newRecord) {
        if (!groupMap.containsKey(key)) groupMap.put(key, new List<Commission_Record__c>());
        groupMap.get(key).add(newRecord);
    }

    private static String formatPaymentPeriod(Date d) {
        String mm = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        return d.year() + '-' + mm;
    }
}