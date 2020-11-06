public with sharing class ParticipantTriggerHelper {
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
}