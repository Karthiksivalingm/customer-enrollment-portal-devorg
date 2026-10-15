@istest
public class NiprNPNTest {
   
     @isTest static void NiprContacthttpclass(){
         String gsRecordTypeID = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Director').getRecordTypeId();

          Contact con = new Contact();
         con.lastname = 'NPN test';
         con.NPN__c = '1016381';
         con.email ='test123@gmail.com';
         con.RecordTypeId=gsRecordTypeID;
         Insert con;
         
        
         Account acc = new Account();
         acc.name = 'Test';
         acc.NPN_Number__c = '1016381';
       //  acc.NIPR_LastUpdated_Date__c = Date.today()-9;
         acc.Agency_Director__c=con.id;
         insert acc;
         
                 
         Doi__c Doi = new Doi__c();
         Doi.Name = 'Test Doi';
         Doi.Account__c= acc.id;
         Doi.Contact__c = con.id;
         insert Doi;
         
         Test.startTest();
         
      Test.setMock(HttpCalloutMock.class, new NiprNPNHttp());
        NiprNPNsearch.npnSearch(con.id,con.NPN__c);
        Test.stopTest(); 
        
     }
}