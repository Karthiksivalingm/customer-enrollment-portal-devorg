/* - - - - - - - - - - - - - - - - - - - - - -
* DeleteFilesInIntergroupCommObject
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* Queueable class to delete all related files in Intergroup_Communication__c object
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2020-12-11    1.0			 Michaela Tarhanicova	initial dev
*/
public with sharing class DeleteFilesInIntergroupCommObject implements Queueable {
    // input parameters
    private Set<Id> setLinkedEntIds;

    /**
     * @param setLinkedEntityIds all LinkedEntityId / ParentId of files which will be deleted
     */
    public DeleteFilesInIntergroupCommObject(Set<Id> setLinkedEntityIds){
        this.setLinkedEntIds = setLinkedEntityIds;
    }

    public void execute(QueueableContext context) {
        Set<Id> setContentDocumentId = new Set<Id>();
        // Get all ContentDocumentLink when LinkedEnityId is in parentId and the object is Intergroup_Communication__c
        for(ContentDocumentLink tmpCDL : [SELECT ContentDocumentId  
                                             FROM ContentDocumentLink 
                                            WHERE LinkedEntityId In :setLinkedEntIds
                                            AND LinkedEntity.Type='Intergroup_Communication__c']){
            setContentDocumentId.add(tmpCDL.ContentDocumentId);
        }
        // Get all ContentDocument records.
        ContentDocument[] lstContentDocument = [SELECT Id 
                                                FROM ContentDocument
                                                WHERE Id In :setContentDocumentId];
        if(lstContentDocument != null && !lstContentDocument.isEmpty()){
          delete lstContentDocument;  
        } 
    }
}