/**
 * Created by aleksandr on 10.3.20.
 */

global class CreateMeetingLogMeInMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"joinURL": "https://test/test"}');
        response.setStatusCode(201);
        return response;
    }
}