@isTest(SeeAllData=true)
public class OpportunityLineItemTriggerTest {
    static testMethod void testOpportunityLineItemTrigger()
    {

        List<OpportunityLineItem> olis = [SELECT Id, PricebookEntryId, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = '0064z00002BsuUiAAJ'];

        OpportunityLineItem newoli = new OpportunityLineItem(
            OpportunityId = olis[0].OpportunityId,
            PricebookEntryId = olis[0].PricebookEntryId,
            Quantity = 1,
            UnitPrice = 500
        );
        insert newoli;

        olis[0].UnitPrice = 600;
        olis[1].UnitPrice = 600;
        olis[2].UnitPrice = 600;
        olis[3].UnitPrice = 600;
        update olis;

        delete olis;
    }
}
