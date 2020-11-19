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
    public String externalUrl {get{
        List<Participant__c> participants = [
            SELECT Id, Name FROM Participant__c WHERE Id = :participantId
        ];
        String contentDocumentName = 'QR code ' + participants[0].Name + '.png';
        List<ContentDocumentLink> conDocLinks = [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :participants[0].Id
                AND ContentDocument.Title = :contentDocumentName
            ];
        List<ContentVersion> conVersions = [
                SELECT ContentBodyId, Id
                FROM ContentVersion
                WHERE ContentDocumentId = :conDocLinks[0].ContentDocumentId
                AND Title = :contentDocumentName
            ];
        if (conVersions.size() == 1) {
            String contentVersionId = conVersions[0].Id;
            String contentBodyId = conVersions[0].ContentBodyId;

            String imageUrl = URL.getSalesforceBaseUrl().toExternalForm().replace('.my.salesforce.com', '--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=').replace('.salesforce.com', '--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=') + contentVersionId.left(15)  + '&operationContext=CHATTER&contentId=' + contentBodyId.left(15);
            return imageUrl;
        }
        return null;
    } set; }
}