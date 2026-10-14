//Apex class from FND

public class OnboardingTriggerHandler {
    
    public static Boolean isFirstTime = true;
    
    public static void AfterUpdateOnboardingFieldOfSameAccount(List<Foundation_Onboarding__c> oldRecords,List<Foundation_Onboarding__c> newRecords, Map<Id,Foundation_Onboarding__c> oldMapOnboarding, Map<Id,Foundation_Onboarding__c> newMapOnboarding)
    {
        Map<ID,List<Foundation_Onboarding__c>> onboardingMapWithSameAcc = new Map<ID,List<Foundation_Onboarding__c>>();
        Map<Foundation_Onboarding__c,List<Foundation_Onboarding__c>> onboardingMapWithNewOnboardWithList = new Map<Foundation_Onboarding__c,List<Foundation_Onboarding__c>>();
        Set<ID> accIdSet = new Set<ID>();
        List<Foundation_Onboarding__c> listToUpdate= new List<Foundation_Onboarding__c>();
        
        for(Foundation_Onboarding__c onboarding:newRecords){
            if(( newMapOnboarding.get(onboarding.Id).Auto_charge_monthly_fee__c != oldMapOnboarding.get(onboarding.Id).Auto_charge_monthly_fee__c )
               //||(newMapOnboarding.get(onboarding.Id).BI_Launch_Date__c != oldMapOnboarding.get(onboarding.Id).BI_Launch_Date__c )
               ||(newMapOnboarding.get(onboarding.Id).BigQuery_is_linked_in_GA4__c != oldMapOnboarding.get(onboarding.Id).BigQuery_is_linked_in_GA4__c )
               ||(newMapOnboarding.get(onboarding.Id).Chat_Provider__c != oldMapOnboarding.get(onboarding.Id).Chat_Provider__c )
               ||(newMapOnboarding.get(onboarding.Id).Chat_Start__c != oldMapOnboarding.get(onboarding.Id).Chat_Start__c )
               ||(newMapOnboarding.get(onboarding.Id).Click_to_Call__c != oldMapOnboarding.get(onboarding.Id).Click_to_Call__c )
               ||(newMapOnboarding.get(onboarding.Id).Custom_Definitions_Configurati__c != oldMapOnboarding.get(onboarding.Id).Custom_Definitions_Configurati__c )
               ||(newMapOnboarding.get(onboarding.Id).DR_Start__c != oldMapOnboarding.get(onboarding.Id).DR_Start__c )
               ||(newMapOnboarding.get(onboarding.Id).Dashboard_View_ID__c != oldMapOnboarding.get(onboarding.Id).Dashboard_View_ID__c )
               ||(newMapOnboarding.get(onboarding.Id).Data_Email_QA__c != oldMapOnboarding.get(onboarding.Id).Data_Email_QA__c )
               ||(newMapOnboarding.get(onboarding.Id).Foundation_GA4_View__c != oldMapOnboarding.get(onboarding.Id).Foundation_GA4_View__c )
               ||(newMapOnboarding.get(onboarding.Id).Foundation_View_ID__c != oldMapOnboarding.get(onboarding.Id).Foundation_View_ID__c )
               ||(newMapOnboarding.get(onboarding.Id).GA4_Measurement_ID__c != oldMapOnboarding.get(onboarding.Id).GA4_Measurement_ID__c )
               ||(newMapOnboarding.get(onboarding.Id).GA4_Notes__c != oldMapOnboarding.get(onboarding.Id).GA4_Notes__c )
               ||(newMapOnboarding.get(onboarding.Id).GA4_Property_Name_from_this_sheet__c != oldMapOnboarding.get(onboarding.Id).GA4_Property_Name_from_this_sheet__c )
               ||(newMapOnboarding.get(onboarding.Id).GA_Account_Shared__c != oldMapOnboarding.get(onboarding.Id).GA_Account_Shared__c )
               ||(newMapOnboarding.get(onboarding.Id).GTM_Container_Updated_for_GA4__c != oldMapOnboarding.get(onboarding.Id).GTM_Container_Updated_for_GA4__c )
               ||(newMapOnboarding.get(onboarding.Id).GTM_ID_provided__c != oldMapOnboarding.get(onboarding.Id).GTM_ID_provided__c )
               ||(newMapOnboarding.get(onboarding.Id).GTM_on_Site__c != oldMapOnboarding.get(onboarding.Id).GTM_on_Site__c )
               ||(newMapOnboarding.get(onboarding.Id).Goals_Inactive_at_Dashboard_Call__c != oldMapOnboarding.get(onboarding.Id).Goals_Inactive_at_Dashboard_Call__c )
               ||(newMapOnboarding.get(onboarding.Id).Google_Facebook_Pixel_script_added_to_GT__c != oldMapOnboarding.get(onboarding.Id).Google_Facebook_Pixel_script_added_to_GT__c )
               ||(newMapOnboarding.get(onboarding.Id).Inventory_Is_In__c != oldMapOnboarding.get(onboarding.Id).Inventory_Is_In__c )
               ||(newMapOnboarding.get(onboarding.Id).Inventory_Ordered_Date__c != oldMapOnboarding.get(onboarding.Id).Inventory_Ordered_Date__c )
               ||(newMapOnboarding.get(onboarding.Id).Lead_Form__c != oldMapOnboarding.get(onboarding.Id).Lead_Form__c )
               ||(newMapOnboarding.get(onboarding.Id).Mutual_Client_with_VistaDash__c != oldMapOnboarding.get(onboarding.Id).Mutual_Client_with_VistaDash__c )
               ||(newMapOnboarding.get(onboarding.Id).Non_Standard_Setup_Notes__c != oldMapOnboarding.get(onboarding.Id).Non_Standard_Setup_Notes__c )
               ||(newMapOnboarding.get(onboarding.Id).Review_Goals__c != oldMapOnboarding.get(onboarding.Id).Review_Goals__c )
               ||(newMapOnboarding.get(onboarding.Id).Secure_completed_CC_Auth__c != oldMapOnboarding.get(onboarding.Id).Secure_completed_CC_Auth__c )
               ||(newMapOnboarding.get(onboarding.Id).Send_CC_Auth__c != oldMapOnboarding.get(onboarding.Id).Send_CC_Auth__c )
               ||(newMapOnboarding.get(onboarding.Id).Touchpoint_Master_ID__c != oldMapOnboarding.get(onboarding.Id).Touchpoint_Master_ID__c )
               ||(newMapOnboarding.get(onboarding.Id).Vistadash_Conversions_Configuration_GA4__c != oldMapOnboarding.get(onboarding.Id).Vistadash_Conversions_Configuration_GA4__c )
               ||(newMapOnboarding.get(onboarding.Id).Vistadash_Event_Owner_Custom_Dimension_C__c != oldMapOnboarding.get(onboarding.Id).Vistadash_Event_Owner_Custom_Dimension_C__c )
               ||(newMapOnboarding.get(onboarding.Id).Website_Provider__c != oldMapOnboarding.get(onboarding.Id).Website_Provider__c )
               ||(newMapOnboarding.get(onboarding.Id).Website_URL__c != oldMapOnboarding.get(onboarding.Id).Website_URL__c )
               ||(newMapOnboarding.get(onboarding.Id).Inventory_Received_Automation__c != oldMapOnboarding.get(onboarding.Id).Inventory_Received_Automation__c )
               ||(newMapOnboarding.get(onboarding.Id).GTM_API_ID__c != oldMapOnboarding.get(onboarding.Id).GTM_API_ID__c )
               ||(newMapOnboarding.get(onboarding.Id).Call_Vendor__c != oldMapOnboarding.get(onboarding.Id).Call_Vendor__c )
               ||(newMapOnboarding.get(onboarding.Id).Text_Provider__c != oldMapOnboarding.get(onboarding.Id).Text_Provider__c )
               ||(newMapOnboarding.get(onboarding.Id).GTM_Sent__c != oldMapOnboarding.get(onboarding.Id).GTM_Sent__c )
               )
            {
                accIdSet.add(onboarding.Account__c);
            }
        }
        
        List<Foundation_Onboarding__c> OnboardingWithSameAcc = [SELECT ID,Account__c,Account__r.Id,Auto_charge_monthly_fee__c ,BI_Launch_Date__c,
                                                     BigQuery_is_linked_in_GA4__c ,Chat_Provider__c ,Chat_Start__c,Click_to_Call__c ,
                                                     Custom_Definitions_Configurati__c ,DR_Start__c ,Dashboard_View_ID__c,
                                                     Data_Email_QA__c ,Foundation_GA4_View__c,
                                                     Foundation_View_ID__c,GA4_Measurement_ID__c ,GA4_Notes__c ,GA4_Property_Name_from_this_sheet__c,
                                                     GA_Account_Shared__c ,GTM_Container_Updated_for_GA4__c ,GTM_ID_provided__c ,
                                                     GTM_on_Site__c ,Goals_Inactive_at_Dashboard_Call__c,
                                                     Google_Facebook_Pixel_script_added_to_GT__c ,Inventory_Is_In__c ,
                                                     Inventory_Ordered_Date__c ,Lead_Form__c,Mutual_Client_with_VistaDash__c ,
                                                     Non_Standard_Setup_Notes__c  ,Review_Goals__c ,
                                                     Secure_completed_CC_Auth__c,Send_CC_Auth__c ,
                                                     Touchpoint_Master_ID__c ,
                                                     Vistadash_Conversions_Configuration_GA4__c, 
                                                     Vistadash_Event_Owner_Custom_Dimension_C__c ,Website_Provider__c ,Website_URL__c,
                                                     Inventory_Received_Automation__c,GTM_API_ID__c,Call_Vendor__c,
                                                     Text_Provider__c,GTM_Sent__c
                                                     FROM Foundation_Onboarding__c 
                                                     WHERE Account__r.ID IN: accIdSet];
        
        for(Foundation_Onboarding__c onboarding:OnboardingWithSameAcc){
            
            if(onboardingMapWithSameAcc.containsKey(onboarding.Account__r.Id))
            {
                onboardingMapWithSameAcc.get(onboarding.Account__r.Id).add(onboarding);
            }
            else{
                onboardingMapWithSameAcc.put(onboarding.Account__r.Id,new List<Foundation_Onboarding__c> {onboarding});
            }
            
        }
        
        for(Id idValue : onboardingMapWithSameAcc.keyset()){
            for(Foundation_Onboarding__c onboarding : onboardingMapWithSameAcc.get(idValue)) { 
                if((newMapOnboarding.get(onboarding.Id))!=NULL){
                    onboardingMapWithNewOnboardWithList.put(newMapOnboarding.get(onboarding.Id) , onboardingMapWithSameAcc.get(idValue));
                } 
                else{
                    continue;
                }
            }
        }
        for(Foundation_Onboarding__c idValueOnboarding : onboardingMapWithNewOnboardWithList.keyset()){
            for(Foundation_Onboarding__c onboarding : onboardingMapWithNewOnboardWithList.get(idValueOnboarding)) { 
                if( onboarding.Auto_charge_monthly_fee__c == FALSE &&  idValueOnboarding.Auto_charge_monthly_fee__c == TRUE)
                {
                    onboarding.Auto_charge_monthly_fee__c = idValueOnboarding.Auto_charge_monthly_fee__c;
                }
                //onboarding.BI_Launch_Date__c =idValueOnboarding.BI_Launch_Date__c;
                if( onboarding.BigQuery_is_linked_in_GA4__c == FALSE &&  idValueOnboarding.BigQuery_is_linked_in_GA4__c == TRUE)
                {
                    onboarding.BigQuery_is_linked_in_GA4__c =idValueOnboarding.BigQuery_is_linked_in_GA4__c;   
                }
                if( onboarding.Chat_Provider__c == NULL ||  onboarding.Chat_Provider__c == '')
                {
                    onboarding.Chat_Provider__c = idValueOnboarding.Chat_Provider__c ; 
                }
                if( onboarding.Chat_Start__c == NULL ||  onboarding.Chat_Start__c == '')
                {
                    onboarding.Chat_Start__c=idValueOnboarding.Chat_Start__c ;
                }
                if( onboarding.Click_to_Call__c == NULL ||  onboarding.Click_to_Call__c == '')
                {
                    onboarding.Click_to_Call__c =idValueOnboarding.Click_to_Call__c;
                }
                if( onboarding.Custom_Definitions_Configurati__c == NULL)
                {
                    onboarding.Custom_Definitions_Configurati__c =idValueOnboarding.Custom_Definitions_Configurati__c;
                }
                if( onboarding.DR_Start__c == NULL ||  onboarding.DR_Start__c == '')
                {
                    onboarding.DR_Start__c =idValueOnboarding.DR_Start__c ;
                }
                if( onboarding.Dashboard_View_ID__c == NULL ||  onboarding.Dashboard_View_ID__c == '')
                {  
                    onboarding.Dashboard_View_ID__c =idValueOnboarding.Dashboard_View_ID__c ;
                }
                if( onboarding.Data_Email_QA__c == NULL )
                { 
                    onboarding.Data_Email_QA__c =idValueOnboarding.Data_Email_QA__c; 
                }
                if( onboarding.Foundation_GA4_View__c == NULL ||  onboarding.Foundation_GA4_View__c == '')
                { 
                    onboarding.Foundation_GA4_View__c =idValueOnboarding.Foundation_GA4_View__c ; 
                }
                if( onboarding.Foundation_View_ID__c == NULL ||  onboarding.Foundation_View_ID__c == '')
                {  
                    onboarding.Foundation_View_ID__c =idValueOnboarding.Foundation_View_ID__c ;
                }
                if( onboarding.GA4_Measurement_ID__c == NULL ||  onboarding.GA4_Measurement_ID__c == '')
                {  
                    onboarding.GA4_Measurement_ID__c =idValueOnboarding.GA4_Measurement_ID__c ; 
                }
                if( onboarding.GA4_Notes__c == NULL ||  onboarding.GA4_Notes__c == '')
                {  
                    onboarding.GA4_Notes__c =idValueOnboarding.GA4_Notes__c ; 
                }
                if( onboarding.GA4_Property_Name_from_this_sheet__c == NULL ||  onboarding.GA4_Property_Name_from_this_sheet__c == '')
                {  
                    onboarding.GA4_Property_Name_from_this_sheet__c =idValueOnboarding.GA4_Property_Name_from_this_sheet__c ;
                }
                if( onboarding.GA_Account_Shared__c == NULL ||  onboarding.GA_Account_Shared__c == '')
                { 
                    onboarding.GA_Account_Shared__c =idValueOnboarding.GA_Account_Shared__c ; 
                }
                if( onboarding.GTM_Container_Updated_for_GA4__c == NULL)
                {  
                    onboarding.GTM_Container_Updated_for_GA4__c =idValueOnboarding.GTM_Container_Updated_for_GA4__c ;
                }
                if( onboarding.GTM_ID_provided__c == NULL ||  onboarding.GTM_ID_provided__c == '')
                {  
                    onboarding.GTM_ID_provided__c =idValueOnboarding.GTM_ID_provided__c ;
                }
                if( onboarding.GTM_on_Site__c == NULL)
                { 
                    onboarding.GTM_on_Site__c =idValueOnboarding.GTM_on_Site__c ; 
                }
                if( onboarding.Goals_Inactive_at_Dashboard_Call__c == NULL ||  onboarding.Goals_Inactive_at_Dashboard_Call__c == '')
                { 
                    onboarding.Goals_Inactive_at_Dashboard_Call__c =idValueOnboarding.Goals_Inactive_at_Dashboard_Call__c ; 
                }
                if( onboarding.Google_Facebook_Pixel_script_added_to_GT__c == NULL ||  onboarding.Google_Facebook_Pixel_script_added_to_GT__c == '')
                {  
                    onboarding.Google_Facebook_Pixel_script_added_to_GT__c =idValueOnboarding.Google_Facebook_Pixel_script_added_to_GT__c ;
                }
                if( onboarding.Inventory_Is_In__c == NULL )
                { 
                    onboarding.Inventory_Is_In__c =idValueOnboarding.Inventory_Is_In__c ;
                }
                if( onboarding.Inventory_Ordered_Date__c == NULL )
                { 
                    onboarding.Inventory_Ordered_Date__c =idValueOnboarding.Inventory_Ordered_Date__c ; 
                }
                if( onboarding.Lead_Form__c == NULL ||  onboarding.Lead_Form__c == '')
                { 
                    onboarding.Lead_Form__c =idValueOnboarding.Lead_Form__c ;
                }
                if( onboarding.Mutual_Client_with_VistaDash__c == FALSE &&  idValueOnboarding.Mutual_Client_with_VistaDash__c == TRUE)
                {  
                    onboarding.Mutual_Client_with_VistaDash__c =idValueOnboarding.Mutual_Client_with_VistaDash__c ; 
                }
                if( onboarding.Non_Standard_Setup_Notes__c == NULL ||  onboarding.Non_Standard_Setup_Notes__c == '')
                { 
                    onboarding.Non_Standard_Setup_Notes__c =idValueOnboarding.Non_Standard_Setup_Notes__c ; 
                }
                if( onboarding.Review_Goals__c == NULL )
                { 
                    onboarding.Review_Goals__c =idValueOnboarding.Review_Goals__c ; 
                }
                if( onboarding.Secure_completed_CC_Auth__c == FALSE &&  idValueOnboarding.Secure_completed_CC_Auth__c == TRUE)
                { 
                    onboarding.Secure_completed_CC_Auth__c =idValueOnboarding.Secure_completed_CC_Auth__c ; 
                }
                if( onboarding.Send_CC_Auth__c == NULL )
                {  
                    onboarding.Send_CC_Auth__c =idValueOnboarding.Send_CC_Auth__c ; 
                }
                if( onboarding.Touchpoint_Master_ID__c == NULL ||  onboarding.Touchpoint_Master_ID__c == '')
                {  
                    onboarding.Touchpoint_Master_ID__c =idValueOnboarding.Touchpoint_Master_ID__c ; 
                }
                if( onboarding.Vistadash_Conversions_Configuration_GA4__c == NULL )
                {
                    onboarding.Vistadash_Conversions_Configuration_GA4__c =idValueOnboarding.Vistadash_Conversions_Configuration_GA4__c ; 
                }
                if( onboarding.Vistadash_Event_Owner_Custom_Dimension_C__c == FALSE &&  idValueOnboarding.Vistadash_Event_Owner_Custom_Dimension_C__c == TRUE)
                { 
                    onboarding.Vistadash_Event_Owner_Custom_Dimension_C__c =idValueOnboarding.Vistadash_Event_Owner_Custom_Dimension_C__c; 
                }
                if( onboarding.Website_Provider__c == NULL ||  onboarding.Website_Provider__c == '')
                { 
                    onboarding.Website_Provider__c =idValueOnboarding.Website_Provider__c ;
                }
                if( onboarding.Website_URL__c == NULL ||  onboarding.Website_URL__c == '')
                {  
                    onboarding.Website_URL__c =idValueOnboarding.Website_URL__c ;
                }
                 if( onboarding.Inventory_Received_Automation__c == NULL ||  onboarding.Inventory_Received_Automation__c == '')
                {  
                    onboarding.Inventory_Received_Automation__c =idValueOnboarding.Inventory_Received_Automation__c ;
                }
                if( onboarding.GTM_API_ID__c == NULL ||  onboarding.GTM_API_ID__c == '')
                {  
                    onboarding.GTM_API_ID__c =idValueOnboarding.GTM_API_ID__c ;
                }
                if( onboarding.Call_Vendor__c == NULL ||  onboarding.Call_Vendor__c == '')
                {  
                    onboarding.Call_Vendor__c =idValueOnboarding.Call_Vendor__c ;
                }
                if( onboarding.GTM_Sent__c == NULL )
                {  
                    onboarding.GTM_Sent__c =idValueOnboarding.GTM_Sent__c ;
                }
                if( onboarding.Text_Provider__c == NULL ||  onboarding.Text_Provider__c == '')
                {  
                    onboarding.Text_Provider__c =idValueOnboarding.Text_Provider__c ;
                }
                
                listToUpdate.add(onboarding);
            }
        }
        system.debug('listToUpdate : '+listToUpdate);
        try{
            update listToUpdate;
        }
        catch(Exception e){
            System.debug('Error occured : '+ e.getMessage());
        }
    }
    
    
    // Code from UT
    // 
    public static void beforeInsert(List<Foundation_Onboarding__c> newList) {
        
        set<Id> oppId = new set<Id>();
        for(Foundation_Onboarding__c obj: newList){
            oppId.add(obj.Opportunity__c);
        }
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        for(Opportunity opp : [Select Id,Name, (Select Id from Foundation_Onboarding__r where Active__c = true ) from Opportunity where Id in :oppId]){
            oppMap.put(opp.Id,opp);
        }
        System.debug('==oppMap==='+oppMap);
        
        for(Foundation_Onboarding__c obj: newList){
            if(oppMap.containsKey(obj.Opportunity__c)){
                if(oppMap.get(obj.Opportunity__c).Foundation_Onboarding__r != null && oppMap.get(obj.Opportunity__c).Foundation_Onboarding__r.size()>0){// If greater than 0, throw error
                    System.debug('====='+oppMap.get(obj.Opportunity__c).Foundation_Onboarding__r);
                    //obj.addError('There is already active onboarding for this '+ oppMap.get(obj.Opportunity__c).Name +' opportunity. Please inactive current onboarding record and try again' );
                }
            }
        }
     
     }
    
