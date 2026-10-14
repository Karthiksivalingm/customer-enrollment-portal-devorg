trigger OpportunityContractFileTrigger on Opportunity (after update) {
    list<Account> lstAcnToUpdate = new list<Account>();
    list<ContentDistribution> lstCDToInsert = new list<ContentDistribution>();
    map<Id,Id> mapCVToAccount = new map<Id,Id>();
    map<Id,String> mapCVToTitle = new map<Id,String>();
    List<ContentDocumentLink> objCntDocLnk = New List<ContentDocumentLink>();

    for(Opportunity opp : trigger.new){
        //Verify if Opportunity Stage has changed and new Stage is Closed Won
        if((opp.Stagename != trigger.oldMap.get(opp.Id).StageName) && (opp.Stagename == 'Closed Won')  &&  (opp.RecordTypeId =='0125f000000e5TjAAI'|| opp.RecordTypeId =='0125f000000e5TiAAI')){
           
             List<Opportunity> opList = [SELECT Name, StageName, Close_Date_Actual__c, AccountId FROM Opportunity WHERE AccountId =: opp.AccountId and 
             (StageName = 'Closed Won')  ORDER BY Close_Date_Actual__c desc LIMIT 1]; 
              
              
         //Retrive the most recently uploaded Docusign document related to this opportunity 
         if(opList.size() > 0){
             objCntDocLnk = [Select Id,ContentDocumentId,ContentDocument.Title,ContentDocument.LatestPublishedVersionId 
             from ContentDocumentLink  where LinkedEntityId = :opList[0].Id order by SystemModstamp desc Nulls Last limit 1];
         
         }
            if (objCntDocLnk.size() > 0){
                //Create Publick Link to this File
                ContentDistribution newDist = new ContentDistribution();
                newDist.ContentVersionId = objCntDocLnk[0].ContentDocument.LatestPublishedVersionId;
                newDist.Name = 'External Link';
                newDist.PreferencesNotifyOnVisit = false;
                newDist.PreferencesAllowViewInBrowser = true;
                newDist.PreferencesAllowOriginalDownload=true;
                //Create list of ContentDistribution to be inserted
                lstCDToInsert.add(newDist);
                
                //Create Map of ContentVersion to Account
                mapCVToAccount.put(objCntDocLnk[0].ContentDocument.LatestPublishedVersionId, opp.AccountId);
                //Create Map of ContentVersion to File Title
                mapCVToTitle.put(objCntDocLnk[0].ContentDocument.LatestPublishedVersionId, objCntDocLnk[0].ContentDocument.Title);
            }
            
        }
    }
    //Insert all ContentDistribution records
    if (lstCDToInsert != null && lstCDToInsert.size() > 0) {
        try{
            insert lstCDToInsert;
        }
        catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    //For each ContentDistribution record created update coresponding Account record with the URL
    for (ContentDistribution objCD: lstCDToInsert){
        //Get Account Id
        Id acntID = mapCVToAccount.get(objCD.ContentVersionId);
        //Get File Title
        String fileTitle = mapCVToTitle.get(objCD.ContentVersionId);
        //Get Public URL
        try{
        ContentDistribution cntDis = [Select Id, DistributionPublicUrl from ContentDistribution where Id=:objCD.Id];
        system.debug('URL::'+cntDis.DistributionPublicUrl);
        
        //Get Account Details and Set the contract public URL on Account field
        Account objAcnt = [Select Id, Contract_File__c from Account where Id=:acntID];
        System.debug(cntDis.DistributionPublicUrl);
        objAcnt.Contract_File__c = '<a href='+cntDis.DistributionPublicUrl+'>'+'Click to see latest Contract'+'</a>';
        lstAcnToUpdate.add(objAcnt);
        }
        catch(exception e){}
    }
    
    //Update all Account records
    if (lstAcnToUpdate != null && lstAcnToUpdate.size() > 0){
        //system.debug('Updated Account');
        try{
            update lstAcnToUpdate;
        }
        catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}