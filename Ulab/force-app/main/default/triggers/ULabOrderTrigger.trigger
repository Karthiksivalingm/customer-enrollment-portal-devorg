trigger ULabOrderTrigger on uLab_Order__c (After insert,After Update) {
    if(Trigger.isAfter && Trigger.isInsert){
        set<Id> accountId = new set<Id>();
        for(uLab_Order__c order : trigger.new){
            if(order.uLab_Case__c != null &&(order.Order_Status__c == 'Processed' || order.Order_Status__c == 'Shipped' || order.Order_Status__c == 'Delivered')){
                accountId.add(order.AccountId__c);
            }
        }
        if(accountId != null && !accountId.isEmpty()){
            Marketing_Reward_Association__c markReward = [select id,Effective_Date__c,End_Date__c,Program_Name__c,Company__r.Premier_Total_Aligner_Price__c,Company__r.Premier_Total_Custom_Box_Price__c,Company__r.Premier_Total_Retainer_Price__c,Company__c,Company__r.New_Total_Aligner_Price__c,Company__r.New_Total_Custom_Box_Price__c,Company__r.New_Total_Retainer_Price__c,Company__r.uPP_Total_Aligner_Price__c,Company__r.uPP_Total_Custom_Box_Price__c,Company__r.uPP_Total_Retainer_Price__c from Marketing_Reward_Association__c where Company__c In:accountId and RecordType.Name='Program Association'];
            list<Account> accList = new  list<Account>();
            for(uLab_Order__c order : trigger.new){
                if(order.OrderDate__c >= markReward.Effective_Date__c && order.OrderDate__c <= markReward.End_Date__c ){
                    if(markReward.Program_Name__c.contains('Premier')){
                        Account acc = new Account();
                        acc.Premier_Total_Aligner_Price__c = order.Total_Aligner_Price__c + markReward.Company__r.Premier_Total_Aligner_Price__c ;
                        acc.Premier_Total_Custom_Box_Price__c = order.Total_Custom_Box_Price__c + markReward.Company__r.Premier_Total_Custom_Box_Price__c ;
                        acc.Premier_Total_Retainer_Price__c = order.Total_Retainer_Price__c + markReward.Company__r.Premier_Total_Retainer_Price__c  ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                    if(markReward.Program_Name__c.contains('New')){
                        Account acc = new Account();
                        acc.New_Total_Aligner_Price__c = order.Total_Aligner_Price__c + markReward.Company__r.New_Total_Aligner_Price__c ;
                        acc.New_Total_Custom_Box_Price__c = order.Total_Custom_Box_Price__c + markReward.Company__r.New_Total_Custom_Box_Price__c ;
                        acc.New_Total_Retainer_Price__c = order.Total_Retainer_Price__c + markReward.Company__r.New_Total_Retainer_Price__c  ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                     if(markReward.Program_Name__c.contains('uPP')){
                        Account acc = new Account();
                        acc.uPP_Total_Aligner_Price__c = order.Total_Aligner_Price__c + markReward.Company__r.uPP_Total_Aligner_Price__c ;
                        acc.uPP_Total_Custom_Box_Price__c = order.Total_Custom_Box_Price__c + markReward.Company__r.uPP_Total_Custom_Box_Price__c ;
                        acc.uPP_Total_Retainer_Price__c = order.Total_Retainer_Price__c + markReward.Company__r.uPP_Total_Retainer_Price__c  ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                }
            }
            Update accList;
        }
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        set<Id> accountId = new set<Id>();
        for(uLab_Order__c order : trigger.new){
            if(order.AccountId__c != null && Trigger.newMap.get(order.Id).Order_Status__c == 'Cancelled' && Trigger.newMap.get(order.Id).Order_Status__c != Trigger.oldMap.get(order.Id).Order_Status__c ){
                accountId.add(order.AccountId__c);
            }
        }
        if(accountId != null && !accountId.isEmpty()){
            Marketing_Reward_Association__c markReward = [select id,Effective_Date__c,End_Date__c,Program_Name__c,Company__r.Premier_Total_Aligner_Price__c,Company__r.Premier_Total_Custom_Box_Price__c,Company__r.Premier_Total_Retainer_Price__c,Company__c,Company__r.New_Total_Aligner_Price__c,Company__r.New_Total_Custom_Box_Price__c,Company__r.New_Total_Retainer_Price__c,Company__r.uPP_Total_Aligner_Price__c,Company__r.uPP_Total_Custom_Box_Price__c,Company__r.uPP_Total_Retainer_Price__c from Marketing_Reward_Association__c where Company__c In:accountId and RecordType.Name='Program Association'];
            list<Account> accList = new  list<Account>();
            for(uLab_Order__c order : trigger.new){
                if(order.OrderDate__c >= markReward.Effective_Date__c && order.OrderDate__c <= markReward.End_Date__c ){
                    if(markReward.Program_Name__c.contains('Premier')){
                        Account acc = new Account();
                        acc.Premier_Total_Aligner_Price__c =  markReward.Company__r.Premier_Total_Aligner_Price__c - order.Total_Aligner_Price__c ;
                        acc.Premier_Total_Custom_Box_Price__c =  markReward.Company__r.Premier_Total_Custom_Box_Price__c -order.Total_Custom_Box_Price__c  ;
                        acc.Premier_Total_Retainer_Price__c =  markReward.Company__r.Premier_Total_Retainer_Price__c -order.Total_Retainer_Price__c   ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                    if(markReward.Program_Name__c.contains('New')){
                        Account acc = new Account();
                        acc.New_Total_Aligner_Price__c =  markReward.Company__r.New_Total_Aligner_Price__c - order.Total_Aligner_Price__c ;
                        acc.New_Total_Custom_Box_Price__c = markReward.Company__r.New_Total_Custom_Box_Price__c - order.Total_Custom_Box_Price__c;
                        acc.New_Total_Retainer_Price__c =  markReward.Company__r.New_Total_Retainer_Price__c -order.Total_Retainer_Price__c ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                     if(markReward.Program_Name__c.contains('uPP')){
                        Account acc = new Account();
                        acc.uPP_Total_Aligner_Price__c =  markReward.Company__r.uPP_Total_Aligner_Price__c - order.Total_Aligner_Price__c ;
                        acc.uPP_Total_Custom_Box_Price__c =  markReward.Company__r.uPP_Total_Custom_Box_Price__c - order.Total_Custom_Box_Price__c;
                        acc.uPP_Total_Retainer_Price__c =  markReward.Company__r.uPP_Total_Retainer_Price__c - order.Total_Retainer_Price__c ;
                        acc.Id =  markReward.Company__c ;
                        accList.add(acc);
                    }
                }
            }
            Update accList;
        }
    }
}