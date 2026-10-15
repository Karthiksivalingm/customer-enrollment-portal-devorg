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
        } else if(req.getEndpoint().contains('/state_marketplace_stats/')){
            res.setBody('{"consumers": {"premium": 38494, "standard": 17005, "preferred": 27167, "non_standard": 2927}, "share_rate": 1.36, "unsold_leads": 27048, "unsold_consumers": {"premium": 10824, "standard": 5566, "preferred": 9827, "non_standard": 825}}');
        }
        res.setStatusCode(200);
        return res;
    }
}