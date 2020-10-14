public with sharing class EAN_EmailController {
    public EAN_EmailController() {

    }
    @AuraEnabled
    public static void sendEmailToParticipants(List<String> participantIds, String templateId) {
        List<Participant__c> participants = [
            SELECT Contact__r.Email, Contact__r.Name, Participant_Email__c, deleted__c, Event_custom__c
            FROM Participant__c
            WHERE Id IN :participantIds
        ];
        List<String> toAddresses = new List<String>();
        List<Participant__c> emptyEmailParticipants = new List<Participant__c>();
        for (Participant__c participant : participants) {
            if (String.isNotBlank(participant.Contact__r.Email)) {
                toAddresses.add(participant.Contact__r.Email);
            } else if (String.isNotBlank(participant.Participant_Email__c)) {
                toAddresses.add(participant.Participant_Email__c);
            } else {
                emptyEmailParticipants.add(participant);
            }
        }
        EmailTemplate template = [
            SELECT Id, Name, Description, Subject, Body, HtmlValue
            FROM EmailTemplate
            WHERE Id = :templateId
        ];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setToAddresses(toAddresses);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch(Exception error){
            System.debug(error);
        }
    }
}