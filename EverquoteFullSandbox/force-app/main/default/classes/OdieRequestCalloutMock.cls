global class OdieRequestCalloutMock implements HttpCalloutMock {
  private HttpResponse res;
  public Map<String, String> urlsRequestBody;

  public void setMockStatusCode(Integer code) {
    res.setStatusCode(code);
  }

  public void setMockStatusAndBody(Integer code, String bodyJSON) {
    res.setStatusCode(code);
    res.setBody(bodyJSON);
  }

  public void setResponseBody(String bodyJSON) {
    res.setBody(bodyJSON);
  }

  public OdieRequestCalloutMock() {
    res = new HttpResponse();
    urlsRequestBody = new Map<String, String>();
    setMockStatusCode(200);
    setResponseBody('{"example": "test"}');
  }

  public OdieRequestCalloutMock(Integer statusCode) {
    res = new HttpResponse();
    urlsRequestBody = new Map<String, String>();
    setMockStatusCode(statusCode);
    setResponseBody('{"error": "test error"}');
  }

  global HttpResponse respond(HTTPRequest req) {
    String endpoint = req.getEndpoint();

    if (endpoint != null) {
      endpoint = endpoint.replace('callout:Odie_API_Credential/', '');
      // fix double slash on testing
      if (endpoint.startsWith('/')) {
        endpoint = endpoint.replaceFirst('/', '');
      }

      urlsRequestBody.put(endpoint, req.getBody());
    }

    res.setHeader('Content-Type', 'application/json');
    return res;
  }
}