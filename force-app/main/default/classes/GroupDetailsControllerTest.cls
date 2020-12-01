@isTest
private class GroupDetailsControllerTest {

	@isTest
	static void getEmptyGroupTest() {
		Map<String, Object> result = GroupDetailsController.getGroupDetails(new Map<String, Object>());

		List<GroupDetailsController.SubGroupDetailsWrap> subGroupList = (List<GroupDetailsController.SubGroupDetailsWrap>) result.get('subGroupList');
		System.assertEquals(1, subGroupList.size());

		List<GroupDetailsController.SubGroupParticipantWrap> subGroupParticipantList = subGroupList[0].subGroupParticipantList;
		System.assertEquals(10, subGroupParticipantList.size());
		System.assertEquals(10, subGroupList[0].subGroupMaxParticipants);
	}

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

		Map<String, Object> result = GroupDetailsController.getGroupDetails(new Map<String, Object>{'params' => JSON.serialize(new Map<String, String>{'contactRecordId' => '' + firstGroupLeader.Id, 'selectedGroupId' => '' + group1.Id})});
		System.assertEquals(true, Boolean.valueOf(result.get('displayAccordions')));
		System.assertEquals(false, Boolean.valueOf(result.get('isChangeRequestMode')));
	}


	@isTest
	static void clickSubmitRegistrationFlowTest() {

		Contact testContact1 = new Contact(FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com');
		Contact testContact2 = new Contact(FirstName = 'testFirst2', LastName = 'testLast2', Email = 'testmail2@nomail.com');
		insert new List<Contact>{testContact1, testContact2};

		List<GroupDetailsController.SubGroupDetailsWrap> subGroupList = new List<GroupDetailsController.SubGroupDetailsWrap>();
		GroupDetailsController.SubGroupDetailsWrap subGroupDetails = new GroupDetailsController.SubGroupDetailsWrap();

		List<GroupDetailsController.SubGroupParticipantWrap> subGroupParticipantList = new List<GroupDetailsController.SubGroupParticipantWrap>();
		GroupDetailsController.SubGroupParticipantWrap subGroupParticipant1 = new GroupDetailsController.SubGroupParticipantWrap();
		subGroupParticipant1.newContactId = '' + testContact1.Id;
		subGroupParticipant1.newContactEmail = testContact1.Email;
		GroupDetailsController.SubGroupParticipantWrap subGroupParticipant2 = new GroupDetailsController.SubGroupParticipantWrap();
		subGroupParticipant2.newContactId = '' + testContact2.Id;
		subGroupParticipant2.newContactEmail = testContact2.Email;
		subGroupParticipantList.add(subGroupParticipant1);
		subGroupParticipantList.add(subGroupParticipant2);

		subGroupDetails.subGroupParticipantList = subGroupParticipantList;
		subGroupList.add(subGroupDetails);

		Map<String, Object> params = new Map<String, Object>{
			'isGroupDefinitionMode' => true,
			'subGroupList' => JSON.serialize(subGroupList)
		};
		Map<String, Object> result = GroupDetailsController.clickSubmitRegistrationFlow(params);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
		System.assertEquals(true, !String.isBlank(String.valueOf(result.get('participantsString'))));
		System.assertNotEquals('[]', String.valueOf(result.get('participantsString')));
	}

	@isTest
	static void clickRequestCancellationGroupParticipantTest() {
		Contact testContact1 = new Contact(FirstName = 'testFirst1', LastName = 'testLast1', Email = 'testmail1@nomail.com');
		Contact testContact2 = new Contact(FirstName = 'testFirst2', LastName = 'testLast2', Email = 'testmail2@nomail.com');
		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert new List<Contact>{testContact1, testContact2, firstGroupLeader};

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
		Participant__c group1_1_1 = new Participant__c(Contact__c = testContact1.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		Participant__c group1_1_2 = new Participant__c(Contact__c = testContact2.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered', Event_Registration_Sub_Group__c = subGroup1_1.Id);
		insert new List<Participant__c>{group1_1_1, group1_1_2};

		GroupDetailsController.SubGroupParticipantWrap currentParticipant = new GroupDetailsController.SubGroupParticipantWrap();
		currentParticipant.participantId = '' + group1_1_1.Id;

		Map<String, Object> params = new Map<String, Object>{
			'participantDetailsString' => JSON.serialize(currentParticipant),
			'subGroupId' => '' + subGroup1_1.Id,
			'description' => 'testDescription',
			'contactRecordId' => '' + firstGroupLeader.Id
		};

		Order__c ordergroup1_1 = new Order__c(Contact__c = firstGroupLeader.Id, Status__c = 'Paid', Event_custom__c = event1.Id, Event_Registration_Sub_Group__c = subGroup1_1.Id);
		insert ordergroup1_1;

		Map<String, Object> result = GroupDetailsController.clickRequestCancellationGroupParticipant(params);
		system.debug('result: ' + JSON.serialize(result));

		System.assertEquals(true, Boolean.valueOf(String.valueOf(result.get('result'))));
	}

}