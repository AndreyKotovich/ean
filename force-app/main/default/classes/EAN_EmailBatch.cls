public with sharing class EAN_EmailBatch implements Database.Batchable<SObject>, Database.Stateful {
    private String emailTemplateDevName = 'EAN_Group_Leader_Reminder';
    String status = 'Registered';
    String undefinedContactName = 'Undefined Participant';
    Date currentDate = Date.today();
    Integer startMailBeforeEventDays = 3000;
    Integer stopMailBeforeEventDays = 1;
    public Set<String> groupId; 
    public EAN_EmailBatch() {
        this.groupId = new Set<String>();
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String status = this.status;
        String undefinedContactName = this.undefinedContactName;
        Datetime currentDatetime = Datetime.newInstance(this.currentDate, Time.newInstance(0, 0, 0, 0));
        Datetime emailStartDayCheck = currentDatetime.addDays(this.startMailBeforeEventDays);
        Datetime emailEndDayCheck = currentDatetime.addDays(this.stopMailBeforeEventDays);
        return Database.getQueryLocator(
            'SELECT Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name, Event_Registration_Sub_Group__r.Event_Registration_Group__c FROM Participant__c WHERE Event_custom__r.Start_Time__c < :emailStartDayCheck AND Event_custom__r.Start_Time__c > :emailEndDayCheck AND Status__c = :status  AND Event_Registration_Sub_Group__c != null AND Contact__r.Name = :undefinedContactName'
            );
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Map<String, List<Participant__c>> participantsToGroupLeaderMap = new Map<String, List<Participant__c>>();
        for(Participant__c participant : participants) {
            if (this.groupId.contains(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c) == false) {
                if (participantsToGroupLeaderMap.containsKey(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c) == false) {
                List<Participant__c> participantsGroup = new List<Participant__c>();
                participantsToGroupLeaderMap.put(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, participantsGroup);                
            }
            participantsToGroupLeaderMap.get(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c).add(participant);
            this.groupId.add(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c);
            }         
        }
        for (String contactId : participantsToGroupLeaderMap.keySet()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :this.emailTemplateDevName LIMIT 1];
            mail = Messaging.renderStoredEmailTemplate(emailTemplates[0].Id, contactId, participantsToGroupLeaderMap.get(contactId)[0].Event_Registration_Sub_Group__c);
            mail.saveAsActivity = false;
            List<String> toAddresses = new List<String>();
            toAddresses.add(participantsToGroupLeaderMap.get(contactId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email);
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Do not reply');
            mails.add(mail);
        }
        Messaging.sendEmail(mails);
    }
    public void finish(Database.BatchableContext BC) {

    }
}