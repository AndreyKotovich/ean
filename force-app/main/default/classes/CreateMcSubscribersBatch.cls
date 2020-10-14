public class CreateMcSubscribersBatch implements Database.Batchable<SObject>, Database.AllowsCallouts  {

    public Database.QueryLocator start(Database.BatchableContext BC) {

        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = 'Non-Member Community User Profile' OR Name = 'Member Community User Profile'];
        if (!Test.isRunningTest()) {
            return Database.getQueryLocator(
                    'SELECT Id, IsActive, ContactId, Contact.LastName, Contact.FirstName, Contact.Email FROM User WHERE ProfileId IN :profiles AND IsActive = false'//????
            );
        } else {
            String name = 'mks.test.batch.dummny@lvk.com';
            return Database.getQueryLocator(
                    'SELECT Id, IsActive, ContactId, Contact.LastName, Contact.FirstName, Contact.Email FROM User WHERE ProfileId IN :profiles AND IsActive = false AND Username LIKE \'%' + name + '%\''
            );
        }
        
    }

    public void execute(Database.BatchableContext BC, List<User> scope) {

        NewsletterSubscriptionController.McInfo creds = Test.isRunningTest() ? new NewsletterSubscriptionController.McInfo() : NewsletterSubscriptionController.getMcAccessToken();
        String body = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '    <s:Header>' +
            '        <fueloauth xmlns="http://exacttarget.com">' + (Test.isRunningTest() == true ? 'test' : creds.access_token) + '</fueloauth>' +
            '    </s:Header>' +
            '    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '        <CreateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">';

        for (User newSubscriber : scope) {
            body += 
                '           <Objects xsi:type="Subscriber">' +
                '               <ObjectID xsi:nil="true">' +
                '               </ObjectID>' +
                '               <EmailAddress>' + newSubscriber.Contact.Email + '</EmailAddress>' +
                '               <SubscriberKey>' + newSubscriber.ContactId + '</SubscriberKey>' + 
                '               <Attributes>' +
                '                   <Name>First Name</Name>' +
                '                   <Value>' + newSubscriber.Contact.FirstName + '</Value>' +
                '               </Attributes>' +
                '               <Attributes>' +
                '                   <Name>Last Name</Name>' +
                '                   <Value>' + newSubscriber.Contact.LastName + '</Value>' +
                '               </Attributes>' +
                '           </Objects>';
        }

        body += 
            '        </CreateRequest>' +
            '    </s:Body>' +
            '</s:Envelope>';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000);
        request.setEndpoint((Test.isRunningTest() == true ? 'test' : creds.soapUri) + '/Service.asmx'); 
        request.setMethod('POST');
        request.setHeader('SOAPAction','Create'); 
        request.setHeader('Content-type','text/xml'); 
        request.setBody(body);

        if (!Test.isRunningTest()) {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() != 200) throw new McException(response.getBody());
        }
    }

    public void finish(Database.BatchableContext BC) {

    }

    public class McException extends Exception {}

}