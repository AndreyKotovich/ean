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
        String statusCanceled = 'Canceled';
        String statusRegistered = 'Registered';
        String undefinedParticipant = 'Undefined Participant';
        Map<ID, Participant__c> participantsMap = new Map<ID, Participant__c>([
            SELECT Id, Name, Event_Registration_Sub_Group__r.Is_Locked__c, Contact__r.Name FROM Participant__c WHERE Id IN :newParticipantsMap.keySet()
        ]);
        Map<String, Participant__c> deleteQRCodeParticipantsMap = new Map<String, Participant__c>();
        Map<String, Participant__c> refreshQRCodeParticipantsMap = new Map<String, Participant__c>();
        for (Participant__c participant : newParticipantsMap.values()) {
            if (participant.Status__c == statusCanceled && oldParticipantsMap.get(participant.Id).Status__c != participant.Status__c) {
                //Participant status changed to canceled
                deleteQRCodeParticipantsMap.put(participant.Id, participant); 
            } else if (participant.Status__c == statusRegistered
            && participant.Contact__c != oldParticipantsMap.get(participant.Id).Contact__c) {
                if (String.isBlank(participant.Event_Registration_Sub_Group__c)) {
                    //Solo participant with status registered changed contact
                    refreshQRCodeParticipantsMap.put(participant.Id, participant);
                } else if (participantsMap.get(participant.Id).Event_Registration_Sub_Group__r.Is_Locked__c) {
                    //Group participant with status registered changed contact
                    refreshQRCodeParticipantsMap.put(participant.Id, participant); 
                }                
            } else if (participant.Status__c == statusRegistered
            && oldParticipantsMap.get(participant.Id).Status__c != participant.Status__c
            && String.isBlank(participant.Event_Registration_Sub_Group__c)
            ) {
                //Solo participant status changed to registered
                refreshQRCodeParticipantsMap.put(participant.Id, participant); 
            } else if (participant.Status__c == statusRegistered
            && participant.Participant_Email__c != oldParticipantsMap.get(participant.Id).Participant_Email__c
            && participantsMap.get(participant.Id).Contact__r.Name == undefinedParticipant
            ) {
                if (participantsMap.get(participant.Id).Event_Registration_Sub_Group__r.Is_Locked__c) {
                    //Undefined group participant with status registered changed participant email
                    refreshQRCodeParticipantsMap.put(participant.Id, participant); 
                }
            } else if (participant.QR_Code_needed__c == true
                    && participant.QR_Code_needed__c != oldParticipantsMap.get(participant.Id).QR_Code_needed__c) {
                    refreshQRCodeParticipantsMap.put(participant.Id, participant);
            }
        }
        if (deleteQRCodeParticipantsMap.size() > 0) {
            processDeleteQRCodeParticipants(deleteQRCodeParticipantsMap);
        }
        if (refreshQRCodeParticipantsMap.size() > 0) {
            processDeleteQRCodeParticipants(refreshQRCodeParticipantsMap);
            processRefreshQRCodeParticipants(refreshQRCodeParticipantsMap);
        }
    }

    public static void processDeleteQRCodeParticipants(Map<String, Participant__c> participantsMap) {
        List<ContentDocumentLink> conDocLinks = [
            SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :participantsMap.keySet()
        ];
        List<String> contentDocumentIds = new List<String>();
        for (ContentDocumentLink conDocLink : conDocLinks) {
            contentDocumentIds.add(conDocLink.ContentDocumentId);
        }
        List<ContentDocument> contentDocuments = [
            SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds AND Title LIKE 'QR code%'
        ];
        if (contentDocuments.size() > 0) {
            delete contentDocuments;
        }
        List<Event_Badge__c> badges = [
            SELECT Id FROM Event_Badge__c WHERE Event_Participation__c IN :participantsMap.keySet()
        ];
        if (badges.size() > 0) {
            delete badges;
        }
    }

    public static void processRefreshQRCodeParticipants(Map<String, Participant__c> refreshQRCodeParticipantsMap) {
        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        for (String participantId : refreshQRCodeParticipantsMap.keySet()) {
            refreshQRCodeParticipantsMap.get(participantId).QR_Code_needed__c = true;
            Event_Badge__c badge = new Event_Badge__c();
            badge.Event_Participation__c = participantId;
            badges.add(badge);
        }
        if (badges.size() > 0) {
            insert badges;
        }
        try {
            startQRcodeBatch();
        } catch (Exception error) {
            System.debug(error);
        }
    }

    public static void processNewParticipants(List<Participant__c> newParticipants) {
        String statusRegistered = 'Registered';
        for (Participant__c newParticipant : newParticipants) {
            if (newParticipant.Status__c == statusRegistered && String.isBlank(newParticipant.Event_Registration_Sub_Group__c)) {
                newParticipant.QR_Code_needed__c = true;
            }
        }
    }

    public static void createBadges(List<Participant__c> newParticipants) {
        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        for (Participant__c newParticipant : newParticipants) {
            if (newParticipant.QR_Code_needed__c == true) {
                Event_Badge__c badge = new Event_Badge__c();
                badge.Event_Participation__c = newParticipant.Id;
                badges.add(badge);
            }
        }
        if(badges.size() > 0) {
            insert badges;
            try {
                startQRcodeBatch();
            } catch (Exception error) {
                System.debug(error);
            }
        }        
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