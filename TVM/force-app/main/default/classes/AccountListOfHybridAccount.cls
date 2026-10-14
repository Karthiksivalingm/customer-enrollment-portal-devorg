public class AccountListOfHybridAccount {
    
    @AuraEnabled
    public static List <Account> fetchAccount() {
        String excludeAcc = Label.Exclude_account;
        string[] splitVal = excludeAcc.split(',');
        list<string> accName = new list<String>();
        for(String str : splitVal){
         accName.add(str);   
        }
        List<String> filterForType = new List<String>{'Dealer Group','NCM','Business Intelligence'};
        return [SELECT Id, Name, Type__c,Health_Flag__c,Health_flag_color__c,Current_Month_Budget__c,New_Month_Budget__c,All_Opportunities__c, 
               FNDN_Billed_Through_TVM__c FROM Account 
               Where 
               FNDN_Billed_Through_TVM__c = True 
               AND 	 
               ((Active__c = TRUE AND Type__c INCLUDES('Digital Advertising') AND Name NOT IN :accName AND Exclude_for_Media_Budget_Email__c = FALSE) 
               OR 
               (Active__c = TRUE AND Name NOT IN :accName AND Hybrid_TVM_Executed_Strategy__c = true))
                Order By 
               createdDate DESC];
    }
    
    @AuraEnabled
    public static String listofEmailTemplates(String emailTempName, String accIds, String roleType) {       
        system.debug('Temp before >>> '+ emailTempName +' ACC ID > '+accIds); 
        List<Account> accList = new List<Account>();
        //List<Contact> conList = new List<Contact>();
        String retrnMessage;
        List<String> contactRoleType = new List<String>();
        system.debug('Role Type >>> '+ roleType);
        if(roleType == 'Media Decision Maker'){
            contactRoleType.add('Foundation Media Budget');
        }else if(roleType == 'Primary/Secondray') {
            contactRoleType.add('Foundation Primary');
            contactRoleType.add('Foundation Secondary');
        }else if(roleType == 'All Contacts'){
            contactRoleType.add('All');
        }
        
        
        
        Type idArrType = Type.forName('List<string>');
        List<string> wrapperList = new  List<string> ();
        if(!test.isRunningTest()){
            wrapperList = (List<string>) JSON.deserialize(accIds, idArrType);
        }
        else{
            String accId = accIds;
            wrapperList.add(accId);
        }
        
        EmailTemplate  tempList = [Select Id,Name from EmailTemplate  where Name =: emailTempName];
        system.debug('Temp after Query >>> '+ tempList+'wraplist >>'+wrapperList); 
       
        if(contactRoleType.contains('All')){
            accList = [SELECT Id, (SELECT ID, Name, Email, Contact_Role__c FROM Contacts) FROM Account WHERE Id IN:wrapperList];    
        }
        else if(contactRoleType.contains('Foundation Media Budget')){
         accList = [SELECT Id, (SELECT ID, Name, Email, Contact_Role__c FROM Contacts Where Contact_Role__c includes ('Foundation Media Budget')) FROM Account WHERE Id IN:wrapperList];    
        }
        else{
        accList = [SELECT Id, (SELECT ID, Name, Email, Contact_Role__c FROM Contacts Where Contact_Role__c includes ('Foundation Primary','Foundation Secondary')) FROM Account WHERE Id IN:wrapperList];    
        }
        
      /*  else{
            accList = [SELECT Id, (SELECT ContactID,Contact.Name,Contact.Email,Roles FROM AccountContactRelations Where Roles =:contactRoleType) FROM Account WHERE Id IN:wrapperList];    
        }*/
        system.debug('account query >> '+accList);
        List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();

        Set<String> supportTemplates = new Set<String>{
            'New Month Media Budgets Updated',
            'New Month Media Budgets Updated Boost Funds Ending 1000',
            'New Month Media Budgets Updated Boost Funds Ending 2500'
        };

        String oweaAddress = supportTemplates.contains(emailTempName)
            ? 'support@info.foundationdirect.com'
            : 'pleto@foundationdirect.com';

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :oweaAddress];

        
        for(Account acc:accList){
            for(Contact con: acc.Contacts){
                try{
                    String[] toAddress = new String[] {con.Email};
                    String[] bccAddress = new String[] {'Budgets@foundationdirect.com'};
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTemplateId(tempList.Id);
                    mail.saveAsActivity = false;
                    mail.setTargetObjectId(con.Id);// Any contact or User id of your record
                    mail.setToAddresses(toAddress);
                    mail.setBccAddresses(bccAddress) ;
                    mail.setWhatId(acc.ID); // Enter your record Id whose merge field you want to add in template
                    //mail.setSenderDisplayName('Foundation Direct Support');
                    //mail.setReplyTo('support@info.foundationdirect.com');
                    if (owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }                    
                    mail.setTreatTargetObjectAsRecipient(false); // set this to stop sending email to target object id(contact ID).
                    mailsToSend.add(mail);
                    System.debug('email body >>>> ');
                }catch(exception e){
                    retrnMessage = 'Exception Occured...';
                }
            }//Contact for loop
        }//Account for loop
        //Send Email
        if(mailsToSend.size() > 0){
            Messaging.sendEmail(mailsToSend);
            retrnMessage = 'Success';
        }
       
        return retrnMessage;     
    }
   @AuraEnabled
    public static list<Contact> getContactRelation( String accIds, String roleType){
        system.debug(' ACC ID > '+accIds); 
        List<Contact> ConRelationList = new List<Contact>();
        //List<Contact> conList = new List<Contact>();
        String retrnMessage;
        List<String> contactRoleType = new List<String>();
        system.debug('Role Type >>> '+ roleType);
        if(roleType == 'Media Decision Maker'){
            contactRoleType.add('Foundation Media Budget');
        }else if(roleType == 'Primary/Secondray') {
            contactRoleType.add('Foundation Primary');
            contactRoleType.add('Foundation Secondary');
        }else if(roleType == 'All Contacts'){
            contactRoleType.add('All');
        }
        
        
        
        Type idArrType = Type.forName('List<string>');
        List<string> wrapperList = new  List<string> ();
        if(!test.isRunningTest()){
            wrapperList = (List<string>) JSON.deserialize(accIds, idArrType);
        }
        else{
            String accId = accIds;
            wrapperList.add(accId);
        }
        
       
        if(contactRoleType.contains('All')){
            ConRelationList = [SELECT ID, Name, Email, Contact_Role__c FROM Contact WHERE AccountId IN:wrapperList order by Name];    
        }
        else if(contactRoleType.contains('Foundation Media Budget')){
            ConRelationList = [SELECT ID, Name, Email, Contact_Role__c FROM Contact Where Contact_Role__c includes ('Foundation Media Budget') and AccountId IN:wrapperList order by Name];    
        }
        else{
            ConRelationList = [SELECT ID, Name, Email, Contact_Role__c FROM Contact Where Contact_Role__c includes ('Foundation Primary','Foundation Secondary') and AccountId IN:wrapperList order by Name];    
        }
        system.debug('account query >> '+ConRelationList);
         return ConRelationList;
    }
}