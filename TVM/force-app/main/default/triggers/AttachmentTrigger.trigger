/* - - - - - - - - - - - - - - - - - - - - - -
* AttachmentTrigger
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: Martin Mandak
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date          Version      Author                 Changes
* 2020-12-07       1.0          Martin Mandak       initial dev
* 2020-12-30       1.1          Martin Mandak       activate before delete
*/

trigger AttachmentTrigger on Attachment (before insert, after insert, after update, before update, before delete) {
    Map<Id, Attachment> mapNewAttForExecute = new Map<Id, Attachment>();
    Map<Id, Attachment> mapOldAttForExecute = new Map<Id, Attachment>();

    // set of fields, for which we want to run trigger if they are changed
    Set<String> setOfFields = new Set<String> {
        // if Set is empty, then ALL fields will be checked for change
        };

    if (!TriggerUtil.needToRunTrigger(setOfFields, mapNewAttForExecute, mapOldAttForExecute,
            AttachmentTriggerHelper.alreadyExecutedBefore, AttachmentTriggerHelper.alreadyExecutedAfter)
    ) {
        return;
    }

        // execute helper methods to execute trigger logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
           // AttachmentTriggerHelper.beforeInsert(Trigger.new);
        } // if
        if (Trigger.isUpdate) {
           // AttachmentTriggerHelper.BeforeUpdate(mapNewOppsForExecute, mapOldOppsForExecute);
        } // if
        if (Trigger.isDelete) {
            AttachmentTriggerHelper.beforeDelete(mapOldAttForExecute);
        } // if
      } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AttachmentTriggerHelper.AfterInsert(mapNewAttForExecute);
        } // if
        if (Trigger.isUpdate) {
           // AttachmentTriggerHelper.AfterUpdate(mapNewOppsForExecute, mapOldOppsForExecute);
        } // if
        if (Trigger.isDelete) {
           // AttachmentTriggerHelper.AfterDelete(mapOldAccountsForExecute);
        } // if
        // optional - not always needed
        //if (Trigger.isUnDelete) {
        //    Trg_Account.AfterUnDelete(mapNewAccountsForExecute);
        //} // if
     } // else if
}