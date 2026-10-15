public class NiprpDbalertsQueueable implements Queueable, Database.AllowsCallouts {
    
    public void execute(QueueableContext context) {
        
        Blob headerValue = Blob.valueOf(label.Nipr_username + ':' + label.Nipr_password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        set<string> npnslist = new set<string>();
        date d =system.today();
        String reportDate = string.valueof(date.valueof(d));
        String day;
        String month;
       
        Integer dd = Date.Today().Day();
        Integer m = Date.Today().Month();
        Integer year = Date.Today().Year();

        if(m < 10){
           month =  '0'+ m;
        }else{
          month = String.valueOf(m);  
        }
        if( dd < 10){
           day =  '0'+ d;
        }else{
          day = String.valueOf(d);  
        }
        
        system.debug(year+'-'+month+'-'+day);
        system.debug(reportDate);
        system.debug(reportDate);
        String soapRequest = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:ind="https://pdb-services.nipr.com/pdb-alerts-industry-services/industry-ws">' +
            '<soapenv:Header/>' +
            '<soapenv:Body>' +
            '<ind:receiveSpecificReport>' +
            '<ind:reportDate>'+year+'-'+month+'-'+day+'</ind:reportDate>' +
            '</ind:receiveSpecificReport>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
        
        Http h1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setBody(soapRequest);
        req1.setHeader('Authorization', authorizationHeader);
        req1.setMethod('POST');
        req1.setEndpoint(label.pdb_alerts_Url);
        system.debug(label.pdb_alerts_Url);
        try{
        HttpResponse res1 = h1.send(req1);
        String xmlResponse = res1.getBody();
        system.debug(xmlResponse);
        xmlResponse= extractLicensingReport(xmlResponse);
        system.debug(xmlResponse);
        // Create a new DOM Document
        Dom.Document doc = new Dom.Document();
        doc.load(xmlResponse);
        
        // Get the root element
        for (Dom.XmlNode PdbNode: doc.getRootElement().getChildElements()){
            // system.debug(PdbNode.getName());
            String CurrentNode =PdbNode.getName();
            if (CurrentNode == 'LicensingReport') {
                for (Dom.XmlNode TypeNode: PdbNode.getChildElements()){
                    String CurrentNode1 =TypeNode.getName();
                    //system.debug(TypeNode.getName());
                    if(CurrentNode1=='Organization'){
                        for (Dom.XmlNode personNode: TypeNode.getChildElements()){
                             string type;
                            if(personNode.getName()=='ExternalIdentifier'){
                                for (Dom.XmlNode Externalnode: personNode.getChildElements()){
                                    //system.debug('Externalnode'+Externalnode.getName());
                                   
                                    if(Externalnode.getName()=='TypeCode'){
                                        type =Externalnode.gettext();
                                    }
                                    if(type=='NAICProducerCode'){  
                                        system.debug(Externalnode.getName());
                                       if(Externalnode.getName()=='Id'){
                                            system.debug('testId');
                                            npnslist.add(Externalnode.gettext());
                                        }                             
                                    }
                                }
                            }
                            
                        }                        
                    }                  
                    if(CurrentNode1=='Person'){
                        for (Dom.XmlNode personNode: TypeNode.getChildElements()){
                            // system.debug(personNode.getName());
                            string type;
                            //system.debug(personNode.getName());
                            String CurrentNode2 =personNode.getName();
                            if(CurrentNode2=='ExternalIdentifier'){
                                for (Dom.XmlNode Externalnode: personNode.getChildElements()){
                                    
                                    //system.debug(Externalnode.getName());
                                    if(Externalnode.getName()=='TypeCode'){
                                        type =Externalnode.gettext();
                                        //system.debug(Externalnode.gettext()); 
                                    }
                                    if(type=='NAICProducerCode'){
                                        if(Externalnode.getName()=='Id'){ 
                                            //  system.debug(Externalnode.gettext());
                                             npnslist.add(Externalnode.gettext()); 
                                        }
                                    }
                                } 
                                
                            }
                            
                        }
                        
                    }
                }
                
            }
        }
        }
        
        Catch(Exception e){
          
        }
        
        
        system.debug('npnslist'+npnslist) ;
        system.debug('npnslist'+npnslist.size()) ;
        System.debug(JSON.serialize(npnslist));
        
       list<contact> conlist = [Select Id,NPN__c from Contact where NPN__c in: npnslist];
          list<string> conids = new  list<string>();
            for (Contact NpnCon: conlist) {
                conids.add(NpnCon.id);
            }
     List < DOI__c > DOI2Update1 = [Select id, Name__c, License_Calss_Code__c, State__c from DOI__c where Contact__c in :conids];
        if(!DOI2Update1.isempty()){
            delete DOI2Update1;
        }
        list<account> Acclist = [Select Id,NPN_Number__c from account where NPN_Number__c in :npnslist];
          list<string> Accids = new  list<string>();
        for (Account NpnAcc: Acclist) {
            Accids.add(NpnAcc.id);            
        }
    list<DOI__c> lstDoiUpdate1 = [Select id, Name__c, License_Calss_Code__c, state__c from DOI__c where Account__c  in:Accids];
       if(!lstDoiUpdate1.isempty()){
           delete lstDoiUpdate1;
       }
        if(!npnslist.isempty()){
       Database.executeBatch(new ScheduledAccountNpnUpdate(npnslist),99);
       Database.executeBatch(new ScheduledContactNpnUpdate(npnslist),99);
        }
    }
    public static String extractLicensingReport(String response) {
        // Define the start and end tag
        String startTag = '<LicensingReportProcessResult';
        String endTag = '</LicensingReportProcessResult>';
        
        // Trim whitespace and newlines to prevent mismatches
        response = response.trim();
        
        // Find the start index (case-sensitive)
        Integer startIndex = response.indexOf(startTag);
        System.debug('Start Index: ' + startIndex);
        
        if (startIndex == -1) {
            return 'No match found (Start tag missing)';
        }
        
        // Find the end index (case-sensitive)
        Integer endIndex = response.indexOf(endTag, startIndex);
        System.debug('End Index: ' + endIndex);
        
        if (endIndex == -1) {
            return 'No match found (End tag missing)';
        }
        
        // Include the full end tag in the result
        endIndex += endTag.length();
        
        // Extract and return the matched content
        return response.substring(startIndex, endIndex);
    }
}