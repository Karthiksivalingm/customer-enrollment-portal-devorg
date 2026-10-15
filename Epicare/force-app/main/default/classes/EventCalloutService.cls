public class EventCalloutService {

    public static void send(String path, Object payload) {

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:EventAPI' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);
    }
}