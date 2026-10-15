public class NIPRRemoveTargetsHelper {
    
    @future (callout=true)
    public static void execute(set<string> idslist){
        system.debug('idslistfuture'+idslist);
        for(string s:idslist){
            system.debug('test');
            String username = label.Nipr_username;
            String password = label.Nipr_password;
            
            Http H1 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setEndpoint(label.Targetsurl);
            Blob headerValue = Blob.valueOf(label.Nipr_username + ':' + label.Nipr_password);
            String authorizationHeader = 'Basic ' +EncodingUtil.base64Encode(headerValue);
            system.debug(authorizationHeader);
            
            String Data = '<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ind=\"https://pdb-services.nipr.com/pdb-alerts-industry-services/industry-ws\">'+
                '<soapenv:Header/>'+
                '<soapenv:Body>'+
                '<ind:removeTargets>'+
                '<ind:subscriptionName>PDB Alert Report</ind:subscriptionName>'+
                '<ind:targetInputData>'+
                '<ind:inputFormat>NPN</ind:inputFormat>'+
                '<ind:targetInputList>'+
                '<ind:npnList>'+s+'</ind:npnList>'+
                '</ind:targetInputList>'+
                '</ind:targetInputData>'+
                '</ind:removeTargets>'+
                '</soapenv:Body>'+
                '</soapenv:Envelope>';
            
            req1.setBody(data);
            req1.setHeader('Authorization', authorizationHeader);
            req1.setHeader('Accept', 'application/json');
            req1.setMethod('POST');
            HttpResponse res1;
            if(!Test.isRunningTest())
                res1=h1.send(req1);
            string response;
            try{
                response = res1.getbody(); 
                system.debug('response'+response);
            }
            catch(Exception e) {                     
            }
        }
        
    }
}