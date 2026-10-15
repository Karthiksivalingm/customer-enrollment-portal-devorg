global class NotifyCTI {
    @future(callout=true)
    public static void sendUpdate(String activity) {
        String base_url = 'https://agents-cti-picker-prod.adh8.com/refreshactivity/';
        if (URL.getOrgDomainUrl().getHost().left(2).equalsIgnoreCase('cs')) {
            base_url = 'https://agents-cti-picker-staging.adh8.com/refreshactivity/';
        }
        String route = base_url + activity;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(route);
        req.setMethod('POST');
        req.setTimeout(10000);
        
        Blob headerValue = Blob.valueOf('api_user:everquote');
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        http.send(req);   
    }
}