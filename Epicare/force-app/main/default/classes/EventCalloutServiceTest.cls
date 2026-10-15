@isTest
public class EventCalloutServiceTest {

    private class EventCalloutMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            System.assertEquals(
                'callout:EventAPI/sf-event-commission-paid',
                req.getEndpoint()
            );

            System.assertEquals('POST', req.getMethod());
            System.assertEquals(
                'application/json',
                req.getHeader('Content-Type')
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');

            return res;
        }
    }

    @isTest
    static void testSend() {

        Test.setMock(HttpCalloutMock.class, new EventCalloutMock());

        Map<String, Object> payload = new Map<String, Object>{
            'contact_id' => '003000000000001AAA',
            'batch_id' => 'a010000000000001AAA',
            'amount' => 5000
        };

        Test.startTest();

        EventCalloutService.send(
            '/sf-event-commission-paid',
            payload
        );

        Test.stopTest();

        System.assert(true);
    }
}