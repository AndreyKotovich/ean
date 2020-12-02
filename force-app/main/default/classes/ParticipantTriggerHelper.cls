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
                    && oldParticipantsMap.get(participant.Id).Status__c != participant.Status__c) {
                //Solo and Group participant status changed to registered
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && participant.QR_Code_needed__c == true
                    && participant.QR_Code_needed__c != oldParticipantsMap.get(participant.Id).QR_Code_needed__c) {
                //Registered solo and Group participant that need QR code
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && participant.Contact__c != oldParticipantsMap.get(participant.Id).Contact__c) {
                //Solo and Group participant contact changed
                getQRCodeParticipantsMap.put(participant.Id, participant);
            } else if (participant.Status__c == statusRegistered
                    && String.isNotBlank(participant.Event_Registration_Sub_Group__c)
                    && participant.Participant_Email__c != oldParticipantsMap.get(participant.Id).Participant_Email__c) {
                //Group participant email changed
                getQRCodeParticipantsMap.put(participant.Id, participant);
            }
        }
        if (getQRCodeParticipantsMap.size() > 0) {
            processGetQRCodeParticipants(getQRCodeParticipantsMap);
        }
    }

    public static void processGetQRCodeParticipants(Map<String, Participant__c> getQRCodeParticipantsMap) {
        List<Participant__c> QRCodeNeededParticipants = [
            SELECT Id, Event_custom__c, Participant_Email__c, Event_Ticket__r.Participation__c, Contact__r.Email
            FROM Participant__c
            WHERE Id IN :getQRCodeParticipantsMap.keySet()
        ];
        // List<String> createBadgeParticipantIds = new List<String>();
        List<Participant__c> submitedGroupParticipants = new List<Participant__c>();
        for (Participant__c participant : QRCodeNeededParticipants) {
            if (participant.Event_Ticket__r.Participation__c == 'Onsite'
                && String.isBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)) {
                getQRCodeParticipantsMap.get(participant.Id).QR_Code_needed__c = true;
                // createBadgeParticipantIds.add(participant.Id);
            } else if (participant.Event_Ticket__r.Participation__c == 'Onsite'
                    && String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)
                    && String.isNotBlank(participant.Contact__r.Email)) {
                getQRCodeParticipantsMap.get(participant.Id).QR_Code_needed__c = true;
                // createBadgeParticipantIds.add(participant.Id);
            }
            // if (String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Event_Registration_Sub_Group__c)
            //         && (String.isNotBlank(participant.Contact__r.Email) || String.isNotBlank(getQRCodeParticipantsMap.get(participant.Id).Participant_Email__c))) {
            //     submitedGroupParticipants.add(participant);
            // }
        }
        // if (submitedGroupParticipants.size() > 0) {
        //     sendEmailToSubmitedGroupParticipants(submitedGroupParticipants);
        // }

        //  moved to Trigger.isAfter && Trigger.isUpdate
        // if (createBadgeParticipantIds.size() > 0) {
        //     upsertBadges(createBadgeParticipantIds);
        // }
    }

    public static void sendEmailToSubmitedGroupParticipants(Map<Id, Participant__c> participantsMap) {
        List<Participant__c> participants = [
            SELECT Id, Event_custom__c, Participant_Email__c, Event_Registration_Sub_Group__c, Event_Ticket__r.Participation__c, Contact__r.Email
            FROM Participant__c
            WHERE Id IN :participantsMap.keySet()
        ];
        List<Email_activity__c> emailActivities = new List<Email_activity__c>();
        for (Participant__c participant : participants) {
            if (String.isNotBlank(participant.Event_Registration_Sub_Group__c)
                    && (String.isNotBlank(participant.Contact__r.Email) || String.isNotBlank(participant.Participant_Email__c))) {
                Email_activity__c emailActivity = new Email_activity__c();
                emailActivity.Event_Participation__c = participant.Id;
                emailActivity.Contact__c = participant.Contact__c;
                emailActivity.Event_custom__c = participant.Event_custom__c;
                if (String.isBlank(participant.Contact__r.Email)) {
                    emailActivity.Send_to_email__c = participant.Participant_Email__c;
                    emailActivity.Type__c = 'Undefined group participant submited';
                } else {
                    emailActivity.Send_to_email__c = participant.Contact__r.Email;
                    emailActivity.Type__c = 'Group participant submited';
                }
                emailActivities.add(emailActivity);
            }
        }
        insert emailActivities;
    }

    public static void processNewParticipants(List<Participant__c> newParticipants) {
        String statusRegistered = 'Registered';
        List<String> ticketIds = new List<String>();
        Set<String> contactIdsSet = new Set<String>();
        for (Participant__c newParticipant : newParticipants) {
            ticketIds.add(newParticipant.Event_Ticket__c);
            contactIdsSet.add(newParticipant.Contact__c);
        }
        Map<Id, Event_Ticket__c> eventTicketsMap = new Map<Id, Event_Ticket__c>([
            SELECT Id, Participation__c FROM Event_Ticket__c WHERE Id IN :ticketIds
        ]);
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([
            SELECT Id, Email FROM Contact WHERE Id IN :contactIdsSet
        ]);
        for (Participant__c newParticipant : newParticipants) {
            if (eventTicketsMap.containsKey(newParticipant.Event_Ticket__c)) {
                if (newParticipant.Status__c == statusRegistered 
                && String.isBlank(newParticipant.Event_Registration_Sub_Group__c)
                && eventTicketsMap.get(newParticipant.Event_Ticket__c).Participation__c == 'Onsite') {
                    newParticipant.QR_Code_needed__c = true;
                } else if (newParticipant.Status__c == statusRegistered 
                && String.isNotBlank(newParticipant.Event_Registration_Sub_Group__c)
                && eventTicketsMap.get(newParticipant.Event_Ticket__c).Participation__c == 'Onsite'
                && (contactsMap.get(newParticipant.Contact__c).Email != null || newParticipant.Participant_Email__c != null)) {
                    newParticipant.QR_Code_needed__c = true;
                }
            }
        }
    }

    public static void updateParticipant(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        Map<String, String> changedEmailToContactIdMap = new Map<String, String>();
        Map<String, String> contactIdToChangedEmailMap = new Map<String, String>();
        for (Contact newContact : newContacts) {
            if (newContact.Email != oldContactsMap.get(newContact.Id).Email
                && String.isNotBlank(newContact.Email)) {
                    changedEmailToContactIdMap.put(newContact.Email, newContact.Id);
                    contactIdToChangedEmailMap.put(newContact.Id, newContact.Email);
                }
        }
        List<Participant__c> participants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Participant_Email__c IN : changedEmailToContactIdMap.keySet()
        ];
        List<Participant__c> updateParticipants = new List<Participant__c>();
        if (participants.size() > 0) {
            for (Participant__c participant : participants) {
                if (String.isBlank(participant.Contact__r.Email)) {
                    participant.Contact__c = changedEmailToContactIdMap.get(participant.Participant_Email__c);
                    updateParticipants.add(participant);
                }
            }
        }
        List<Participant__c> emailChangedParticipants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Contact__c IN :contactIdToChangedEmailMap.keySet()
            AND Contact__r.Email != null
        ];
        if (emailChangedParticipants.size() > 0) {
            for (Participant__c emailChangedParticipant : emailChangedParticipants) {
                emailChangedParticipant.Participant_Email__c = contactIdToChangedEmailMap.get(emailChangedParticipant.Contact__c);
                updateParticipants.add(emailChangedParticipant);
            }
        }
        if(updateParticipants.size() > 0) {
            update updateParticipants;
        }
    }

    public static void updateParticipant(List<Contact> contacts) {
        Map<String, String> emailToContactIdMap = new Map<String, String>();
        for (Contact contact : contacts) {
            if (String.isNotBlank(contact.Email)) {
                emailToContactIdMap.put(contact.Email, contact.Id);
            }
        }
        List<Participant__c> participants = [
            SELECT Id, Participant_Email__c, Contact__r.Email
            FROM Participant__c
            WHERE Participant_Email__c IN :emailToContactIdMap.keySet()
        ];
        List<Participant__c> updateParticipants = new List<Participant__c>();
        if (participants.size() > 0) {
            for (Participant__c participant :participants) {
                if (String.isBlank(participant.Contact__r.Email)
                    && emailToContactIdMap.containsKey(participant.Participant_Email__c)) {
                    participant.Contact__c = emailToContactIdMap.get(participant.Participant_Email__c);
                    updateParticipants.add(participant);
                }
            }
        }
        if (updateParticipants.size() > 0) {
            update updateParticipants;
        }
    }

    public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';
    public static final Id personaPressRTId = Schema.SObjectType.Event_Persona__c.getRecordTypeInfosByDeveloperName().get('Press').getRecordTypeId();

    public static void upsertBadges(List<String> participantIds) {
        List<Participant__c> participants = [
            SELECT Id, Event_Exhibitor__c, Event_custom__c, Lecture_Presentation__c, Presentation__c, Tournament_Candidate__c,
                Contact__c, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName, Contact__r.Residency__c, Contact__r.MailingCity,
                Contact__r.Prescriber__c, Event_Persona__c, Event_Persona__r.RecordTypeId,
                Contact__r.AccountId, Contact__r.Account.Name, Contact__r.Membership_Status__c,
                Event_Ticket__c, Event_Ticket__r.Ticket__r.Event_Country_Ticket__c,
                Event_Registration_Sub_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
                (SELECT Id FROM Event_Badges__r ORDER BY LastModifiedDate DESC LIMIT 1)
            FROM Participant__c
            WHERE Id IN :participantIds
        ];

        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        for (Participant__c participant : participants) {

            Id badgeId = participant.Event_Badges__r.isEmpty() ? null : participant.Event_Badges__r[0].Id;

            Event_Badge__c badge = new Event_Badge__c();
            badge.Id = badgeId;
            badge.Event_Participation__c = participant.Id;
            badge.Event_custom__c = participant.Event_custom__c;
            badge.Country__c = participant.Contact__r.Residency__c;
            badge.City__c = participant.Contact__r.MailingCity;
            badge.FirstName__c = participant.Contact__r.FirstName;
            badge.LastName__c = participant.Contact__r.LastName;
            badge.Non_Prescriber_Info__c = participant.Contact__r.Prescriber__c;

            if (participant.Contact__r.AccountId != null) badge.Company__c = participant.Contact__r.Account.Name;

            if (participant.Event_Registration_Sub_Group__c != null) {
                badge.Label__c = participant.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
                badge.Event_Registration_Group__c = participant.Event_Registration_Sub_Group__r.Event_Registration_Group__c;
            }
            List<String> footerDefinitionsList = generateFooterValues(participant);
            if (footerDefinitionsList.isEmpty()) footerDefinitionsList.add('None');
            String footerDefinitionsString = String.join(footerDefinitionsList, ';');
            badge.Footer_Definitions__c = footerDefinitionsString;
            badges.add(badge);
        }

        if(!badges.isEmpty()) upsert badges;
    }

    public static List<String> generateFooterValues(Participant__c participant) {
        List<String> values = new List<String>();

        if (participant.Event_Exhibitor__c != null) {
            values.add('Exhibitor');
            return values;
        }

        if (participant.Contact__r.Membership_Status__c == 'EAN Full Member') { values.add('Full');
        } else if (participant.Contact__r.Membership_Status__c == 'EAN Corresponding Member') { values.add('Corresponding');
        } else if (participant.Contact__r.Membership_Status__c == 'Fellow of EAN') { values.add('Fellow of the EAN');
        } else if (participant.Contact__r.Membership_Status__c == 'EAN Resident and Research Member') { values.add('Resident & Research Member');
        } else if (participant.Contact__r.Membership_Status__c == 'EAN Associate Member') { values.add('Associate Member');
        } else if (participant.Contact__r.Membership_Status__c == 'EAN Student Member') { values.add('Student Member');
        } else if (participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME) { values.add('Non-Member'); }

        if (participant.Event_Persona__c != null && participant.Event_Persona__r.RecordTypeId == personaPressRTId) values.add('Press');
        if (participant.Lecture_Presentation__c != null) values.add('Faculty');
        if (!String.isBlank(participant.Presentation__c)) values.add(participant.Presentation__c);  //  ePoster presenter, ePresentation presenter
        if (participant.Tournament_Candidate__c == true) values.add('Tournament Candidate');        //  Tournament candidate
        if (participant.Event_Ticket__c != null && participant.Event_Ticket__r.Ticket__r.Event_Country_Ticket__c == true) values.add('Day of the week');

        //  TODO
        //  Panel Management Group Member

        return values;
    }

    public static void updateEventPersonas_delete(List<Participant__c> deletedParticipants){
        Set<Id> eventPersonaId = new Set<Id>();
        Set<Id> lecturePresentationId = new Set<Id>();

        for(Participant__c participant : deletedParticipants){
            if(participant.Lecture_Presentation__c != null){
                lecturePresentationId.add(participant.Lecture_Presentation__c);
            }
            if(participant.Event_Persona__c != null){
                eventPersonaId.add(participant.Event_Persona__c);
            }
        }

        List<Event_Persona__c> eventPersonas = [SELECT Id, Status__c FROM Event_Persona__c WHERE Id IN :eventPersonaId AND Status__c != ''];
        List<Speaker__c> speakers = [SELECT Id, Status__c FROM Speaker__c WHERE Id IN :lecturePresentationId];

        if(!eventPersonas.isEmpty()){

            for(Event_Persona__c ep : eventPersonas){
                ep.Status__c = '';
            }

            update eventPersonas;
        }

        if(!speakers.isEmpty()){

            for(Speaker__c s : speakers){
                s.Status__c = '';
            }

            update speakers;
        }

    }

    public static void updateEventPersonas_insert_undelete(List<Participant__c> insertedParticipants){
        Map<String, String> statusesMap = new Map<String, String>{
                'Registered'=>'confirmed',
                'Pending'=>'invited',
                'Canceled'=>'cancelled'
        };
        Set<Id> eventPersonaId = new Set<Id>();
        Set<Id> lecturePresentationId = new Set<Id>();

        for(Participant__c participant : insertedParticipants){
            if(participant.Lecture_Presentation__c != null){
                lecturePresentationId.add(participant.Lecture_Presentation__c);
            }
            if(participant.Event_Persona__c != null){
                eventPersonaId.add(participant.Event_Persona__c);
            }
        }

        Map<Id, Event_Persona__c> eventPersonasMap = new Map<Id, Event_Persona__c>([SELECT Id, Status__c FROM Event_Persona__c WHERE Id IN :eventPersonaId]);
        Map<Id, Speaker__c> speakersMap = new Map<Id, Speaker__c>([SELECT Id, Status__c FROM Speaker__c WHERE Id IN :lecturePresentationId]);

        Map<Id, Event_Persona__c> eventPersonasMapDML = new Map<Id, Event_Persona__c>();
        Map<Id, Speaker__c> speakersMapDML = new Map<Id, Speaker__c>();

        for(Participant__c participant : insertedParticipants){
            if(participant.Lecture_Presentation__c != null && participant.Status__c != null && speakersMap.containsKey(participant.Lecture_Presentation__c)){
                String status = statusesMap.containsKey(participant.Status__c) ? statusesMap.get(participant.Status__c) : '';

                if(status != speakersMap.get(participant.Lecture_Presentation__c).Status__c){
                    Speaker__c speaker = speakersMap.get(participant.Lecture_Presentation__c);
                    speaker.Status__c = status;
                    speakersMapDML.put(speaker.Id, speaker);
                }
            }
            if(participant.Event_Persona__c != null && participant.Status__c != null && eventPersonasMap.containsKey(participant.Event_Persona__c)){
                String status = statusesMap.containsKey(participant.Status__c) ? statusesMap.get(participant.Status__c) : '';

                if(status != eventPersonasMap.get(participant.Event_Persona__c).Status__c){
                    Event_Persona__c eventPersona = eventPersonasMap.get(participant.Event_Persona__c);
                    eventPersona.Status__c = status;
                    eventPersonasMapDML.put(eventPersona.Id, eventPersona);
                }
            }
        }

        if(!eventPersonasMapDML.isEmpty())  update eventPersonasMapDML.values();

        if(!speakersMapDML.isEmpty())       update speakersMapDML.values();
    }

    public static void updateEventPersonas_update(List<Participant__c> newParticipants, List<Participant__c> oldParticipants){
        Map<String, String> statusesMap = new Map<String, String>{
                'Registered'=>'confirmed',
                'Pending'=>'invited',
                'Canceled'=>'cancelled'
        };
        Set<Id> eventPersonaId = new Set<Id>();
        Set<Id> lecturePresentationId = new Set<Id>();
        Set<Participant__c> deleteParticipants = new Set<Participant__c>();

        for(Integer i = 0; i < newParticipants.size(); i++){

            if(newParticipants[i].Lecture_Presentation__c != null){
                lecturePresentationId.add(newParticipants[i].Lecture_Presentation__c);
            }
            if(newParticipants[i].Event_Persona__c != null){
                eventPersonaId.add(newParticipants[i].Event_Persona__c);
            }

            if(oldParticipants[i].Lecture_Presentation__c != newParticipants[i].Lecture_Presentation__c){

                if(oldParticipants[i].Lecture_Presentation__c != null){
                    deleteParticipants.add(oldParticipants[i]);
                }

            }

            if(oldParticipants[i].Event_Persona__c != newParticipants[i].Event_Persona__c){

                if(oldParticipants[i].Event_Persona__c != null){
                    deleteParticipants.add(oldParticipants[i]);
                }

            }
        }

        Set<Participant__c> participantsNotNeedToDelete = new Set<Participant__c>();

        for(Participant__c participant : deleteParticipants){
            if(participant.Event_Persona__c !=null && eventPersonaId.contains(participant.Event_Persona__c)){
                participantsNotNeedToDelete.add(participant);
            }
            if (participant.Lecture_Presentation__c!=null && lecturePresentationId.contains(participant.Lecture_Presentation__c)){
                participantsNotNeedToDelete.add(participant);
            }
        }

        if(!deleteParticipants.isEmpty()){
            updateEventPersonas_delete(new List<Participant__c>(deleteParticipants));
        }

        Map<Id, Event_Persona__c> eventPersonasMap = new Map<Id, Event_Persona__c>([SELECT Id, Status__c FROM Event_Persona__c WHERE Id IN :eventPersonaId]);
        Map<Id, Speaker__c> speakersMap = new Map<Id, Speaker__c>([SELECT Id, Status__c FROM Speaker__c WHERE Id IN :lecturePresentationId]);

        Map<Id, Event_Persona__c> eventPersonasMapDML = new Map<Id, Event_Persona__c>();
        Map<Id, Speaker__c> speakersMapDML = new Map<Id, Speaker__c>();

        for(Participant__c participant : newParticipants){
            if(participant.Lecture_Presentation__c != null && participant.Status__c != null && speakersMap.containsKey(participant.Lecture_Presentation__c)){
                String status = statusesMap.containsKey(participant.Status__c) ? statusesMap.get(participant.Status__c) : '';

                if(status != speakersMap.get(participant.Lecture_Presentation__c).Status__c){
                    Speaker__c speaker = speakersMap.get(participant.Lecture_Presentation__c);
                    speaker.Status__c = status;
                    speakersMapDML.put(speaker.Id, speaker);
                }
            }
            if(participant.Event_Persona__c != null && participant.Status__c != null && eventPersonasMap.containsKey(participant.Event_Persona__c)){
                String status = statusesMap.containsKey(participant.Status__c) ? statusesMap.get(participant.Status__c) : '';

                if(status != eventPersonasMap.get(participant.Event_Persona__c).Status__c){
                    Event_Persona__c eventPersona = eventPersonasMap.get(participant.Event_Persona__c);
                    eventPersona.Status__c = status;
                    eventPersonasMapDML.put(eventPersona.Id, eventPersona);
                }
            }
        }

        if(!eventPersonasMapDML.isEmpty())  update eventPersonasMapDML.values();
        if(!speakersMapDML.isEmpty())       update speakersMapDML.values();
    }

    // public static void startQRcodeBatch() {
    //     String jobName = 'get QR codes';
    //     List<CronTrigger> waitingJobs = [SELECT Id, CronJobDetail.Name, NextFireTime, State
    //                             FROM CronTrigger
    //                             WHERE CronJobDetail.Name = :jobName];
    //     Boolean isBatchWorking = false;
    //     for (CronTrigger waitingJob : waitingJobs) {
    //         if (waitingJob.NextFireTime < System.now().addMinutes(3) 
    //         && waitingJob.NextFireTime > System.now().addSeconds(-30)
    //         && waitingJob.CronJobDetail.Name == jobName){
    //             isBatchWorking = true;
    //         } else if (waitingJob.CronJobDetail.Name == jobName){
    //             System.abortJob(waitingJob.Id);
    //         }
    //     }
    //     if (isBatchWorking == false) {
    //         System.scheduleBatch(new QRcodeBatch(), jobName, 2, 70);
    //     }
    // }
}