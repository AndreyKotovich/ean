/**
 * Created by aleksandr on 10.3.20.
 */

global class getAccessTokenMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token": "token123456"}');
        response.setStatusCode(200);
        return response;
    }
}