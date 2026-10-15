public with sharing class PaymentBatchTriggerHandler {
 public static void validateOnSubmit(
        List<Payment_Batch__c> newList,
        Map<Id, Payment_Batch__c> oldMap
    ) {

        Set<Id> batchIds = new Set<Id>();

        // Detect status change → Submitted
        for (Payment_Batch__c pb : newList) {

            Payment_Batch__c oldPb = oldMap.get(pb.Id);

            if (pb.Status__c == 'Submitted' &&
                oldPb.Status__c != 'Submitted') {

                batchIds.add(pb.Id);

                // FIX (Daniel's email, PRD §7.4 — segregation of duties):
                // the Approver_not_equal_to_Submitter validation rule on
                // Payment_Batch__c (AND(ISPICKVAL(Status__c,"Approved"),
                // Approved_By__c = Submitted_By__c)) was confirmed ACTIVE,
                // but Submitted_By__c was confirmed blank on PB-0018 —
                // nothing anywhere ever set it. A blank Submitted_By__c can
                // never equal Approved_By__c, so the rule could never catch
                // a same-user violation no matter who approved. This is a
                // before-update trigger, so setting the field directly here
                // (same record already being saved, no extra DML) is enough
                // for the rule to start actually enforcing on the very next
                // Approve step.
                pb.Submitted_By__c = UserInfo.getUserId();
            }
        }

        if (batchIds.isEmpty()) return;

        // ─────────────────────────────────────────────
        // Commission Records
        // Added Payment_Flow__c and Status__c for §7.5 validation
        // Added Epicare_Pays__c for Epicare_Pays block
        // ─────────────────────────────────────────────
        List<Commission_Record__c> commissions = [
            SELECT Id, Name, Agent__c, Agency__c,
                   Payment_Flow__c,   // §7.5 — read stamped value on CR, NOT Appointment
                   Status__c,             // §7.5 — Disputed check
                   Epicare_Pays__c        // NEW — block if FALSE
            FROM Commission_Record__c
            WHERE Payment_Batch__c IN :batchIds
        ];

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Commission_Record__c cr : commissions) {
            if (cr.Agent__c != null) contactIds.add(cr.Agent__c);
            if (cr.Agency__c != null) accountIds.add(cr.Agency__c);
        }

        // ─────────────────────────────────────────────
        // Agents (Contacts)
        // ─────────────────────────────────────────────
        Map<Id, Contact> agents = new Map<Id, Contact>([
            SELECT Id, Name, Agent_Status__c
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        // ─────────────────────────────────────────────
        // Agencies (Accounts)
        // ─────────────────────────────────────────────
        Map<Id, Account> agencies = new Map<Id, Account>([
            SELECT Id, Name, Agency_Status__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

        // ─────────────────────────────────────────────
        // Banking Info
        // ─────────────────────────────────────────────
        Map<Id, Banking_Info__c> bankingMap = new Map<Id, Banking_Info__c>();

        for (Banking_Info__c b : [
            SELECT Id, Agency__c, Verified__c
            FROM Banking_Info__c
            WHERE Agency__c IN :accountIds
        ]) {
            bankingMap.put(b.Agency__c, b);
        }

        // ─────────────────────────────────────────────
        // VALIDATION
        // ─────────────────────────────────────────────
        List<String> errors = new List<String>();

        for (Commission_Record__c cr : commissions) {

            // ── NEW: Block Epicare_Pays__c = FALSE ───────────────────────────
            // Records where Epicare does not pay cannot be included in any batch.
            // Epicare_Pays__c = FALSE means carrier pays agent directly.
            if (cr.Epicare_Pays__c == false) {
                errors.add('Commission Record ' + cr.Name +
                    ' is not payable by Epicare (Epicare_Pays__c = FALSE) ' +
                    'and cannot be included in a Payment Batch.');
            }

            // ── §7.5: Block Direct-Flow payment types ────────────────────────
            // Reads Payment_Flow__c on Commission_Record__c (stamped value)
            // NOT from Appointment__c.Payment_Flow__c
            if (cr.Payment_Flow__c == 'Carrier_Direct' ||
                cr.Payment_Flow__c == 'Upline_Direct') {
                errors.add('Commission Record ' + cr.Name +
                    ' has a direct-flow Payment type (' +
                    cr.Payment_Flow__c +
                    ') and cannot be included in a Payment Batch.');
            }

            // ── §7.5: Block Disputed records ─────────────────────────────────
            if (cr.Status__c == 'Disputed') {
                errors.add('Commission Record ' + cr.Name +
                    ' is Disputed and cannot be included in a Payment Batch.');
            }

            // ── Agent validation ──────────────────────────────────────────────
            Contact agent = agents.get(cr.Agent__c);

            if (agent == null || agent.Agent_Status__c != 'Active') {
                errors.add('Inactive Agent: ' +
                    (agent != null ? agent.Name : 'Unknown Agent'));
            }

            // ── Agency validation ─────────────────────────────────────────────
            Account agency = agencies.get(cr.Agency__c);

            if (agency == null || agency.Agency_Status__c != 'Active') {
                errors.add('Inactive Agency: ' +
                    (agency != null ? agency.Name : 'Unknown Agency'));
            }

            // ── Banking validation ────────────────────────────────────────────
            Banking_Info__c bank = bankingMap.get(cr.Agency__c);

            if (bank == null || bank.Verified__c != true) {
                errors.add('Banking not verified for Agency: ' +
                    (agency != null ? agency.Name : 'Unknown Agency'));
            }
        }

        // ─────────────────────────────────────────────
        // BLOCK SUBMISSION
        // ─────────────────────────────────────────────
        if (!errors.isEmpty()) {

            for (Payment_Batch__c pb : newList) {
                pb.addError(
                    'Cannot submit Payment Batch due to issues:\n' +
                    String.join(errors, '\n')
                );
            }
        }
    }
   
}