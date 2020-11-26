@isTest
public with sharing class VisaLetterControllerTest {
    @isTest
    public static void visaLetterTest() {
        Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
        MailingCity = 'TestCity', MailingPostalCode = '11111',
        MailingCountry = 'Germany');
        insert c;

        Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
        Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, 
            Start_Time__c = System.now().addDays(10), End_Time__c = System.now().addDays(20), Status__c = 'Scheduled');
        insert event;

        Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
        Participant__c p = new Participant__c(Contact__c = c.Id, Event_custom__c = event.Id, 
            RecordTypeId = congressParticipantRT, Status__c = 'Registered');
        insert p;
        
        Visa_Letter__c vL = new Visa_Letter__c(
            Event_Participation__c =p.Id, Date_of_Birth__c = Date.Today(), Date_of_Issue__c = Date.Today(), Date_of_Expiry__c= Date.Today()
        );
        insert vL;
        PageReference pref = Page.VisaLetter;
        pref.getParameters().put('id', vL.Id);
        Test.setCurrentPage(pref);
        VisaLetterController controller = new VisaLetterController();
        System.assertEquals(1, controller.visaLetters.size()); 
    }
   
}