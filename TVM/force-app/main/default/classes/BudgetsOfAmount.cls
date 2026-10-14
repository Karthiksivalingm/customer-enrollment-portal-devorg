//Apex from FND
global class BudgetsOfAmount {
    global String mediaId{get;set;}
    global Monthly_Budget__c MediaObj{
        get{
            if(mediaId != null){
                Monthly_Budget__c obj = [select id,PPC_Budget_Sales__c,PPC_Budget_Service__c,PPC_Budget_DISC__c,SMA_Budget_Service__c,SMA_Budget_Sales__c,Display_Budget_Sales__c,Video_Budget_Sales__c,Display_Budget_Preowned__c,Video_Budget_Preowned__c from Monthly_Budget__c where id =: mediaId];
                
                return obj;
            }
            return null;
        }
        set{}
        
    }
}