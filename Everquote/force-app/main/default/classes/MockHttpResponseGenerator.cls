@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {  
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint().contains('/lead_familiar_names/')){
        	res.setBody('{"distance": 0, "colleagues": [], "familiar_names": []}');    
        } else if(req.getEndpoint().contains('/account_familiar_names/')){
        	res.setBody('{"distance": 0, "colleagues": [], "familiar_names": []}');    
        }
        res.setStatusCode(200);
        return res;
    }
}