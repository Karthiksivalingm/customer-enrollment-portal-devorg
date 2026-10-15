/* Class:       DataFactory
 * Created On:  
 * Created by:  J. Pipkin (OpFocus, Inc)
 * Description: 
 */

@isTest
public class DataFactory {
	
	public static Account buildAccount(String name){
		Account a = new Account();
		a.Name = name;
		return a;
	}

	public static Opportunity buildOpportunity(String name, Id acctId, String recordType){
		Opportunity o = new Opportunity();
		o.Name = name;
		o.AccountId = acctId;
		o.RecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		o.CloseDate = System.today().addMonths(1);
		o.StageName = 'Open';
		o.LeadSource = 'Outbound Call';
		return o;
	}

	public static OnboardingSettings__c setOnboardingDefaults(){
		OnboardingSettings__c s = OnboardingSettings__c.getOrgDefaults();
		s.RecordType__c = 'Agency';
		upsert s;
		return s;
	}
	
}