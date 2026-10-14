/* - - - - - - - - - - - - - - - - - - - - - -
* CaseTriggerHelper
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* assist methods for CaseTrigger
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2020-12-31    1.0			 Martin Mandak			initial dev
*/

global  class CaseTriggerHelper {
    public static Set<Id> alreadyExecutedBefore = new Set<Id>();
    public static Set<Id> alreadyExecutedAfter = new Set<Id>();
   

    /**
	 * Called for before delete trigger execution.
	 *
	 * @param mapOldCaseForExecute     old map Case by CaseIds
	 */
   public static void beforeDelete(Map<Id, Case> mapOldCaseForExecute){
      delete [SELECT Id FROM SF2SF_Sharing_Queue__c WHERE RelationId__c IN : mapOldCaseForExecute.keySet()];
   }
    
}