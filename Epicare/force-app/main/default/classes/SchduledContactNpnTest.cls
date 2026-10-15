@isTest
public class SchduledContactNpnTest {
     @isTest static void NiprContacthttpclass(){
        system.debug('Test');
         Contact con = new Contact();
         con.lastname = 'Test';
         con.NPN__c = '17595388';
         con.NIPR_LastUpdated_Date__c = Date.today()-9;
         con.IsUpdated__c = True;
         insert con;
         
         Set<String> npnNum = new Set<String>();
         npnNum.add(con.NPN__c);
         Test.startTest();
         
      Test.setMock(HttpCalloutMock.class, new NiprNPNHttp());
       
      ScheduledContactNpnUpdate ba= new ScheduledContactNpnUpdate(npnNum);
        Id jobid= Database.executeBatch(ba,10);  
         
        Test.stopTest(); 
        
     }
}