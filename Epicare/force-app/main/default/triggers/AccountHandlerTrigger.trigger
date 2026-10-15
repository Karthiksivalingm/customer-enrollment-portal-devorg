trigger AccountHandlerTrigger on Account (after insert,after update,before delete) {
    
    
    string name;
    integer Numberr;
    string lname;
    integer fNumberr;
    integer kNumberr;
    integer nNumberr;
    
     if(Trigger.isAfter && Trigger.isInsert){   
        set<id> idlist = new  set<id>();    
        for(Account con:trigger.new ){
            idlist.add(con.id);
        }
        NIPRAddTargetsHelper.execute(idlist );
    }
    if(Trigger.isBefore && Trigger.isDelete){
        set<string> idlist = new  set<string>();    
        for(Account con:trigger.old ){
            idlist.add(con.NPN_Number__c);
        }
        NIPRRemoveTargetsHelper.execute(idlist);
    }
}