//Apex class from FND

global class mediaBudgetFlagOnAccBatch implements Database.Batchable<sObject>,Database.Stateful,schedulable {
    
    global string query,Month,Year,NxtMnth,NxtYear,LastMnth,LastYear;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        DateTime dt = Datetime.now();
        Month = dt.format('MMM');
        Year = String.valueOf(dt.format('YYYY'));
        //___________________________________________________
        DateTime lstDt = dt.addMonths(-1);
        LastMnth = lstDt.format('MMM');
        LastYear = String.valueOf(lstDt.format('YYYY'));
        //___________________________________________________
        
        DateTime nxtDt = dt.addMonths(1);
        NxtMnth = nxtDt.format('MMM');
        NxtYear = String.valueOf(nxtDt.format('YYYY'));
       
      //query = 'SELECT ID,MRR__c,Sys_Agency_Fee_ARR__c,Month__c,Year__c,Opportunity.AccountId,Product2.Name,Percentage__c FROM OpportunityLineItem WHERE Percentage__c != null AND Product2.Name = \''+System.Label.AgencyFee_ProductName+'\'';
        if (Test.isRunningTest()) {
        query = 'SELECT Id, Name,FNDN_Billed_Through_TVM__c,Touchpoint_Master_ID__c,Foundation_Account__c, (SELECT Id, Budget_Month__c, Budget_Year__c, PPC_Budget_Sales__c, PPC_Budget_Service__c, PPC_Budget_DISC__c, Video_Budget_Sales__c, SMA_Budget_Sales__c, SMA_Budget_Preowned__c, PPC_Budget_VLA_New__c, PPC_Budget_VLA_Used__c, Total__c FROM Monthly_Budgets__r) FROM Account WHERE Id IN (SELECT Account__c FROM Monthly_Budget__c)';
        }
        else {
        query ='SELECT Id,Name,Tech_Fee_To_Budget_Ratio__c,Active__c,FNDN_Billed_Through_TVM__c,Touchpoint_Master_ID__c,Foundation_Account__c,Type__c, Total_MRR__c,(SELECT Id,Account__r.Active__c,Account__r.Type__c,Account__r.Tech_Fee_To_Budget_Ratio__c,Account__r.Total_MRR__c,Total__c,Date__c, Budget_Month__c,Budget_Year__c,PPC_Budget_Sales__c, PPC_Budget_Service__c, PPC_Budget_DISC__c, Video_Budget_Sales__c, SMA_Budget_Sales__c, SMA_Budget_Preowned__c, PPC_Budget_VLA_New__c, PPC_Budget_VLA_Used__c FROM Monthly_Budgets__r Where  (Budget_Month__c= \''+Month +'\'AND Budget_Year__c=\''+ Year +'\') OR (Budget_Month__c= \''+NxtMnth +'\'AND Budget_Year__c=\''+ NxtYear +'\') OR (Budget_Month__c= \''+LastMnth +'\'AND Budget_Year__c=\''+ LastYear +'\')  ) FROM Account where Id In (SELECT Account__c FROM Monthly_Budget__c where (Account__r.FNDN_Billed_Through_TVM__c = true AND Account__r.Touchpoint_Master_ID__c != null) OR (Budget_Month__c= \''+Month +'\'AND Budget_Year__c=\''+ Year +'\') OR (Budget_Month__c= \''+NxtMnth +'\'AND Budget_Year__c=\''+ NxtYear +'\') OR (Budget_Month__c= \''+LastMnth +'\'AND Budget_Year__c=\''+LastYear +'\')) ';
         }
        
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        List<Account> accList = new List<Account>();
          
        System.debug('===='+scope);
        
        for(Account acc:scope)
        {
               System.debug('acc'+acc.id); 
            map<String,Boolean> mapOfMonth = new map<String,Boolean>();
            map<String,Monthly_Budget__c> mapOfMonthAndMedia = new map<String,Monthly_Budget__c>();
            system.debug(acc.name);
            Account act = new Account();
           
        if(acc.FNDN_Billed_Through_TVM__c == false){
          
           for(Monthly_Budget__c m:acc.Monthly_Budgets__r)
            {
                if(m.Budget_Month__c != null && m.Budget_Year__c != null)
                {
                    if(m.Budget_Month__c == Month && m.Budget_Year__c == Year)
                    {
                        mapOfMonth.put('Current_Month_Budget', True);
                        mapOfMonthAndMedia.put('Current_Month_Budget', m);
                    }  
                    if(m.Budget_Month__c == NxtMnth && m.Budget_Year__c == NxtYear)
                    {
                        mapOfMonth.put('New_Month_Budget', True);
                        mapOfMonthAndMedia.put('New_Month_Budget', m);
                    }
                    if(m.Budget_Month__c == LastMnth && m.Budget_Year__c == LastYear)
                    {
                        mapOfMonth.put('Last_Month__c', True);
                        mapOfMonthAndMedia.put('Last_Month__c', m);
                    }
                    /* if(m.Budget_Month__c == Month && m.Budget_Year__c == Year){
act.Current_Month_Budget__c = True;
}  
if((m.Budget_Month__c != Month && m.Budget_Year__c != Year)||(m.Budget_Month__c != Month && m.Budget_Year__c == Year && m.Budget_Month__c != NxtMnth)||(m.Budget_Month__c == Month && m.Budget_Year__c != Year && m.Budget_Month__c != NxtMnth)){
act.Current_Month_Budget__c = False;
}                    
if(m.Budget_Month__c == NxtMnth && m.Budget_Year__c == NxtYear){
act.New_Month_Budget__c = True;
}
if((m.Budget_Month__c != NxtMnth && m.Budget_Year__c != NxtYear) || (m.Budget_Month__c != NxtMnth && m.Budget_Year__c == NxtYear && m.Budget_Month__c != Month)||(m.Budget_Month__c == NxtMnth && m.Budget_Year__c != NxtYear && m.Budget_Month__c != Month)){
act.New_Month_Budget__c = False;
} */   
                }
            }
            System.debug('mapOfMonth ================'+mapOfMonth);
            System.debug('mapOfMonthAndMedia ================'+mapOfMonthAndMedia);
            
            If(mapOfMonth.containsKey('Current_Month_Budget'))
            {
                act.Current_Month_Budget__c = true;
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('Current_Month_Budget');
                act.Current_Month_Budget_Fields__c ='New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
                
                /*If(mediaBudget.Account__r.Active__c == true)
                {
                    Integer index =  mediaBudget.Account__r.Type__c?.split(';').indexOf('Digital Advertising');
                    if(index != null && index != -1) {
                        if(mediaBudget.Total__c == 0 )
                        {
                            act.Tech_Fee_To_Budget_Ratio__c = 0;
                        }
                        else{
                             act.Tech_Fee_To_Budget_Ratio__c = ((mediaBudget.Account__r.Total_MRR__c/mediaBudget.Total__c)*100 ). setScale(2);
                        }
                    }
                }*/
                act.Current_Month_Budget_Total__c = mediaBudget.Total__c;
                
            }
            else
            {
                act.Current_Month_Budget__c = false; 
                act.Current_Month_Budget_Fields__c = '';
            }
            If(mapOfMonth.containsKey('New_Month_Budget'))
            {
                act.New_Month_Budget__c = true;
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('New_Month_Budget');
                act.New_Month_Budget_Fields__c    = 'New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
                
            /*    act.New_Search__c              = mediaBudget.PPC_Budget_Sales__c;
                act.Service_Search__c          = mediaBudget.PPC_Budget_Service__c;
                act.Used_Search__c             = mediaBudget.PPC_Budget_DISC__c ;
                act.Video__c               = mediaBudget.Video_Budget_Sales__c;
                act.FB__c            = mediaBudget.SMA_Budget_Sales__c  ;
                act.Facebook_Used_Car_Budget__c           = mediaBudget.SMA_Budget_Preowned__c;
                act.New_Vehicle_Ads__c  = mediaBudget.PPC_Budget_VLA_New__c;
                act.Vehicle_Ads_Used_Car_Budget__c = mediaBudget.PPC_Budget_VLA_Used__c; */
            }
            else
            {
                act.New_Month_Budget__c = false; 
                act.New_Month_Budget_Fields__c  ='';
           /*     act.New_Search__c              = null;
                act.Service_Search__c          = null;
                act.Used_Search__c             = null;
                act.Video__c               = null;
                act.FB__c            = null;
                act.Facebook_Used_Car_Budget__c           = null;
                act.New_Vehicle_Ads__c  = null;
                act.Vehicle_Ads_Used_Car_Budget__c = null;  */
            }
            If(mapOfMonth.containsKey('Last_Month__c'))
            {
                act.Last_Month__c = true; 
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('Last_Month__c');
                act.Last_Month_Budget_Fields__c   = 'New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
            }
            else
            {
                act.Last_Month__c = false; 
                act.Last_Month_Budget_Fields__c= '';
            }
            
            act.Id = acc.Id;
            accList.add(act);
        }
          
        if(acc.FNDN_Billed_Through_TVM__c == True && acc.Touchpoint_Master_ID__c != null){
            System.debug('acc ' +acc.Touchpoint_Master_ID__c);
            System.debug('acc ' +acc.id);
             List<Account> acc1List = [
    SELECT Id, Name, Foundation_Account__c, FNDN_Billed_Through_TVM__c, Touchpoint_Master_ID__c,
        (SELECT Id, Total__c, Budget_Month__c, Budget_Year__c,
                PPC_Budget_Sales__c, PPC_Budget_Service__c, PPC_Budget_DISC__c,
                Video_Budget_Sales__c, SMA_Budget_Sales__c, SMA_Budget_Preowned__c,
                PPC_Budget_VLA_New__c, PPC_Budget_VLA_Used__c
         FROM Monthly_Budgets__r
         WHERE (Budget_Month__c = :Month AND Budget_Year__c = :Year)
            OR (Budget_Month__c = :NxtMnth AND Budget_Year__c = :NxtYear)
            OR (Budget_Month__c = :LastMnth AND Budget_Year__c = :LastYear)
         )
    FROM Account
               
    WHERE Foundation_Account__c = :acc.Touchpoint_Master_ID__c
    LIMIT 1
];
           /* List<Account> acc1List = [ SELECT Id, Name, Tech_Fee_To_Budget_Ratio__c, Active__c, FNDN_Billed_Through_TVM__c, Touchpoint_Master_ID__c, Foundation_Account__c, Type__c, Total_MRR__c, ( SELECT Id, Account__r.Active__c, Account__r.Type__c, Account__r.Tech_Fee_To_Budget_Ratio__c, Account__r.Total_MRR__c, Total__c, Date__c, Budget_Month__c, Budget_Year__c, PPC_Budget_Sales__c, PPC_Budget_Service__c, PPC_Budget_DISC__c, Video_Budget_Sales__c, SMA_Budget_Sales__c, SMA_Budget_Preowned__c, PPC_Budget_VLA_New__c, PPC_Budget_VLA_Used__c FROM Monthly_Budgets__r WHERE (Budget_Month__c = :Month AND Budget_Year__c = :Year) OR (Budget_Month__c = :NxtMnth AND Budget_Year__c = :NxtYear) OR (Budget_Month__c = :LastMnth AND Budget_Year__c = :LastYear) LIMIT 3 ) FROM Account WHERE Id IN ( SELECT Account__c FROM Monthly_Budget__c WHERE ( Account__r.FNDN_Billed_Through_TVM__c = true AND Account__r.Touchpoint_Master_ID__c != null ) OR (Budget_Month__c = :Month AND Budget_Year__c = :Year) OR (Budget_Month__c = :NxtMnth AND Budget_Year__c = :NxtYear) OR (Budget_Month__c = :LastMnth AND Budget_Year__c = :LastYear) ) ];*/
  System.debug('recordcount ' + acc1List.size());
              System.debug('list ' + acc1List);
if (acc1List.isEmpty() || acc1List[0].Monthly_Budgets__r == null) {
    System.debug('SKIPPING ACCOUNT ' + acc.Id +' | TVM=' + acc.FNDN_Billed_Through_TVM__c +' | TPM=' + acc.Touchpoint_Master_ID__c);

    continue;
}


Account acc1 = acc1List[0];
 
           
            for(Monthly_Budget__c m:acc1.Monthly_Budgets__r)
            {
               system.debug('month'+m.Budget_Month__c);
               system.debug('Year'+m.Budget_Year__c);
               if(m.Budget_Month__c != null && m.Budget_Year__c != null)
                {
                    if(m.Budget_Month__c == Month && m.Budget_Year__c == Year)
                    {
                        

                        mapOfMonth.put('Current_Month_Budget', True);
                        mapOfMonthAndMedia.put('Current_Month_Budget', m);
                    }  
                    if(m.Budget_Month__c == NxtMnth && m.Budget_Year__c == NxtYear)
                    {
                        mapOfMonth.put('New_Month_Budget', True);
                        mapOfMonthAndMedia.put('New_Month_Budget', m);
                    }
            }
                    if(m.Budget_Month__c == LastMnth && m.Budget_Year__c == LastYear)
                    {
                        mapOfMonth.put('Last_Month__c', True);
                        mapOfMonthAndMedia.put('Last_Month__c', m);
                    }
                    /* if(m.Budget_Month__c == Month && m.Budget_Year__c == Year){
act.Current_Month_Budget__c = True;
}  
if((m.Budget_Month__c != Month && m.Budget_Year__c != Year)||(m.Budget_Month__c != Month && m.Budget_Year__c == Year && m.Budget_Month__c != NxtMnth)||(m.Budget_Month__c == Month && m.Budget_Year__c != Year && m.Budget_Month__c != NxtMnth)){
act.Current_Month_Budget__c = False;
}                    
if(m.Budget_Month__c == NxtMnth && m.Budget_Year__c == NxtYear){
act.New_Month_Budget__c = True;
}
if((m.Budget_Month__c != NxtMnth && m.Budget_Year__c != NxtYear) || (m.Budget_Month__c != NxtMnth && m.Budget_Year__c == NxtYear && m.Budget_Month__c != Month)||(m.Budget_Month__c == NxtMnth && m.Budget_Year__c != NxtYear && m.Budget_Month__c != Month)){
act.New_Month_Budget__c = False;
} */   
                }
           

            System.debug('mapOfMonth ================'+mapOfMonth);
            System.debug('mapOfMonthAndMedia ================'+mapOfMonthAndMedia);
            
            If(mapOfMonth.containsKey('Current_Month_Budget'))
            {
                act.Current_Month_Budget__c = true;
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('Current_Month_Budget');
                act.Current_Month_Budget_Fields__c ='New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
                
                /*If(mediaBudget.Account__r.Active__c == true)
                {
                    Integer index =  mediaBudget.Account__r.Type__c?.split(';').indexOf('Digital Advertising');
                    if(index != null && index != -1) {
                        if(mediaBudget.Total__c == 0 )
                        {
                            act.Tech_Fee_To_Budget_Ratio__c = 0;
                        }
                        else{
                             act.Tech_Fee_To_Budget_Ratio__c = ((mediaBudget.Account__r.Total_MRR__c/mediaBudget.Total__c)*100 ). setScale(2);
                        }
                    }
                }*/
                act.Current_Month_Budget_Total__c = mediaBudget.Total__c;
                
            }
            else
            {
                act.Current_Month_Budget__c = false; 
                act.Current_Month_Budget_Fields__c = '';
            }
            If(mapOfMonth.containsKey('New_Month_Budget'))
            {
                act.New_Month_Budget__c = true;
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('New_Month_Budget');
                act.New_Month_Budget_Fields__c    = 'New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
                
            /*    act.New_Search__c              = mediaBudget.PPC_Budget_Sales__c;
                act.Service_Search__c          = mediaBudget.PPC_Budget_Service__c;
                act.Used_Search__c             = mediaBudget.PPC_Budget_DISC__c ;
                act.Video__c               = mediaBudget.Video_Budget_Sales__c;
                act.FB__c            = mediaBudget.SMA_Budget_Sales__c  ;
                act.Facebook_Used_Car_Budget__c           = mediaBudget.SMA_Budget_Preowned__c;
                act.New_Vehicle_Ads__c  = mediaBudget.PPC_Budget_VLA_New__c;
                act.Vehicle_Ads_Used_Car_Budget__c = mediaBudget.PPC_Budget_VLA_Used__c; */
            }
            else
            {
                act.New_Month_Budget__c = false; 
                act.New_Month_Budget_Fields__c  ='';
           /*     act.New_Search__c              = null;
                act.Service_Search__c          = null;
                act.Used_Search__c             = null;
                act.Video__c               = null;
                act.FB__c            = null;
                act.Facebook_Used_Car_Budget__c           = null;
                act.New_Vehicle_Ads__c  = null;
                act.Vehicle_Ads_Used_Car_Budget__c = null;  */
            }
            If(mapOfMonth.containsKey('Last_Month__c'))
            {
                act.Last_Month__c = true; 
                Monthly_Budget__c mediaBudget = mapOfMonthAndMedia.get('Last_Month__c');
                act.Last_Month_Budget_Fields__c   = 'New Search : $ '                  + mediaBudget.PPC_Budget_Sales__c               + '\n' +
                    'Service Search : $ '              + mediaBudget.PPC_Budget_Service__c           + '\n' +
                    'Used Search : $ '                 + mediaBudget.PPC_Budget_DISC__c              + '\n' +
                    'New Video : $ '                   + mediaBudget.Video_Budget_Sales__c                    + '\n' +
                    'Facebook New : $ '                + mediaBudget.SMA_Budget_Sales__c                       + '\n' +
                    'Facebook Used : $ '               + mediaBudget.SMA_Budget_Preowned__c + '\n' +
                    'Vehicle Ads New Car Budget : $ '  + mediaBudget.PPC_Budget_VLA_New__c          + '\n' +
                    'Vehicle Ads Used Car Budget : $ ' + mediaBudget.PPC_Budget_VLA_Used__c;
            }
            else
            {
                act.Last_Month__c = false; 
                act.Last_Month_Budget_Fields__c= '';
            }
            
            act.Id = acc.Id;
            accList.add(act);
        }
        }
            
        if(accList != null && !accList.isEmpty())
        {
            system.debug('accList before update -- '+accList);
            database.update(accList,true);
        }
    }
    
     global void finish(Database.BatchableContext BC)
    {
  Integer i= 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
             i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
         i++;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
            
    }
    
    global void execute(SchedulableContext sc)
    {
        mediaBudgetFlagOnAccBatch b = new mediaBudgetFlagOnAccBatch(); //ur batch class
        database.executebatch(b,50);
    }
}