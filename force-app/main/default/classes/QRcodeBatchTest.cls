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
        Ticket__c testTicket = new Ticket__c();
        insert testTicket;
        Event_Ticket__c testEventTicket = new Event_Ticket__c(
            Event_custom__c = event.Id,
            Participation__c = 'Onsite',
            Ticket__c = testTicket.Id
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
    }

    @isTest
    private static void QRcodeBatchTest() {
        Map<Id, Participant__c> testParticipantsMapOld = new Map<Id, Participant__c>([
            SELECT Id, Name
            FROM Participant__c
            WHERE QR_Code_needed__c = true
            AND Status__c = 'Registered'
        ]);
         Test.setMock(HttpCalloutMock.class, new QRcodeBatchMock());
         Test.startTest();
         Database.executeBatch(new QRcodeBatch(), 10);
         Test.stopTest();
        Map<Id, Participant__c> testParticipantsMap = new Map<Id, Participant__c>([
            SELECT Id, Name, QR_Code_needed__c
            FROM Participant__c
            WHERE Id IN :testParticipantsMapOld.keySet()
        ]);
        System.debug(testParticipantsMap);
        if (testParticipantsMap.size() > 0) {
            List<ContentDocumentLink> conDocLinks = [
                SELECT Id, LinkedEntityId, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :testParticipantsMap.keySet()
            ];
            System.assert(conDocLinks.size() > 0);
            Map<String, List<ContentDocumentLink>> participantIdToconDocLinkMap = new Map<String, List<ContentDocumentLink>>();
            for (ContentDocumentLink conDocLink : conDocLinks) {
                if (!participantIdToconDocLinkMap.containsKey(conDocLink.LinkedEntityId)) {
                    participantIdToconDocLinkMap.put(conDocLink.LinkedEntityId, new List<ContentDocumentLink>());
                }
                participantIdToconDocLinkMap.get(conDocLink.LinkedEntityId).add(conDocLink);
            }
            for (Id participantId : testParticipantsMap.keySet()) {
                System.assert(testParticipantsMap.get(participantId).QR_Code_needed__c == false);
                for (ContentDocumentLink conDocLink : participantIdToconDocLinkMap.get(participantId)) {
                    System.assert(conDocLink.ContentDocument.Title == 'QR code ' + testParticipantsMap.get(participantId).Name + '.png');
                }
            }
            List<Email_Activity__c> emailActivities = [
                SELECT Id
                FROM Email_Activity__c
                WHERE Event_Participation__c IN :testParticipantsMap.keySet()
            ];
            System.assert(emailActivities.size() > 0);
        }
    }
}