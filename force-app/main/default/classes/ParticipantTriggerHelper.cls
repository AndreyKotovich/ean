public without sharing class ParticipantTriggerHelper {

    public ParticipantTriggerHelper() {

    }
    public static void soloParticipantRegistration(List<String> soloParticipantIds) {
        System.debug('method soloParticipantRegistration');
        System.debug('soloParticipantIds --> ' + soloParticipantIds);
        List<Participant__c> participants = [
            SELECT Id,Contact__r.Email, Event_custom__c, Participant_Email__c FROM Participant__c WHERE Id IN :soloParticipantIds
        ];
        System.debug('participants --> ' + participants);
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
        }
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
            System.debug('emailActivity --> ' + emailActivity);
        }
        if (emailActivities.size() > 0) {
            System.debug('emailActivities --> ' + emailActivities);
            insert emailActivities;
            System.debug('insert success');
        }
    }

    public static void groupParticipantRegistration(List<String> groupParticipantIds) {
        System.debug('method groupParticipantRegistration');
        System.debug('groupParticipantIds --> ' + groupParticipantIds);
        List<Participant__c> participants = [
            SELECT Id, Event_custom__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email FROM Participant__c WHERE Id IN :groupParticipantIds
        ];
        System.debug('participants --> ' + participants);
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
        }
        Set<String> groupIdsSet = new Set<String>();
        for (Participant__c participant : participants) {
            groupIdsSet.add(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id);
        }
        System.debug('groupIdsSet --> ' + groupIdsSet);
        List<Event_Registration_Group__c> eventGroups = [
            SELECT Id, (SELECT Id FROM Event_Registration_Sub_Groups__r) FROM Event_Registration_Group__c WHERE Id IN :groupIdsSet
        ];
        System.debug('eventGroups --> ' + eventGroups);
        for (Event_Registration_Group__c eventGroup : eventGroups) {
            System.debug('eventGroup --> ' + eventGroup);
        }
        Set<String> createdGroupIdsSet = new Set<String>();
        Set<String> participantAddedGroupIdsSet = new Set<String>();
        for (Event_Registration_Group__c eventGroup : eventGroups) {
            if (eventGroup.Event_Registration_Sub_Groups__r.size() == 1) {
                createdGroupIdsSet.add(eventGroup.Id);
            } else if (eventGroup.Event_Registration_Sub_Groups__r.size() > 1) {
                participantAddedGroupIdsSet.add(eventGroup.Id);
            }
        }
        System.debug('createdGroupIdsSet --> ' + createdGroupIdsSet);
        System.debug('participantAddedGroupIdsSet --> ' + participantAddedGroupIdsSet);
        Map<String, List<Participant__c>> groupIdToParticipantsMap = new Map<String, List<Participant__c>>();
        for (Participant__c participant : participants) {
            if (groupIdToParticipantsMap.containsKey(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c) == false) {
                groupIdToParticipantsMap.put(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c, new List<Participant__c>());
            }
            groupIdToParticipantsMap.get(participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c).add(participant);
        }
        System.debug('groupIdToParticipantsMap --> ' + groupIdToParticipantsMap);
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (String groupId : createdGroupIdsSet) {
            Email_Activity__c emailActivity = new Email_Activity__c(
                Contact__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c,
                Event_Custom__c = groupIdToParticipantsMap.get(groupId)[0].Event_custom__c,
                Event_Participation__c = groupIdToParticipantsMap.get(groupId)[0].Id,
                Send_To_Email__c = groupIdToParticipantsMap.get(groupId)[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Email,
                Type__c = 'Group registration success'
            );
            System.debug('emailActivity --> ' + emailActivity);
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
            System.debug('emailActivity --> ' + emailActivity);
            emailActivities.add(emailActivity);
        }
        System.debug('emailActivities --> ' + emailActivities);
        insert emailActivities;
        System.debug('insert success');
    }

    public static void checkQRCode(Map<Id, Participant__c> newParticipantsMap, Map<Id, Participant__c> oldParticipantsMap) {
        for (Id newParticipantId : newParticipantsMap.keySet()) {
            System.debug('newParticipant --> ' + newParticipantsMap.get(newParticipantId));
            System.debug('oldParticipant --> ' + oldParticipantsMap.get(newParticipantId));
        }
        System.debug('method checkQRCode');
        String statusRegistered = 'Registered';
        Map<String, Participant__c> getQRCodeParticipantsMap = new Map<String, Participant__c>();
        
        for (Participant__c participant : newParticipantsMap.values()) {
            if (participant.Status__c == statusRegistered
                    && oldParticipantsMap.get(participant.Id).Status__c != participant.Status__c) {
                //Solo and Group participant status changed to registered
                System.debug('Solo and Group participant status changed to registered');
                System.debug('participant --> ' + participant);
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && participant.QR_Code_needed__c == true
                    && participant.QR_Code_needed__c != oldParticipantsMap.get(participant.Id).QR_Code_needed__c) {
                //Registered solo and Group participant that need QR code
                System.debug('Registered solo and Group participant that need QR code');
                System.debug('participant --> ' + participant);
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && participant.Contact__c != oldParticipantsMap.get(participant.Id).Contact__c) {
                //Solo and Group participant contact changed
                System.debug('Solo and Group participant contact changed');
                System.debug('participant --> ' + participant);
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && String.isNotBlank(participant.Event_Registration_Sub_Group__c)
                    && participant.Participant_Email__c != oldParticipantsMap.get(participant.Id).Participant_Email__c) {
                //Group participant email changed
                System.debug('Group participant email changed');
                System.debug('participant --> ' + participant);
                getQRCodeParticipantsMap.put(participant.Id, participant);
            }
        }
        if (getQRCodeParticipantsMap.size() > 0) {
            processGetQRCodeParticipants(getQRCodeParticipantsMap);
        }
    }

    public static void processGetQRCodeParticipants(Map<String, Participant__c> getQRCodeParticipantsMap) {
        System.debug('method processGetQRCodeParticipants');
        System.debug('getQRCodeParticipantsMap --> ' + getQRCodeParticipantsMap);
        for (String participantId : getQRCodeParticipantsMap.keySet()) {
            System.debug('participant --> ' + getQRCodeParticipantsMap.get(participantId));
        }
        List<Participant__c> QRCodeNeededParticipants = [
            SELECT Id, Event_custom__c, Participant_Email__c, Event_Ticket__r.Participation__c, Contact__r.Email
            FROM Participant__c
            WHERE Id IN :getQRCodeParticipantsMap.keySet()
        ];
        System.debug('QRCodeNeededParticipants --> ' + QRCodeNeededParticipants);
        for (Participant__c participant : QRCodeNeededParticipants) {
            System.debug('participant --> ' + participant);
        }
        List<String> createBadgeParticipantIds = new List<String>();
        List<Participant__c> submitedGroupParticipants = new List<Participant__c>();
        for (Participant__c participant : QRCodeNeededParticipants) {
            System.debug('participant --> ' + participant);
            if (participant.Event_Ticket__r.Participation__c == 'Onsite'
                && String.isBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)) {
                getQRCodeParticipantsMap.get(participant.Id).QR_Code_needed__c = true;
                createBadgeParticipantIds.add(participant.Id);
                System.debug('need QR code participant');
                System.debug('participant --> ' + participant);
            } else if (participant.Event_Ticket__r.Participation__c == 'Onsite'
                    && String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)
                    && String.isNotBlank(participant.Contact__r.Email)) {
                getQRCodeParticipantsMap.get(participant.Id).QR_Code_needed__c = true;
                createBadgeParticipantIds.add(participant.Id);
                System.debug('need QR code participant');
                System.debug('participant --> ' + participant);
            }
            if (String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)
                    && (String.isNotBlank(participant.Contact__r.Email) || String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Participant_Email__c))) {
                submitedGroupParticipants.add(participant);
                System.debug('submited group participant');
                System.debug('participant --> ' + participant);
            }
        }
        if (submitedGroupParticipants.size() > 0) {
            sendEmailToSubmitedGroupParticipants(submitedGroupParticipants);
        }
        if (createBadgeParticipantIds.size() > 0) {
            createBadges(createBadgeParticipantIds);
        }
    }

    public static void sendEmailToSubmitedGroupParticipants(List<Participant__c> submitedGroupParticipants) {
        System.debug('method sendEmailToSubmitedGroupParticipants');
        System.debug('submitedGroupParticipants --> ' + submitedGroupParticipants);
        for (Participant__c participant : submitedGroupParticipants) {
            System.debug('participant --> ' + participant);
        }
        List<Email_activity__c> emailActivities = new List<Email_activity__c>();
        for (Participant__c partisipant : submitedGroupParticipants) {
            Email_activity__c emailActivity = new Email_activity__c();
            emailActivity.Event_Participation__c = partisipant.Id;
            emailActivity.Contact__c = partisipant.Contact__c;
            emailActivity.Event_custom__c = partisipant.Event_custom__c;
            if (String.isBlank(partisipant.Contact__r.Email)) {
                emailActivity.Send_to_email__c = partisipant.Participant_Email__c;
                emailActivity.Type__c = 'Undefined group participant submited';
            } else {
                emailActivity.Send_to_email__c = partisipant.Contact__r.Email;
                emailActivity.Type__c = 'Group participant submited';
            }
            System.debug('emailActivity --> ' + emailActivity);
            emailActivities.add(emailActivity);
        }
        insert emailActivities;
        System.debug('emailActivities --> ' + emailActivities);
        System.debug('emailActivities.size --> ' + emailActivities.size());
    }

    public static void processNewParticipants(List<Participant__c> newParticipants) {
        System.debug('method processNewParticipants');
        System.debug('newParticipants --> ' + newParticipants);
        for (Participant__c newParticipant : newParticipants) {
            System.debug('newParticipant --> ' + newParticipant);
        }
        String statusRegistered = 'Registered';
        List<String> ticketIds = new List<String>();
        Set<String> contactIdsSet = new Set<String>();
        for (Participant__c newParticipant : newParticipants) {
            ticketIds.add(newParticipant.Event_Ticket__c);
            contactIdsSet.add(newParticipant.Contact__c);
        }
        System.debug('ticketIds --> ' + ticketIds);
        System.debug('contactIdsSet --> ' + contactIdsSet);
        Map<Id, Event_Ticket__c> eventTicketsMap = new Map<Id, Event_Ticket__c>([
            SELECT Id, Participation__c FROM Event_Ticket__c WHERE Id IN :ticketIds
        ]);
        System.debug('eventTicketsMap --> ' + eventTicketsMap);
        for (Id eventTicketId : eventTicketsMap.keySet()) {
            System.debug('eventTicket --> ' + eventTicketsMap.get(eventTicketId));
        }
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([
            SELECT Id, Email FROM Contact WHERE Id IN :contactIdsSet
        ]);
        System.debug('contactsMap --> ' + contactsMap);
        for (Id contactId : contactsMap.keySet()) {
            System.debug('contact --> ' + contactsMap.get(contactId));
        }
        for (Participant__c newParticipant : newParticipants) {
            if (eventTicketsMap.containsKey(newParticipant.Event_Ticket__c)) {
                if (newParticipant.Status__c == statusRegistered 
                && String.isBlank(newParticipant.Event_Registration_Sub_Group__c)
                && eventTicketsMap.get(newParticipant.Event_Ticket__c).Participation__c == 'Onsite') {
                    newParticipant.QR_Code_needed__c = true;
                    System.debug('need QR code participant');
                    System.debug('newParticipant --> ' + newParticipant);
                } else if (newParticipant.Status__c == statusRegistered 
                && String.isNotBlank(newParticipant.Event_Registration_Sub_Group__c)
                && eventTicketsMap.get(newParticipant.Event_Ticket__c).Participation__c == 'Onsite'
                && (contactsMap.get(newParticipant.Contact__c).Email != null || newParticipant.Participant_Email__c != null)) {
                    newParticipant.QR_Code_needed__c = true;
                    System.debug('need QR code participant');
                    System.debug('newParticipant --> ' + newParticipant);
                }
            }
        }
    }

    public static void updateParticipant(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        System.debug('method updateParticipant after contact update');
        Map<String, String> changedEmailToContactIdMap = new Map<String, String>();
        Map<String, String> contactIdToChangedEmailMap = new Map<String, String>();
        for (Contact newContact : newContacts) {
            if (newContact.Email != oldContactsMap.get(newContact.Id).Email
                && String.isNotBlank(newContact.Email)) {
                    changedEmailToContactIdMap.put(newContact.Email, newContact.Id);
                    contactIdToChangedEmailMap.put(newContact.Id, newContact.Email);
                }
        }
        System.debug('contactIdToChangedEmailMap --> ' + contactIdToChangedEmailMap);
        List<Participant__c> participants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Participant_Email__c IN : changedEmailToContactIdMap.keySet()
        ];
        System.debug('participants Email as Contact Email--> ' + participants);
        System.debug('participants.size --> ' + participants.size());
        List<Participant__c> updateParticipants = new List<Participant__c>();
        if (participants.size() > 0) {
            for (Participant__c participant : participants) {
                if (String.isBlank(participant.Contact__r.Email)) {
                    participant.Contact__c = changedEmailToContactIdMap.get(participant.Participant_Email__c);
                    updateParticipants.add(participant);
                    System.debug('participant Contact change--> ');
                    System.debug('participant --> ' + participant);
                    
                }
            }
        }
        List<Participant__c> emailChangedParticipants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Contact__c IN :contactIdToChangedEmailMap.keySet()
            AND Contact__r.Email != null
        ];
        System.debug('participants Contact Email changed --> ' + emailChangedParticipants);
        if (emailChangedParticipants.size() > 0) {
            for (Participant__c emailChangedParticipant : emailChangedParticipants) {
                emailChangedParticipant.Participant_Email__c = contactIdToChangedEmailMap.get(emailChangedParticipant.Contact__c);
                updateParticipants.add(emailChangedParticipant);
                System.debug('participant Contact Email change --> ');
                System.debug('emailChangedParticipant --> ' + emailChangedParticipant);
            }
        }
        if(updateParticipants.size() > 0) {
            update updateParticipants;
            System.debug('Update participant Contact Email change --> ');
            System.debug('updateParticipants --> ' + updateParticipants);
        }
    }

    public static void updateParticipant(List<Contact> contacts) {
        System.debug('method updateParticipant after contact insert');
        Map<String, String> emailToContactIdMap = new Map<String, String>();
        for (Contact contact : contacts) {
            if (String.isNotBlank(contact.Email)) {
                emailToContactIdMap.put(contact.Email, contact.Id);
            }
        }
        System.debug('emailToContactIdMap --> ' + emailToContactIdMap);
        List<Participant__c> participants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Participant_Email__c IN :emailToContactIdMap.keySet()
        ];
        System.debug('participants with Email as contact email --> ' + participants);
        System.debug('participants.size with Email as contact email --> ' + participants.size());
        List<Participant__c> updateParticipants = new List<Participant__c>();
        if (participants.size() > 0) {
            for (Participant__c participant :participants) {
                if (String.isBlank(participant.Contact__r.Email)
                    && emailToContactIdMap.containsKey(participant.Participant_Email__c)) {
                    participant.Contact__c = emailToContactIdMap.get(participant.Participant_Email__c);
                    updateParticipants.add(participant);
                    System.debug('participant Contact change --> ');
                    System.debug('participant --> ' + participant);
                }
            }
        }
        if (updateParticipants.size() > 0) {
            update updateParticipants;
            System.debug('update');
            System.debug('updateParticipants --> ' + updateParticipants);
        }
    }

    public static void createBadges(List<String> participantIds) {
        System.debug('method createBadges');
        System.debug('participantIds --> ' + participantIds);
        List<Participant__c> participants = [
            SELECT Id, (SELECT Id FROM Event_Badges__r) FROM Participant__c WHERE Id IN :participantIds
        ];
        System.debug('participants --> ' + participants);
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
        }
        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
            if (participant.Event_Badges__r.size() == 0) {
                Event_Badge__c badge = new Event_Badge__c();
                badge.Event_Participation__c = participant.Id;
                badges.add(badge);
                System.debug('badge --> ' + badge);
            }
        }
        if(badges.size() > 0) {
            insert badges;
            System.debug('insert badges');
        }
        startQRcodeBatch();
    }

    public static void startQRcodeBatch() {
        System.debug('startQRcodeBatch');
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
                System.debug('running job aborted');
            }
        }
        if (isBatchWorking == false) {
            System.scheduleBatch(new QRcodeBatch(), jobName, 2, 70);
            System.debug('start new job');
        } else {
            System.debug('job allredy running');
        }
    }
}