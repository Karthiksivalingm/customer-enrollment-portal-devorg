trigger RewardAssociationTrigger on Marketing_Reward_Association__c (before insert, after insert, after update, before update, after delete, after undelete) {
    
    list<Id> accId = new list<Id>();
    list<Id> mraId = new list<Id>();
    //if(Trigger.isInsert && Trigger.isBefore){
    if(Trigger.isBefore){
        for(Marketing_Reward_Association__c obj : Trigger.new){
            system.debug('====='+obj.RecordTypeId);
            mraId.add(obj.id);
            if(obj.Company__c != null  && obj.RecordTypeId =='0126g000000bOBUAA2'){
                accId.add(obj.Company__c);
            }
        }
        if( !accId.isEmpty()){
            list<Marketing_Reward_Association__c> reward = [select id,Active__c,Program_Name__c,company__r.Name,End_Date__c,Effective_Date__c from Marketing_Reward_Association__c where company__c In:accId and id != null and recordType.Name =:'Program Association' and id Not In :mraId];
            if(reward != null && reward.size() > 0){
                for(Marketing_Reward_Association__c obj : Trigger.new){
                    for(Marketing_Reward_Association__c objReward :reward){
                        if(obj.company__c == objReward.company__c){
                            //if(obj.Effective_Date__c < objReward.End_Date__c && objReward.Active__c == true  ){
                            if(objReward.Active__c == true && obj.Active__c == true){
                                obj.adderror(objReward.company__r.Name+' has already active Marketing Reward Association');
                            }
                            if(objReward.Program_Name__c.contains('uPP') ||objReward.Program_Name__c.contains('New') ){
                                //obj.Duplicate_Program_Type__c = true;
                            }
                        }
                    }
                }
            }
        }
        
        // ===== NEW: Only one active Program_Association per Account at a time =====
        // On INSERT: sets Active_Start_Date__c so that a new record overlapping an existing
        // one becomes active only the day after the existing record's End_Date__c.
        // (Updates / deletes / undeletes are handled by MRAActiveStartDateHelper below.)
        if(Trigger.isInsert){
        Id progAssocRtId = Schema.SObjectType.Marketing_Reward_Association__c
                            .getRecordTypeInfosByDeveloperName()
                            .get('Program_Association').getRecordTypeId();
        
        Set<Id> paCompanyIds = new Set<Id>();
        Set<Id> paSelfIds = new Set<Id>();
        List<Marketing_Reward_Association__c> paRecords = new List<Marketing_Reward_Association__c>();
        
        for(Marketing_Reward_Association__c obj : Trigger.new){
            if(obj.RecordTypeId != progAssocRtId || obj.Company__c == null
               || obj.Effective_Date__c == null || obj.End_Date__c == null){
                continue;
            }
            paCompanyIds.add(obj.Company__c);
            paRecords.add(obj);
        }
        
        if(!paRecords.isEmpty()){
            Map<Id, List<Marketing_Reward_Association__c>> othersByCompany =
                new Map<Id, List<Marketing_Reward_Association__c>>();
            
            for(Marketing_Reward_Association__c ex : [
                    SELECT Id, Company__c, Effective_Date__c, End_Date__c, Active_Start_Date__c
                    FROM Marketing_Reward_Association__c
                    WHERE Company__c IN :paCompanyIds
                      AND RecordType.DeveloperName = 'Program_Association'
                      AND Id NOT IN :paSelfIds
                      AND Effective_Date__c != null
                      AND End_Date__c != null
                    ORDER BY Effective_Date__c ASC]){
                if(!othersByCompany.containsKey(ex.Company__c)){
                    othersByCompany.put(ex.Company__c, new List<Marketing_Reward_Association__c>());
                }
                othersByCompany.get(ex.Company__c).add(ex);
            }
            
            for(Marketing_Reward_Association__c obj : paRecords){
                if(!othersByCompany.containsKey(obj.Company__c)){
                    othersByCompany.put(obj.Company__c, new List<Marketing_Reward_Association__c>());
                }
                List<Marketing_Reward_Association__c> others = othersByCompany.get(obj.Company__c);
                
                Date startDt = obj.Effective_Date__c;
                Boolean moved = true;
                
                // Keep pushing the start date past any record active in the same window
                while(moved && startDt <= obj.End_Date__c){
                    moved = false;
                    for(Marketing_Reward_Association__c ex : others){
                        Date exStart = (ex.Active_Start_Date__c != null)
                                        ? ex.Active_Start_Date__c : ex.Effective_Date__c;
                        if(exStart > ex.End_Date__c){
                            continue; // that record is never active, ignore it
                        }
                        if(startDt <= ex.End_Date__c && obj.End_Date__c >= exStart){
                            startDt = ex.End_Date__c.addDays(1);
                            moved = true;
                        }
                    }
                }
                
                obj.Active_Start_Date__c = startDt;
                
                // So records saved together in the same batch also respect each other
                others.add(obj);
            }
        }
        } // end if(Trigger.isInsert)
        // ===== END NEW =====
    }

    // ===== NEW: Recalculate Active_Start_Date__c when dates change, or a record is deleted / restored =====
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete)){
        Id progAssocRtIdRecalc = Schema.SObjectType.Marketing_Reward_Association__c
                                  .getRecordTypeInfosByDeveloperName()
                                  .get('Program_Association').getRecordTypeId();
        Set<Id> recalcAccountIds = new Set<Id>();

        if(Trigger.isUpdate){
            for(Marketing_Reward_Association__c obj : Trigger.new){
                Marketing_Reward_Association__c oldObj = Trigger.oldMap.get(obj.Id);
                Boolean changed = oldObj.Effective_Date__c != obj.Effective_Date__c
                               || oldObj.End_Date__c != obj.End_Date__c
                               || oldObj.Company__c != obj.Company__c
                               || oldObj.RecordTypeId != obj.RecordTypeId;
                if(!changed) continue;
                if(obj.RecordTypeId == progAssocRtIdRecalc && obj.Company__c != null){
                    recalcAccountIds.add(obj.Company__c);
                }
                if(oldObj.RecordTypeId == progAssocRtIdRecalc && oldObj.Company__c != null){
                    recalcAccountIds.add(oldObj.Company__c); // old account also needs recalculation
                }
            }
        }
        else {
            List<Marketing_Reward_Association__c> recs = Trigger.isDelete ? Trigger.old : Trigger.new;
            for(Marketing_Reward_Association__c obj : recs){
                if(obj.RecordTypeId == progAssocRtIdRecalc && obj.Company__c != null){
                    recalcAccountIds.add(obj.Company__c);
                }
            }
        }

        MRAActiveStartDateHelper.recalculate(recalcAccountIds);
    }
    // ===== END NEW =====
    
    if((Trigger.isInsert && Trigger.isAfter) || (Trigger.isAfter &&Trigger.isUpdate)){
       List<string> yearList = new List<string>();
        for(Integer i = 2000; i < 2100; i++){
            yearList.add(string.valueOf(i));
        }
        
        map<id,string> accProgIdMap = new map<id,string>();
        Id contRecordTypeId = Schema.SObjectType.Marketing_Reward_Association__c.getRecordTypeInfosByName().get('Program Association').getRecordTypeId();
        for(Marketing_Reward_Association__c obj : Trigger.new){
            system.debug('====='+obj.RecordTypeId+'========'+ obj.RecordType.Name);
            if(obj.Company__c != null  && obj.RecordTypeId == contRecordTypeId && obj.Active__c == true){
                if(obj.Program_Name__c != null){
                    
                    List<string> nameProgram = obj.Program_Name__c.split(' ');
                    List<string> newnameProgram = new List<string>();
                    string s = nameProgram.get(nameProgram.size() - 1);
                    for(string st : nameProgram){
                        if((st.isNumeric() && st.length() == 4 && yearList.contains(st)) || st == '-'){
                            
                        }
                        else{
                            newnameProgram.add(st); 
                        }
                    }
                    string proName = String.join(newnameProgram, ' ' );
                    accProgIdMap.put(obj.Company__c,proName);
                }
            }
        }
        list<Account> acc = [select id,Program_Name__c from account where id =: accProgIdMap.keySet()];
        for(Account ac : acc){
            ac.Program_Name__c = accProgIdMap.get(ac.id);
        }
        update acc;
    }
    
    if(Trigger.isInsert && Trigger.isAfter){
        list<Account> accList = new list<Account>();
        for(Marketing_Reward_Association__c obj : Trigger.new){
            system.debug('====='+obj.RecordTypeId);
            if(obj.Company__c != null  && obj.RecordTypeId =='0126g000000bOBUAA2'){
                accId.add(obj.Company__c);
            }
        }
        if( !accId.isEmpty()){
            //list<Marketing_Reward_Association__c> reward = [select id,Active__c,Duplicate_Program_Type__c,company__c,Program_Name__c,company__r.Name,End_Date__c,Effective_Date__c from Marketing_Reward_Association__c where company__c In:accId  and recordType.Name =:'Program Association' and Duplicate_Program_Type__c = false order by CreatedDate];
            list<Marketing_Reward_Association__c> reward = [select id,Active__c, company__c,Program_Name__c,company__r.Name,End_Date__c,Effective_Date__c from Marketing_Reward_Association__c where company__c In:accId  and recordType.Name =:'Program Association' order by CreatedDate];
            list<Account> currentAcc = [Select Id, New_Start_Date__c, uPP_Start_Date__c from Account where Id In : accId];
            System.debug('Reward: ==' + reward);
            if(reward != null && reward.size() > 0){
                for(Marketing_Reward_Association__c obj : Trigger.new){
                    Account compObj = new Account();
                    compObj.Id = obj.Company__c; 
                    if(obj.Program_Name__c.contains('uPP')){
                        compObj.Current_uPP_End_Date__c = obj.End_Date__c;
                    }
                    
                    if(obj.Program_Name__c.contains('uPP')){
                        if(currentAcc[0].uPP_Start_Date__c == null){
                            compObj.uPP_Start_Date__c =  obj.Effective_Date__c;
                        }
                        else{
                            if(currentAcc[0].uPP_Start_Date__c.year() != System.Today().Year()){
                                compObj.uPP_Start_Date__c =  obj.Effective_Date__c;
                            }
                        }
                    }
                    
                    if(obj.Program_Name__c.contains('New')){
                        if(currentAcc[0].New_Start_Date__c == null){
                            compObj.New_Start_Date__c =  obj.Effective_Date__c;
                        }
                        else{
                            if(currentAcc[0].New_Start_Date__c.year() != System.Today().Year()){
                                compObj.New_Start_Date__c =  obj.Effective_Date__c;
                            }
                        }
                    }
                    
                    /*
                    for(Marketing_Reward_Association__c objReward :reward){
                        if(obj.company__c == objReward.company__c){
                            if( objReward.Program_Name__c.contains('New')){
                                compObj.New_Start_Date__c =  objReward.Effective_Date__c ;
                            }
                            if(objReward.Program_Name__c.contains('uPP')){
                            System.debug('uPP StartDate: ==' + objReward.Effective_Date__c);
                                compObj.uPP_Start_Date__c =  objReward.Effective_Date__c;
                            }
                        }
                    }
                    */
                    accList.add(compObj);
                }
                update accList;
            }
        }
    }
}