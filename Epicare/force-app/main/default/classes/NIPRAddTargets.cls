public class NIPRAddTargets implements system.Queueable, Database.AllowsCallouts {
    
  List<NAICProducerCode__C> lstNPN ;
    
  public static boolean isFirstTime = False;
    
  public NIPRAddTargets(List<NAICProducerCode__C> newNPN) {
    lstNPN = newNPN;
  }

  public void execute(QueueableContext context) {

      if (isFirstTime) return;
     
      for(NAICProducerCode__C npn : lstNPN){
          
           
       
        Http H1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint(label.Targetsurl);
        Blob headerValue = Blob.valueOf(label.Nipr_username + ':' + label.Nipr_password);
        String authorizationHeader = 'Basic ' +EncodingUtil.base64Encode(headerValue);
        system.debug(authorizationHeader);
        
        String Data = '<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ind=\"https://pdb-services.nipr.com/pdb-alerts-industry-services/industry-ws\">'+
	'<soapenv:Header/>'+
	'<soapenv:Body>'+
		'<ind:addTargets>'+
			'<ind:subscriptionName>PDB Alert Report</ind:subscriptionName>'+
			'<ind:targetInputData>'+
				'<ind:inputFormat>NPN</ind:inputFormat>'+
				'<ind:targetInputList>'+
					'<ind:npnList>'+npn.NpnNumber__c+'</ind:npnList>'+
				'</ind:targetInputList>'+
			'</ind:targetInputData>'+
		'</ind:addTargets>'+
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
         response= res1.getbody();
          }
          catch(Exception e) {
              
          }
        system.debug(response);
          
      }
  }       
}