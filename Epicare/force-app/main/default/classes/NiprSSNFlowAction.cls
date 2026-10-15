public class NiprSSNFlowAction {

    public class Request {
        @InvocableVariable(required=true)
        public Id contactId;
    }

    public class Response {
        @InvocableVariable
        public String npn;
    }

    @InvocableMethod(label='NIPR SSN Search' description='Calls NIPR API with Contact SSN and Last Name')
    public static List<Response> ssnSearchFromFlow(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            try {
                Contact ssnNum = [SELECT Id, LastName, SSN_Number__c FROM Contact WHERE Id = :req.contactId LIMIT 1];

                String username = Label.Nipr_username;
                String password = Label.Nipr_password;
                String lastname = ssnNum.LastName.replace(' ', '%20');

                Http h1 = new Http();
                HttpRequest req1 = new HttpRequest();
                req1.setEndpoint(Label.SSN_URL + lastname + '&ssn=' + ssnNum.SSN_Number__c);

                Blob headerValue = Blob.valueOf(username + ':' + password);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

                req1.setHeader('Authorization', authorizationHeader);
                req1.setMethod('GET');

                HttpResponse res1 = h1.send(req1);
                DOM.Document doc = res1.getBodyDocument();

                for (Dom.XmlNode fluxNode : doc.getRootElement().getChildElements()) {
                    if (fluxNode.getName() == 'INDIVIDUAL') {
                        String npn = fluxNode.getChildElement('NPN', null).getText();

                        // Update Contact if needed
                        Contact conUpdate = new Contact(Id = req.contactId);
                        conUpdate.NPN__c = npn;
                        update conUpdate;

                        // Optionally invoke the next callout (converted if needed)
                        // NiprNPNFutureCallout.npnSearch(req.contactId, npn); -- if needed, convert this class for flow too

                        res.npn = npn;
                        break;
                    }
                }
            } catch (Exception e) {
                // Log or handle error gracefully
                System.debug('Error: ' + e.getMessage());
                res.npn = null;
            }

            responses.add(res);
        }

        return responses;
    }
}