@isTest
private class MyRegistrationsControllerTest {

	@isTest
	static void myRegistrationsControllerMainTest() {

		Contact testContact1 = new Contact(FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com');
		Contact testContact2 = new Contact(FirstName = 'testFirst2', LastName = 'testLast2', Email = 'testmail2@nomail.com');
		Contact testContact3 = new Contact(FirstName = 'testFirst3', LastName = 'testLast3', Email = 'testmail3@nomail.com');
		Contact testContact4 = new Contact(FirstName = 'testFirst4', LastName = 'testLast4', Email = 'testmail4@nomail.com');
		Contact undefined = new Contact(FirstName = 'Undefined', LastName = 'Participant', Email = '');
		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		Contact secondGroupLeader = new Contact(FirstName = 'Leader2First', LastName = 'Leader2Last', Email = 'leader2@nomail.com');
		insert new List<Contact>{testContact1, testContact2, testContact3, testContact4, undefined, firstGroupLeader, secondGroupLeader};

		Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event1 = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		Event__c event2 = new Event__c(Name = 'Event2', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		Event__c event3 = new Event__c(Name = 'Event3', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert new List<Event__c>{event1, event2, event3};

		Event_Registration_Group__c group1 = new Event_Registration_Group__c(Name = 'Group1', Contact__c = firstGroupLeader.Id);
		Event_Registration_Group__c group2 = new Event_Registration_Group__c(Name = 'Group2', Contact__c = secondGroupLeader.Id);
		insert new List<Event_Registration_Group__c>{group1, group2};

		Event_Registration_Sub_Group__c subGroup1_1 = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group1.Id);
		Event_Registration_Sub_Group__c subGroup1_2 = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group1.Id);
		Event_Registration_Sub_Group__c subGroup2_1 = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group2.Id);
		insert new List<Event_Registration_Sub_Group__c>{subGroup1_1, subGroup1_2, subGroup2_1};

		// Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();
		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c solosolo = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
		Participant__c sologroup1_1 = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c sologroup2_1 = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event3.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup2_1.Id);

		Participant__c group1_1_1 = new Participant__c(Contact__c = testContact1.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_2 = new Participant__c(Contact__c = testContact2.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_3 = new Participant__c(Contact__c = testContact3.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_4 = new Participant__c(Contact__c = testContact4.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);

		Participant__c group1_2_1 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_2.Id);
		Participant__c group1_2_2 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event2.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_2.Id);

		Participant__c group2_1_1 = new Participant__c(Contact__c = testContact1.Id, Event_custom__c = event3.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup2_1.Id);
		Participant__c group2_1_2 = new Participant__c(Contact__c = testContact2.Id, Event_custom__c = event3.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup2_1.Id);
		insert new List<Participant__c>{solosolo, sologroup1_1, sologroup2_1, group1_1_1, group1_1_2, group1_1_3, group1_1_4, group1_2_1, group1_2_2, group2_1_1, group2_1_2};

		Order__c ordersolo1 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event1.Id);
		Order__c ordergroup1_1 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event2.Id, Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Order__c ordergroup1_2 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event2.Id, Event_Registration_Sub_Group__c = subGroup1_2.Id);
		Order__c ordergroup2_1 = new Order__c(Contact__c = secondGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event3.Id, Event_Registration_Sub_Group__c = subGroup2_1.Id);
		insert new List<Order__c>{ordersolo1, ordergroup1_1, ordergroup1_2, ordergroup2_1};

		Map<String, Object> result = MyRegistrationsController.getMyRegistrations(new Map<String, Object>{'params' => JSON.serialize(new Map<String, String>{'contactRecordId' => '' + firstGroupLeader.Id})});
		System.assertEquals(3, ((List<MyRegistrationsController.EventRegistrationWrap>) result.get('registrationsSolo')).size());
		System.assertEquals(1, ((List<MyRegistrationsController.EventRegistrationWrap>) result.get('registrationsGroup')).size());

		Change_Request__c newCr = new Change_Request__c(Contact__c = firstGroupLeader.Id, Type__c = MyRegistrationsController.CR_TYPE_GROUP_CANCELLATION, Event_Registration_Group__c = group1.Id, Status__c = 'In Progress');
		insert newCr;
		result = MyRegistrationsController.getMyRegistrations(new Map<String, Object>{'params' => JSON.serialize(new Map<String, String>{'contactRecordId' => '' + firstGroupLeader.Id, 'selectedCRType' => MyRegistrationsController.CR_TYPE_SOLO_CANCELLATION})});
		System.assertEquals(MyRegistrationsController.AVAILABLE_MY_REGISTRATIONS_FOR_CR_LABEL, String.valueOf(result.get('myRegistrationsLabel')));
	}
}