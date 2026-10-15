public class CompanyTotalPriceBatch implements Database.Batchable<sObject>, Schedulable  {
    
    public set<Id> accountId = new set<Id>();
    public list<Account> accList = new  list<Account>();
    public list<Account> accListtoUpdate = new  list<Account>();
    public set<Account> accSet = new  set<Account>();
    public string companyIds;
    public CompanyTotalPriceBatch(String companyId){
        if(companyId != null){
            companyIds = companyId;
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        if(companyIds == null){
            query = 'select id,Prorated_Goal__c,uPP_Aligner_Count_6_Month__c,uPP_Aligner_Count_Current_Month__c,uPP_Retainer_Count_6_Month__c,uPP_Retainer_Count_Current_Month__c,Progress_Towards_Annual_Goal__c,Premier_Partner_Aligner_Count__c,Premier_Partner_Retainer_Count__c,Month_1_Aligner_Count__c,Month_1_Retainer_Count__c,Month_2_Aligner_Count__c,Month_2_Retainer_Count__c,Month_3_Aligner_Count__c,Month_3_Retainer_Count__c,Month_4_Aligner_Count__c,Month_4_Retainer_Count__c from Account where Id In(select company__c from Marketing_Reward_Association__c where  RecordType.Name=\'Program Association\')';
        }
        else {
            query = 'select id,Prorated_Goal__c,uPP_Aligner_Count_6_Month__c,uPP_Aligner_Count_Current_Month__c,uPP_Retainer_Count_6_Month__c,uPP_Retainer_Count_Current_Month__c,Progress_Towards_Annual_Goal__c,Premier_Partner_Aligner_Count__c,Premier_Partner_Retainer_Count__c,Month_1_Aligner_Count__c,Month_1_Retainer_Count__c,Month_2_Aligner_Count__c,Month_2_Retainer_Count__c,Month_3_Aligner_Count__c,Month_3_Retainer_Count__c,Month_4_Aligner_Count__c,Month_4_Retainer_Count__c from Account where Id =: companyIds and  Id In(select company__c from Marketing_Reward_Association__c where  RecordType.Name=\'Program Association\')';
        }  
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Account> scope){
        
        for(Account obj : scope){
            accountId.add(obj.Id);
        }
        map<Id,list<uLab_Order__c>> uLabOrderListMap = new map<Id,list<uLab_Order__c>>();
        list<Marketing_Reward_Association__c> markRewardList = [select id,Prorated_Goal__c,Effective_Date__c,End_Date__c,Program_Name__c,company__c from Marketing_Reward_Association__c where RecordType.Name='Program Association' and Company__c In: accountId and Marketing_Program__r.Status__c = 'Active' and Active__c = true];
        list<uLab_Order__c> orderList = new list<uLab_Order__c>();
        orderList = [select id,AccountId__c,Total_Price__c,Total_Aligner_Count__c,Total_Retainer_Count__c,OrderDate__c from uLab_Order__c where AccountId__c In: accountId and Order_Status__c Not In ('Preorder','Cancelled') AND Order_Type__c = 'uLab Aligner' and OrderDate__c != null];
        
        for(uLab_Order__c order : orderList){
            if(uLabOrderListMap.containsKey(order.AccountId__c )) {
                uLabOrderListMap.get(order.AccountId__c).add(order);
            }
            else{
                uLabOrderListMap.put(order.AccountId__c, new List<uLab_Order__c> { order });
            }
        }
        for(Marketing_Reward_Association__c markReward :markRewardList){
            String programName;
            Account acc = new Account();
            acc.Id =  markReward.Company__c ;
            if(uLabOrderListMap.containsKey(markReward.Company__c)) {
                Decimal progressTowardGoal  = 0;
                Decimal premierTotalAligner  = 0;
                Decimal premierTotalRetainer  = 0;
                Decimal newTotalAlignerCurrent = 0;
                Decimal newTotalRetainerCurrent = 0;
                Decimal newTotalAlignerPrevious = 0;
                Decimal newTotalRetainerPrevious = 0;
                Decimal newTotalAligner2Previous = 0;
                Decimal newTotalRetainer2Previous = 0;
                Decimal newTotalAligner3Previous = 0;
                Decimal newTotalRetainer3Previous = 0;
                Decimal uPPTotalAlignerCurrent = 0;
                Decimal uPPTotalRetainerCurrent = 0;
                Decimal uPPTotalAligner6Month = 0;
                Decimal uPPTotalRetainer6Month = 0;
                integer i =0;
                
                System.debug('===='+uLabOrderListMap.get(markReward.Company__c).size());
                for(uLab_Order__c order : uLabOrderListMap.get(markReward.Company__c)){
                    if(order.Total_Retainer_Count__c == null ){
                        order.Total_Retainer_Count__c = 0;
                    }
                    Date d = Date.today();
                    if(order.OrderDate__c >= markReward.Effective_Date__c && order.OrderDate__c <= markReward.End_Date__c){
                        System.debug('===='+i+1);
                        if(markReward.Program_Name__c.contains('Premier')){
                            programName ='Premier';
                            premierTotalAligner =  order.Total_Aligner_Count__c + premierTotalAligner;
                            premierTotalRetainer = order.Total_Retainer_Count__c + premierTotalRetainer;
                            progressTowardGoal = order.Total_Price__c + progressTowardGoal;
                        }
                        if(markReward.Program_Name__c.contains('New')){
                            programName ='New';
                            if(d.month() == (order.OrderDate__c).Month()){
                                system.debug('= order.Total_Aligner_Count__c==='+ order.Total_Aligner_Count__c);
                                newTotalAlignerCurrent =  newTotalAlignerCurrent + order.Total_Aligner_Count__c ;
                                newTotalRetainerCurrent = newTotalRetainerCurrent + order.Total_Retainer_Count__c;
                            }
                            /* else{
                                   system.debug('==orderMonth==='+(order.OrderDate__c).Month());
                                   system.debug('==month==='+d.addMonths(-1).month()); 
                            
                            */
                            if(d.addMonths(-1).month() == (order.OrderDate__c).Month()){
                                system.debug('==orderMonth==='+(order.OrderDate__c).Month());
                                system.debug('==month==='+d.addMonths(-1).month());
                                newTotalAlignerPrevious =  newTotalAlignerPrevious + order.Total_Aligner_Count__c ;
                                newTotalRetainerPrevious = newTotalRetainerPrevious + order.Total_Retainer_Count__c;
                            }
                            if(d.addMonths(-2).month() == (order.OrderDate__c).Month()){
                                system.debug('====='+(order.OrderDate__c).Month());
                                system.debug('====='+d.addMonths(-2).month());
                                newTotalAligner2Previous =  newTotalAligner2Previous + order.Total_Aligner_Count__c ;
                                newTotalRetainer2Previous = newTotalRetainer2Previous + order.Total_Retainer_Count__c;
                            }
                            if(d.addMonths(-3).month() == (order.OrderDate__c).Month()){
                                newTotalAligner3Previous =  newTotalAligner3Previous + order.Total_Aligner_Count__c ;
                                newTotalRetainer3Previous = newTotalRetainer3Previous + order.Total_Retainer_Count__c;
                            }
                            // }
                        }
                        if(markReward.Program_Name__c.contains('uPP')){
                            programName = 'uPP';
                            
                            if(d.month() == (order.OrderDate__c).Month()){
                                uPPTotalAlignerCurrent =  uPPTotalAlignerCurrent + order.Total_Aligner_Count__c ;
                                uPPTotalRetainerCurrent = uPPTotalRetainerCurrent + order.Total_Retainer_Count__c;
                            }
                            uPPTotalAligner6Month =  uPPTotalAligner6Month + order.Total_Aligner_Count__c ;
                            uPPTotalRetainer6Month = uPPTotalRetainer6Month + order.Total_Retainer_Count__c;
                            
                        }
                    }  
                }
                if(programName == 'Premier'){
                    acc.Progress_Towards_Annual_Goal__c = progressTowardGoal;
                    acc.Premier_Partner_Aligner_Count__c = premierTotalAligner;
                    acc.Premier_Partner_Retainer_Count__c = premierTotalRetainer;
                }
                if(programName =='New'){
                    acc.Month_1_Aligner_Count__c = newTotalAlignerCurrent;
                    acc.Month_1_Retainer_Count__c = newTotalRetainerCurrent;
                    acc.Month_2_Aligner_Count__c =   newTotalAlignerPrevious;
                    acc.Month_2_Retainer_Count__c = newTotalRetainerPrevious;
                    acc.Month_3_Aligner_Count__c = newTotalAligner2Previous;
                    acc.Month_3_Retainer_Count__c = newTotalRetainer2Previous;
                    acc.Month_4_Aligner_Count__c = newTotalAligner3Previous;
                    acc.Month_4_Retainer_Count__c = newTotalRetainer3Previous;
                }
                if(programName =='uPP'){
                    System.Debug('Goal uPP' + markReward.Prorated_Goal__c);
                    acc.Prorated_Goal__c = markReward.Prorated_Goal__c;
                    acc.uPP_Aligner_Count_Current_Month__c = uPPTotalAlignerCurrent;
                    acc.uPP_Retainer_Count_Current_Month__c = uPPTotalRetainerCurrent;
                    acc.uPP_Aligner_Count_6_Month__c = uPPTotalAligner6Month;
                    acc.uPP_Retainer_Count_6_Month__c = uPPTotalRetainer6Month;
                }
                
                acc.Prorated_Goal__c = markReward.Prorated_Goal__c;
                accList.add(acc);
                System.Debug('======IF Conditon');
            }
            else if(orderList == null || orderList.isEmpty() ){
                if(markReward.Program_Name__c.contains('Premier')){
                    acc.Progress_Towards_Annual_Goal__c = 0;
                    acc.Premier_Partner_Aligner_Count__c = 0;
                    acc.Premier_Partner_Retainer_Count__c = 0;
                }
                if(markReward.Program_Name__c.contains('New')){
                    acc.Month_1_Aligner_Count__c = 0;
                    acc.Month_1_Retainer_Count__c = 0;
                    acc.Month_2_Aligner_Count__c =   0;
                    acc.Month_2_Retainer_Count__c = 0;
                    acc.Month_3_Aligner_Count__c = 0;
                    acc.Month_3_Retainer_Count__c = 0;
                    acc.Month_4_Aligner_Count__c = 0;
                    acc.Month_4_Retainer_Count__c = 0;
                }
                if(markReward.Program_Name__c.contains('uPP')){
                    acc.Prorated_Goal__c = markReward.Prorated_Goal__c;
                    System.Debug('Goal uPP1' + markReward.Prorated_Goal__c);
                    acc.uPP_Aligner_Count_Current_Month__c = 0;
                    acc.uPP_Retainer_Count_Current_Month__c = 0;
                    acc.uPP_Aligner_Count_6_Month__c = 0;
                    acc.uPP_Retainer_Count_6_Month__c = 0;
                } 
                acc.Prorated_Goal__c = markReward.Prorated_Goal__c;
                accList.add(acc);
                System.Debug('====== Else Conditon');
            }
        }
        accSet.addAll(accList);
        accListtoUpdate = new List<account>(accSet);        
        database.update(accListtoUpdate,true);
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    public void execute(SchedulableContext sc) {
        //Database.executeBatch takes in the class, and then the size of batches.
        ID BatchId = Database.executeBatch(new CompanyTotalPriceBatch(null), 100);
    }
    
}