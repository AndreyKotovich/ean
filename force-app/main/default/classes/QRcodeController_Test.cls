@isTest
private class QRcodeController_Test {
    public QRcodeController_Test() {

    }
    @testSetup
    static void Setup() {
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@mail.com'
        );
        insert testContact;
        Event__c event = new Event__c(
            Name = 'Test event'
        );
        insert event;
        Participant__c testParticipant = new Participant__c(
            Contact__c = testContact.Id,
            Event_custom__c = event.Id
        );
        insert testParticipant;
        List<Participant__c> testParticipants = [
            SELECT Id, Name FROM Participant__c LIMIT 1
        ];
        ContentVersion testConVer = new ContentVersion(
            ContentLocation = 'S',
            PathOnClient = 'QR code ' + testParticipants[0].Name + '.png',
            Title = 'QR code ' + testParticipants[0].Name + '.png',
            VersionData = Blob.valueOf('Test Version Data')
        );
        insert testConVer;
        List<ContentVersion> testConVers = [
                    SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :testConVer.Id
                    ];
        ContentDocumentLink conDocLink = new ContentDocumentLink(
            LinkedEntityId = testParticipant.Id,
            ContentDocumentId = testConVers[0].ContentDocumentId,
            shareType = 'V',
            Visibility='AllUsers'
        );
        insert conDocLink;
    }

    @isTest
	static void getUrlForBadgeRecordTest() {
        List<Participant__c> testParticipants = [
            SELECT Id, Name FROM Participant__c LIMIT 1
        ];
        QRcodeController controllerInstance = new QRcodeController();
        controllerInstance.participantId = testParticipants[0].Id;
        String contentDocumentName = 'QR code ' + testParticipants[0].Name + '.png';
        List<ContentDocumentLink> conDocLinks = [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :testParticipants[0].Id
                AND ContentDocument.Title = :contentDocumentName
            ];
        List<ContentVersion> conVersions = [
                SELECT ContentBodyId, Id
                FROM ContentVersion
                WHERE ContentDocumentId = :conDocLinks[0].ContentDocumentId
                AND Title = :contentDocumentName
            ];
        String contentBodyId = conVersions[0].ContentBodyId;
        String conVersionId = conVersions[0].Id;
        System.debug(controllerInstance.externalUrl);
        System.assert(String.isNotBlank(controllerInstance.externalUrl));
        System.assert(controllerInstance.externalUrl.contains(URL.getSalesforceBaseUrl().toExternalForm().replace('.my.salesforce.com', '--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=').replace('.salesforce.com', '--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=')));
        System.assert(controllerInstance.externalUrl.contains(contentBodyId.left(15)));
        System.assert(controllerInstance.externalUrl.contains(conVersionId.left(15)));
    }
}