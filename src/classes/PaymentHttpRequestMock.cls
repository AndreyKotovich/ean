global class PaymentHttpRequestMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"payment-redirect-url": "https://test.com"}');
        response.setStatusCode(201);
        return response;
    }
}