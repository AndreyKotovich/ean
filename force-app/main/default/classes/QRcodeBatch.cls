public without sharing class QRcodeBatch implements Database.Batchable<Participant__c>, Database.Stateful, Database.AllowsCallouts {
    public QRcodeBatch() {
        
    }
    Integer Count = 0;
    public List<Participant__c> start(Database.BatchableContext bc) {
        String statusRegistered = 'Registered';
        List<Participant__c> participants = [
            SELECT Id, Name, QR_Code_needed__c, Contact__r.Email, (SELECT Id FROM Event_Badges__r)
            FROM Participant__c 
            WHERE QR_Code_needed__c = true AND Status__c = :statusRegistered
        ];
        return participants;
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        String networkId = Network.getNetworkId();
        String QRGeneratorLink = 'callout:QR_Code_Generator_Link/chart?chs=200x200&cht=qr&chl=';
        Map<String, ContentVersion> conVerToparticipantIdsMap = new Map<String, ContentVersion>();
        for (Participant__c participant : participants) {
            String Link = QRGeneratorLink + URL.getSalesforceBaseUrl().toExternalForm().replace('my.salesforce.com', 'lightning.force.com/lightning/r/Event_Badge__c').replace('salesforce.com', 'lightning.force.com/lightning/r/Event_Badge__c') + '/' + participant.Event_Badges__r[0].Id  + '/view';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(link);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                ContentVersion conVer = new ContentVersion();
                conVer.NetworkId = ConnectApi.Communities.getCommunities().communities[0].Id;
                conVer.ContentLocation = 'S';
                conVer.PathOnClient = 'QR code ' + participant.Name + '.png';
                conVer.Title = 'QR code ' + participant.Name + '.png';
                conVer.VersionData = response.getBodyAsBlob();
                conVerToparticipantIdsMap.put(participant.Id, conVer);
            }  
        }           
        if (conVerToparticipantIdsMap.size() > 0) {
            insert conVerToparticipantIdsMap.values();
            List<String> conVerIds = new List<String>();
            for (ContentVersion conVer : conVerToparticipantIdsMap.values()) {
                conVerIds.add(conVer.Id);
            }
            Map<ID, ContentVersion> conVersMap = new Map<ID, ContentVersion>([
                SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :conVerIds
                ]);
            List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();
            for (String participantId : conVerToparticipantIdsMap.keySet()) {
                ContentDocumentLink conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = participantId;
                conDocLink.ContentDocumentId = conVersMap.get(conVerToparticipantIdsMap.get(participantId).Id).ContentDocumentId;
                conDocLink.shareType = 'V';
                conDocLinks.add(conDocLink);
            }
            insert conDocLinks;
            for (Participant__c participant : participants) {
                if (conVerToparticipantIdsMap.keySet().contains(participant.Id)) {
                    participant.QR_Code_needed__c = false;
                }                
            }
            update participants;
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
    }
}