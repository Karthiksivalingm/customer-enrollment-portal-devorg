/* - - - - - - - - - - - - - - - - - - - - - -
* ContentDocumentLinkHelper
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* assist methods for ContentDocumentLinkTrigger
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2021-01-11    1.0			 Michaela Tarhanicova	initial dev
*/
public class ContentDocumentLinkTriggerHelper {
    public static Set<Id> alreadyExecutedBefore = new Set<Id>();
    public static Set<Id> alreadyExecutedAfter = new Set<Id>();
    
    /**
	 * Called for after insert trigger execution.
     * Get all files related to Intergroup Communication object and convert it to an Attachment.
	 *
	 * @param listNewContentDocs     new list of ContentDocument
	 */
    public static void processFilesConvert(List<ContentDocumentLink> listNewContentDocLinks){
        
        map<Id,Id> mapLinkedEntityIdByContentDocId = new map<Id,Id>();
        // get Intergroup Communication object prefix
        String prefix_IntergroupCommunication = Intergroup_Communication__c.sobjecttype.getDescribe().getKeyPrefix();

        // if file is related to IC object, put it to the map
        for(ContentDocumentLink tmpCLD : listNewContentDocLinks){
            String linkedEntitId = String.valueOf(tmpCLD.LinkedEntityId);
                if ( linkedEntitId.left(3) == prefix_IntergroupCommunication) {
                    mapLinkedEntityIdByContentDocId.put(tmpCLD.ContentDocumentId, tmpCLD.LinkedEntityId);
            }
        }

        // convert file (form map) to attachments
        if(mapLinkedEntityIdByContentDocId != null && !mapLinkedEntityIdByContentDocId.isEmpty()){
            Attachment[] lstAttachment = ContentDocumentTrg_ConvFilesToAtts.convertFilesToAttchs(mapLinkedEntityIdByContentDocId);
            if(lstAttachment != null && !lstAttachment.isEmpty()){
                insert lstAttachment;                    
            }                
        }
    }
}