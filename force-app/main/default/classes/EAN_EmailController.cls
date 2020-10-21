public with sharing class EAN_EmailController {
    public EAN_EmailController() {

    }
    @AuraEnabled
    public static List<SObject> sendEmail(Map<String, Object> emailOptionsMap){
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
        Set<String> additionalFieldApiNames = new Set<String>();
        List<SObject> objects = getObjects(recordIds, objectApiName, emailFieldApiName, additionalFieldApiNames);
        List<SObject> emptyEmailObjects = emptyEmailFieldCheck(objects, emailFieldApiName);
        try {
        List<Messaging.SingleEmailMessage> mails = createMails(objects, objectApiName, emailFieldApiName, templates, contactId);
        Messaging.sendEmail(mails);
        } catch(Exception error){
            throw new AuraHandledException(error.getMessage());
        }
        return emptyEmailObjects;
    }

    public static List<SObject> getObjects(List<String> recordIds, String objectApiName, String emailFieldApiName, Set<String> additionalFieldApiNames) {
        List<String> objectIds = recordIds;
        String query = 'SELECT ' + emailFieldApiName;
        for (String additionalFieldApiName : additionalFieldApiNames) {
            query = query + ', ' + additionalFieldApiName;
        }
        query = query + ' FROM ' + objectApiName + ' WHERE Id IN :objectIds LIMIT ' + objectIds.size();
        return Database.query(query);
    }

    public static List<SObject> emptyEmailFieldCheck(List<SObject> objects, String emailFieldApiName) {
        List<SObject> emptyEmailObjects = new List<SObject>();
        for (SObject objectItem : objects) {
            if (String.isBlank(String.valueOf(objectItem.get(emailFieldApiName)))) {
                emptyEmailObjects.add(objectItem);
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
        for (SObject objectItem : objects) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (!templates.isEmpty()) {
                mail = Messaging.renderStoredEmailTemplate(templates[0].Id, contactId, objectItem.Id);
                mail.saveAsActivity = false;
            }            
            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(String.valueOf(objectItem.get(emailFieldApiName)))) {
                toAddresses = String.valueOf(objectItem.get(emailFieldApiName)).split(', ');
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