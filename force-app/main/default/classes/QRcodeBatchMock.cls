@IsTest
global class QRcodeBatchMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"response": "success"}');
        response.setStatusCode(200);
        return response;
    }
}