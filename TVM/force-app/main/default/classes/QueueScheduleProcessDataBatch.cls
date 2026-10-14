/* - - - - - - - - - - - - - - - - - - - - - -
* QueueScheduleProcessDataBatch
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: Martin Mandak
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose: processing data from SF2SF_Sharing_Queue__c
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
* 
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date          Version      Author                 Changes
* 2020-12-30    1.0          Martin Mandak       initial dev
*/
global without sharing class QueueScheduleProcessDataBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    
    global Integer delay = 60;
    
    global QueueScheduleProcessDataBatch(Integer delay){
        system.debug('QueueScheduleProcessDataBatch delay = '+delay);
        if(delay != null && delay != 0) this.delay = delay;
        system.debug('QueueScheduleProcessDataBatch this.delay = '+this.delay);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        	String query = 'SELECT Id,Name, '
                  + '              RelationId__c,'   
                  + '              ConnectionId__c,'   
                  + '              LocalRecordId__c'   
	              + '         FROM SF2SF_Sharing_Queue__c '
                  + '        ORDER BY Name DESC';
	          return database.getQueryLocator(query);
    }

global void execute(database.BatchableContext bc , List<SF2SF_Sharing_Queue__c> scope ){
	
    List<Attachment> lstAttachment = new List<Attachment>();
    List<Attachment> lstAttachmentUpdate = new List<Attachment>();
    List<SF2SF_Sharing_Queue__c> lstQueue = new List<SF2SF_Sharing_Queue__c>();
    List<SF2SF_Sharing_Queue__c> lstQueueDelete = new List<SF2SF_Sharing_Queue__c>();
    List<PartnerNetworkRecordConnection> lstPartnerNetworkRecordConnection = new List<PartnerNetworkRecordConnection>();
    Map<Id,SF2SF_Sharing_Queue__c> mapQueueByAttachmentId = new Map<Id,SF2SF_Sharing_Queue__c>(); 
    Map<Id,SF2SF_Sharing_Queue__c> mapQueueByCaseId = new Map<Id,SF2SF_Sharing_Queue__c>(); 
    Set<Id> setAttParentIds = new Set<Id>();
    Set<Id> setPartnerNetworkRecordConnectionLocalRecordId = new Set<Id>();

	for(SF2SF_Sharing_Queue__c queue : scope){
        system.debug('queue'+queue.Name);
		if (queue.Name == 'Attachment_set_IsPartnerShared') {
            system.debug('queue');
            mapQueueByAttachmentId.put(queue.RelationId__c,queue);
        } else if (queue.Name == 'Create_History_Connection'){
            mapQueueByCaseId.put(queue.RelationId__c,queue);
            setAttParentIds.add(queue.RelationId__c);
        }
	}
	
    system.debug(mapQueueByAttachmentId);
    system.debug(mapQueueByCaseId);
    system.debug(setAttParentIds);
    if (!mapQueueByAttachmentId.isEmpty()) {
        system.debug('dfsfds');
        for (Attachment attachment : [SELECT Id, 
                                             IsPartnerShared,
                                             ParentId 
                                        FROM Attachment 
                                       WHERE Id IN :mapQueueByAttachmentId.keySet()]) {
         system.debug('attachment'+attachment);                                  
         if( setAttParentIds.isEmpty() || !setAttParentIds.contains(attachment.ParentId)){
            setAttParentIds.add(attachment.ParentId);
            //attachment.IsPartnerShared = true;
            lstAttachment.add(attachment);   
         }                                
      }
    }
    system.debug('setAttParentIds '+setAttParentIds);

    for (PartnerNetworkRecordConnection partnerNetworkRecordConnection:[SELECT LocalRecordId 
                                                                          FROM PartnerNetworkRecordConnection
                                                                          WHERE LocalRecordId IN :setAttParentIds
                                                                            AND (status = 'Received'
                                                                              or status = 'Sent')   ]){
         setPartnerNetworkRecordConnectionLocalRecordId.add(partnerNetworkRecordConnection.LocalRecordId);
        }
    
    system.debug('setPartnerNetworkRecordConnectionLocalRecordId '+setPartnerNetworkRecordConnectionLocalRecordId);

     for(SF2SF_Sharing_Queue__c queue: mapQueueByCaseId.values()) {
         if (setPartnerNetworkRecordConnectionLocalRecordId.contains(queue.RelationId__c)){
              PartnerNetworkRecordConnection partnerNetworkRecordConnection = new PartnerNetworkRecordConnection();
              partnerNetworkRecordConnection.ConnectionId = queue.ConnectionId__c;
              partnerNetworkRecordConnection.LocalRecordId = queue.LocalRecordId__c;
              partnerNetworkRecordConnection.ParentRecordId = queue.RelationId__c;
          lstPartnerNetworkRecordConnection.add(partnerNetworkRecordConnection);
          lstQueue.add(queue);
         }
     }
    
    system.debug('lstQueue '+lstQueue);


     for (Attachment attachment:lstAttachment) {
            if (setPartnerNetworkRecordConnectionLocalRecordId.contains(attachment.ParentId)){
               attachment.IsPartnerShared = true;
               lstAttachmentUpdate.add(attachment);
               lstQueue.add(mapQueueByAttachmentId.get(attachment.Id));
            }
        }
    
    system.debug('lstQueue+ Attachment '+lstQueue);
    
    system.debug('lstPartnerNetworkRecordConnection '+lstPartnerNetworkRecordConnection);
    system.debug('lstAttachmentUpdate '+lstAttachmentUpdate);
    
        Set<Id> setConfirmDelete = new Set<Id>();
        Set<Id> setRetrieveData = new Set<Id>();
       if (!lstPartnerNetworkRecordConnection.isEmpty()){
           Database.SaveResult[] lstSaveResultPartnerNetworkRecordConnection = Database.insert(lstPartnerNetworkRecordConnection, false);
       
          for (Database.SaveResult sr : lstSaveResultPartnerNetworkRecordConnection) {
          if (sr.isSuccess()) {
            setRetrieveData.add(sr.getId()); 
            }    
          }
          
          for (PartnerNetworkRecordConnection partnerNetworkRecordConnection:[ SELECT ParentRecordId,
                                                                                      LocalRecordId
                                                                                 FROM PartnerNetworkRecordConnection
                                                                              WHERE Id IN :setRetrieveData] ){
              setConfirmDelete.add(partnerNetworkRecordConnection.ParentRecordId);                                                                    
          }
       }
    
       if (!lstAttachmentUpdate.isEmpty()) {
         Database.SaveResult[] lstSaveResultAttachmentUpdate = Database.update(lstAttachmentUpdate, false);
          for (Database.SaveResult sr : lstSaveResultAttachmentUpdate) {
          if (sr.isSuccess()) {
            setConfirmDelete.add(sr.getId()); 
          }    
          }
       }
    
    for (SF2SF_Sharing_Queue__c queue:lstQueue) {
        if (setConfirmDelete.contains(queue.RelationId__c)) {
            lstQueueDelete.add(queue);
        }
    }            
	   if (!lstQueueDelete.isEmpty()) {
        
           delete lstQueueDelete;
       }
    
}
    global void finish(Database.BatchableContext BC) {        
        //run after delay minutes again, but the test class. From the test class we can run the batch only once.
        if (!System.Test.isRunningTest()) runMe(this.delay);
    }
    
    public static void runMe(Integer delay){
        
        QueueScheduleProcessDataBatch myBatchObject = new QueueScheduleProcessDataBatch(delay); 
        if(delay == null || delay == 0){
            database.executebatch(myBatchObject,10);
        }
        
        Datetime rightNow = datetime.now();
        String uniqueStr =  String.valueOf(date.today().year())+'-'+String.valueOf(date.today().month())+'-'+String.valueOf(date.today().day())+'_'+String.valueOf(rightNow.hour())+':'+String.valueOf(rightNow.minute())+':'+String.valueOf(rightNow.second());
        System.scheduleBatch(myBatchObject, 'EQueueScheduleProcessDataBatch_'+uniqueStr, delay, 10);
    }   
}