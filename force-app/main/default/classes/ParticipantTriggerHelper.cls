public without sharing class ParticipantTriggerHelper {

    public ParticipantTriggerHelper() {

    }
    public static void soloParticipantRegistration(List<String> soloParticipantIds) {
        List<Participant__c> participants = [
            SELECT Id,Contact__r.Email, Event_custom__c, Participant_Email__c FROM Participant__c WHERE Id IN :soloParticipantIds
        ];
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Participant__c participant : participants) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = participant.Contact__c,
                Event_Custom__c = participant.Event_custom__c,
                Event_Participation__c = participant.Id,
                Type__c = 'Solo registration success'
            );
            if (String.isNotBlank(participant.Contact__r.Email)) {
                emailActivity.Send_To_Email__c = participant.Contact__r.Email;
            } else {
                emailActivity.Send_To_Email__c = participant.Participant_Email__c;
            }
            emailActivities.add(emailActivity);
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
        }
    }

    public static void groupParticipantRegistration(List<String> groupParticipantIds) {
        List<Participant__c> participants = [
            SELECT Id, Event_custom__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email FROM Participant__c WHERE Id IN :groupParticipantIds
        ];
        Set<String> groupIdsSet = new Set<String>();
        for (Participant__c participant : participants) {
            groupIdsSet.add(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id);
        }
        List<Event_Registration_Group__c> eventGroups = [
            SELECT Id, (SELECT Id FROM Event_Registration_Sub_Groups__r) FROM Event_Registration_Group__c WHERE Id IN :groupIdsSet
        ];
        Set<String> createdGroupIdsSet = new Set<String>();
        Set<String> participantAddedGroupIdsSet = new Set<String>();
        for (Event_Registration_Group__c eventGroup : eventGroups) {
            if (eventGroup.Event_Registration_Sub_Groups__r.size() == 1) {
                createdGroupIdsSet.add(eventGroup.Id);
            } else if (eventGroup.Event_Registration_Sub_Groups__r.size() > 1) {
                participantAddedGroupIdsSet.add(eventGroup.Id);
            }
        }
        Map<String, List<Participant__c>> groupIdToParticipantsMap = new Map<String, List<Participant__c>>();
        for (Participant__c participant : participants) {
            if (groupIdToParticipantsMap.containsKey(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c) == false) {
                groupIdToParticipantsMap.put(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c, new List<Participant__c>());
            }
            groupIdToParticipantsMap.get(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c).add(participant);
        }
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (String groupId : createdGroupIdsSet) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c,
                Event_Custom__c = groupIdToParticipantsMap.get(groupId)[0].Event_custom__c,
                Event_Participation__c = groupIdToParticipantsMap.get(groupId)[0].Id,
                Send_To_Email__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email,
                Type__c = 'Group registration success'
            );
            emailActivities.add(emailActivity);
        }
        for (String groupId : participantAddedGroupIdsSet) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c,
                Event_Custom__c = groupIdToParticipantsMap.get(groupId)[0].Event_custom__c,
                Event_Participation__c = groupIdToParticipantsMap.get(groupId)[0].Id,
                Send_To_Email__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email,
                Type__c = 'Group participants added'
            );
            emailActivities.add(emailActivity);
        }
        insert emailActivities;
    }

    public static void checkQRCode(Map<Id, Participant__c> newParticipantsMap, Map<Id, Participant__c> oldParticipantsMap) {
        String statusRegistered = 'Registered';
        Map<String, Participant__c> getQRCodeParticipantsMap = new Map<String, Participant__c>();
        for (Participant__c participant : newParticipantsMap.values()) {
            if (participant.Status__c == statusRegistered
            && oldParticipantsMap.get(participant.Id).Status__c != participant.Status__c
            && String.isBlank(participant.Event_Registration_Sub_Group__c)
            ) {
                //Solo participant status changed to registered
                getQRCodeParticipantsMap.put(participant.Id, participant); 
            } else if (participant.QR_Code_needed__c == true
                    && participant.QR_Code_needed__c != oldParticipantsMap.get(participant.Id).QR_Code_needed__c) {
                    //Group participants subgroup locked
                    getQRCodeParticipantsMap.put(participant.Id, participant);
            }
        }
        if (getQRCodeParticipantsMap.size() > 0) {
            processGetQRCodeParticipants(getQRCodeParticipantsMap);
        }
    }

    // public static void processDeleteQRCodeParticipants(Map<String, Participant__c> participantsMap) {
    //     List<ContentDocumentLink> conDocLinks = [
    //         SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :participantsMap.keySet()
    //     ];
    //     List<String> contentDocumentIds = new List<String>();
    //     for (ContentDocumentLink conDocLink : conDocLinks) {
    //         contentDocumentIds.add(conDocLink.ContentDocumentId);
    //     }
    //     List<ContentDocument> contentDocuments = [
    //         SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds AND Title LIKE 'QR code%'
    //     ];
    //     if (contentDocuments.size() > 0) {
    //         delete contentDocuments;
    //     }
    //     List<Event_Badge__c> badges = [
    //         SELECT Id FROM Event_Badge__c WHERE Event_Participation__c IN :participantsMap.keySet()
    //     ];
    //     if (badges.size() > 0) {
    //         delete badges;
    //     }
    // }

    public static void processGetQRCodeParticipants(Map<String, Participant__c> getQRCodeParticipantsMap) {
        List<Participant__c> QRCodeNeededParticipants = [
            SELECT Id, Event_Ticket__r.Participation__c FROM Participant__c WHERE Id IN :getQRCodeParticipantsMap.keySet()
        ];
        List<String> createBadgeParticipantIds = new List<String>();
        for (Participant__c participant : QRCodeNeededParticipants) {
            if (participant.Event_Ticket__r.Participation__c == 'Onsite') {
                getQRCodeParticipantsMap.get(participant.Id).QR_Code_needed__c = true;
                createBadgeParticipantIds.add(participant.Id);
            }
        }
        createBadges(createBadgeParticipantIds);
    }

    public static void processNewParticipants(List<Participant__c> newParticipants) {
        String statusRegistered = 'Registered';
        List<String> ticketIds = new List<String>();
        for (Participant__c newParticipant : newParticipants) {
            ticketIds.add(newParticipant.Event_Ticket__c);
        }
        Map<Id, Event_Ticket__c> eventTicketsMap = new Map<Id, Event_Ticket__c>([
            SELECT Id, Participation__c FROM Event_Ticket__c WHERE Id IN :ticketIds
        ]);
        List<String> createBadgeParticipantIds = new List<String>();
        for (Participant__c newParticipant : newParticipants) {
            if (eventTicketsMap.containsKey(newParticipant.Event_Ticket__c)) {
                if (newParticipant.Status__c == statusRegistered 
                && String.isBlank(newParticipant.Event_Registration_Sub_Group__c)
                && eventTicketsMap.get(newParticipant.Event_Ticket__c).Participation__c == 'Onsite') {
                    newParticipant.QR_Code_needed__c = true;
                }
            }
        }
    }

    public static void createBadges(List<String> participantIds) {
        List<Participant__c> participants = [
            SELECT Id, (SELECT Id FROM Event_Badges__r) FROM Participant__c WHERE Id IN :participantIds
        ];
        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        for (Participant__c participant : participants) {
            if (participant.Event_Badges__r.size() == 0) {
                Event_Badge__c badge = new Event_Badge__c();
                badge.Event_Participation__c = participant.Id;
                badges.add(badge);
            }
        }
        if(badges.size() > 0) {
            insert badges;
        }
        startQRcodeBatch();
    }

    public static void startQRcodeBatch() {
        String jobName = 'get QR codes';
        List<CronTrigger> waitingJobs = [SELECT Id, CronJobDetail.Name, NextFireTime, State
                                FROM CronTrigger
                                WHERE CronJobDetail.Name = :jobName];
        Boolean isBatchWorking = false;
        for (CronTrigger waitingJob : waitingJobs) {
            if (waitingJob.NextFireTime < System.now().addMinutes(3) 
            && waitingJob.NextFireTime > System.now().addSeconds(-30)
            && waitingJob.CronJobDetail.Name == jobName){
                isBatchWorking = true;
            } else if (waitingJob.CronJobDetail.Name == jobName){
                System.abortJob(waitingJob.Id);
            }
        }
        if (isBatchWorking == false) {
            System.scheduleBatch(new QRcodeBatch(), jobName, 2, 70);
        }
    }
}