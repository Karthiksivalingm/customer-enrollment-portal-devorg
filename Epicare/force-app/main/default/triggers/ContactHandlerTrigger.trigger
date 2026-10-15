trigger ContactHandlerTrigger on Contact (After insert,After update,before Delete) {
    
    string name; 
    integer Numberr;
    string lname;
    integer fNumberr;
    integer kNumberr;
    
    if(Trigger.isAfter && Trigger.isInsert){   
        set<id> idlist = new  set<id>();    
        for(contact con:trigger.new ){
            idlist.add(con.id);
        }
        NIPRAddTargetsHelper.execute(idlist );
    }
    if(Trigger.isbefore && Trigger.isDelete){
        set<string> idlist = new  set<string>();    
        for(contact con:trigger.old ){
            system.debug('con.id'+con.id);
            idlist.add(con.NPN__c);
        }
        system.debug('idlist'+idlist);
        NIPRRemoveTargetsHelper.execute(idlist);
    }
    
    if(Trigger.isAfter&&(Trigger.isInsert||Trigger.isUpdate)){
    for(Contact con: Trigger.new){
        if( TriggerHandler.isFirstTime){
            if(Trigger.isafter && Trigger.isInsert && con.NPN__c == null && con.ssn_Number__c != null){
                if(!Test.isRunningTest())
                    NiprSSNsearch.ssnSearch(con.Id);
            }
            
            if(Trigger.isafter && Trigger.isUpdate && con.SSN_Number__c !=null && TriggerHandler.isFirstTime && trigger.oldMap.get(con.id).SSN_Number__c != con.SSN_Number__c){
                if(!Test.isRunningTest())
                    NiprSSNsearch.ssnSearch(con.Id);  
            }
        }
    }
   }
}