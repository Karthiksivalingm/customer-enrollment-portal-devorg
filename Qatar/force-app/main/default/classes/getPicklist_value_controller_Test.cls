@isTest
public class getPicklist_value_controller_Test {

    @isTest
    public static void testPicklistMEthod(){
        
        contact cont = new contact();
        cont.LastName = 'testContct';
        cont.FirstName = 'tfnames';
        cont.BUSINESS__c = 'ACTORS';
        insert cont;
        
        getPicklist_value_controller.getpicklistMapApex();
        getPicklist_value_controller.getpicklistMethodApex();
        getPicklist_value_controller.getProfileInfo();
        getPicklist_value_controller.getSelectedPLValues(cont.id);
        getPicklist_value_controller.savePicklistValues(cont.id, '', '', '', '', '','');
    }
}