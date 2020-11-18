public without sharing class QRcodeBatchReminder implements Database.Batchable<Participant__c>, Database.Stateful, Database.AllowsCallouts{
    public QRcodeBatchReminder(String jobName) {
        this.eventName = jobName.remove('QR code reminder ');
    }
    public String eventName;

    public List<Participant__c> start(Database.BatchableContext bc) {
        String statusRegistered = 'Registered';
        String onSiteBadgeRetrieval = 'onsite';
        String onSiteParticipation = 'Onsite';
        List<Participant__c> participants = [
            SELECT Id, Name, Event_custom__c, Participant_Email__c, Contact__r.Email
            FROM Participant__c 
            WHERE Status__c = :statusRegistered
            AND Event_custom__r.Name = :this.eventName
            AND Badge_Retrieval__c = :onSiteBadgeRetrieval
            AND Event_Ticket__r.Participation__c = :onSiteParticipation
        ];
        return participants;
    }

    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Participant__c participant : participants) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = participant.Contact__c,
                Event_Custom__c = participant.Event_custom__c,
                Event_Participation__c = participant.Id,
                Type__c = 'QR code for participant reminder'
            );
            if (String.isBlank(participant.Contact__r.Email)) {
                emailActivity.Send_To_Email__c = participant.Participant_Email__c;
            } else {
                emailActivity.Send_To_Email__c = participant.Contact__r.Email;
            }
            emailActivities.add(emailActivity);              
        }
        insert emailActivities;
    }
    public void finish(Database.BatchableContext BC) {

    }
}