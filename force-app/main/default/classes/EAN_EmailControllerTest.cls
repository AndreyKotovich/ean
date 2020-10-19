@isTest
private with sharing class EAN_EmailControllerTest {

    @testSetup static void setup() {
        List<Event__c> eventsCustom = new List<Event__c>();
        for (Integer i=1; i<=2; i++){
            Event__c eventCustom = new Event__c();
            eventCustom.Name = 'Test ivent ' + i;
            eventsCustom.add(eventCustom);
        }
        insert eventsCustom;
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i=1; i<=8; i++){
            Contact contact = new Contact();
            contact.LastName = 'Test contact ' + i;
            contacts.add(contact);
        }
        insert contacts;
        List<Participant__c> participants = new List<Participant__c>();
        Integer i = 1;
        for (Contact contact : contacts){
            Participant__c participant = new Participant__c();
            participant.Event_custom__c = eventsCustom[Math.round(Math.random())].Id;
            participant.Participant_Email__c = 'test'+i+'@test.ru';
            participant.Contact__c = contact.Id;
            participants.add(participant);
            i = i +1;
        }
        insert participants;
    }
    @isTest
    static void sendEmailTest(){
        Map<String, Object> emailOptionsMap = new Map<String, Object>();
        List<String> recordIds = new List<String>();
        List<Participant__c> records = [SELECT Id FROM Participant__c];
        for (Participant__c record : records){
            recordIds.add(record.Id);
        }
        emailOptionsMap.put('recordIds', recordIds);
        emailOptionsMap.put('objectApiName', 'Participant__c');
        emailOptionsMap.put('emailFieldApiName', 'Participant_Email__c');
        emailOptionsMap.put('emailTemplateDevName', 'EANSuccessfullRegisrationEmailTemplate');
        Test.startTest();
        List<Participant__c> unusedRecords = EAN_EmailController.sendEmail(emailOptionsMap);
        Test.stopTest();
        System.assert(unusedRecords.size() == 0);
    }
}