/**
 * Created by aleksandr on 11.3.20.
 */

@IsTest
global class updateMeetingLogMeInMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        response.setBody('{"response": "meeting updated successfully"}');
        response.setStatusCode(200);
        return response;
    }
}