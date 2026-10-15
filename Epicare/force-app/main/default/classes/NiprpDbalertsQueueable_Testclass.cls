@istest
public class NiprpDbalertsQueueable_Testclass {
    
       @isTest static void Niprpdbhttpclass(){
           
            Account acc = new Account();
         acc.name = 'Test';
         acc.NPN_Number__c = '21174118';
         acc.NIPR_LastUpdated_Date__c = Date.today()-9;
         insert acc;
           
           acc.name='test123';
           update acc;
           
            Contact con = new Contact();
         con.lastname = 'NPN test';
         con.NPN__c = '21174118';
         Insert con;                 
              Test.startTest();
           Test.setMock(HttpCalloutMock.class, new NiprpdbNPNHttp());
                system.enqueueJob(new NiprpDbalertsQueueable()); 
           ScheduledBatchableNiprpDbalertsHelper myClass = new ScheduledBatchableNiprpDbalertsHelper ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, myClass);
              Test.stopTest(); 
           
           contact con1 =[select id from contact where id=:con.id];
           delete con1;
           
            Account Acc1 =[select id from Account where id=:acc.id];
           delete Acc1;
       }

}