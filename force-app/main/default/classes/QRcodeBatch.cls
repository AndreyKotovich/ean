public without sharing class QRcodeBatch implements Database.Batchable<Participant__c>, Database.Stateful, Database.AllowsCallouts {
    public QRcodeBatch() {
        
    }
    public List<Participant__c> start(Database.BatchableContext bc) {
        String statusRegistered = 'Registered';
        System.debug('Start generating QR code');
        List<Participant__c> participants = [
            SELECT Id, Name, Event_custom__c, Participant_Email__c, QR_Code_needed__c, Contact__r.Email, Badge_Retrieval__c, Event_Ticket__r.Participation__c, (SELECT Id FROM Event_Badges__r)
            FROM Participant__c 
            WHERE QR_Code_needed__c = true AND Status__c = :statusRegistered
        ];
        System.debug('participants --> ' + participants);
        System.debug('participants.size --> ' + participants.size());
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
        }
        List<String> participantIds =new List<String>();
        List<String> participantQRcodeFileNames =new List<String>();
        for (Participant__c participant : participants) {
            participantIds.add(participant.Id);
            participantQRcodeFileNames.add('QR code ' + participant.Name + '.png');
        }
        System.debug('participantIds --> ' + participantIds);
        System.debug('participantQRcodeFileNames --> ' + participantQRcodeFileNames);
        if (participantIds.size() > 0) {
            List<ContentDocumentLink> conDocLinks = [
                SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :participantIds
            ];
            System.debug('conDocLinks --> ' + conDocLinks);
            for (ContentDocumentLink conDocLink : conDocLinks) {
                System.debug('conDocLink --> ' + conDocLink);
            }
            List<String> contentDocumentIds = new List<String>();
            for (ContentDocumentLink conDocLink : conDocLinks) {
                contentDocumentIds.add(conDocLink.ContentDocumentId);
            }
            System.debug('contentDocumentIds --> ' + contentDocumentIds);
            List<ContentDocument> contentDocuments = [
                SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds AND Title IN :participantQRcodeFileNames
            ];
            System.debug('contentDocuments --> ' + contentDocuments);
            for (ContentDocument contentDocument : contentDocuments) {
                System.debug('contentDocument --> ' + contentDocument);
            }
            if (contentDocuments.size() > 0) {
                delete contentDocuments;
                System.debug(' delete contentDocuments --> ');
            }
        }
        return participants;
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        System.debug('Execute logic --> ');
        System.debug('participants --> ' + participants);
        for (Participant__c participant : participants) {
            System.debug('participant --> ' + participant);
        }
        String networkId = Network.getNetworkId();
        System.debug('networkId --> ' + networkId);
        String QRGeneratorLink = 'callout:QR_Code_Generator_Link/chart?chs=200x200&cht=qr&chl=';
        System.debug('QRGeneratorLink --> ' + QRGeneratorLink);
        Map<String, ContentVersion> conVerToparticipantIdsMap = new Map<String, ContentVersion>();
        for (Participant__c participant : participants) {
            String Link = QRGeneratorLink + URL.getSalesforceBaseUrl().toExternalForm().replace('my.salesforce.com', 'lightning.force.com/lightning/r/Event_Badge__c').replace('salesforce.com', 'lightning.force.com/lightning/r/Event_Badge__c') + '/' + participant.Event_Badges__r[0].Id  + '/view';
            System.debug('Link --> ' + Link);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(link);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            System.debug('response --> ' + response);
            if (response.getStatusCode() == 200) {
                ContentVersion conVer = new ContentVersion();
                conVer.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;
                conVer.ContentLocation = 'S';
                conVer.PathOnClient = 'QR code ' + participant.Name + '.png';
                conVer.Title = 'QR code ' + participant.Name + '.png';
                conVer.VersionData = response.getBodyAsBlob();
                conVerToparticipantIdsMap.put(participant.Id, conVer);
                System.debug('conVer --> ' + conVer);
            }  
        }           
        if (conVerToparticipantIdsMap.size() > 0) {
            insert conVerToparticipantIdsMap.values();
            System.debug('conVerToparticipantIdsMap.values --> ' + conVerToparticipantIdsMap.values());
            List<String> conVerIds = new List<String>();
            for (ContentVersion conVer : conVerToparticipantIdsMap.values()) {
                conVerIds.add(conVer.Id);
            }
            System.debug('conVerIds --> ' + conVerIds);
            Map<ID, ContentVersion> conVersMap = new Map<ID, ContentVersion>([
                SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :conVerIds
                ]);
            System.debug('conVersMap --> ' + conVersMap);
            List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();
            List<ContentDistribution> newDists = new List<ContentDistribution>();
            for (String participantId : conVerToparticipantIdsMap.keySet()) {
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = participantId;
                conDocLink.ContentDocumentId = conVersMap.get(conVerToparticipantIdsMap.get(participantId).Id).ContentDocumentId;
                conDocLink.shareType = 'V';
                conDocLink.Visibility='AllUsers';
                conDocLinks.add(conDocLink);
                System.debug('conDocLink --> ' + conDocLink);
                ContentDistribution newDist = new ContentDistribution();
                newDist.ContentVersionId = conVerToparticipantIdsMap.get(participantId).Id;
                newDist.RelatedRecordId = participantId;
                newDist.Name = conVerToparticipantIdsMap.get(participantId).Title + ' external Link';
                newDist.PreferencesNotifyOnVisit = false;
                newDist.PreferencesAllowViewInBrowser = true;
                newDists.add(newDist);
                System.debug('newDist --> ' + newDist);
            }
            insert conDocLinks;
            insert newDists;
            System.debug('insert newDists --> ' + newDists);
            System.debug('insert conDocLinks --> ' + conDocLinks);
            List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
            for (Participant__c participant : participants) {
                if (conVerToparticipantIdsMap.keySet().contains(participant.Id)) {
                    participant.QR_Code_needed__c = false;
                    if (participant.Badge_Retrieval__c == 'onsite' 
                    && participant.Event_Ticket__r.Participation__c == 'Onsite') {
                        Email_Activity__c emailActivity = new Email_Activity__c(
                            Contact__c = participant.Contact__c,
                            Event_Custom__c = participant.Event_custom__c,
                            Event_Participation__c = participant.Id,
                            Type__c = 'QR code for participant'
                        );
                        if (String.isBlank(participant.Contact__r.Email)) {
                            emailActivity.Send_To_Email__c = participant.Participant_Email__c;
                        } else {
                            emailActivity.Send_To_Email__c = participant.Contact__r.Email;
                        }
                        emailActivities.add(emailActivity);
                        System.debug('emailActivity --> ' + emailActivity);                       
                    }
                }
            }
            insert emailActivities;
            System.debug('insert emailActivities --> ' + emailActivities);
            update participants;
            System.debug('update participants --> ' + participants);
        }
        
    }
    public void finish(Database.BatchableContext BC) {
        String jobName = 'get QR codes';
        List<CronTrigger> QRcodeJobs = [SELECT Id
                                FROM CronTrigger
                                WHERE CronJobDetail.Name = :jobName];
        for (CronTrigger QRcodeJob : QRcodeJobs) {
            System.abortJob(QRcodeJob.Id);
        }
        System.scheduleBatch(new QRcodeBatch(), jobName, 60, 70);

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