@istest
public class NiprSSNtest {
   
     @isTest static void NiprContacthttpclass(){
                     
        Contact con = new Contact();
         con.lastname = 'Sessa';
         con.SSN__c = '91545622';
         database.Insert(con,false);
         
         Test.startTest();
         
        Test.setMock(HttpCalloutMock.class, new NiprSSNHttp());
        NiprSSNsearch.ssnSearch(con.id); 
         
        Test.stopTest(); 
        
     }
}