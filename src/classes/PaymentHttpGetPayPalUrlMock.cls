global class PaymentHttpGetPayPalUrlMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"payment":{"statuses":{"status":[{"code":"201.0000","description":"The resource was successfully created.","severity":"information"}]},"payment-methods":{"payment-method":[{"url":"https://www.sandbox.paypal.com/","name":"paypal"}]}}}');
        response.setStatusCode(201);
        return response;
    }
}