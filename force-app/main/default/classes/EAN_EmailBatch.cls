public with sharing class EAN_EmailBatch implements Database.Batchable<Participant__c>, Database.Stateful {
    private final String status = 'Registered';
    Date currentDate = Date.today();
    Integer startMailBeforeEventDays = 150;
    Integer stopMailBeforeEventDays = 8;
    public Set<String> groupId; 
    public EAN_EmailBatch() {
        this.groupId = new Set<String>();
    }
    public List<Participant__c> start(Database.BatchableContext bc) {
        String status = this.status;
        Datetime currentDatetime = Datetime.newInstance(this.currentDate, Time.newInstance(0, 0, 0, 0));
        Datetime emailStartDayCheck = currentDatetime.addDays(this.startMailBeforeEventDays);
        Datetime emailEndDayCheck = currentDatetime.addDays(this.stopMailBeforeEventDays);
        List<Participant__c> participants = [
            SELECT Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email, Event_custom__c
            FROM Participant__c
            WHERE Event_custom__r.Start_Time__c < :emailStartDayCheck
            AND Event_custom__r.Start_Time__c > :emailEndDayCheck
            AND Status__c = :status 
            AND Event_Registration_Sub_Group__c != null
            AND Contact__r.Email = null
        ];
        return participants;
    }

    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        Map<String, List<Participant__c>> groupIdToPatrticipantsMap = new Map<String, List<Participant__c>>();
        for (Participant__c participant : participants) {
            if (this.groupId.contains(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c) == false) {
                if (!groupIdToPatrticipantsMap.containsKey(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c)) {
                List<Participant__c> groupParticipants = new List<Participant__c>();
                groupIdToPatrticipantsMap.put(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c, groupParticipants);                
            }
            groupIdToPatrticipantsMap.get(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c).add(participant);
            this.groupId.add(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c);
            }         
        }
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (String groupId : groupIdToPatrticipantsMap.keySet()) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = groupIdToPatrticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c,
                Event_Custom__c = groupIdToPatrticipantsMap.get(groupId)[0].Event_custom__c,
                Send_To_Email__c = groupIdToPatrticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email,
                Type__c = 'Reminder GR add participants'
            );
            emailActivities.add(emailActivity);
        }
        insert emailActivities;
    }

    public void finish(Database.BatchableContext BC) {
        String jobName = 'Reminder GR add participants';
            List<CronTrigger> QRcodeJobs = [SELECT Id
                                    FROM CronTrigger
                                    WHERE CronJobDetail.Name = :jobName];
            for (CronTrigger QRcodeJob : QRcodeJobs) {
                System.abortJob(QRcodeJob.Id);
            }
            System.scheduleBatch(new EAN_EmailBatch(), jobName, 10080);
    }
}