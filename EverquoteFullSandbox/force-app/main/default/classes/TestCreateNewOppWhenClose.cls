@isTest
public class TestCreateNewOppWhenClose {
	static testMethod void closeOpp(){
        Account dummy_acc = new Account();
        dummy_acc.Name = 'dummy';
        insert dummy_acc;
        
        List<Account> accs = [SELECT Id FROM Account WHERE Name = 'dummy'];
        String dummy_acc_id = accs[0].Id;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'dummy';
        opp.RecordTypeId = '0121a000000RNO1AAO';
        opp.LeadSource = 'Outbound Call';
        opp.AccountId = dummy_acc_id;
        opp.StageName = 'Open';
        opp.CloseDate = Date.today();
        insert opp;
        
        opp.StageName = 'Closed Won';
        opp.Notes_for_Next_Opp__c = 'Done';
        opp.NextStep = 'Done';
        update opp;
    }
}