/* Class:       OnboardingOwnerAssignmentCtrlTest
 * Created On:  Feb 2018
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: 
 */

@isTest
public class OnboardingOwnerAssignmentCtrlTest {
	
	static testMethod void positive() {
      	OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl(); 
      	System.assertEquals(null,ctrl.add());

      	ctrl.onLoad();
      	ctrl.queryLeadRecipients();
      	ctrl.save();
      	ctrl.queryLeadRecipients();
      	ctrl.populateOpenLeadCount();

      	Integer csrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  csrsize += csrs.size();
            }
      	System.assertEquals(csrsize,[Select count() from User where IsActive = true and UserRole.Name = 'Customer Support Rep']);
      	Customer_Success_Rep__c[] lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];
      	Boolean isFirst = true;
      	for(Customer_Success_Rep__c csr : lstreps){
      		System.assertEquals(false, csr.Available__c);
  			System.assertEquals(false, csr.NextUp__c);
      	}
      	
            String[] types = new String[]{'Other','Life Buyer','Farmers'};
            Integer ti = 0;
      	for(Customer_Success_Rep__c csr : ctrl.lstCSRs.get('Unassigned')){
      		csr.Available__c = true;
                  csr.Onboarding_Type__c = types[ti];
                  ti++;
                  if(ti == types.size()) ti = 0;
      	}
      	ctrl.save();

      	lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];

      	User newrep = [Select Id from User where IsActive=true and UserRole.Name != 'Customer Support Rep' LIMIT 1];
      	ctrl.csr.User__c = newrep.Id;

      	ctrl.add();
      	ctrl.queryLeadRecipients();

            Integer newcsrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  newcsrsize += csrs.size();
            }
      	System.assertEquals(csrsize + 1, newcsrsize);

      	ctrl.populateOpenLeadCount();

    }

    static testMethod void missingOnboardingType() {
            OnboardingOwnerAssignmentCtrl ctrl = new OnboardingOwnerAssignmentCtrl(); 
            System.assertEquals(null,ctrl.add());

            ctrl.onLoad();
            ctrl.queryLeadRecipients();
            ctrl.save();
            ctrl.queryLeadRecipients();
            ctrl.populateOpenLeadCount();

            Integer csrsize = 0;
            for(Customer_Success_Rep__c[] csrs : ctrl.lstCSRs.values()){
                  csrsize += csrs.size();
            }
            System.assertEquals(csrsize,[Select count() from User where IsActive = true and UserRole.Name = 'Customer Support Rep']);
            Customer_Success_Rep__c[] lstreps = [Select Id, Available__c, OpenOpps__c, NextUp__c from Customer_Success_Rep__c Order by User__r.LastName];
            Boolean isFirst = true;
            for(Customer_Success_Rep__c csr : lstreps){
                  System.assertEquals(false, csr.Available__c);
                  System.assertEquals(false, csr.NextUp__c);
            }
            
            for(Customer_Success_Rep__c csr : ctrl.lstCSRs.get('Unassigned')){
                  csr.Available__c = true;
            }
            ctrl.save();
            System.assert(ApexPages.hasMEssages());
            String err = ApexPages.getMessages()[0].getSummary();
            System.assert(err.containsIgnoreCase('Onboarding Type is required'));
    }
    
	
}