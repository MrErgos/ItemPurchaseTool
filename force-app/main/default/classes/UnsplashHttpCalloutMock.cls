/**
 * Created by George on 19.02.2026.
 */

@IsTest
global class UnsplashHttpCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"results": [{"urls": {"regular": "https://example.com/image.jpg"}}]}');
        response.setStatusCode(200);
        return response;
    }
}