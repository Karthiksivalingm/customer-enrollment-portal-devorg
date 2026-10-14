/* - - - - - - - - - - - - - - - - - - - - - -
* ContentDocumentTrg_ConvFilesToAtts
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
* Convert files (represent as content documents) to attachment.
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2020-12-07    1.0			 Michaela Tarhanicova	initial dev
*/
public without sharing class ContentDocumentTrg_ConvFilesToAtts {
    
    /**
	 * Call convertion methods and return an attachment
	 *
	 * @param mapLinkedEntityIdByContentDocId    map of LinkedEntityId by ContenDocumentId. names are the same as are in  ContentDocumentLink object. 
	 */
    public static Attachment[] convertFilesToAttchs(map<Id,Id> mapLinkedEntityIdByContentDocId){
        ContentDocumentWrapper cdw = new ContentDocumentWrapper(mapLinkedEntityIdByContentDocId);
        Attachment[] lstAttachments = convertFileToAttachs(cdw);
        return lstAttachments;
    }

    /**
	 * Call convertion methods and return an attachment
	 *
	 * @param contentDocumLinksWrapper  New input wrapper. 
	 */
    private static Attachment[] convertFileToAttachs(ContentDocumentWrapper contentDocumLinksWrapper) {
        Attachment[] lstAttachments = new Attachment[]{};
        if(!contentDocumLinksWrapper.isMapLinkedEntityIdByContentDocIdEmpty){
            System.debug(LoggingLevel.ERROR, 'false');
            for (ContentVersion tmpContentVersion :  [SELECT title, FileType, VersionData, ContentDocumentId 
                                                        FROM ContentVersion
                                                        WHERE ContentDocumentId IN :contentDocumLinksWrapper.mapLinkedEntityIdByContentDocId.keySet()
                                                        ]){
            lstAttachments.add(
                generateAttachment(
                    tmpContentVersion, 
                    contentDocumLinksWrapper.mapLinkedEntityIdByContentDocId.get(tmpContentVersion.ContentDocumentId)
                    )
                ); 
            }
        }
       
        return lstAttachments;
    }

    /**
     * Create new Attachment record. (Without DML operations)
     * @param objContentVersion record of origin ContentVersion
     * @param linkedEntityId    ParentId for new attachment.
     */
    private static Attachment generateAttachment(ContentVersion objContentVersion, Id linkedEntityId) {        
        Attachment objAttachment = new Attachment();
	    objAttachment.name = objContentVersion.title +'.' + objContentVersion.FileType;
        objAttachment.body = objContentVersion.versiondata;
        objAttachment.ParentId = linkedEntityId;
        return objAttachment;
    }

    /**
     * Wrapper class of input from convertFileToAttachs methods. 
     * The class contains map of LinkedEntityId by ContenDocumentId and information if this map is empty.
     */
    private class ContentDocumentWrapper {
        public map<Id,Id> mapLinkedEntityIdByContentDocId;
        public Boolean isMapLinkedEntityIdByContentDocIdEmpty;
        
        /**
         * Constuctor of class.
         * @param mapLinkEntityIdByContentDocId  map of LinkedEntityId by ContenDocumentId
         */
        public ContentDocumentWrapper(map<Id,Id> mapLinkEntityIdByContentDocId){
            mapLinkedEntityIdByContentDocId = mapLinkEntityIdByContentDocId;
            if(mapLinkedEntityIdByContentDocId == null || mapLinkedEntityIdByContentDocId.isEmpty()){
                isMapLinkedEntityIdByContentDocIdEmpty = true;
            }else{
                isMapLinkedEntityIdByContentDocIdEmpty = false;
            }
        }
    }//end ContentDocumentWrapper
}