/**
 * Created by aleksandr on 11.3.20.
 */

@IsTest
global class startMeetingMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        response.setBody('{"hostURL": "https://test/test/test"}');
        response.setStatusCode(200);
        return response;
    }
}