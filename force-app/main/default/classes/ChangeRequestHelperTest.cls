@IsTest
public with sharing class ChangeRequestHelperTest {
    @IsTest
    static void oneRecordTest() {
        
        Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
        insert firstGroupLeader;

        Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		insert new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
        
        Change_Request__c cr = new Change_Request__c(
            Contact__c = firstGroupLeader.Id, 
            Type__c = 'Solo Registration Cancellation',
            Status__c = 'In Progress'
        );

        insert cr;

        cr.Status__c = 'Approved';

        update cr;

        List<Email_activity__c> eAs = [SELECT Id, Event_custom__c, Type__c, Change_Request__c, Contact__c, Send_To_Email__c FROM Email_activity__c];
        
        System.assertEquals(1, eAs.size());
        System.assertEquals(cr.Type__c, eAs[0].Type__c);
        System.assertEquals(cr.Id, eAs[0].Change_Request__c);
        System.assertEquals(firstGroupLeader.Id, eAs[0].Contact__c);
        System.assertEquals(firstGroupLeader.Email, eAs[0].Send_To_Email__c);
    
    }
    @IsTest
    static void balkRecordsTest() {
        
        Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
        insert firstGroupLeader;

        Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		insert new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
        
        List<Change_Request__c> crs = new List<Change_Request__c>();

        for (Integer i = 0; i < 200; i++) {
            crs.add(
                new Change_Request__c(
                    Contact__c = firstGroupLeader.Id, 
                    Type__c = 'Solo Registration Cancellation',
                    Status__c = 'In Progress'
                )
            );
        }
        
        insert crs;

        for (Integer i = 0; i < 200; i++) {
            crs[i].Status__c = 'Approved';
        }
        update crs;

        List<Email_activity__c> eAs = [SELECT Id, Event_custom__c, Type__c, Change_Request__c, Contact__c, Send_To_Email__c FROM Email_activity__c];
        
        System.assertEquals(200, eAs.size());
        System.assertEquals(crs[0].Type__c, eAs[0].Type__c);
        System.assertEquals(firstGroupLeader.Id, eAs[0].Contact__c);
        System.assertEquals(firstGroupLeader.Email, eAs[0].Send_To_Email__c);
    }
}