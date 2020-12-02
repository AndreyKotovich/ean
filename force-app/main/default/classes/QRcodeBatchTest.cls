@isTest
private without sharing class QRcodeBatchTest {
    public QRcodeBatchTest() {

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
        Event_Ticket__c testEventTicket = new Event_Ticket__c(
            Event_custom__c = event.Id,
            Participation__c = 'Onsite'
        );
        insert testEventTicket;
        Participant__c testParticipant = new Participant__c(
            Contact__c = testContact.Id,
            Event_custom__c = event.Id,
            QR_Code_needed__c = true,
            Status__c = 'Registered',
            Badge_Retrieval__c = 'onsite',
            Event_Ticket__c = testEventTicket.Id
        );
        insert testParticipant;
        // List<Participant__c> testParticipants = [
        //     SELECT Id, Name FROM Participant__c LIMIT 1
        // ];
        // ContentVersion testConVer = new ContentVersion(
        //     ContentLocation = 'S',
        //     PathOnClient = 'QR code ' + testParticipants[0].Name + '.png',
        //     Title = 'QR code ' + testParticipants[0].Name + '.png',
        //     VersionData = Blob.valueOf('Test Version Data')
        // );
        // insert testConVer;
        // List<ContentVersion> testConVers = [
        //             SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :testConVer.Id
        //             ];
        // ContentDocumentLink conDocLink = new ContentDocumentLink(
        //     LinkedEntityId = testParticipant.Id,
        //     ContentDocumentId = testConVers[0].ContentDocumentId,
        //     shareType = 'V',
        //     Visibility='AllUsers'
        // );
        // insert conDocLink;
    }
}