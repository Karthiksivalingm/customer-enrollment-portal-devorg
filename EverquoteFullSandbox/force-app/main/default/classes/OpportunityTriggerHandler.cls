/* Class:       OpportunityTriggerHandler
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 */
 
public with sharing class OpportunityTriggerHandler {


	/* Trigger fires on update Opportunity
	 * 1. Enrichment opp only
	 * 2. When opp is Closed Lost/Won
	 * 3. Create new opp with the same information
	 */
	public static void createNewOppWhenClose(){
		List<Opportunity> change_opps = new List<Opportunity>();
        Id enrichmentType = SObjectType.Opportunity.getRecordTypeInfosByName().get('Enrichment').getRecordTypeId();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity change_opp: (Opportunity[])Trigger.new){
            Opportunity oldopp = (Opportunity) Trigger.oldMap.get(change_opp.Id);
            if(change_opp.RecordTypeId == enrichmentType && change_opp.StageName != oldopp.StageName && 
                    (change_opp.StageName == 'Closed Won' || change_opp.Stagename == 'Closed Lost')){
                accountIds.add(change_opp.AccountId);
                change_opps.add(change_opp);
            }
        }

        if(accountIds.isEmpty()) return;

        Map<Id,Opportunity[]> acctOppMap = new Map<Id,Opportunity[]>();
        for(Opportunity opp : [Select Id,AccountId from Opportunity 
                where RecordTypeId =: enrichmentType AND StageName != 'Closed Won' AND Stagename != 'Closed Lost' AND AccountId in :accountIds]){
            if(acctOppMap.get(opp.AccountId) == null){
                acctOppMap.put(opp.AccountId, new List<Opportunity>());
            }

            acctOppMap.get(opp.AccountId).add(opp);
        }


        List<Opportunity> newOpps = new List<Opportunity>();
        // Loop through change events
        for (Opportunity change_opp: change_opps){
            Opportunity[] lstOtherOpps = acctOppMap.get(change_opp.AccountId);

            if(lstOtherOpps != null && lstOtherOpps.size() > 0) continue;
            
            // Create new opp
            Opportunity new_opp = new Opportunity();
            new_opp.Type = change_opp.Type;
            new_opp.Name = change_opp.Name;
            new_opp.LeadSource = change_opp.LeadSource;
            new_opp.RecordTypeId = change_opp.RecordTypeId;
            new_opp.OwnerId = change_opp.OwnerId;
            new_opp.AccountId = change_opp.AccountId;
            new_opp.Estimated_Lift__c = change_opp.Estimated_Lift__c;
            new_opp.Account_in_Extended_Pause__c = change_opp.Account_in_Extended_Pause__c;
            new_opp.Trigger_Ranking__c = change_opp.Trigger_Ranking__c;
            new_opp.Pro_Dunning_Success_Time__c = change_opp.Pro_Dunning_Success_Time__c;
            new_opp.Initial_CC_Failure_Date__c = change_opp.Initial_CC_Failure_Date__c;
            
            new_opp.StageName = 'Inactive';
            new_opp.CloseDate = Date.today().addDays(14);
            new_opp.Notes_from_Last_Opp__c = change_opp.Notes_for_Next_Opp__c;
            newOpps.add(new_opp);
        }
        insert newOpps;
	}

	///**
	// * Marks every other opportunity as Onboarding Treatment when opp is inserted
	// * and has a record type defined in the onboarding settings.
	// */
	//public static void enterOnboardingProcess(){
	//	// gather data
	//	List<Opportunity> triggernew = (Opportunity[]) Trigger.new;
	//	OnboardingSettings__c setting = OnboardingSettings__c.getOrgDefaults();
	//	Boolean onboardnext = setting.Onboard_Next_Opp__c;
	//	Set<Id> rtIds = new Set<Id>();

	//	// get record type ids based on names defined in custom settings
	//	Map<String,Schema.RecordTypeInfo> rtInfoMap = SObjectType.Opportunity.getRecordTypeInfosByName();
	//	if(setting.RecordType__c == null) return;
	//	for(String rt : setting.RecordType__c.split(',')){
	//		rtIds.add(rtInfoMap.get(rt).getRecordTypeId());
	//	}

 //       Set<Id> acctIds = new Set<Id>();
 //       for(Opportunity opp : triggernew){
 //           acctIds.add(opp.AccountId);
 //       }

 //       Map<Id,Account> mapAccount = new Map<Id,Account>([Select Id, Carrier__r.Exclude_from_Onboarding__c,Carrier__c from Account where Id in :acctIds]);

	//	for(Opportunity opp : triggernew){
 //           Account a = mapAccount.get(opp.AccountId);
 //           if(a == null) continue;
 //           if(a.Carrier__c != null && a.Carrier__r.Exclude_from_Onboarding__c) {
 //               continue;
 //           }
	//		if(rtIds.contains(opp.RecordTypeId)){
	//			opp.Onboarding_Treatment__c = onboardnext ? 'Yes' : 'No';
	//			onboardnext = !onboardnext;
	//		}
	//	}

	//	setting.Onboard_Next_Opp__c = onboardnext;
	//	update setting;
	//}

    ///**
    // * when onboarding opp is assigned, use round robin functionality to assign
    // * an onboarding owner based on onboarding type
    // */
    //public static void assignOnboardingOwner(){
    //    List<Opportunity> triggernew = (Opportunity[]) Trigger.new;
    //    List<Opportunity> onboardingOpps = new List<Opportunity>();

    //    Map<Id,Id> ownerToAccountMap = new Map<Id,Id>();
    //    // gather onboarding opps
    //    for(Opportunity opp : triggernew){
    //        if(opp.Onboarding_Treatment__c == 'Yes'){
    //            onboardingOpps.add(opp);
    //            ownerToAccountMap.put(opp.OwnerId,opp.AccountId);
    //        }
    //    }

    //    if(onboardingOpps.isEmpty()) return;

    //    // get rep availability info, separate lists by onboarding type
    //    Customer_Success_Rep__c[] lstCSRs = [Select Id, NextUp__c, Available__c,User__c, Onboarding_Type__c 
    //        from Customer_Success_Rep__c where Available__c=true Order by User__r.LastName];
    //    Map<String,List<Customer_Success_Rep__c>> mapCSRs = new Map<String,List<Customer_Success_Rep__c>>();
    //    Map<String,Integer> mapUpNext = new Map<String,Integer>();
    //    for(Customer_Success_Rep__c csr : lstCSRs){
    //        if(csr.Onboarding_Type__c == null) continue;
    //        if(mapCSRs.get(csr.Onboarding_Type__c) == null){
    //            mapCSRs.put(csr.Onboarding_Type__c,new List<Customer_Success_Rep__c>());
    //        }
    //        mapCSRs.get(csr.Onboarding_Type__c).add(csr);
    //        if(csr.NextUp__c){
    //            mapUpNext.put(csr.Onboarding_Type__c,mapCSRs.get(csr.Onboarding_Type__c).size() - 1);
    //        }
    //    }

    //    if(lstCSRs.isEmpty()) return;

    //    Map<Id,User> mapOwner = new Map<Id,User>([Select Id, Life_Buyer__c from User where Id in :ownerToAccountMap.keyset()]);
    //    Map<Id,Account> mapAccount = new Map<Id,Account>([Select Id, Carrier__r.Exclude_from_Onboarding__c,Carrier__c, Carrier__r.Name 
    //                                                from Account where Id in :ownerToAccountMap.values()]);

    //    // find who is up next by list index
    //    for(String key : mapCSRs.keySet()){
    //        if(!mapUpNext.containsKey(key)){
    //            mapUpNext.put(key,0);
    //        }
    //    }

    //    Map<Id,Account> accountUpdates = new Map<Id,Account>();

    //    // loop through opps and assign
    //    for(Opportunity opp : onboardingOpps){
    //        Account a = mapAccount.get(opp.AccountId);
    //        User u = mapOwner.get(opp.OwnerId);
    //        if(a == null || u == null) continue;

    //        // find onboarding type
    //        String onboardtype = 'IA/Growth';

    //        if(u.Life_Buyer__c){
    //            onboardtype = 'Life Buyer';
    //        }
    //        else if(a.Carrier__c != null && a.Carrier__r.Name.equalsIgnoreCase('Farmers')){
    //            onboardtype = 'Farmers';
    //        }
    //        else if(a.Carrier__c != null && a.Carrier__r.Name.equalsIgnoreCase('Allstate')){
    //            onboardtype = 'Allstate';
    //        }
    //        System.debug('onboardtype: ' + onboardtype);

    //        List<Customer_Success_Rep__c> csrList = mapCSRs.get(onboardtype);
    //        System.debug('csr list:\n' + JSON.serializePretty(csrList));
    //        // get who is up next for this onboarding type
    //        Integer upnext = mapUpNext.get(onboardtype);
    //        if(csrList == null) continue;

    //        System.debug('upnext: ' + upnext);

    //        // assign opp to them
    //        opp.Onboarding_Owner__c = csrList[upnext].User__c;
    //        opp.Customer_Success_Rep__c = csrList[upnext].Id;
    //        // log support rep on account
    //        a.Support_Rep__c = opp.Onboarding_Owner__c;
    //        accountUpdates.put(a.Id,a);
    //        csrList[upnext].NextUp__c = false;

    //        // get who's up next
    //        upnext++;
    //        // set to 0 index if last person in list
    //        upnext = upnext == csrList.size() ? 0 : upnext;
    //        System.debug('new upnext: ' + upnext);
    //        csrList[upnext].NextUp__c = true;
    //        // put updated info back into map
    //        mapCSRs.put(onboardtype,csrList);
    //        mapUpNext.put(onboardtype, upnext);
    //    }

    //    // update new csr availability information
    //    List<Customer_Success_Rep__c> allCSR = new List<Customer_Success_Rep__c>();
    //    for(Customer_Success_Rep__c[] csrs : mapCSRs.values()){
    //        allCSR.addAll(csrs);
    //    }
    //    update allCSR;
    //    update accountUpdates.values();
    //}
}