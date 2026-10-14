/* - - - - - - - - - - - - - - - - - - - - - -
* ContentDocumentLinkTrigger
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: Michaela Tarhanicova NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date          Version      Author                 Changes
* 2021-01-11      1.0        Michaela Tarhanicova   initial dev
*/trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    Map<Id, ContentDocumentLink> mapNewContentDocLinkForExecute = new Map<Id, ContentDocumentLink>();
    Map<Id, ContentDocumentLink> mapOldContentDocLinkForExecute = new Map<Id, ContentDocumentLink>();

    // set of fields, for which we want to run trigger if they are changed
    Set<String> setOfFields = new Set<String> {
        // if Set is empty, then ALL fields will be checked for change
        };

    if (!TriggerUtil.needToRunTrigger(setOfFields, mapNewContentDocLinkForExecute, mapOldContentDocLinkForExecute,
        ContentDocumentLinkTriggerHelper.alreadyExecutedBefore, ContentDocumentLinkTriggerHelper.alreadyExecutedAfter)
    ) {
        return;
    }

    // execute helper methods to execute trigger logic
    if (Trigger.isBefore) {

    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContentDocumentLinkTriggerHelper.processFilesConvert(mapNewContentDocLinkForExecute.values());
        } 
     } 
}