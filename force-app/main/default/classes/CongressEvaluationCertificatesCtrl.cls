public with sharing class CongressEvaluationCertificatesCtrl {
    public static Contact getContactInfo(Id recordId){
        Id contactId;

        if(recordId != null && recordId.getSobjectType().getDescribe().getName() == 'Contact'){
            contactId = recordId;
        } else {
            User user = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];

            if(user.ContactId != null){
                contactId = user.ContactId;
            } else {
                AuraHandledException e = new AuraHandledException('Cannot find a contact');
                e.setMessage('Cannot find a contact');
                throw e;
            }

        }

        Contact contact = [SELECT Id, FirstName, LastName, MiddleName, MailingCity, MailingCountry FROM Contact WHERE Id = :contactId];
        return contact;
    }

    public static List<Congress_Component_Metadata__mdt> getComponentMetadata(){
        List<Congress_Component_Metadata__mdt> componentMetadata = [SELECT Id, Congress_Name__c, Congress_External_Id__c, Congress_End_Date__c FROM Congress_Component_Metadata__mdt WHERE Is_Credentials__c = FALSE ORDER BY Congress_End_Date__c LIMIT 10];
        if(!componentMetadata.isEmpty()){
            return componentMetadata;
        } else {
            AuraHandledException e = new AuraHandledException('There are no congresses yet.');
            e.setMessage('There are no congresses yet.');
            throw e;
        }

    }

    public static List<Congress_Component_Metadata__mdt> getAuthorizationCredentials(){
        List<Congress_Component_Metadata__mdt> componentMetadata = [SELECT Id, Password__c, Username__c FROM Congress_Component_Metadata__mdt WHERE Is_Credentials__c = TRUE AND Congress_Name__c = 'Credentials' LIMIT 1];
        if(!componentMetadata.isEmpty()){
            return componentMetadata;
        } else {
            AuraHandledException e = new AuraHandledException('Authorization problem');
            e.setMessage('Authorization problem');
            throw e;
        }

    }

    public static String getAuthorizationToken(){
        List<Congress_Component_Metadata__mdt> credentials = getAuthorizationCredentials();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CongressCertificateAuthorization');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String reqBody = 'username='+EncodingUtil.urlEncode(credentials[0].Username__c,'UTF-8')+'&password='+EncodingUtil.urlEncode(credentials[0].Password__c,'UTF-8');
        request.setBody(reqBody);
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            return response.getHeader('AuthenticationToken');
        } else {
            throw new AuraHandledException('Authorization problem');
        }
    }

    @AuraEnabled public static List<Map<String, Object>> getCertificatesLinks(Id contactId){
        Contact contact = getContactInfo(contactId);
        List<Map<String, Object>> congressLinksMapList = new List<Map<String, Object>>();
        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('SalesforceContactId', contact.Id == null ? '' : contact.Id);
        bodyMap.put('SalesforceContactFirstname', contact.FirstName == null ? '' : contact.FirstName);
        bodyMap.put('SalesforceContactMiddlename', contact.MiddleName == null ? '' : contact.MiddleName);
        bodyMap.put('SalesforceContactLastname', contact.LastName == null ? '' : contact.LastName);
        bodyMap.put('SalesforceContactCity', contact.MailingCity == null ? '' : contact.MailingCity);
        bodyMap.put('SalesforceContactCountry', contact.MailingCountry == null ? '' : contact.MailingCountry);
        String reqBody = JSON.serialize(bodyMap);
        String authToken;
        if(Test.isRunningTest()){
            authToken = 'Test';
        } else {
            authToken = getAuthorizationToken();
        }

        for(Congress_Component_Metadata__mdt metadata : getComponentMetadata()){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:CongressGetCertificatesLinks' + '?eventId=' + metadata.Congress_External_Id__c);
            request.setMethod('POST');
            request.setHeader('Authorization', 'AuthenticationToken '+ authToken);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(reqBody);
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                congressLinksMapList.add(new Map<String, Object>{'congressName' => (Object) metadata.Congress_Name__c, 'congressCertificateLinks' => (Object) JSON.deserializeUntyped(response.getBody()), 'isParticipantFound' => true });
            } else {
                String resBody = response.getBody();
                if(resBody.contains('"No virtual delegate found')){
                    congressLinksMapList.add(new Map<String, Object>{'congressName' => (Object) metadata.Congress_Name__c, 'isParticipantFound' => false });
                }
            }
        }

        return congressLinksMapList;
    }
}