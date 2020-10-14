/**
 * Created by aleksandr on 11.3.20.
 */

@IsTest
global class GetSomethingLogMeInMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        response.setBody('{"response": "success"}');
        response.setStatusCode(200);
        return response;
    }
}