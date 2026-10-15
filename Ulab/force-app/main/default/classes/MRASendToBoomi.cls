/**
 * Send to Boomi rules.
 *
 * SCOPE: Program_Association record type ONLY.
 *
 * Rule 1 - A Company can only have one Program Association MRA with
 *          Send to Boomi checked.
 * Rule 2 - Send to Boomi can only be checked while the record is ACTIVE:
 *          Effective Date is today or earlier, AND
 *          End Date is today or later (blank End Date = open ended).
 *
 * Active state is derived from the dates rather than read from Active__c,
 * because formula fields are not recalculated in a before trigger.
 */
public class MRASendToBoomi {

    @TestVisible
    private static final String ERR_NO_EFFECTIVE_DATE =
        'Please add an Effective Date before sending this reward to Boomi.';

    @TestVisible
    private static final String ERR_NOT_STARTED =
        'This reward hasn\'t started yet - it becomes effective on {0}. ' +
        'You can send it to Boomi on or after that date.';

    @TestVisible
    private static final String ERR_ENDED =
        'This reward ended on {0}, so it can no longer be sent to Boomi. ' +
        'If it\'s still running, please update the End Date first.';

    @TestVisible
    private static final String ERR_DUPLICATE_NAMED =
        'Send to Boomi is already switched on for {0} on this Company. ' +
        'Only one reward per Company can be sent at a time, so please uncheck it there first.';

    @TestVisible
    private static final String ERR_DUPLICATE_GENERIC =
        'Send to Boomi is already switched on for another reward on this Company. ' +
        'Only one reward per Company can be sent at a time, so please uncheck it there first.';

    public static void validate(
        List<Marketing_Reward_Association__c> newRecords,
        Map<Id, Marketing_Reward_Association__c> oldMap
    ) {

        Date today = Date.today();

        Set<Id> companyIds       = new Set<Id>();
        Set<Id> currentRecordIds = new Set<Id>();

        // Records that already failed Rule 2 - skip them in Rule 1
        Set<Integer> erroredIndexes = new Set<Integer>();

        Id programAssociationRecordTypeId =
            Schema.SObjectType.Marketing_Reward_Association__c
                .getRecordTypeInfosByDeveloperName()
                .get('Program_Association')
                .getRecordTypeId();

        /* =====================================================
         * PASS 1
         * a) Rule 2 - active check
         * b) Collect Company IDs for Rule 1
         * ===================================================== */
        for (Integer i = 0; i < newRecords.size(); i++) {

            Marketing_Reward_Association__c mra = newRecords[i];

            // Program Association only
            if (mra.RecordTypeId != programAssociationRecordTypeId) {
                continue;
            }

            // Nothing to police unless the box is ticked
            if (mra.Send_to_Boomi__c != true) {
                continue;
            }

            // ---------- a) Rule 2 : must be active ----------
            Boolean notStarted =
                mra.Effective_Date__c == null || mra.Effective_Date__c > today;

            Boolean hasEnded =
                mra.End_Date__c != null && mra.End_Date__c < today;

            if (notStarted || hasEnded) {

                Marketing_Reward_Association__c oldMra =
                    (oldMap == null || mra.Id == null) ? null : oldMap.get(mra.Id);

                Boolean wasAlreadyChecked = (oldMra != null && oldMra.Send_to_Boomi__c == true);

                Boolean datesChanged =
                    oldMra != null
                    && (oldMra.Effective_Date__c != mra.Effective_Date__c
                        || oldMra.End_Date__c != mra.End_Date__c);

                if (wasAlreadyChecked && !datesChanged) {

                    /*
                     * Record was flagged while active and has since aged out
                     * of its date window. Don't block unrelated edits -
                     * just clear the checkbox.
                     */
                    mra.Send_to_Boomi__c = false;

                } else {

                    mra.addError(
                        Marketing_Reward_Association__c.Send_to_Boomi__c,
                        buildNotActiveMessage(mra, today)
                    );
                    erroredIndexes.add(i);
                }

                continue;
            }

            // ---------- b) Rule 1 data ----------
            if (mra.Company__c == null) {
                continue;
            }

            companyIds.add(mra.Company__c);

            if (mra.Id != null) {
                currentRecordIds.add(mra.Id);
            }
        }

        if (companyIds.isEmpty()) {
            return;
        }

        /* =====================================================
         * Existing flagged MRAs for the same Company.
         * Active status is NOT considered here - both Active and
         * Inactive records block another MRA.
         * The record Name is captured so the error can point the
         * user straight at the record they need to change.
         * ===================================================== */
        Map<Id, String> blockingRecordNameByCompany = new Map<Id, String>();

        for (Marketing_Reward_Association__c existingMRA : [
            SELECT Id, Name, Company__c
            FROM Marketing_Reward_Association__c
            WHERE Company__c IN :companyIds
            AND RecordTypeId = :programAssociationRecordTypeId
            AND Send_to_Boomi__c = true
            AND Id NOT IN :currentRecordIds
            ORDER BY Name
        ]) {

            if (!blockingRecordNameByCompany.containsKey(existingMRA.Company__c)) {
                blockingRecordNameByCompany.put(existingMRA.Company__c, existingMRA.Name);
            }
        }

        /* =====================================================
         * PASS 2 - Rule 1
         * ===================================================== */
        for (Integer i = 0; i < newRecords.size(); i++) {

            if (erroredIndexes.contains(i)) {
                continue;
            }

            Marketing_Reward_Association__c mra = newRecords[i];

            if (mra.RecordTypeId != programAssociationRecordTypeId) {
                continue;
            }

            if (mra.Send_to_Boomi__c != true) {
                continue;
            }

            if (mra.Company__c == null) {
                continue;
            }

            if (blockingRecordNameByCompany.containsKey(mra.Company__c)) {

                String blockingName = blockingRecordNameByCompany.get(mra.Company__c);

                String msg = String.isBlank(blockingName)
                    ? ERR_DUPLICATE_GENERIC
                    : String.format(ERR_DUPLICATE_NAMED, new List<String>{ blockingName });

                mra.addError(Marketing_Reward_Association__c.Send_to_Boomi__c, msg);
            }
        }
    }

    /**
     * Picks the message that matches the actual reason the record
     * is not active, so the user isn't told about a date that is fine.
     */
    private static String buildNotActiveMessage(
        Marketing_Reward_Association__c mra,
        Date today
    ) {

        if (mra.Effective_Date__c == null) {
            return ERR_NO_EFFECTIVE_DATE;
        }

        if (mra.Effective_Date__c > today) {
            return String.format(
                ERR_NOT_STARTED,
                new List<String>{ mra.Effective_Date__c.format() }
            );
        }

        return String.format(
            ERR_ENDED,
            new List<String>{ mra.End_Date__c.format() }
        );
    }
}