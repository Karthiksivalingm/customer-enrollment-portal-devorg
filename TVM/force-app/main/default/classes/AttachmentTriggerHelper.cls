/* - - - - - - - - - - - - - - - - - - - - - -
* AttachmentTriggerHelper
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* assist methods for AttachmentTrigger
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2020-12-07    1.0			 Martin Mandak			initial dev
* 2020-12-30    1.1          Martin Mandak			before delete and implement queue
* 2021-01-08	1.2			 Michaela Tarhanicova	comment out Test.isRunningTest() condition.
*/

global  class AttachmentTriggerHelper {
    public static Set<Id> alreadyExecutedBefore = new Set<Id>();
    public static Set<Id> alreadyExecutedAfter = new Set<Id>();
   

    /**
	 * Called for before delete trigger execution.
	 *
	 * @param mapOldAttForExecute     old map Attachment by AttachmentIds
	 */
   public static void beforeDelete(Map<Id, Attachment> mapOldAttForExecute){
      delete [SELECT Id FROM SF2SF_Sharing_Queue__c WHERE RelationId__c IN : mapOldAttForExecute.keySet()];
   }
    /**
	 * Called for after insert trigger execution.
	 *
	 * @param mapNewAttForExecute     new map Attachment by AttachmentIds
	 */
    public static void afterInsert(Map<Id, Attachment> mapNewAttForExecute) {
        Set<Id> setAttParentIds = new Set<Id>();
        List<Attachment> lstAttachmentUpdate = new List<Attachment>();
        List<Attachment> lstAttachment = new List<Attachment>();
        String prefix_IntergroupCommunication = Intergroup_Communication__c.sobjecttype.getDescribe().getKeyPrefix();
		Set<Id> setAttachmentIds = new Set<Id>();
        // identify attachments which should be updated 
        for(Attachment attachment:mapNewAttForExecute.values()) {
            if (attachment.ParentId != null) {
                String parentId = String.valueOf(attachment.ParentId);
              if ( parentId.left(3) == prefix_IntergroupCommunication && attachment.IsPartnerShared != true) {
                  setAttachmentIds.add(attachment.Id);
                  lstAttachment.add(attachment);        
              } 
              if (parentId.left(3) == prefix_IntergroupCommunication) {
                setAttParentIds.add(attachment.ParentId); 
              }
            }            
        }                       
        
        // after the insert we need to delete ContentDocuments file related to Intergroup_Communication__c object
        if(setAttParentIds != null && !setAttParentIds.isEmpty()){
            DeleteFilesInIntergroupCommObject deleteFiles = new DeleteFilesInIntergroupCommObject(setAttParentIds);
            System.enqueueJob(deleteFiles);
        }    
        
       Set<Id> setPartnerNetworkRecordConnectionLocalRecordId = new Set<Id>();
       Set<Id> setAttachmentIdsUpdated = new Set<Id>();
       List<SF2SF_Sharing_Queue__c> listQueue = new List<SF2SF_Sharing_Queue__c>();
       // check if parent of IntergroupCommunication is shared
       for (PartnerNetworkRecordConnection partnerNetworkRecordConnection:[SELECT LocalRecordId 
                                                                             FROM PartnerNetworkRecordConnection
                                                                            WHERE LocalRecordId IN :setAttParentIds
                                                                              AND (status = 'Received' OR status = 'Sent')]){
         setPartnerNetworkRecordConnectionLocalRecordId.add(partnerNetworkRecordConnection.LocalRecordId);
        }
        system.debug(setPartnerNetworkRecordConnectionLocalRecordId);
        // checked if there  is shared
        for (Attachment attachment:lstAttachment) {
            if (!setPartnerNetworkRecordConnectionLocalRecordId.contains(attachment.ParentId)){
              SF2SF_Sharing_Queue__c queue = new SF2SF_Sharing_Queue__c();
              queue.Name = 'Attachment_set_IsPartnerShared';
              queue.RelationId__c  = attachment.Id;
              listQueue.add(queue);
            } else {
                setAttachmentIdsUpdated.add(attachment.Id);
            }
        }
        // insert into queue
        if (!listQueue.isEmpty()) {
          insert listQueue;
        }
        system.debug(setAttachmentIdsUpdated);
        // after insert we need retrieve Attachments and then update them
        for( Attachment att : [select Id,IsPartnerShared from Attachment where Id IN :setAttachmentIdsUpdated]) {
            att.IsPartnerShared = true;
            lstAttachmentUpdate.add(att);
        }
        system.debug(lstAttachmentUpdate);
        // update statement
        if (!lstAttachmentUpdate.isEmpty() /*&& !Test.isRunningTest()*/) {
            update(lstAttachmentUpdate);
        }
	}
}