@isTest
global class NiprSSNsearchMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('<?xml version="1.0" encoding="UTF-8"?><HITLIST><TRANSACTION_TYPE><TYPE>LIST</TYPE></TRANSACTION_TYPE><INDIVIDUAL><NAME>Freire, David </NAME><ID_ENTITY>17524533</ID_ENTITY><NPN>17524533</NPN><STATE_RESIDENT>FL</STATE_RESIDENT><DATE_BIRTH>03/06/1995</DATE_BIRTH></INDIVIDUAL></HITLIST>');
        res.setStatusCode(200);
        return res;
    }
}