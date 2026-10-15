@isTest
public class SchduledAccountNpnTest {
     @isTest static void NiprContacthttpclass(){
        
         Account acc = new Account();
         acc.name = 'Test';
         acc.NPN_Number__c = '21174118';
         acc.NIPR_LastUpdated_Date__c = Date.today()-9;
        // acc.Is_Updated__c = True;
         insert acc;
         
         Set<String> npnNum = new Set<String>();
         npnNum.add(acc.NPN_Number__c);
         
         Test.startTest();
         
      Test.setMock(HttpCalloutMock.class, new NiprNPNHttp());
       
      ScheduledAccountNpnUpdate ba= new ScheduledAccountNpnUpdate(npnNum);
        Id jobid= Database.executeBatch(ba,5);  
         
        Test.stopTest(); 
        
     }
}