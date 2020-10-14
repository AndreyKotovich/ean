global class CongressEvaluationCertificatesCtrlMock  implements HttpCalloutMock {
    global Boolean isAuthorization{get; set;}

    global HttpResponse respond(HttpRequest request) {
        if(isAuthorization){
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            response.setHeader('AuthenticationToken', 'Test Token');
            response.setStatusCode(200);
            return response;
        } else {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            response.setBody('{"test":"OK"}');
            return response;
        }
    }
}