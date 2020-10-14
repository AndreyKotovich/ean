public class McMock implements HttpCalloutMock {
    public static final String TOKEN_RESPONSE = '{\"access_token\": \"successToken\"}';
    public static final String RETRIEVE_RESPONSE = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><env:Header xmlns:env="http://www.w3.org/2003/05/soap-envelope"><wsa:Action>RetrieveResponse</wsa:Action><wsa:MessageID>urn:uuid:7ae171a3-23ee-46fd-87a7-9b46f141f3e4</wsa:MessageID><wsa:RelatesTo>urn:uuid:3bc57039-a59e-4aa7-b861-268a71e94fee</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-c7d413a4-740e-404f-93be-9582ba072c46"><wsu:Created>2020-01-10T13:20:30Z</wsu:Created><wsu:Expires>2020-01-10T13:25:30Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body><RetrieveResponseMsg xmlns="http://exacttarget.com/wsdl/partnerAPI"><OverallStatus>OK</OverallStatus><RequestID>15a7b0a8-c2a9-47f7-9710-e3616bcd1e2c</RequestID><Results xsi:type="Subscriber"><PartnerKey xsi:nil="true" /><ObjectID xsi:nil="true" /><EmailAddress>maksim.lavreniyk@succraft.com</EmailAddress><SubscriberKey>maksim.lavreniyk@succraft.com</SubscriberKey><Status>Unsubscribed</Status></Results></RetrieveResponseMsg></soap:Body></soap:Envelope>';
    public static final String UPDATE_RESPONSE = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><env:Header xmlns:env="http://www.w3.org/2003/05/soap-envelope"><wsa:Action>UpdateResponse</wsa:Action><wsa:MessageID>urn:uuid:c5a6737f-4de6-4149-a207-e138f4b993f3</wsa:MessageID><wsa:RelatesTo>urn:uuid:abbaf90a-250c-4b09-8997-d92dfc74f743</wsa:RelatesTo><wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security><wsu:Timestamp wsu:Id="Timestamp-dce3c7d6-c90d-4a77-bdde-c352f9f332e3"><wsu:Created>2020-01-13T10:24:51Z</wsu:Created><wsu:Expires>2020-01-13T10:29:51Z</wsu:Expires></wsu:Timestamp></wsse:Security></env:Header><soap:Body><UpdateResponse xmlns="http://exacttarget.com/wsdl/partnerAPI"><Results><StatusCode>OK</StatusCode><StatusMessage>Updated Subscriber.</StatusMessage><OrdinalID>0</OrdinalID><Object xsi:type="Subscriber"><PartnerKey xsi:nil="true" /><ID>20</ID><ObjectID xsi:nil="true" /><SubscriberKey>maksim.lavreniyk@succraft.com</SubscriberKey><Status>Active</Status></Object></Results><RequestID>a83e608b-b5fd-4228-b953-5775782a43b1</RequestID><OverallStatus>OK</OverallStatus></UpdateResponse></soap:Body></soap:Envelope>';

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        MC_credentials__c creds = MC_credentials__c.getAll().get('MC');

        if (req.getEndpoint().contains(creds.AuthUri__c + '/v2/token')) {
		    res.setHeader('Content-Type', 'application/json');
            res.setBody(TOKEN_RESPONSE);
            res.setStatusCode(200);
        } else if (req.getHeader('SOAPAction') == 'Retrieve') {
		    res.setHeader('Content-Type', 'application/json');
            res.setBody(RETRIEVE_RESPONSE);
            res.setStatusCode(200);
        } else if (req.getHeader('SOAPAction') == 'Update') {
		    res.setHeader('Content-Type', 'application/json');
            res.setBody(UPDATE_RESPONSE);
            res.setStatusCode(200);
        }

        return res;
    }
}