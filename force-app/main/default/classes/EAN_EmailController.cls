public with sharing class EAN_EmailController {
    public EAN_EmailController() {

    }
    @AuraEnabled
    public static List<SObject> sendEmail(Map<String, Object> emailOptionsMap){
        System.debug('Start Email logic');
        List<String> recordIds = new List<String>();
        if (emailOptionsMap.containsKey('recordIds')) {
           recordIds = (List<String>) emailOptionsMap.get('recordIds');
        }
        String objectApiName = '';
        if (emailOptionsMap.containsKey('objectApiName')) {
            objectApiName = String.valueOf(emailOptionsMap.get('objectApiName'));
        }
        String emailFieldApiName = '';
        if (emailOptionsMap.containsKey('emailFieldApiName')) {
            emailFieldApiName = String.valueOf(emailOptionsMap.get('emailFieldApiName'));
        }
        String emailTemplateDevName = '';
        if (emailOptionsMap.containsKey('emailTemplateDevName')) {
            emailTemplateDevName = String.valueOf(emailOptionsMap.get('emailTemplateDevName'));
        }
        String contactId;
        if (emailOptionsMap.containsKey('contactId')){
            contactId = String.valueOf(emailOptionsMap.get('contactId'));
        }
        List<EmailTemplate> templates = getEmailTemplate(emailTemplateDevName);
        List<SObject> objects = getObjects(recordIds, objectApiName, emailFieldApiName);
        List<SObject> emptyEmailObjects = emptyEmailFieldCheck(objects, emailFieldApiName);
        try {
        List<Messaging.SingleEmailMessage> mails = createMails(objects, objectApiName, emailFieldApiName, templates, contactId);
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
        } catch(Exception error){
            System.debug(error.getMessage());
        }
        return emptyEmailObjects;
    }

    public static List<SObject> getObjects(List<String> recordIds, String objectApiName, String emailFieldApiName) {
        System.debug('get objects');
        List<String> objectIds = recordIds;
        String query = 'SELECT Id';
        if (String.isNotBlank(emailFieldApiName)) {
            query = query + ', ' + emailFieldApiName;
        }
        query = query + ' FROM ' + objectApiName + ' WHERE Id IN :objectIds LIMIT ' + objectIds.size();
        return Database.query(query);
    }

    public static List<SObject> emptyEmailFieldCheck(List<SObject> objects, String emailFieldApiName) {
        List<SObject> emptyEmailObjects = new List<SObject>();
        for (SObject objectItem : objects) {
            if (String.isNotBlank(emailFieldApiName)){
                if (String.isBlank(String.valueOf(objectItem.get(emailFieldApiName)))) {
                    emptyEmailObjects.add(objectItem);
                }
            }  
        }
        return emptyEmailObjects;
    }

    public static List<EmailTemplate> getEmailTemplate(String emailTemplateDevName) {
        List<EmailTemplate> templates = [SELECT DeveloperName, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :emailTemplateDevName LIMIT 1];
        return templates;        
    }

    public static List<Messaging.SingleEmailMessage> createMails(List<SObject> objects, String objectApiName, String emailFieldApiName, List<EmailTemplate> templates, String contactId) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Contact contact;
        if (String.isNotBlank(contactId)) {
            try {
                contact = [
                SELECT Email FROM Contact WHERE Id = :contactId
                ];
                System.debug(contact);
            } catch(Exception error) {
                System.debug(error.getMessage());
            }
        }
        for (SObject objectItem : objects) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (!templates.isEmpty()) {
                mail = Messaging.renderStoredEmailTemplate(templates[0].Id, contactId, objectItem.Id);
                mail.saveAsActivity = false;
            }            
            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(emailFieldApiName)) {
                if (String.isNotBlank(String.valueOf(objectItem.get(emailFieldApiName)))) {
                    toAddresses = String.valueOf(objectItem.get(emailFieldApiName)).split(', ');
                }
            } else if (contact.Email != null) {
                toAddresses.add(contact.Email);
            }
            if (toAddresses.size() > 0) {
                mail.setToAddresses(toAddresses);
                mail.setSenderDisplayName('Do not reply');
                mails.add(mail);
            }
        }
        return mails;
    }
}