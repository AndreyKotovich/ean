public with sharing class QRcodeController {
    public QRcodeController() {

    }
    public String participantId { get; set; }
    public String publicUrl { get{
        List<Participant__c> participants = [
            SELECT Id, Name FROM Participant__c WHERE Id = :participantId
        ];
        if (participants.size() == 1) {
            String contentDistributionName = 'QR code%' + participants[0].Name + '%';
            List<ContentDistribution> contentDistributions = [
                SELECT Id, DistributionPublicUrl 
                FROM ContentDistribution 
                WHERE RelatedRecordId = :participantId 
                AND Name LIKE :contentDistributionName
            ];
            if (contentDistributions.size() > 0) {
                return contentDistributions[0].DistributionPublicUrl;
            }
        }
        return null;
    } set; }
    public String contentDocumentId {get{
        List<Participant__c> participants = [
            SELECT Id, Name FROM Participant__c WHERE Id = :participantId
        ];
        if (participants.size() == 1) {
            String contentDocumentName = 'QR code ' + participants[0].Name + '.png';
            List<ContentDocumentLink> conDocLinks = [
                SELECT Id, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :participantId
                AND ContentDocument.Title = :contentDocumentName
            ];
            if (conDocLinks.size() > 0) {
                return conDocLinks[0].ContentDocumentId;
            }
        }
        return null;
    } set; }
}