    public static void AfterInsert(List<Foundation_Onboarding__c> newList){
        
        set<Account> accIdHyundai = new set<Account>();
        for(Foundation_Onboarding__c obj :newList){
            if(obj.Hyundai_Coop__c == true && obj.Account__c != null){
                Account acc = new Account();
                acc.Id = obj.Account__c;
                acc.Hyundai_Coop__c = obj.Hyundai_Coop__c;
                accIdHyundai.add(acc);
            }
        }
        if(accIdHyundai != null && !accIdHyundai.isEmpty()){
            database.update(new list<Account>(accIdHyundai),false);
        }
        
    }
    
    public static void afterUpdate(Map<Id, Foundation_Onboarding__c> oldMap, Map<Id, Foundation_Onboarding__c> newMap) {
        
        Set<Id> accountIdsForTasks = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();

        for (Foundation_Onboarding__c newOb : newMap.values()) {
            Foundation_Onboarding__c oldOb = oldMap.get(newOb.Id);

        //    if (oldOb.Confirm_Launch_Date_with_Client__c != newOb.Confirm_Launch_Date_with_Client__c && newOb.Confirm_Launch_Date_with_Client__c == 'Completed' && newOb.Account__c != null) {
                accountIdsForTasks.add(newOb.Account__c);
         //   }

            if (oldOb.Hyundai_Coop__c != newOb.Hyundai_Coop__c && newOb.Account__c != null) {
                accountsToUpdate.add(new Account(
                    Id = newOb.Account__c,
                    Hyundai_Coop__c = newOb.Hyundai_Coop__c
                ));
            }
        }
        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false);
        }
        if (!accountIdsForTasks.isEmpty()) {
            List<Task> tasksToUpdate = [SELECT Id, Status FROM Task WHERE WhatId IN :accountIdsForTasks AND Subject = 'Confirm Launch Date and Details' ];

            for (Task t : tasksToUpdate) {
                t.Status = 'Completed';
            }
            if (!tasksToUpdate.isEmpty()) {
                update tasksToUpdate;
            }
        }
    }
    
  /*  public static void beforeUpdate(List<Foundation_Onboarding__c> newList){
      
        for(Foundation_Onboarding__c obj : newList){
            String followUp = '';
            String ATFollowUp ='';
            if(Trigger.newMap.get(obj.Id).Facebook_Request_Sent__c != Trigger.OldMap.get(obj.Id).Facebook_Request_Sent__c && obj.Facebook_Request_Sent__c == 'Needs Followup'){
                followUp = 'Facebook Request Sent';
            }
            if(Trigger.newMap.get(obj.Id).Facebook_Request_Accepted__c != Trigger.OldMap.get(obj.Id).Facebook_Request_Accepted__c && obj.Facebook_Request_Accepted__c == 'Needs Followup'){
                followUp = 'Facebook Request Accepted'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).GMB_Request_Sent__c != Trigger.OldMap.get(obj.Id).GMB_Request_Sent__c && obj.GMB_Request_Sent__c == 'Needs Followup'){
                followUp = 'GMB Request Sent'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).GMB_Request_Received__c != Trigger.OldMap.get(obj.Id).GMB_Request_Received__c && obj.GMB_Request_Received__c== 'Needs Followup'){
                followUp = 'GMB Request Received'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Turn_Sitelinks_Off_in_Apollo__c != Trigger.OldMap.get(obj.Id).Turn_Sitelinks_Off_in_Apollo__c && obj.Turn_Sitelinks_Off_in_Apollo__c == 'Needs Followup'){
                followUp = 'Turn Sitelinks Off in Apollo'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_Sitelinks_to_Google_Ads__c != Trigger.OldMap.get(obj.Id).Add_Sitelinks_to_Google_Ads__c && obj.Add_Sitelinks_to_Google_Ads__c == 'Needs Followup'){
                followUp = 'Add Sitelinks to Google Ads'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Zipcodes_Received__c != Trigger.OldMap.get(obj.Id).Zipcodes_Received__c && obj.Zipcodes_Received__c == 'Needs Followup'){
                followUp = 'Zipcodes Received'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Budgets_Confirmed__c != Trigger.OldMap.get(obj.Id).Budgets_Confirmed__c && obj.Budgets_Confirmed__c == 'Needs Followup'){
                followUp = 'Budgets Confirmed'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Budgets_Updated_in_Apollo__c != Trigger.OldMap.get(obj.Id).Budgets_Updated_in_Apollo__c && obj.Budgets_Updated_in_Apollo__c == 'Needs Followup'){
                followUp = 'Budgets Updated in Apollo'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Schedule_Kickoff_Call__c != Trigger.OldMap.get(obj.Id).Schedule_Kickoff_Call__c && obj.Schedule_Kickoff_Call__c == 'Needs Followup'){
                followUp = 'Schedule Kickoff Call'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Send_Geo_targeting_for_Approval__c != Trigger.OldMap.get(obj.Id).Send_Geo_targeting_for_Approval__c && obj.Send_Geo_targeting_for_Approval__c == 'Needs Followup'){
                followUp = 'Send Geo-targeting for Client Approval'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Send_Advertised_Payments_for_Approval__c != Trigger.OldMap.get(obj.Id).Send_Advertised_Payments_for_Approval__c && obj.Send_Advertised_Payments_for_Approval__c == 'Needs Followup'){
                followUp = 'Send Ad Payments for Client Approval'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Confirm_Launch_Date_with_Client__c != Trigger.OldMap.get(obj.Id).Confirm_Launch_Date_with_Client__c && obj.Confirm_Launch_Date_with_Client__c == 'Needs Followup'){
                followUp = 'Confirm Launch Date with Client'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Verify_Inventory_Pricing__c    != Trigger.OldMap.get(obj.Id).Verify_Inventory_Pricing__c   && obj.Verify_Inventory_Pricing__c  == 'Needs Followup'){
                followUp = 'Verify Inventory Pricing'+','+followUp;
            } 
            //if(Trigger.newMap.get(obj.Id).Inventory_Ordered__c != Trigger.OldMap.get(obj.Id).Inventory_Ordered__c && obj.Inventory_Ordered__c == 'Needs Followup'){
               followUp = 'Inventory Ordered'+','+followUp;
              //} 
            if(Trigger.newMap.get(obj.Id).OnboardingPackSent__c != Trigger.OldMap.get(obj.Id).OnboardingPackSent__c && obj.OnboardingPackSent__c == 'Needs Followup'){
                followUp = 'Onboarding Pack Sent'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Onboarding_Pack_Received__c != Trigger.OldMap.get(obj.Id).Onboarding_Pack_Received__c && obj.Onboarding_Pack_Received__c == 'Needs Followup'){
                followUp = 'Onboarding Pack Received'+','+followUp;
            }
            if(Trigger.newMap.get(obj.Id).Create_Google_Account__c != Trigger.OldMap.get(obj.Id).Create_Google_Account__c && obj.Create_Google_Account__c == 'Needs Followup'){
                followUp = 'Create Google Account'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Create_Bing_Account__c != Trigger.OldMap.get(obj.Id).Create_Bing_Account__c && obj.Create_Bing_Account__c == 'Needs Followup'){
                followUp = 'Create Bing Account'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Create_Facebook_Account__c != Trigger.OldMap.get(obj.Id).Create_Facebook_Account__c && obj.Create_Facebook_Account__c == 'Needs Followup'){
                followUp = 'Create Facebook Account'+','+followUp;
            } 
            //if(Trigger.newMap.get(obj.Id).CreditCardAuthSent__c != Trigger.OldMap.get(obj.Id).CreditCardAuthSent__c && obj.CreditCardAuthSent__c == 'Needs Followup'){
                followUp = 'Credit Card Auth Sent'+','+followUp;
             //} 
             // if(Trigger.newMap.get(obj.Id).Credit_Card_Received__c != Trigger.OldMap.get(obj.Id).Credit_Card_Received__c && obj.Credit_Card_Received__c == 'Needs Followup'){
                  followUp = 'Credit Card Received'+','+followUp;
               //   } 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Google__c    != Trigger.OldMap.get(obj.Id).Add_CC_to_Google__c   && obj.Add_CC_to_Google__c  == 'Needs Followup'){
                followUp = 'Add CC to Google'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Bing__c != Trigger.OldMap.get(obj.Id).Add_CC_to_Bing__c && obj.Add_CC_to_Bing__c == 'Needs Followup'){
                followUp = 'Add CC to Bing'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Facebook__c != Trigger.OldMap.get(obj.Id).Add_CC_to_Facebook__c && obj.Add_CC_to_Facebook__c == 'Needs Followup'){
                followUp = 'Add CC to Facebook'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_Received__c != Trigger.OldMap.get(obj.Id).Logo_Received__c && obj.Logo_Received__c == 'Needs Followup'){
                followUp = 'Logo Received'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_added_to_Compliance_Board__c != Trigger.OldMap.get(obj.Id).Logo_added_to_Compliance_Board__c && obj.Logo_added_to_Compliance_Board__c == 'Needs Followup'){
                followUp = 'Logo Added to Compliance Board'+','+followUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_approved_by_Compliance_Team__c != Trigger.OldMap.get(obj.Id).Logo_approved_by_Compliance_Team__c && obj.Logo_approved_by_Compliance_Team__c == 'Needs Followup'){
                followUp = 'Logo Approved by Compliance Team'+','+followUp;
            }
            if(Trigger.newMap.get(obj.Id).Link_GMB_for_Location_Extenstions__c != Trigger.OldMap.get(obj.Id).Link_GMB_for_Location_Extenstions__c && obj.Link_GMB_for_Location_Extenstions__c == 'Needs Followup'){
                followUp = 'Link GMB for Location Extenstions'+','+followUp;
            }
            if(Trigger.newMap.get(obj.Id).Add_to_Measurement_Trix__c != Trigger.OldMap.get(obj.Id).Add_to_Measurement_Trix__c && obj.Add_to_Measurement_Trix__c == 'Needs Followup'){
                followUp = 'Add to Measurement Trix'+','+followUp;
            }
            
            //=================================AT follow up
            if(Trigger.newMap.get(obj.Id).Facebook_Request_Sent__c != Trigger.OldMap.get(obj.Id).Facebook_Request_Sent__c && obj.Facebook_Request_Sent__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Facebook Request Sent';
            }
            if(Trigger.newMap.get(obj.Id).Facebook_Request_Accepted__c != Trigger.OldMap.get(obj.Id).Facebook_Request_Accepted__c && obj.Facebook_Request_Accepted__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Facebook Request Accepted'+','+ATFollowUp ;
            } 
            if(Trigger.newMap.get(obj.Id).GMB_Request_Sent__c != Trigger.OldMap.get(obj.Id).GMB_Request_Sent__c && obj.GMB_Request_Sent__c == 'Needs AT Follow Up'){
                ATFollowUp = 'GMB Request Sent'+','+ATFollowUp ;
            } 
            if(Trigger.newMap.get(obj.Id).GMB_Request_Received__c != Trigger.OldMap.get(obj.Id).GMB_Request_Received__c && obj.GMB_Request_Received__c== 'Needs AT Follow Up'){
                ATFollowUp = 'GMB Request Received'+','+ATFollowUp ;
            } 
            if(Trigger.newMap.get(obj.Id).Turn_Sitelinks_Off_in_Apollo__c != Trigger.OldMap.get(obj.Id).Turn_Sitelinks_Off_in_Apollo__c && obj.Turn_Sitelinks_Off_in_Apollo__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Turn Sitelinks Off in Apollo'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_Sitelinks_to_Google_Ads__c != Trigger.OldMap.get(obj.Id).Add_Sitelinks_to_Google_Ads__c && obj.Add_Sitelinks_to_Google_Ads__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Add Sitelinks to Google Ads'+','+ATFollowUp ;
            } 
            if(Trigger.newMap.get(obj.Id).Zipcodes_Received__c != Trigger.OldMap.get(obj.Id).Zipcodes_Received__c && obj.Zipcodes_Received__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Zipcodes Received'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Budgets_Confirmed__c != Trigger.OldMap.get(obj.Id).Budgets_Confirmed__c && obj.Budgets_Confirmed__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Budgets Confirmed'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Budgets_Updated_in_Apollo__c != Trigger.OldMap.get(obj.Id).Budgets_Updated_in_Apollo__c && obj.Budgets_Updated_in_Apollo__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Budgets Updated in Apollo'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Schedule_Kickoff_Call__c != Trigger.OldMap.get(obj.Id).Schedule_Kickoff_Call__c && obj.Schedule_Kickoff_Call__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Schedule Kickoff Call'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Send_Geo_targeting_for_Approval__c != Trigger.OldMap.get(obj.Id).Send_Geo_targeting_for_Approval__c && obj.Send_Geo_targeting_for_Approval__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Send Geo-targeting for Client Approval'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Send_Advertised_Payments_for_Approval__c != Trigger.OldMap.get(obj.Id).Send_Advertised_Payments_for_Approval__c && obj.Send_Advertised_Payments_for_Approval__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Send Ad Payments for Client Approval'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Confirm_Launch_Date_with_Client__c != Trigger.OldMap.get(obj.Id).Confirm_Launch_Date_with_Client__c && obj.Confirm_Launch_Date_with_Client__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Confirm Launch Date with Client'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Verify_Inventory_Pricing__c    != Trigger.OldMap.get(obj.Id).Verify_Inventory_Pricing__c   && obj.Verify_Inventory_Pricing__c  == 'Needs AT Follow Up'){
                ATFollowUp = 'Verify Inventory Pricing'+','+ATFollowUp;
            } 
            //if(Trigger.newMap.get(obj.Id).Inventory_Ordered__c != Trigger.OldMap.get(obj.Id).Inventory_Ordered__c && obj.Inventory_Ordered__c == 'Needs AT Follow Up'){
                     ATFollowUp = 'Inventory Ordered'+','+ATFollowUp;
            //  } 
            if(Trigger.newMap.get(obj.Id).OnboardingPackSent__c != Trigger.OldMap.get(obj.Id).OnboardingPackSent__c && obj.OnboardingPackSent__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Onboarding Pack Sent'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Onboarding_Pack_Received__c != Trigger.OldMap.get(obj.Id).Onboarding_Pack_Received__c && obj.Onboarding_Pack_Received__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Onboarding Pack Received'+','+ATFollowUp;
            }
            if(Trigger.newMap.get(obj.Id).Create_Google_Account__c != Trigger.OldMap.get(obj.Id).Create_Google_Account__c && obj.Create_Google_Account__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Create Google Account'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Create_Bing_Account__c != Trigger.OldMap.get(obj.Id).Create_Bing_Account__c && obj.Create_Bing_Account__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Create Bing Account'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Create_Facebook_Account__c != Trigger.OldMap.get(obj.Id).Create_Facebook_Account__c && obj.Create_Facebook_Account__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Create Facebook Account'+','+ATFollowUp;
            } 
            //if(Trigger.newMap.get(obj.Id).CreditCardAuthSent__c != Trigger.OldMap.get(obj.Id).CreditCardAuthSent__c && obj.CreditCardAuthSent__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Credit Card Auth Sent'+','+ATFollowUp;
              //} 
             //if(Trigger.newMap.get(obj.Id).Credit_Card_Received__c != Trigger.OldMap.get(obj.Id).Credit_Card_Received__c && obj.Credit_Card_Received__c == 'Needs AT Follow Up'){
                  ATFollowUp = 'Credit Card Received'+','+ATFollowUp;
                  //} 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Google__c    != Trigger.OldMap.get(obj.Id).Add_CC_to_Google__c   && obj.Add_CC_to_Google__c  == 'Needs AT Follow Up'){
                ATFollowUp = 'Add CC to Google'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Bing__c != Trigger.OldMap.get(obj.Id).Add_CC_to_Bing__c && obj.Add_CC_to_Bing__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Add CC to Bing'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Add_CC_to_Facebook__c != Trigger.OldMap.get(obj.Id).Add_CC_to_Facebook__c && obj.Add_CC_to_Facebook__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Add CC to Facebook'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_Received__c != Trigger.OldMap.get(obj.Id).Logo_Received__c && obj.Logo_Received__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Logo Received'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_added_to_Compliance_Board__c != Trigger.OldMap.get(obj.Id).Logo_added_to_Compliance_Board__c && obj.Logo_added_to_Compliance_Board__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Logo Added to Compliance Board'+','+ATFollowUp;
            } 
            if(Trigger.newMap.get(obj.Id).Logo_approved_by_Compliance_Team__c != Trigger.OldMap.get(obj.Id).Logo_approved_by_Compliance_Team__c && obj.Logo_approved_by_Compliance_Team__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Logo Approved by Compliance Team'+','+ATFollowUp;
            }
            if(Trigger.newMap.get(obj.Id).Link_GMB_for_Location_Extenstions__c != Trigger.OldMap.get(obj.Id).Link_GMB_for_Location_Extenstions__c && obj.Link_GMB_for_Location_Extenstions__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Link GMB for Location Extenstions'+','+ATFollowUp;
            }
            if(Trigger.newMap.get(obj.Id).Add_to_Measurement_Trix__c != Trigger.OldMap.get(obj.Id).Add_to_Measurement_Trix__c && obj.Add_to_Measurement_Trix__c == 'Needs AT Follow Up'){
                ATFollowUp = 'Add to Measurement Trix'+','+ATFollowUp;
            }
            if(ATFollowUp.right(1) == ','){
                ATFollowUp =  ATFollowUp.removeEnd(',');
            }
            if(followUp.right(1) == ','){
                followUp =  followUp.removeEnd(',');
            }
            if(ATFollowUp.length() > 255){
                obj.AT_Follow_Up__c = ATFollowUp.substring(0,254);
            }
            else {
                obj.AT_Follow_Up__c = ATFollowUp;
            }
            if(followUp.length() > 255){
                obj.Follow_up_fields__c = followUp.substring(0,254);
            }
            else{
                obj.Follow_up_fields__c = followUp;
            }
            
        }
     
    }*/
    
}