/* - - - - - - - - - - - - - - - - - - - - - -
* CaseTrigger
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
* 2020-12-31       1.0          Martin Mandak       initial dev
*/
trigger CaseTrigger on Case (before delete) {
 Map<Id, Case> mapNewCaseForExecute = new Map<Id, Case>();
    Map<Id, Case> mapOldCaseForExecute = new Map<Id, Case>();

    // set of fields, for which we want to run trigger if they are changed
    Set<String> setOfFields = new Set<String> {
        // if Set is empty, then ALL fields will be checked for change
        };

    if (!TriggerUtil.needToRunTrigger(setOfFields, mapNewCaseForExecute, mapOldCaseForExecute,
            CaseTriggerHelper.alreadyExecutedBefore, CaseTriggerHelper.alreadyExecutedAfter)
    ) {
        return;
    }

        // execute helper methods to execute trigger logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
           // CaseTriggerHelper.beforeInsert(Trigger.new);
        } // if
        if (Trigger.isUpdate) {
           // CaseTriggerHelper.BeforeUpdate(mapNewOppsForExecute, mapOldOppsForExecute);
        } // if
        if (Trigger.isDelete) {
            CaseTriggerHelper.beforeDelete(mapOldCaseForExecute);
        } // if
      } else if (Trigger.isAfter) {
        //if (Trigger.isInsert) {
            //CaseTriggerHelper.AfterInsert(mapNewCaseForExecute);
        //} // if
        //if (Trigger.isUpdate) {
           // CaseTriggerHelper.AfterUpdate(mapNewOppsForExecute, mapOldOppsForExecute);
        //} // if
        //if (Trigger.isDelete) {
           // CaseTriggerHelper.AfterDelete(mapOldAccountsForExecute);
        //} // if
        // optional - not always needed
        //if (Trigger.isUnDelete) {
        //    Trg_Account.AfterUnDelete(mapNewAccountsForExecute);
        //} // if
     }
}