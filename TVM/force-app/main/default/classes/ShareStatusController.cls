/* - - - - - - - - - - - - - - - - - - - - - -
* ShareStatusController
* - - - - - - - - - - - - - - - - - - - - - - 
* Author: NESS(CassaCloud)
* - - - - - - - - - - - - - - - - - - - - - -
* Purpose:
* 
*  controller for lightning component ShareStatus
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Test Coverage:
*  
* - - - - - - - - - - - - - - - - - - - - - -
* Revision History:
* Date       	Version      Author      			Changes
* 2020-12-15    1.0			 Martin Mandak	initial dev
*/

public class ShareStatusController {
    
    /**
	 * Called from lightning component helper to retrieve data 
	 *
	 * @param String jsonIn     includes parameters
     * @return String jsonIn     includes results 
	 */
    @AuraEnabled
    public static String getData(String jsonIn) {
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonIn);
        Map<String, Object> out = new Map<String, Object>();
        Map<String,String> mapMasterLabelByDeveloperName = new Map<String,String>();
        // retrieve recordId from json
        String localRecordId = String.valueOf(inputMap.get('recordId'));
        
        for (SharingStatusMapping__mdt sharingStatusMapping:[SELECT MasterLabel, 
                                                                    DeveloperName  
                                                               FROM SharingStatusMapping__mdt ] ) {
         mapMasterLabelByDeveloperName.put(sharingStatusMapping.DeveloperName,sharingStatusMapping.MasterLabel);                                                              
        }
      
      List<PartnerNetworkRecordConnection> lstPartnerNetworkRecordConnection = [SELECT Status, 
                                                                                       ConnectionId
                                                                                  FROM PartnerNetworkRecordConnection
                                                                                 WHERE LocalRecordId = :localRecordId];
      String connectionId;
      if (lstPartnerNetworkRecordConnection != null && !lstPartnerNetworkRecordConnection.isEmpty()) {
        connectionId = lstPartnerNetworkRecordConnection[0].ConnectionId;
      }
        

      PartnerNetworkConnection partnerNetworkConnection;
      if (connectionId != null) {
         partnerNetworkConnection = [SELECT ConnectionName 
                                      FROM PartnerNetworkConnection 
                                     WHERE id = :connectionId
                                     LIMIT 1];
      }
      String status = 'Not Shared';
      if (lstPartnerNetworkRecordConnection != null && !lstPartnerNetworkRecordConnection.isEmpty()){
         status = (mapMasterLabelByDeveloperName.containsKey(lstPartnerNetworkRecordConnection[0].Status))? 
                  mapMasterLabelByDeveloperName.get(lstPartnerNetworkRecordConnection[0].Status): 'Not Shared';
      }
       
       String connectionName = (partnerNetworkConnection !=null)?partnerNetworkConnection.ConnectionName:null;

        out.put('status', status);
        out.put('connectionName', connectionName);

        return JSON.serialize(out);
    }
}