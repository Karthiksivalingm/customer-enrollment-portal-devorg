@isTest
private class showmetestclass {
   static testMethod void showme() {
 Test.setMock(HttpCalloutMock.class, new showmemockclass());
       Patient__c pp = new Patient__c();      
          insert pp;
        Account acc = new Account();
        acc.name = 'test';
        insert acc;
        system.debug('pp'+pp);
         uLab_Case__c cc = new uLab_Case__c();
        cc.name='589189';
        cc.Account__c = acc.id;
        cc.Patient_ID__c=pp.id;
        insert cc;       
        uLab_Order__c oo = new uLab_Order__c();
        oo.uLab_Case__c = cc.id;
        oo.test__c='test123';
        insert oo;
        system.debug(cc);
        Test.startTest();
        Showme.getmessagesfromapi(oo.id); 
        Test.stopTest();    
    }
}