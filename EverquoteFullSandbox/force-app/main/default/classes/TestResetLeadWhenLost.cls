@isTest
public class TestResetLeadWhenLost {
    static testMethod void test(){
        Lead dummy_lead = new Lead();
        dummy_lead.LastName = 'dummy';
        dummy_lead.Company = 'dummy';
        insert dummy_lead;
        
        dummy_lead.Status = 'Lost';
        update dummy_lead;
    }
}