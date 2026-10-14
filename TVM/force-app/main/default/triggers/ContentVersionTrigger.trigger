trigger ContentVersionTrigger on ContentVersion (After insert) {
  
    list<Account> lstAcnToUpdate = new list<Account>();
    list<ContentDistribution> lstCDToInsert = new list<ContentDistribution>();
    map<Id,Id> mapCVToAccount = new map<Id,Id>();
    map<Id,String> mapCVToTitle = new map<Id,String>();
    
    for(ContentVersion cv : trigger.new){
        Id cdId = cv.ContentDocumentId;
        Id cvId = cv.Id;
        String fileTitle = cv.Title;
        
        list<ContentDocumentLink> lstCntDocLnk = [Select Id,LinkedEntityId from ContentDocumentLink where ContentDocumentId =:cdId];
               
        for(ContentDocumentLink objCdl: lstCntDocLnk){
          //Verify if file is added on Opportunity object and is a Docusigned contract file
          If (objCdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Opportunity'){
                    //Get Account Related to the Opportunity on which file is added
                    Opportunity objOpty = [Select Id, StageName, Close_Date_Actual__c, AccountId from Opportunity where Id=:objCdl.LinkedEntityId ];
                    //Get the most recently closed Opportunity related to the Account fetched above
                    LIST<Opportunity> objOptyLinkedToAccnt = [Select Id, StageName, Close_Date_Actual__c,AccountId from Opportunity where AccountId=:objOpty.AccountId and (RecordTypeId ='0125f000000e5TjAAI'or RecordTypeId ='0125f000000e5TiAAI') and (StageName='Closed Won' or StageName = 'Closed Lost') order by Close_Date_Actual__c desc  LimiT 1];
                    //If the Opportunity on which the file is being added is the most recently closed Opportunity related to the Account
                    if(objOptyLinkedToAccnt.size() > 0){
                        if (objOptyLinkedToAccnt[0].Id == objCdl.LinkedEntityId){                        
                            //Create Publick Link to this File
                            ContentDistribution newDist = new ContentDistribution();
                            newDist.ContentVersionId = cvId;
                            newDist.Name = 'External Link';
                            newDist.PreferencesNotifyOnVisit = false;
                            newDist.PreferencesAllowViewInBrowser = true;
                            newDist.PreferencesAllowOriginalDownload=true;
                            //Create list of ContentDistribution to be inserted
                            lstCDToInsert.add(newDist);
                            
                            //Create Map of ContentVersion to Account
                            mapCVToAccount.put(cvId, objOptyLinkedToAccnt[0].AccountId);
                            //Create Map of ContentVersion to File Title
                            mapCVToTitle.put(cvId, fileTitle);
                        }
                    }
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
        ContentDistribution cntDis = [Select Id, DistributionPublicUrl from ContentDistribution where Id=:objCD.Id];
        system.debug('URL::'+cntDis.DistributionPublicUrl);
        
        //Get Account Details and Set the contract public URL on Account field
        Account objAcnt = [Select Id, Contract_File__c from Account where Id=:acntID];
        objAcnt.Contract_File__c = '<a href='+cntDis.DistributionPublicUrl+'>'+'Click to see latest Contract'+'</a>';
        lstAcnToUpdate.add(objAcnt);
    }
    
    //Update all Account records
    if (lstAcnToUpdate != null && lstAcnToUpdate.size() > 0){
        try{
            update lstAcnToUpdate;
        }
        catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }    
}