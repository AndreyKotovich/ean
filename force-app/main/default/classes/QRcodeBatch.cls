public without sharing class QRcodeBatch implements Database.Batchable<Participant__c>, Database.Stateful, Database.AllowsCallouts {
    String step;
    public QRcodeBatch() {
        this.step = 'Generate QR code';
    }
    public QRcodeBatch(String step) {
        this.step = step;
    }
    public List<Participant__c> start(Database.BatchableContext bc) {
        String statusRegistered = 'Registered';
        List<Participant__c> participants = [
            SELECT Id, Name, Event_custom__c, Participant_Email__c, QR_Code_needed__c, Contact__r.Email, Badge_Retrieval__c, Event_Ticket__r.Participation__c, (SELECT Id, QR_code__c FROM Event_Badges__r)
            FROM Participant__c 
            WHERE QR_Code_needed__c = true AND Status__c = :statusRegistered
        ];
        return participants;
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        Map<String, Participant__c> participantsMap = new Map<String, Participant__c>();
        for (Participant__c participant : participants) {
            participantsMap.put(participant.Id, participant);
        }

        //Check if record allready has QR code
        Map<String, String> participantIdToParticipantQRcodeFileNameMap =new Map<String, String>();
        for (String participantId : participantsMap.keySet()) {
            participantIdToParticipantQRcodeFileNameMap.put(participantId, 'QR code ' + participantsMap.get(participantId).Name + '.png');
        }
        Map<String, Participant__c> participantWithQRCodeMap = new Map<String, Participant__c>();
        if (participantIdToParticipantQRcodeFileNameMap.size() > 0) {
            List<ContentDocumentLink> conDocLinks = [
                SELECT Id, ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :participantIdToParticipantQRcodeFileNameMap.keySet()
            ];
            Map<String, List<ContentDocumentLink>> participantIdToconDocLinksMap = new Map<String, List<ContentDocumentLink>>();
            List<String> contentDocumentIds = new List<String>();
            for (ContentDocumentLink conDocLink : conDocLinks) {
                if (!participantIdToconDocLinksMap.containsKey(conDocLink.LinkedEntityId)) {
                    participantIdToconDocLinksMap.put(conDocLink.LinkedEntityId, new List<ContentDocumentLink>());
                }
                participantIdToconDocLinksMap.get(conDocLink.LinkedEntityId).add(conDocLink);
                contentDocumentIds.add(conDocLink.ContentDocumentId);
            }
            Map<Id, ContentDocument> contentDocumentsMap = new Map<Id, ContentDocument>([
                SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIds AND Title IN :participantIdToParticipantQRcodeFileNameMap.values()
            ]);
            
            for(String participantId : participantIdToconDocLinksMap.keySet()) {
                for (ContentDocumentLink conDocLink : participantIdToconDocLinksMap.get(participantId)) {
                    if (contentDocumentsMap.containsKey(conDocLink.ContentDocumentId)
                        && participantsMap.get(participantId).QR_Code_needed__c) {
                            if (contentDocumentsMap.get(conDocLink.ContentDocumentId).Title == 'QR code ' + participantsMap.get(participantId).Name + '.png') {
                                participantWithQRCodeMap.put(participantId, participantsMap.get(participantId));
                            }
                        }
                }
            }
        }
        if (this.step == 'Generate QR code') {
            //Generate QR code
            String networkId = Network.getNetworkId();
            String QRGeneratorLink = 'callout:QR_Code_Generator_Link/chart?chs=200x200&cht=qr&chl=';
            Map<Participant__c, ContentVersion> participantToConVerMap = new Map<Participant__c, ContentVersion>();

            for (Participant__c participant : participants) {
                if (!participantWithQRCodeMap.containsKey(participant.Id)){
                    String Link = QRGeneratorLink + URL.getSalesforceBaseUrl().toExternalForm() + '/' + participant.Event_Badges__r[0].Id;
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(link);
                    request.setMethod('GET');
                    request.setTimeout(60000);
                    HttpResponse response = http.send(request);
                    if (response.getStatusCode() == 200) {
                        ContentVersion conVer = new ContentVersion();
                        if (Test.isRunningTest()) {
                            conVer.NetworkId = null;
                        } else {
                            conVer.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;
                        }                        
                        conVer.ContentLocation = 'S';
                        conVer.PathOnClient = 'QR code ' + participant.Name + '.png';
                        conVer.Title = 'QR code ' + participant.Name + '.png';
                        conVer.VersionData = response.getBodyAsBlob();
                        participantToConVerMap.put(participant, conVer);
                    }
                }
            }
            if (participantToConVerMap.size() > 0) {
                insert participantToConVerMap.values();

                List<String> conVerIds = new List<String>();

                for (ContentVersion conVer : participantToConVerMap.values()) {
                    conVerIds.add(conVer.Id);
                }

                Map<ID, ContentVersion> conVersMap = new Map<ID, ContentVersion>([
                    SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :conVerIds
                    ]);
                List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();
                List<Event_Badge__c> badgesToUpdate = new List<Event_Badge__c>();
                String orgUrl = Url.getOrgDomainUrl().toExternalForm();

                for (Participant__c participant : participantToConVerMap.keySet()) {
                    ContentDocumentLink conDocLink = New ContentDocumentLink();
                    conDocLink.LinkedEntityId = participant.Id;
                    conDocLink.ContentDocumentId = conVersMap.get(participantToConVerMap.get(participant).Id).ContentDocumentId;
                    conDocLink.shareType = 'V';
                    conDocLink.Visibility='AllUsers';
                    conDocLinks.add(conDocLink);

                    if(!participant.Event_Badges__r.isEmpty() && participant.Event_Badges__r[0].QR_code__c == null){
                        badgesToUpdate.add(new Event_Badge__c(Id = participant.Event_Badges__r[0].Id, QR_code__c = orgUrl + '/sfc/servlet.shepherd/version/download/'+participantToConVerMap.get(participant).Id));
                    }

                }

                insert conDocLinks;
                update badgesToUpdate;
            }
        } else if (this.step == 'Send email with QR code') {
            List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
            for (String participantId : participantWithQRCodeMap.keySet()) {
                if (participantWithQRCodeMap.get(participantId).Badge_Retrieval__c == 'onsite' 
                && participantWithQRCodeMap.get(participantId).Event_Ticket__r.Participation__c == 'Onsite') {
                    Email_Activity__c emailActivity = new Email_Activity__c(
                        Contact__c = participantWithQRCodeMap.get(participantId).Contact__c,
                        Event_Custom__c = participantWithQRCodeMap.get(participantId).Event_custom__c,
                        Event_Participation__c = participantWithQRCodeMap.get(participantId).Id,
                        Type__c = 'QR code for participant'
                    );
                    if (String.isBlank(participantWithQRCodeMap.get(participantId).Contact__r.Email)) {
                        emailActivity.Send_To_Email__c = participantWithQRCodeMap.get(participantId).Participant_Email__c;
                    } else {
                        emailActivity.Send_To_Email__c = participantWithQRCodeMap.get(participantId).Contact__r.Email;
                    }
                    emailActivities.add(emailActivity);
                    participantWithQRCodeMap.get(participantId).QR_Code_needed__c = false;                      
                }
            }
            if (emailActivities.size() > 0) {
                insert emailActivities;
            }
            if (participantWithQRCodeMap.values().size() > 0) {
                update participantWithQRCodeMap.values();
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (this.step == 'Generate QR code') {
            Database.executeBatch(new QRcodeBatch('Send email with QR code'));
        } else {
            String jobName = 'get QR codes';
            List<CronTrigger> QRcodeJobs = [SELECT Id
                                    FROM CronTrigger
                                    WHERE CronJobDetail.Name = :jobName];
            for (CronTrigger QRcodeJob : QRcodeJobs) {
                System.abortJob(QRcodeJob.Id);
            }
            System.scheduleBatch(new QRcodeBatch(), jobName, 60, 20);

            // Logic for QR code reminder
            List<Event__c> events = [
                SELECT Id, Name, Start_Time__c FROM Event__c WHERE Start_Time__c > :Datetime.now()
            ];
            List<Event__c> upcommingEvents = new List<Event__c>();
            for (Event__c event : events) {
                if (event.Start_Time__c.addDays(-15).date() == Date.today()) {
                    upcommingEvents.add(event);
                }
            }
            if (upcommingEvents.size() > 0) {
                List<String> reminderJobNames = new List<String>();
                for (Event__c upcommingEvent : upcommingEvents) {
                    String reminderJobName = 'QR code reminder ' + upcommingEvent.Name;
                    reminderJobNames.add(reminderJobName);
                }
                List<CronTrigger> reminderQRcodeJobs = [SELECT Id, CronJobDetail.Name, State, NextFireTime
                    FROM CronTrigger
                    WHERE CronJobDetail.Name IN :reminderJobNames];
                Map<String, CronTrigger> reminderJobNameToQRcodeJobsMap = new Map<String, CronTrigger>();
                for (CronTrigger reminderQRcodeJob : reminderQRcodeJobs) {
                    if (String.isNotBlank(reminderQRcodeJob.CronJobDetail.Name)) {
                        reminderJobNameToQRcodeJobsMap.put(reminderQRcodeJob.CronJobDetail.Name, reminderQRcodeJob);
                    }
                }
                for (String reminderJobName : reminderJobNames) {
                    if (reminderJobNameToQRcodeJobsMap.containsKey(reminderJobName)) {
                        if (reminderJobNameToQRcodeJobsMap.get(reminderJobName).NextFireTime < Datetime.now()
                            || reminderJobNameToQRcodeJobsMap.get(reminderJobName).NextFireTime.addHours(-26) > Datetime.now()
                            || reminderJobNameToQRcodeJobsMap.get(reminderJobName).State != 'WAITING') {
                                System.abortJob(reminderJobNameToQRcodeJobsMap.get(reminderJobName).Id);
                                System.scheduleBatch(new QRcodeBatchReminder(reminderJobName), reminderJobName, 1500);
                            }
                    } else {
                        System.scheduleBatch(new QRcodeBatchReminder(reminderJobName), reminderJobName, 1500);
                    }
                }
            }
        }
    }
}