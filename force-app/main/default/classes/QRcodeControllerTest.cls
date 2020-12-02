@IsTest
public with sharing class QRcodeControllerTest {

    @IsTest
    public static void QRcodeControllerTest(){
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Contact contact = new Contact(FirstName = 'Name', LastName = 'Name');
        insert  contact;

        Participant__c part = new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id);
        insert part;
        part = [SELECT Id, Name, Contact__c, Event_custom__c FROM Participant__c WHERE Id = :part.Id];

        ContentVersion cv=new ContentVersion();
        cv.Title = 'QR code ' + part.Name + '.png';
        cv.PathOnClient = 'QR code ' + part.Name + '.png';
        cv.VersionData = Blob.valueOf('Test');
        insert cv;

        cv = [SELECT Id, ContentDocumentId, ContentDocument.Title FROM ContentVersion WHERE  Id = :cv.Id];

        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = part.Id;
        contentLink.ShareType = 'I';
        contentLink.LinkedEntityId = part.Id;
        contentLink.ContentDocumentId = cv.ContentDocumentId;
        contentLink.Visibility = 'AllUsers';
        insert contentLink;


        QRcodeController qr = new QRcodeController();
        qr.participantId = part.Id;
        System.assert(qr.externalUrl.contains(String.valueOf(cv.Id).left(15)));

    }
}