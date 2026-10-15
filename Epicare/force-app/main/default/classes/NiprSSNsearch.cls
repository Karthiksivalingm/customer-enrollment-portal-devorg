public class NiprSSNsearch {
    @AuraEnabled
    public static void initiateSSNSearch(Id contactId) {
        // Just call the future method here
        ssnSearch(contactId);
    }
    @auraEnabled
    @future(Callout=True)
    public static void ssnSearch(Id Ide){
        String transactionType; 
        if(TriggerHandler.isFirstTime){
            
        TriggerHandler.isFirstTime=False;
            
        Contact ssnNum = [Select id,lastName,SSN_Number__c from Contact where id=:Ide];
   
        String username = label.Nipr_username;
        String password = label.Nipr_password;
        String lastname = ssnNum.lastName.replace( ' ', '%20' );   
        Contact con = new Contact();
        con.id = Ide;
        system.debug(ssnNum.SSN_Number__c);
        Http H1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint(label.SSN_URL+lastname+'&ssn='+ssnNum.SSN_Number__c);
        Blob headerValue = Blob.valueOf(label.Nipr_username + ':' + label.Nipr_password);
    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        system.debug(authorizationHeader);
        req1.setHeader('Authorization', authorizationHeader);
        req1.setMethod('GET');        
        HttpResponse res1=h1.send(req1);
        string response = res1.getbody();  
            system.debug(req1);
        system.debug(response);
            
        DOM.Document doc = res1.getBodyDocument();
        
        for(Dom.XmlNode fluxNode: doc.getRootElement().getChildElements()) {   
            string currentnode = fluxNode.getname();
      system.debug(currentNode);
      transactionType = currentNode;
    if(fluxNode.getName() == 'INDIVIDUAL') {
     con.NPN__c= fluxNode.getChildElement('NPN',null).getText();
      //  Database.Update (con,false);
     NiprNPNFutureCallout.npnSearch(Ide,fluxNode.getChildElement('NPN',null).getText());  
   
    }
}
     system.debug(con);    
    }
    }
}