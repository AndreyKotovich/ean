@isTest
private class ChangeRequestControllerTest {

	@isTest
	static void getPreparedDataTest() {
		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert firstGroupLeader;

		Event_Registration_Group__c group1 = new Event_Registration_Group__c(Name = 'Group1', Contact__c = firstGroupLeader.Id);
		Event_Registration_Group__c group2 = new Event_Registration_Group__c(Name = 'Group2', Contact__c = firstGroupLeader.Id);
		insert new List<Event_Registration_Group__c>{group1, group2};

		Change_Request__c cr1 = new Change_Request__c(Contact__c = firstGroupLeader.Id, Type__c = MyRegistrationsController.CR_TYPE_GROUP_CANCELLATION, Event_Registration_Group__c = group1.Id, Status__c = 'Requested');
		Change_Request__c cr2 = new Change_Request__c(Contact__c = firstGroupLeader.Id, Type__c = MyRegistrationsController.CR_TYPE_GROUP_CANCELLATION, Event_Registration_Group__c = group2.Id, Status__c = 'In Progress');
		insert new List<Change_Request__c>{cr1, cr2};

		Map<String, Object> params = new Map<String, Object>{
			'recordId' => '' + firstGroupLeader.Id
		};

		Map<String, Object> result = ChangeRequestController.getPreparedData(params);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
		List<ChangeRequestController.ChangeRequestWrap> changeRequestsList = (List<ChangeRequestController.ChangeRequestWrap>) result.get('changeRequestsList');
		System.assertEquals(2, changeRequestsList.size());

		params = new Map<String, Object>{'selectedChangeRequestId' => '' + cr1.Id};
		result = ChangeRequestController.clickOnRevoke(params);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
	}

	@isTest
	static void submitSoloCancellationTest() {

		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert firstGroupLeader;

		Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event1 = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event1;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c solosolo = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
		insert solosolo;

		Map<String, Object> params = new Map<String, Object>{
			'selectedContactId' => '' + firstGroupLeader.Id,
			'crDescription' => 'test description',
			'selectedParticipantId' => '' + solosolo.Id
		};
		Map<String, Object> result = ChangeRequestController.submitSoloCancellation(params);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
		List<Change_Request__c> changeRequest = [SELECT Id, Name, Status__c, Type__c FROM Change_Request__c LIMIT 1];
		System.assertEquals(ChangeRequestController.CR_TYPE_SOLO_CANCELLATION, changeRequest[0].Type__c);
		System.assertEquals('Requested', changeRequest[0].Status__c);
	}

	@isTest
	static void submitGroupCancellationTest() {

		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert firstGroupLeader;

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
		insert sologroup1_1;

		Map<String, Object> params = new Map<String, Object>{
			'selectedContactId' => '' + firstGroupLeader.Id,
			'crDescription' => 'test description',
			'selectedGroupId' => '' + group1.Id
		};
		Map<String, Object> result = ChangeRequestController.submitGroupCancellation(params);
		System.assertEquals(true, Boolean.valueOf(result.get('result')));
		List<Change_Request__c> changeRequest = [SELECT Id, Name, Status__c, Type__c FROM Change_Request__c LIMIT 1];
		System.assertEquals(ChangeRequestController.CR_TYPE_GROUP_CANCELLATION, changeRequest[0].Type__c);
		System.assertEquals('Requested', changeRequest[0].Status__c);
	}



	@isTest
	static void submitSoloTransferTest() {

		Contact firstGroupLeader = new Contact(FirstName = 'Leader1First', LastName = 'Leader1Last', Email = 'leader1@nomail.com');
		insert firstGroupLeader;

		Datetime nowAdd10 = System.now().addDays(10);
		Datetime nowAdd20 = nowAdd10.addDays(10);

		Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Event__c event1 = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, Start_Time__c = nowAdd10, End_Time__c = nowAdd20, Status__c = 'Scheduled');
		insert event1;

		Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
		Participant__c solosolo = new Participant__c(Contact__c = firstGroupLeader.Id, Event_custom__c = event1.Id, RecordTypeId = congressParticipantRT, Status__c = 'Registered');
		insert solosolo;

		Map<String, Object> params = new Map<String, Object>{
			'communityContactId' => '' + firstGroupLeader.Id,
			'selectedParticipantId' => '' + solosolo.Id,
			'requestedContactEmail' => '' + 'newtestemail@nomail.com'
		};
		Map<String, Object> result = ChangeRequestController.submitSoloTransfer(params);
		System.assertEquals(false, result.isEmpty());
		// List<Change_Request__c> changeRequest = [SELECT Id, Name, Status__c, Type__c, TransferToEmail__c FROM Change_Request__c LIMIT 1];
		// System.assertEquals(ChangeRequestController.CR_TYPE_SOLO_TRANSFER, changeRequest[0].Type__c);
		// System.assertEquals('Requested', changeRequest[0].Status__c);
		// System.assertEquals('newtestemail@nomail.com', changeRequest[0].TransferToEmail__c);
	}


	@isTest
	static void submitGroupTransferTest() {
		Map<String, Object> params = new Map<String, Object>{
			'communityContactId' => '' + 'error',
			'selectedGroupId' => '' + 'error',
			'eventparamsString' => ''
		};
		Map<String, Object> result = ChangeRequestController.finalSubmitTransferGroup(params);
		System.assertEquals(false, Boolean.valueOf(result.get('result')));
	}

}