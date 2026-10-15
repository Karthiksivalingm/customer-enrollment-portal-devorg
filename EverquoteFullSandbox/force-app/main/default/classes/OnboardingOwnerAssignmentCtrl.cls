/*
/* Class:       OnboardingOwnerAssignmentCtrl
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: 
 */
 /*
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

*/

/**********************************
Class Name    : OnboardingOwnerAssignmentCtrl
Description     : Visualforce controller for managing Customer Success Rep onboarding assignment -
                   availability, next-up rotation, and onboarding-type grouping.
VERSION          DATE                   AUTHOR                DETAIL
---------------------------------------------------------------------------------------------------------
1.0                                                            Original implementation (see commented-out
                                                                block above).
1.1              (refactor)                                    Status of each flagged finding:
                                                                 - "SOQL query inside a for/while loop" -
                                                                   NOT PRESENT. Every SOQL query in this
                                                                   class (add, getLeadRecipients,
                                                                   populateNextUp, populateOpenLeadCount)
                                                                   runs once, outside any loop. No change
                                                                   needed/made for this finding.
                                                                 - "DML statement inside a for/while loop" -
                                                                   CONFIRMED AND FIXED. save() previously had
                                                                   `upsert csr;` inside
                                                                   `for(... : lstCSRs.values())` - firing one
                                                                   upsert per distinct Onboarding_Type group
                                                                   instead of a single bulk upsert. Fixed by
                                                                   flattening all groups into one List before
                                                                   the loop and issuing a single upsert after
                                                                   it exits.
                                                                 - "API version critically outdated (v40)" -
                                                                   FIXED. apiVersion updated to 60.0 in the
                                                                   accompanying .cls-meta.xml.
                                                                Additional fix (not in the original finding
                                                                list, but directly responsible for the
                                                                NullPointerExceptions seen in
                                                                OnboardingOwnerAssignmentCtrlTest.positive and
                                                                .missingOnboardingType):
                                                                 - getLeadRecipients() only added an
                                                                   'Unassigned' key to lstCSRs if it found at
                                                                   least one qualifying record. Any caller
                                                                   (this controller's own test, or the VF page
                                                                   itself) that reads lstCSRs.get('Unassigned')
                                                                   unconditionally would NPE whenever no
                                                                   unassigned CSR/User existed. Fixed by always
                                                                   pre-seeding an empty 'Unassigned' list, so
                                                                   the key is always present.
                                                                All public method signatures/properties are
                                                                unchanged, so OnboardingOwnerAssignmentCtrlTest
                                                                continues to work.
1.2              2026-09-01                                    getLeadRecipients()'s main query did not
                                                                select User__r.UserRole.Name, but the VF page
                                                                renders {!lr.User__r.UserRole.Name} whenever a
                                                                record's User_Role__c is blank - throwing
                                                                "SObject row was retrieved via SOQL without
                                                                querying the requested field" for any real CSR
                                                                record hitting that path (only the synthetic
                                                                'Unassigned' records built by hand in this
                                                                method had User__r populated). Added
                                                                User__r.UserRole.Name to the SELECT list.
***********************************/
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
            Boolean isNextUpMarked = true;
            for (Customer_Success_Rep__c[] csrs : lstCSRs.values()) {
                for (Customer_Success_Rep__c csr : csrs) {
                    if (csr.Available__c && csr.Onboarding_Type__c == null) {
                        throw new OnboardingSetupException('Onboarding Type is required for available CSRs');
                    }
                    if (csr.NextUp__c && !csr.Available__c) {
                        csr.NextUp__c = false;
                        isNextUpMarked = false;
                    }
                    if (!isNextUpMarked && csr.Available__c) {
                        csr.NextUp__c = true;
                        isNextUpMarked = true;
                    }
                }
            }

            // Flatten every Onboarding_Type group into a single list BEFORE the DML call, so this
            // is one bulk upsert for the whole page instead of one upsert per group (see 1.1 note).
            List<Customer_Success_Rep__c> allCSRsToSave = new List<Customer_Success_Rep__c>();
            for (Customer_Success_Rep__c[] csrs : lstCSRs.values()) {
                allCSRsToSave.addAll(csrs);
            }
            if (!allCSRsToSave.isEmpty()) {
                upsert allCSRsToSave;
            }

            populateNextUp();
            return null;
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
        return null;
    }

    public class OnboardingSetupException extends Exception {
    }

    public PageReference add() {

        if (csr.User__c == null || [SELECT Id, User__c FROM Customer_Success_Rep__c WHERE User__c =: csr.User__c].size() != 0) {
            return null;
        } else {
            try {
                List<User> lstUser = [SELECT UserRole.Name, Id FROM User WHERE Id = :csr.User__c];

                Customer_Success_Rep__c newRecipient = new Customer_Success_Rep__c(
                    User__c = lstUser[0].Id,
                    Available__c = true,
                    NextUp__c = false
                );
                insert newRecipient;
                populateNextUp();
                return null;
            } catch (System.DMLException e) {
                ApexPages.addMessages(e);
                return null;
            }
        }
    }

    public Map<String,List<Customer_Success_Rep__c>> getLeadRecipients() {
        lstCSRs = new Map<String,List<Customer_Success_Rep__c>>();
        // Always guarantee an 'Unassigned' entry exists, even if empty - previously this key was
        // only added conditionally below, so any caller reading lstCSRs.get('Unassigned')
        // unconditionally (including this controller's own test) could NPE when no qualifying
        // record existed.
        lstCSRs.put('Unassigned', new List<Customer_Success_Rep__c>());

        List<Customer_Success_Rep__c> csrs = [
            SELECT c.OpenOpps__c, Available__c, c.User__c, c.User_Role__c, c.NextUp__c, c.Onboarding_Type__c,
                c.User__r.UserRole.Name
            FROM Customer_Success_Rep__c c
            ORDER BY c.Available__c DESC, c.User__r.Lastname ASC
            LIMIT 5000
        ];
        Set<Id> csrIds = new Set<Id>();
        for (Customer_Success_Rep__c c : csrs) {
            String key = c.Onboarding_Type__c == null ? 'Unassigned' : c.Onboarding_Type__c;
            if (lstCSRs.get(key) == null) {
                lstCSRs.put(key, new List<Customer_Success_Rep__c>());
            }
            lstCSRs.get(key).add(c);
            csrIds.add(c.User__c);
        }

        User[] lstUsers = [
            SELECT Id, FirstName, LastName, UserRole.Name
            FROM User
            WHERE UserRole.Name = 'Customer Support Rep' AND IsActive = true AND Id NOT IN :csrIds
        ];
        if (!lstUsers.isEmpty()) {
            for (User u : lstUsers) {
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
        if (isNextUpSet) {
            return;
        }
        Map<String,List<Customer_Success_Rep__c>> allMap = new Map<String,List<Customer_Success_Rep__c>>();
        Map<String,Boolean> nextUpMap = new Map<String,Boolean>();
        Customer_Success_Rep__c[] lst = [
            SELECT Id, Onboarding_Type__c, NextUp__c
            FROM Customer_Success_Rep__c
            WHERE Available__c = true AND User__r.IsActive = true
            ORDER BY User__r.LastName ASC
        ];
        for (Customer_Success_Rep__c c : lst) {
            String key = c.Onboarding_Type__c == null ? 'Unassigned' : c.Onboarding_Type__c;
            if (key == 'Unassigned') {
                continue;
            }
            if (allMap.get(key) == null) {
                allMap.put(key, new List<Customer_Success_Rep__c>());
            }
            allMap.get(key).add(c);
            if (nextUpMap.get(key) == null) {
                nextUpMap.put(key, false);
            }
            if (c.NextUp__c) {
                nextUpMap.put(key, true);
            }
        }

        List<Customer_Success_Rep__c> changedCSR = new List<Customer_Success_Rep__c>();
        for (String ot : allMap.keySet()) {
            if (!nextUpMap.get(ot)) {
                allMap.get(ot)[0].NextUp__c = true;
                changedCSR.add(allMap.get(ot)[0]);
            }
        }

        if (!changedCSR.isEmpty()) {
            update changedCSR;
        }
    }

    public void populateOpenLeadCount() {
        List<Customer_Success_Rep__c> csrs = [
            SELECT Id, OpenOpps__c, (SELECT Id FROM Opportunities__r)
            FROM Customer_Success_Rep__c
        ];
        for (Customer_Success_Rep__c c : csrs) {
            c.OpenOpps__c = c.Opportunities__r.size();
        }
        if (!csrs.isEmpty()) {
            update csrs;
        }
    }
}