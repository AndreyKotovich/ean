@IsTest
public with sharing class ParticipantTriggerHelperTest {
    @TestSetup
    public static void setup(){
        List<Event__c> events = new List<Event__c>();

        for(Integer i = 0; i < 3; i++){
            events.add(new Event__c(Name = 'Event '+i));
        }

        insert events;

        List<Session__c> extraSessions = new List<Session__c>();

        for(Event__c event : events){
            extraSessions.add(new Session__c(Name = 'Session Extra 1', Type__c = 'Payable', Session_Type__c = 'Special Session',
                    Max_Participants__c = 50, Event_custom__c = event.Id, Session_Start__c = Datetime.now(),
                    Session_End__c = Datetime.now().addDays(1)));
        }

        insert extraSessions;

        Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'info@test.com');
        insert contact;
    }
    @IsTest
    public static void updateEventPersonas_insert_undeleteTest(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        List<Session__c> sessions = [SELECT Id FROM Session__c];

        List<RecordType> eventPersonaRTs = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Event_Persona__c'];
        Event_Persona__c ep = new Event_Persona__c(Contact__c = contact.Id, Event_custom__c = event.Id, RecordTypeId = eventPersonaRTs[0].Id);
        insert ep;

        Lecture__c lecture = new Lecture__c(Event_custom__c = event.Id, Session__c = sessions[0].Id);
        insert lecture;

        Speaker__c speaker = new Speaker__c(Lecture__c = lecture.Id, Contact__c = contact.Id);
        insert speaker;

        Participant__c participant = new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id,
                Status__c = 'Pending', Event_Persona__c = ep.Id, Lecture_Presentation__c = speaker.Id);
        insert participant;

        System.assertEquals('invited', [SELECT Id, Status__c FROM Speaker__c WHERE Id = :speaker.Id].Status__c);
        System.assertEquals('invited', [SELECT Id, Status__c FROM Event_Persona__c WHERE Id = :ep.Id].Status__c);

        participant.Status__c = 'Registered';
        update participant;

        System.assertEquals('confirmed', [SELECT Id, Status__c FROM Speaker__c WHERE Id = :speaker.Id].Status__c);
        System.assertEquals('confirmed', [SELECT Id, Status__c FROM Event_Persona__c WHERE Id = :ep.Id].Status__c);

        participant.Event_Persona__c = null;
        participant.Lecture_Presentation__c = null;
        update participant;

        System.assertEquals(null, [SELECT Id, Status__c FROM Speaker__c WHERE Id = :speaker.Id].Status__c);
        System.assertEquals(null, [SELECT Id, Status__c FROM Event_Persona__c WHERE Id = :ep.Id].Status__c);
    }
}