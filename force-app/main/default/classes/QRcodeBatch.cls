public without sharing class QRcodeBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    public QRcodeBatch() {
        
    }
    Integer Count = 0;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String statusParticipated = 'Participated';
        String statusCanceled = 'Canceled';
        return Database.getQueryLocator(
            'SELECT Id, Name, QR_Code_added__c FROM Participant__c WHERE QR_Code_added__c = false AND deleted__c = false AND Status__c != :statusParticipated AND Status__c != :statusCanceled' 
        );
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        String networkId = Network.getNetworkId();
        String QRGeneratorLink = 'callout:QR_Code_Generator_Link/chart?chs=200x200&cht=qr&chl=';
        Map<String, ContentVersion> conVerToparticipantIdsMap = new Map<String, ContentVersion>();
        for (Participant__c participant : participants) {
            String Link = QRGeneratorLink + URL.getSalesforceBaseUrl().toExternalForm() + '/' + participant.Id;
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
                    participant.QR_Code_added__c = true;
                }                
            }
            update participants;
        }
        
    }
    public void finish(Database.BatchableContext BC) {

    }
}