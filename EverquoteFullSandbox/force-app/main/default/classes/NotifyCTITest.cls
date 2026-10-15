@isTest
private class NotifyCTITest {

    private class NotifyCTIMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            System.assertEquals(
                'POST',
                req.getMethod(),
                'The CTI request should use POST method.'
            );

            System.assert(
                req.getEndpoint().endsWith('/task'),
                'The endpoint should end with /task.'
            );

            System.assertNotEquals(
                null,
                req.getHeader('Authorization'),
                'Authorization header should be present.'
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Success');

            return res;
        }
    }

    private class NotifyCTIErrorMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');

            return res;
        }
    }

    @isTest
    static void testSendUpdateSuccess() {

        Test.setMock(
            HttpCalloutMock.class,
            new NotifyCTIMock()
        );

        Test.startTest();

        NotifyCTI.sendUpdate('task');

        Test.stopTest();
    }

    @isTest
    static void testSendUpdateErrorResponse() {

        Test.setMock(
            HttpCalloutMock.class,
            new NotifyCTIErrorMock()
        );

        Test.startTest();

        NotifyCTI.sendUpdate('task');

        Test.stopTest();
    }

    @isTest
    static void testSendUpdateBulk200Tasks() {

        List<Task> tasks = new List<Task>();

        for (Integer i = 0; i < 200; i++) {
            tasks.add(
                new Task(
                    Subject = 'CTI Bulk Test ' + i,
                    Status = 'Not Started'
                )
            );
        }

        Test.setMock(
            HttpCalloutMock.class,
            new NotifyCTIMock()
        );

        Test.startTest();

        insert tasks;

        Test.stopTest();

        System.assertEquals(
            200,
            tasks.size(),
            '200 Tasks should have been created.'
        );
    }
}