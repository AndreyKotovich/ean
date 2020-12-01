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

    @IsTest
    public static void groupParticipantRegistrationTest(){
		Contact testContact1 = new Contact(FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com');
		Contact testContact2 = new Contact(FirstName = 'testFirst2', LastName = 'testLast2', Email = 'testmail2@nomail.com');
		Contact testContact3 = new Contact(FirstName = 'testFirst3', LastName = 'testLast3', Email = 'testmail3@nomail.com');
		Contact testContact4 = new Contact(FirstName = 'testFirst4', LastName = 'testLast4', Email = 'testmail4@nomail.com');
		Contact undefined = new Contact(FirstName = 'Undefined', LastName = 'Participant', Email = '');
		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert new List<Contact>{testContact1, testContact2, testContact3, testContact4, undefined, firstGroupLeader};

		Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event1 = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event1;

		Event_Registration_Group__c group1 = new Event_Registration_Group__c(Name = 'Group1', Contact__c = firstGroupLeader.Id);
		insert group1;

		Event_Registration_Sub_Group__c subGroup1_1 = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group1.Id);
		insert subGroup1_1;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c sologroup1_1 = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);

		Participant__c group1_1_1 = new Participant__c(Contact__c = testContact1.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_2 = new Participant__c(Contact__c = testContact2.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_3 = new Participant__c(Contact__c = testContact3.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_4 = new Participant__c(Contact__c = testContact4.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);

		Participant__c group1_2_1 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_2_2 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		insert new List<Participant__c>{sologroup1_1, group1_1_1, group1_1_2, group1_1_3, group1_1_4, group1_2_1, group1_2_2};

		Order__c ordergroup1_1 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event1.Id, Event_Registration_Sub_Group__c = subGroup1_1.Id);
		insert ordergroup1_1;

        List<String> groupParticipantIds = new List<String>();
        groupParticipantIds.add('' + group1_1_1.Id);
        groupParticipantIds.add('' + group1_1_2.Id);
        groupParticipantIds.add('' + group1_1_3.Id);
        groupParticipantIds.add('' + group1_1_4.Id);
        groupParticipantIds.add('' + group1_2_1.Id);
        groupParticipantIds.add('' + group1_2_2.Id);


        ParticipantTriggerHelper.groupParticipantRegistration(groupParticipantIds);
        ParticipantTriggerHelper.sendEmailToSubmitedGroupParticipants(new List<Participant__c>{sologroup1_1, group1_1_1, group1_1_2, group1_1_3, group1_1_4, group1_2_1, group1_2_2});

        System.assertNotEquals(0, [SELECT COUNT() FROM Email_Activity__c]);
    }

}