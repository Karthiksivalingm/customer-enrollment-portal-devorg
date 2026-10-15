/* Class:       OnboardingOwnerAssignmentCtrl
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: 
 */
 
public with sharing class OnboardingOwnerAssignmentCtrl {
    public Customer_Success_Rep__c csr {get; set;}
    public Map<String,List<Customer_Success_Rep__c>> lstCSRs {get; set;}
    public static Boolean isNextUpSet = false;

    // Constructor
    public OnboardingOwnerAssignmentCtrl() {
        csr = new Customer_Success_Rep__c();
        lstCSRs = new Map<String,List<Customer_Success_Rep__c>>(); 
    }

    public PageReference queryLeadRecipients() {        
        getLeadRecipients();
        return null;
    }

    public PageReference onLoad() {
        populateNextUp();  
        populateOpenLeadCount();
        return null;
    }
    
    public PageReference save() {
        try {
            Boolean isNextUpMarked= true;
            for(Customer_Success_Rep__c[] csrs : lstCSRs.values()) {
                for(Customer_Success_Rep__c csr : csrs) {
                    if(csr.Available__c && csr.Onboarding_Type__c == null){
                        throw new OnboardingSetupException('Onboarding Type is required for available CSRs');
                    }
                    if(csr.NextUp__c && !csr.Available__c) {
                        csr.NextUp__c = false;
                        isNextUpMarked = false;
                    }
                    if(!isNextUpMarked && csr.Available__c) {
                        csr.NextUp__c = true;
                        isNextUpMarked = true;
                    }
                }
            }
            for(Customer_Success_Rep__c[] csr : lstCSRs.values()){
                upsert csr;
            }
            populateNextUp();
            return NULL; 
        } 
        catch(Exception e) {
            ApexPages.addMessages(e); 
        }  
        return null;
    }

    public class OnboardingSetupException extends Exception{}
    
    public PageReference add() {    
            
        if(csr.User__c == null || [SELECT Id, User__c FROM Customer_Success_Rep__c WHERE User__c =: csr.User__c].size() != 0) {
            return NULL;
        }
        else {
            try {   
                List<User> lstUser = [Select UserRole.Name,Id FROM User WHERE Id = :csr.User__c];
            
                Customer_Success_Rep__c newRecipient = new Customer_Success_Rep__c(User__c = lstUser[0].Id,                                                                          
                                                                             Available__c = true,
                                                                             NextUp__c = false);
                insert newRecipient;
                populateNextUp();
                return NULL;
            } 
            catch(System.DMLException e) {
                ApexPages.addMessages(e); 
                return null;
            }
        }
    }

    public Map<String,List<Customer_Success_Rep__c>> getLeadRecipients() {
        lstCSRs = new Map<String,List<Customer_Success_Rep__c>>(); 
        List<Customer_Success_Rep__c> csrs = [SELECT c.OpenOpps__c, Available__c, c.User__c, c.User_Role__c, c.NextUp__c, c.Onboarding_Type__c
                FROM Customer_Success_Rep__c c 
                ORDER BY c.Available__c DESC, c.User__r.Lastname ASC LIMIT 5000];
        Set<Id> csrIds = new Set<Id>();
        for(Customer_Success_Rep__c c : csrs){
            String key = c.Onboarding_Type__c == null ? 'Unassigned' : c.Onboarding_Type__c;
            if(lstCSRs.get(key) == null){
                lstCSRs.put(key, new List<Customer_Success_Rep__c>());
            }
            lstCSRs.get(key).add(c);
            csrIds.add(c.User__c);
        }
        User[] lstUsers = [Select Id, FirstName, LastName, UserRole.Name from User where UserRole.Name = 'Customer Support Rep' and IsActive=true and Id not in:csrIds];
        if(!lstUsers.isEmpty()){
            for(User u : lstUsers){
                if(lstCSRs.get('Unassigned') == null){
                    lstCSRs.put('Unassigned', new List<Customer_Success_Rep__c>());
                }
                Customer_Success_Rep__c newcsr = new Customer_Success_Rep__c();
                newcsr.User__c = u.Id;
                newcsr.User__r = u;
                lstCSRs.get('Unassigned').add(newcsr);
            }
        }
        System.debug('csrs\n' + JSON.serializePretty(lstCSRs));
        return lstCSRs;
    } 

    private void populateNextUp() {
        if(isNextUpSet) {
            return;
        }
        Map<String,List<Customer_Success_Rep__c>> allMap = new Map<String,List<Customer_Success_Rep__c>>();
        Map<String,Boolean> nextUpMap = new Map<String,Boolean>();
        Customer_Success_Rep__c[] lst = [Select Id,Onboarding_Type__c, NextUp__c from Customer_Success_Rep__c where Available__c = true and User__r.IsActive = true ORDER BY User__r.LastName ASC];
        for(Customer_Success_Rep__c c : lst){
            String key = c.Onboarding_Type__c == null ? 'Unassigned' : c.Onboarding_Type__c;
            if(key == 'Unassigned') continue;
            if(allMap.get(key) == null){
                allMap.put(key,new List<Customer_Success_Rep__c>());
            }
            allMap.get(key).add(c);
            if(nextUpMap.get(key) == null){
                nextUpMap.put(key,false);
            }
            if(c.NextUp__c){
                nextUpMap.put(key,true);
            }
        }

        List<Customer_Success_Rep__c> changedCSR = new List<Customer_Success_Rep__c>();
        for(String ot : allMap.keySet()){
            if(!nextUpMap.get(ot)){
                allMap.get(ot)[0].NextUp__c = true;
                changedCSR.add(allMap.get(ot)[0]);
            }
        }

        if(!changedCSR.isEmpty()) update changedCSR;

    }
    
    public void populateOpenLeadCount() {
        list<Customer_Success_Rep__c> csrs = [Select Id,OpenOpps__c,(Select Id from Opportunities__r) FROM Customer_Success_Rep__c];
        for(Customer_Success_Rep__c c : csrs) {
            c.OpenOpps__c = c.Opportunities__r.size();
        }
        if(!csrs.isEmpty()) {
            update csrs;
        }
    }
}