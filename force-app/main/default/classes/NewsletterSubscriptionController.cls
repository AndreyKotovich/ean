public without sharing class NewsletterSubscriptionController {
    
    public static Boolean isCreateSubscribersEnabled = true;

    @future (callout = true)
    public static void createMcSubscribers (Set<Id> contactIds) {
        System.debug(contactIds);

        McInfo creds = getMcAccessToken();
        List<Contact> contacts = [
            SELECT Id, LastName, FirstName, Email
            FROM Contact
            WHERE Id IN :contactIds
        ];
        System.debug(contacts.size());
        if (creds.access_token == null || contacts.isEmpty()) return;

        String body = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '    <s:Header>' +
            '        <fueloauth xmlns="http://exacttarget.com">' + creds.access_token + '</fueloauth>' +
            '    </s:Header>' +
            '    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '        <CreateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">';

        for (Contact newSubscriber : contacts) {
            body += 
                '           <Objects xsi:type="Subscriber">' +
                '               <ObjectID xsi:nil="true">' +
                '               </ObjectID>' +
                '               <EmailAddress>' + newSubscriber.Email + '</EmailAddress>' +
                '               <SubscriberKey>' + newSubscriber.Id + '</SubscriberKey>' + 
                '               <Attributes>' +
                '                   <Name>First Name</Name>' +
                '                   <Value>' + newSubscriber.FirstName + '</Value>' +
                '               </Attributes>' +
                '               <Attributes>' +
                '                   <Name>Last Name</Name>' +
                '                   <Value>' + newSubscriber.LastName + '</Value>' +
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
        request.setEndpoint(creds.soapUri + '/Service.asmx'); 
        request.setMethod('POST');
        request.setHeader('SOAPAction','Create'); 
        request.setHeader('Content-type','text/xml'); 
        request.setBody(body);
        HttpResponse response = http.send(request);
    }

    public static McInfo getMcAccessToken() {
        MC_credentials__c creds = MC_credentials__c.getAll().get('MC');
        if (String.isEmpty(creds.ClientId__c) || String.isEmpty(creds.ClientSecret__c) || String.isEmpty(creds.AuthUri__c)) {
            throw new AuraHandledException('smthg wrong with the mc credentials');
        }
        String clientId = creds.ClientId__c;
        String clientSecret = creds.ClientSecret__c;
        String authUri = creds.AuthUri__c;
        String soapUri = creds.SoapUri__c;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(authUri + '/v2/token');
        request.setHeader('Content-Type', 'application/json');
        String body = '{"grant_type":"client_credentials",' + 
                        '"client_id":"' + clientId + '",' + 
                        '"client_secret":"' + clientSecret + '"}';
        request.setBody(body);
        
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            McInfo info = (McInfo) JSON.deserialize(response.getBody(), McInfo.class);
            info.clientId = clientId;
            info.clientSecret = clientSecret;
            info.authUri = authUri;
            info.soapUri = soapUri;
            System.debug(info.access_token);
            return info;
        } else {
            return null;
        }
    }
    
    public static Boolean checkMcSubscriberStatus(McInfo creds, String recordId) {
        System.debug('*********');
        System.debug(creds.access_token);
        String body = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '    <s:Header>' +
            //'        <a:Action s:mustUnderstand="1">Retrieve</a:Action>' +
            //'        <a:To s:mustUnderstand="1">' + 'https://mcw89mv4c-3xpgdr9xz39wp3tw6y.soap.marketingcloudapis.com' + '</a:To>' +
            '        <fueloauth xmlns="http://exacttarget.com">' + creds.access_token + '</fueloauth>' +
            '    </s:Header>' +
            '    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '        <RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
            '            <RetrieveRequest>' +
            '                <ObjectType>Subscriber</ObjectType>' +
            '                <Properties>SubscriberKey</Properties>' +
            '                <Properties>EmailAddress</Properties>' +
            '                <Properties>Status</Properties>' +
            '                <Filter xmlns:q1="http://exacttarget.com/wsdl/partnerAPI" xsi:type="q1:SimpleFilterPart">' +
            '                   <q1:Property>SubscriberKey</q1:Property>' +
            '                   <q1:SimpleOperator>equals</q1:SimpleOperator>' +
            '                   <q1:Value>' + recordId + '</q1:Value>' +
            '                </Filter>' +
            '            </RetrieveRequest>' +
            '        </RetrieveRequestMsg>' +
            '    </s:Body>' +
            '</s:Envelope>';

        Http h = new Http();
        HttpRequest r = new HttpRequest();
        r.setTimeout(60000);
        r.setEndpoint(creds.soapUri + '/Service.asmx');  
        r.setMethod('POST');
        r.setHeader('SOAPAction','Retrieve'); 
        //r.setHeader('Accept','text/xml');  
        r.setHeader('Content-type','text/xml');    
        //r.setHeader('charset','UTF-8'); 
        r.setBody(body);    
        HttpResponse s = h.send(r);
        System.debug(s.getBody());
        String responseNode;
        try {
            Dom.Document doc = s.getBodyDocument();
            Dom.XMLNode root = doc.getRootElement();

            Dom.XMLNode bodyNode = root.getChildElement('Body', root.getNamespace());

            responseNode = bodyNode.getChildElement('RetrieveResponseMsg','http://exacttarget.com/wsdl/partnerAPI')
                .getChildElement('Results', 'http://exacttarget.com/wsdl/partnerAPI')
                .getChildElement('Status', 'http://exacttarget.com/wsdl/partnerAPI')
                .getText();

            System.debug(responseNode);
        } catch(Exception e) {
            throw new AuraHandledException('Fail');
        }
        return responseNode == 'Active';
    }
    //method to add/remove subscriptions for contacts
    public static void subscriptionManagement(List<Contact> contactsToProcess, Map<Id, Contact> contactsToProcessOldMap, Boolean isInsert) {
        //newsletter
        Set<Id> contactsToSubscribeNL = new Set<Id>();
        Set<Id> contactsToUnsubscribeNL = new Set<Id>();
        //ipe
        Set<Id> contactsToSubscribeIPE = new Set<Id>();
        Set<Id> contactsToUnsubscribeIPE = new Set<Id>();
        for (Contact item : contactsToProcess) {
            //checking of "I agree to receive EAN newsletter" checkbox  changes
            if (isInsert) {
                if (item.Newsletter__c) {
                    contactsToSubscribeNL.add(item.Id);//from false to true
                }
            }
            else if (item.Newsletter__c != contactsToProcessOldMap.get(item.Id).Newsletter__c) {
                if (item.Newsletter__c) {
                    contactsToSubscribeNL.add(item.Id);//from false to true
                } else {
                    contactsToUnsubscribeNL.add(item.Id);//from true to false
                }
            }
            //checking of "IPE" checkbox  changes
            if (isInsert) {
                if (item.Industry_Sponsored_Emails__c) {
                    contactsToSubscribeIPE.add(item.Id);//from false to true
                }
            }
            else if (item.Industry_Sponsored_Emails__c != contactsToProcessOldMap.get(item.Id).Industry_Sponsored_Emails__c) {
                if (item.Industry_Sponsored_Emails__c) {
                    contactsToSubscribeIPE.add(item.Id);//from false to true
                } else {
                    contactsToUnsubscribeIPE.add(item.Id);//from true to false
                }
            }
        }

        //List<Campaign> campaigns = new List<Campaign>();
        Campaign newsletterCampaign;
        Campaign ipeCampaign;
        if (!contactsToSubscribeNL.isEmpty() || !contactsToUnsubscribeNL.isEmpty() || !contactsToSubscribeIPE.isEmpty() || !contactsToUnsubscribeIPE.isEmpty()) {
            //generate full set of contacts to use in soql
            Set<Id> fullContacts = new Set<Id>();
            fullContacts.addAll(contactsToSubscribeNL);
            fullContacts.addAll(contactsToUnsubscribeNL);
            fullContacts.addAll(contactsToSubscribeIPE);
            fullContacts.addAll(contactsToUnsubscribeIPE);
            Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');
            //select all campaigns that are used for MC
            List<Campaign> campaigns = [
                SELECT Id, Name,
                    (SELECT Id, ContactId, CampaignId FROM CampaignMembers WHERE ContactId IN :fullContacts)
                FROM Campaign
                WHERE Name = :cmpgNames.Newsletter_Name__c OR Name = :cmpgNames.IPE_Name__c
            ];
            for (Campaign item : campaigns) {
                if (item.Name == cmpgNames.Newsletter_Name__c) {
                    newsletterCampaign = item;
                } else if (item.Name == cmpgNames.IPE_Name__c) {
                    ipeCampaign = item;
                }
            }
        }

        List<CampaignMember> membersToInsert = new List<CampaignMember>();
        //creating of new cmembers
        if (!contactsToSubscribeNL.isEmpty() && newsletterCampaign != null) {
            for (Id contactId : contactsToSubscribeNL) {
                CampaignMember newMember = new CampaignMember();
                newMember.ContactId = contactId;
                newMember.CampaignId = newsletterCampaign.Id;
                membersToInsert.add(newMember);
            }
        }
        if (!contactsToSubscribeIPE.isEmpty() && ipeCampaign != null) {
            for (Id contactId : contactsToSubscribeIPE) {
                CampaignMember newMember = new CampaignMember();
                newMember.ContactId = contactId;
                newMember.CampaignId = ipeCampaign.Id;
                membersToInsert.add(newMember);
            }
        }
        if (!membersToInsert.isEmpty()) insert membersToInsert;

        List<CampaignMember> membersToDelete = new List<CampaignMember>();
        //deleting of cmembers
        if (!contactsToUnsubscribeNL.isEmpty() && newsletterCampaign != null) {
            for (CampaignMember item : newsletterCampaign.CampaignMembers) {
                if (contactsToUnsubscribeNL.contains(item.ContactId)) membersToDelete.add(item);
            }
        }
        
        if (!contactsToUnsubscribeIPE.isEmpty() && ipeCampaign != null) {
            for (CampaignMember item : ipeCampaign.CampaignMembers) {
                if (contactsToUnsubscribeIPE.contains(item.ContactId)) membersToDelete.add(item);
            }
        }

        if (!membersToDelete.isEmpty()) delete membersToDelete;
    }

    @AuraEnabled
    public static string getNewsletterList(String recordId) {
        List<User> currentuser = [
            SELECT Id, Industry_Sponsored_Emails__c, Newsletter__c, Contact.Newsletter__c, Contact.Industry_Sponsored_Emails__c
            FROM User 
            WHERE ContactId = :recordId
            LIMIT 1
        ];
        if (!currentuser.isEmpty()) {
            if (currentuser[0].Industry_Sponsored_Emails__c != currentuser[0].Contact.Industry_Sponsored_Emails__c
                || currentuser[0].Newsletter__c != currentuser[0].Contact.Newsletter__c) {
                    return JSON.serialize(new List<Subscription>());
            }
        }
        Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');
        List<Subscription> result = new List<Subscription>();
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>();
        
        campaigns = new Map<Id, Campaign>([
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :cmpgNames.Newsletter_Name__c OR Name = :cmpgNames.IPE_Name__c
        ]);

        if (!campaigns.values().isEmpty()) {
            List<CampaignMember> members = new List<CampaignMember>();
            members = [
                SELECT Id, ContactId, CampaignId 
                FROM CampaignMember
                WHERE ContactId = :recordId
            ];
            Set<Id> campaignsIds = new Set<Id>();
            for (CampaignMember member : members) {
                campaignsIds.add(member.CampaignId);
            }
            for (Campaign item : campaigns.values()) {
                Subscription subscription = new Subscription();
                subscription.campaignRecord = item;
                subscription.isSubscribed = campaignsIds.contains(item.Id);
                result.add(subscription);
            }
        }
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static void updateSubscriptions(List<Id> campaignIds, String recordId) {
        Campaign_Names__c cmpgNames = Campaign_Names__c.getAll().get('MC');
        List<Campaign> campaigns = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :cmpgNames.Newsletter_Name__c OR Name = :cmpgNames.IPE_Name__c
        ];
        System.debug(campaignIds);
        Contact currentContact = new Contact(Id = recordId);
        for (Campaign item : campaigns) {
            if (campaignIds.contains(item.Id)) {
                if (item.Name == cmpgNames.Newsletter_Name__c) {
                    currentContact.Newsletter__c = true;
                }
                if (item.Name == cmpgNames.IPE_Name__c) {
                    currentContact.Industry_Sponsored_Emails__c = true;
                }
            } else {
                if (item.Name == cmpgNames.Newsletter_Name__c) {
                    currentContact.Newsletter__c = false;
                }
                if (item.Name == cmpgNames.IPE_Name__c) {
                    currentContact.Industry_Sponsored_Emails__c = false;
                }
            }
        }

        update currentContact;
    }

    @AuraEnabled
    public static String checkMcStatus(String recordId) {
        McInfo creds = getMcAccessToken();
        creds.isSubscribed = checkMcSubscriberStatus(creds, recordId);
        return JSON.serialize(creds);
    }

    @AuraEnabled
    public static Boolean updateMcStatus(String recordId, String data) {
        McInfo creds = (McInfo) JSON.deserialize(data, McInfo.class);
        System.debug(creds);
        //logic to update status
        String body = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '    <s:Header>' +
            '        <fueloauth xmlns="http://exacttarget.com">' + creds.access_token + '</fueloauth>' +
            '    </s:Header>' +
            '    <s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
            '        <UpdateRequest xmlns="http://exacttarget.com/wsdl/partnerAPI">' +
            '            <Options>' +
            '                <SaveOptions>' +
            '                    <SaveOption>' +
            '                        <PropertyName>*</PropertyName>' +
            '                        <SaveAction>UpdateOnly</SaveAction>' +
            '                    </SaveOption>' +
            '                </SaveOptions>' +
            '            </Options>' +
            '            <Objects xsi:type="Subscriber">' +
            '            ' +
            '                <PartnerKey xsi:nil="true" />' +
            '                <ObjectID xsi:nil="true" />' +
            '                <Status>' + (creds.isSubscribed ? 'Unsubscribed' : 'Active') + '</Status>' +
            '                <SubscriberKey>' + recordId + '</SubscriberKey>' +
            '            </Objects>' +
            '        </UpdateRequest>' +
            '    </s:Body>' +
            '</s:Envelope>';

        Http h = new Http();
        HttpRequest r = new HttpRequest();
        r.setTimeout(60000);
        r.setEndpoint(creds.soapUri + '/Service.asmx');  
        r.setMethod('POST');
        r.setHeader('SOAPAction','Update'); 
        r.setHeader('Content-type','text/xml');    
        r.setBody(body);    
        HttpResponse s = h.send(r);
        System.debug(s.getBody());

        try {
            Dom.Document doc = s.getBodyDocument();
            Dom.XMLNode root = doc.getRootElement();
            Dom.XMLNode bodyNode = root.getChildElement('Body', root.getNamespace());

            String responseNode = bodyNode.getChildElement('UpdateResponse','http://exacttarget.com/wsdl/partnerAPI')
                .getChildElement('Results', 'http://exacttarget.com/wsdl/partnerAPI')
                .getChildElement('Object', 'http://exacttarget.com/wsdl/partnerAPI')
                .getChildElement('Status', 'http://exacttarget.com/wsdl/partnerAPI')
                .getText();

            if (creds.isSubscribed) {
                Contact currentContact = new Contact(Id = recordId);
                currentContact.Newsletter__c = false;
                currentContact.Industry_Sponsored_Emails__c = false;
                
                update currentContact;
            }

            return !creds.isSubscribed;
        } catch(Exception e) {
            throw new AuraHandledException('Fail');
        }
    }

    public class Subscription {
        public Campaign campaignRecord { get; set;}
        public Boolean isSubscribed { get; set;}
        
        public Subscription() {
        }
    }

    public class McInfo {
        public String access_token { get; set;}
        public String clientId { get; set;}
        public String clientSecret { get; set;}
        public String authUri { get; set;}
        public String soapUri { get; set;}
        public Boolean isSubscribed { get; set;}
        public McInfo() {
        }
    }
}