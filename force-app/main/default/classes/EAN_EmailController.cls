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
        List<EmailTemplate> templates = getEmailTemplate(emailTemplateDevName);
        Set<String> additionalFieldApiNames = new Set<String>();
        //if (!templates.isEmpty()) {
        //     additionalFieldApiNames.addAll(getAdditionalFieldApiNames(templates[0].Subject, objectApiName));
        //     additionalFieldApiNames.addAll(getAdditionalFieldApiNames(templates[0].Body, objectApiName));
        // }
        List<SObject> objects = getObjects(recordIds, objectApiName, emailFieldApiName, additionalFieldApiNames);
        List<SObject> emptyEmailObjects = emptyEmailFieldCheck(objects, emailFieldApiName);
        try {
        List<Messaging.SingleEmailMessage> mails = createMails(objects, objectApiName, emailFieldApiName, templates);
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

    // public static List<String> getAdditionalFieldApiNames(String templateField, String objectApiName) {
    //     List<String> additionalFieldApiNames = new List<String>();
    //         List<String> partsPreliminary = templateField.split('\\{');
    //         List<String> parts = new List<String>();
    //         for(String part : partsPreliminary) {
    //             parts.addAll(part.split('}'));
    //         }
    //         for (String part : parts) {
    //             if (part.startsWith('!')
    //             && !part.contains(' ')
    //             && part.contains('.')) {
    //                 part = part.removeStart('!');
    //                 List<String> objectFields = part.split('\\.', 2);
    //                 if (objectApiName == objectFields[0]
    //                 && !additionalFieldApiNames.contains(objectFields[1])) {
    //                     additionalFieldApiNames.add(objectFields[1]);
    //                 }
    //             }
    //         }
    //     return additionalFieldApiNames;
    // }

    public static List<Messaging.SingleEmailMessage> createMails(List<SObject> objects, String objectApiName, String emailFieldApiName, List<EmailTemplate> templates) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (SObject objectItem : objects) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (!templates.isEmpty()) {
                mail = Messaging.renderStoredEmailTemplate(templates[0].Id, null, objectItem.Id);
                mail.saveAsActivity = false;
                // mail.setSubject(getEmailFields(templates[0].Subject, objectItem, objectApiName));
                // mail.setPlainTextBody(getEmailFields(templates[0].Body, objectItem, objectApiName));
                // mail.setHtmlBody(getEmailHTMLFields(templates[0].Body, objectItem, objectApiName));
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

    // public static String getEmailFields(String templateField, SObject objectItem, String objectApiName) {
    //     List<String> partsPreliminary = templateField.split('\\{');
    //     List<String> parts = new List<String>();
    //     for(String part : partsPreliminary) {
    //         parts.addAll(part.split('}'));
    //         }
    //     List<String> partsFinally = new List<String>();
    //     for (String part : parts) {
    //         if (part.startsWith('!')
    //             && !part.contains(' ')
    //             && part.contains('.')) {
    //             part = part.removeStart('!');
    //             List<String> objectFields = part.split('\\.');
    //             if (objectApiName == objectFields[0]) {
    //                 Map<String, Object> objectItemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objectItem));
    //                 Object value;
    //                 for (Integer i=1; i < objectFields.size(); i++){
    //                     value = objectItemMap.get(objectFields[i]);
    //                     if (i < objectFields.size()-1){
    //                         objectItemMap.clear();
    //                         objectItemMap = (Map<String, Object>) value;
    //                     }
    //                 }
    //                 part = String.valueOf(value);
    //             }
    //         }
    //         partsFinally.add(part);
    //     }
    //     String newTemplateField = '';
    //     for (String part : partsFinally) {
    //         newTemplateField = newTemplateField + part;
    //     }
    //     return newTemplateField;
    // }

    // public static String getEmailHTMLFields(String templateField, SObject objectItem, String objectApiName) {
    //     System.debug(templateField.escapeHtml4());
    //     List<String> partsPreliminary = templateField.split('\\{');
    //     List<String> parts = new List<String>();
    //     for(String part : partsPreliminary) {
    //         parts.addAll(part.split('}'));
    //         }
    //     List<String> partsFinally = new List<String>();
    //     for (String part : parts) {
    //         if (part.startsWith('!')
    //             && !part.contains(' ')
    //             && part.contains('.')) {
    //             part = part.removeStart('!');
    //             List<String> objectFields = part.split('\\.');
    //             if (objectApiName == objectFields[0]) {
    //                 Map<String, Object> objectItemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objectItem));
    //                 Object value;
    //                 for (Integer i=1; i < objectFields.size(); i++){
    //                     value = objectItemMap.get(objectFields[i]);
    //                     if (i < objectFields.size()-1){
    //                         objectItemMap.clear();
    //                         objectItemMap = (Map<String, Object>) value;
    //                     }
    //                 }
    //                 if (objectFields.size() <= 2) {
    //                     part = '<b>' + String.valueOf(value) + '</b>';
    //                 } else {
    //                     System.debug(objectItemMap);
    //                     System.debug(objectFields);
    //                     part = '<a href=https://eventreg1-myeanspace.cs89.force.com/s/detail/' + String.valueOf(objectItemMap.get('Id')) + '>'  + String.valueOf(value) + '</a>';
    //                 }
                    
    //             }
    //         }
    //         partsFinally.add(part);
    //     }
    //     String newTemplateField = '';
    //     for (String part : partsFinally) {
    //         newTemplateField = newTemplateField + part;
    //     }
    //     return newTemplateField;
    // }
}