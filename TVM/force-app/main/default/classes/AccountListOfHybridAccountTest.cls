@isTest
public class AccountListOfHybridAccountTest {
     private static String uniqueSuffix() {        
        //Long ts = Datetime.now().getTime();
        Integer rnd = Math.abs(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        //return ts + '_' + String.valueOf(rnd);
        return String.valueOf(rnd);
    }
    @isTest
    public static void test(){
        String suf = uniqueSuffix();
        Account acc = new Account();
        acc.Name = 'testacc2';
        acc.Active__c = true;
        acc.Type = 'Dealer Group';
        acc.Quickbase_Record_ID__c = suf;
        insert acc;
        Contact con = new Contact();
        con.LastName = 'test1';
        con.Email ='test1@gmail.com';
       con.AccountId = acc.id;
        insert con;
         Account accRecord2=new account();
        accRecord2.Name='Test Acc3';
         acc.Quickbase_Record_ID__c = suf + 1;
        insert accRecord2;
        AccountContactRelation  accCon = new AccountContactRelation ();
        accCon.AccountId = accRecord2.id;
        accCon.ContactId = con.Id;
        accCon.Roles = 'All';
       
        insert accCon;
        String accId = acc.Id;
        AccountListOfHybridAccount.fetchAccount();
       // accountListToSendEmail.listofEmailTemplates('SAMPLE: New Account Manager',accId,'Media Decision Maker');
        AccountListOfHybridAccount.listofEmailTemplates('SAMPLE: New Account Manager',accId,'All Contacts');
        AccountListOfHybridAccount.getContactRelation(accId,'All Contacts');
        AccountListOfHybridAccount.getContactRelation(accId,'All');
       
    }

    
}