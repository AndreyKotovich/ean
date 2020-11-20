@isTest
private class GroupDetailsLeaderControllerTest {

	@isTest
	static void getExistingGroupTest() {
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
		Event_Registration_Sub_Group__c subGroup1_2 = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group1.Id);
		insert new List<Event_Registration_Sub_Group__c>{subGroup1_1, subGroup1_2};

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c sologroup1_1 = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);

		Participant__c group1_1_1 = new Participant__c(Contact__c = testContact1.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_2 = new Participant__c(Contact__c = testContact2.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_3 = new Participant__c(Contact__c = testContact3.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_4 = new Participant__c(Contact__c = testContact4.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);

		Participant__c group1_2_1 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_2.Id);
		Participant__c group1_2_2 = new Participant__c(Contact__c = undefined.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_2.Id);
		insert new List<Participant__c>{sologroup1_1, group1_1_1, group1_1_2, group1_1_3, group1_1_4, group1_2_1, group1_2_2};

		Order__c ordergroup1_1 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event1.Id, Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Order__c ordergroup1_2 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event1.Id, Event_Registration_Sub_Group__c = subGroup1_2.Id);
		insert new List<Order__c>{ordergroup1_1, ordergroup1_2};

		Map<String, Object> result = GroupDetailsLeaderController.getGroupDetails(new Map<String, String>{'contactRecordId' => '' + firstGroupLeader.Id, 'groupId' => '' + group1.Id});

		system.debug('TEST result: ' + JSON.serialize(result));

	}
}