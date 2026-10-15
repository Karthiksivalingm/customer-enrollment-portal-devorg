@isTest
private class Schedule_Birthday_Event_Test {
    static testmethod void test() {
        // Create test accounts to be updated by batch
    List<Contact> conlist = new List<Contact>();
    List<Contact> updateconlist = new List<Contact>();
        
    for (Integer i=0;i<5;i++) {
        date bds = system.today();
        
        contact cont = new contact();
        cont.LastName = 'test'+i;
        cont.FirstName = 'tfnames';
        cont.Birthdate = bds.addMonths(1);
        if(i==3){
                //cont.Company__c = 'abc pvt ltd';
        }else if(i==4){
        		cont.Company__c = 'dts ltd';
            }else{
                cont.Company__c = 'abc pvt ltd';
        }
        cont.OtherStreet = 'a13 ratnam hights';
   		cont.MailingStreet = 'c42 kana hights';
        conlist.add(cont);
    }
    insert conlist;
 	
        for(contact ct: conlist){
            
            if(ct.Company__c == 'dts ltd'){
                ct.Company__c = null;
            }else{
                ct.Company__c = 'datatvs ptl';
            }
        }
        update conlist;
        
        Test.startTest();
        Schedule_Birthday_Event b = new Schedule_Birthday_Event();
        b.execute(null);
        //Database.executeBatch(b);
        Test.stopTest();
        // Verify accounts updated
    //Account[] accUpdatedList = [SELECT Id, Name FROM Account];
    //System.assert(accUpdatedList[0].Name.Contains('sfdcpoint'));
    }
}