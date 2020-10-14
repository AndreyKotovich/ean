public without sharing class MyRegistrationsController {

	public static final String STATUS_PAID = 'Paid';					//	on order and on 'my registrations'
	public static final String STATUS_NOT_PAID = 'Not Paid';			//	on 'my registrations'
	public static final String STATUS_PARTIAL_PAID = 'Partial Paid';	//	on 'my registrations'
	public static final String STATUS_NO_ORDERS = 'No Orders';			//	on 'my registrations'

	public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';


	//	COMMUNITY PAGE: MY REGISTRAIONS
	@AuraEnabled
	public static Map<String, Object> connectedCallbackApex() {
		return connectedCallbackApex2(UserInfo.getUserId());
	}

	public static Map<String, Object> connectedCallbackApex2(Id userId) {
		try {

			// DELETE
			List<String> logList = new List<String>();

			// Id userId = UserInfo.getUserId();
			List<User> currentUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];
			Id contactId = currentUser[0].ContactId;
			Id accountId = currentUser[0].Contact.AccountId;
			Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();

			List<Participant__c> allMyParticipations = [
				SELECT Id, Name, Contact__c,
					Event_custom__c, Event_custom__r.Name, Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c,
					Event_Registration_Sub_Group__c, Event_Registration_Sub_Group__r.Max_Participants__c,
					Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
					Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name
				FROM Participant__c
				WHERE (Contact__c =:contactId OR Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:contactId)
				AND RecordTypeId !=:g2mRT
			];

			//	SOLO
			Map<String, EventRegistrationWrap> registrationsMapSolo = new Map<String, EventRegistrationWrap>();		// participantId TO Details

			Map<String, String> subGroupIdToParticipantId = new Map<String, String>();

			//	GROUP
			Map<String, EventRegistrationWrap> groupIdToRegistrationDetails = new Map<String, EventRegistrationWrap>();
			Map<String, List<String>> groupIdToProcessedSubGroups = new Map<String, List<String>>();
			Map<String, Integer> groupIdToMaxParticipants = new Map<String, Integer>();
			Map<String, Integer> groupIdToExistingParticipants = new Map<String, Integer>();

			for (Participant__c participation : allMyParticipations) {

				EventRegistrationWrap myRegistration = new EventRegistrationWrap();
				myRegistration.participantId = '' + participation.Id;
				myRegistration.eventId = '' + participation.Event_custom__c;
				myRegistration.eventName = participation.Event_custom__c != null ? participation.Event_custom__r.Name : '';
				myRegistration.eventEndTime = participation.Event_custom__c != null ? participation.Event_custom__r.End_Time__c : null;						//	Datetime
				myRegistration.eventStartTime = participation.Event_custom__c != null ? participation.Event_custom__r.Start_Time__c : null;					//	Datetime
				myRegistration.eventEndDateString = myRegistration.eventEndTime != null ? (myRegistration.eventEndTime).format('dd.MM.yyyy') : '';
				myRegistration.eventStartDateString = myRegistration.eventStartTime != null ? (myRegistration.eventStartTime).format('dd.MM.yyyy') : '';
				myRegistration.eventEndTimeString = myRegistration.eventEndTime != null ? (myRegistration.eventEndTime).format('HH:mm') : '';
				myRegistration.eventStartTimeString = myRegistration.eventStartTime != null ? (myRegistration.eventStartTime).format('HH:mm') : '';

				myRegistration.registrationStatus = STATUS_NO_ORDERS;

				myRegistration.registrationGroupId = participation.Event_Registration_Sub_Group__c != null ? '' + participation.Event_Registration_Sub_Group__r.Event_Registration_Group__c : '';
				myRegistration.registrationGroupName = participation.Event_Registration_Sub_Group__c != null ? '' + participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name : '';
				myRegistration.registrationGroupLeaderName = participation.Event_Registration_Sub_Group__c != null && participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c != null
					? '' + participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name : '';
				myRegistration.registrationSubGroupId = participation.Event_Registration_Sub_Group__c != null ? '' + participation.Event_Registration_Sub_Group__c : '';

				if (!String.isBlank(myRegistration.registrationSubGroupId)) subGroupIdToParticipantId.put(myRegistration.registrationSubGroupId, myRegistration.participantId);

				//	event participations where the user was participated (NOTE: he can patricipate himself at group, where he is a group leader)
				if (participation.Contact__c == contactId) {
					myRegistration.registrationType = participation.Event_Registration_Sub_Group__c != null ? 'Group' : 'Solo';
					registrationsMapSolo.put(myRegistration.participantId, myRegistration);
				}

				// logList.add('participantId=' + myRegistration.participantId + ' 1 RULE= ' + Boolean.valueOf(participation.Event_custom__c != null) +
				// 	' 2 RULE= ' + Boolean.valueOf(participation.Event_Registration_Sub_Group__c != null) +
				// 	' 3 RULE= ' + Boolean.valueOf(participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c == contactId) +
				// 	' 4 ContactId = ' + contactId +
				// 	' 5 RULE= ' + participation.Event_Registration_Sub_Group__c +
				// 	' 6 RULE= ' + participation.Event_Registration_Sub_Group__r.Event_Registration_Group__c +
				// 	' 7 RULE= ' + participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c +
				// 	' 8 RULE= ' + JSON.serialize(participation));

				//	event participations where the user is group leader
				if (participation.Event_custom__c != null && participation.Event_Registration_Sub_Group__c != null && participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c == contactId) {

					// system.debug('AAA myRegistration.eventId= ' + myRegistration.eventId);
					// system.debug('AAA myRegistration.participantId= ' + myRegistration.participantId);

					myRegistration.registrationType = 'Group';

					List<String> processedSubGroups = groupIdToProcessedSubGroups.containsKey(myRegistration.registrationGroupId) ? groupIdToProcessedSubGroups.get(myRegistration.registrationGroupId) : new List<String>();
					Integer groupMaxParticipants = groupIdToMaxParticipants.containsKey(myRegistration.registrationGroupId) ? groupIdToMaxParticipants.get(myRegistration.registrationGroupId) : 0;
					Integer subGroupMaxParticipants = participation.Event_Registration_Sub_Group__r.Max_Participants__c != null ? Integer.valueOf(participation.Event_Registration_Sub_Group__r.Max_Participants__c) : 0;
					Integer groupExistingParticipants = groupIdToExistingParticipants.containsKey(myRegistration.registrationGroupId) ? groupIdToExistingParticipants.get(myRegistration.registrationGroupId) : 0;

					groupMaxParticipants += !processedSubGroups.contains(myRegistration.registrationSubGroupId) ? subGroupMaxParticipants : 0;


					//	TODO: ADD LOGIC FOR SKIP EMPTY PARTICIPANTS (check name, or temp_contact_name)
					groupExistingParticipants++;

					processedSubGroups.add(myRegistration.registrationSubGroupId);

					groupIdToProcessedSubGroups.put(myRegistration.registrationGroupId, processedSubGroups);
					groupIdToMaxParticipants.put(myRegistration.registrationGroupId, groupMaxParticipants);
					groupIdToExistingParticipants.put(myRegistration.registrationGroupId, groupExistingParticipants);

					myRegistration.groupMaxParticipants = groupMaxParticipants;
					myRegistration.groupExistingParticipants = groupExistingParticipants;
					// groupIdToRegistrationDetails.put(myRegistration.registrationGroupId, myRegistration);

					EventRegistrationWrap cloned = myRegistration.clone();
					groupIdToRegistrationDetails.put(myRegistration.registrationGroupId, cloned);
				}
			}

			system.debug('1 registrationsMapSolo= ' + JSON.serialize(registrationsMapSolo));
			system.debug('1 groupIdToRegistrationDetails= ' + JSON.serialize(groupIdToRegistrationDetails));

			//	For SOLO STATUS and GROUP STATUS
			// List<Order__c> groupOrders = !subGroupsIds.isEmpty() ? [
			List<Order__c> groupOrders = !groupIdToRegistrationDetails.isEmpty() ? [
				SELECT Id, Event_Registration_Sub_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__c, Status__c
				FROM Order__c
				// WHERE Event_Registration_Sub_Group__r.Event_Registration_Group__c IN :groupIdToRegistrationDetails.keySet()
				WHERE Event_Registration_Sub_Group__c IN :subGroupIdToParticipantId.keySet()
				AND Status__c != 'Closed'
			] : new List<Order__c>();

			//	SOLO STATUS
			List<Order_Item__c> soloOrderItems = !registrationsMapSolo.isEmpty() ? [
				SELECT Id, Event_Participation__c, Order_Custom__c, Order_Custom__r.Status__c
				FROM Order_Item__c
				WHERE Event_Participation__c IN :registrationsMapSolo.keySet()
				AND Order_Custom__r.Status__c != 'Closed'
			] : new List<Order_Item__c>();

			Map<String, String> participantIdToOrderStatus = new Map<String, String>();
			for (Order_Item__c item : soloOrderItems) {
				if (registrationsMapSolo.containsKey('' + item.Event_Participation__c)) {
					String registrationStatus = item.Order_Custom__r.Status__c == 'Opened' ? STATUS_NOT_PAID : item.Order_Custom__r.Status__c;
					registrationsMapSolo.get('' + item.Event_Participation__c).registrationStatus = registrationStatus;
				}
			}
			for (Order__c groupOrder : groupOrders) {
				if (subGroupIdToParticipantId.containsKey('' + groupOrder.Event_Registration_Sub_Group__c)) {
					String participantId = subGroupIdToParticipantId.get('' + groupOrder.Event_Registration_Sub_Group__c);
					String registrationStatus = groupOrder.Status__c == 'Opened' ? STATUS_NOT_PAID : groupOrder.Status__c;
					registrationsMapSolo.get(participantId).registrationStatus = registrationStatus;
				}
				
			}

			system.debug('2 registrationsMapSolo= ' + JSON.serialize(registrationsMapSolo));
			system.debug('2 groupIdToRegistrationDetails= ' + JSON.serialize(groupIdToRegistrationDetails));

			//	GROUP STATUS
			for (Order__c groupOrder : groupOrders) {
				if (groupIdToRegistrationDetails.containsKey('' + groupOrder.Event_Registration_Sub_Group__r.Event_Registration_Group__c)) {
					EventRegistrationWrap registrationDetails = groupIdToRegistrationDetails.get('' + groupOrder.Event_Registration_Sub_Group__r.Event_Registration_Group__c);
					String orderStatus = groupOrder.Status__c == 'Opened' ? STATUS_NOT_PAID : groupOrder.Status__c;
					String registrationStatus = orderStatus == STATUS_PAID && registrationDetails.registrationStatus == STATUS_NO_ORDERS ? orderStatus
						: orderStatus == STATUS_NOT_PAID && registrationDetails.registrationStatus == STATUS_NO_ORDERS ? STATUS_NOT_PAID
							: orderStatus == STATUS_NOT_PAID && registrationDetails.registrationStatus == STATUS_PAID ? STATUS_PARTIAL_PAID
								: orderStatus == STATUS_PAID && registrationDetails.registrationStatus == STATUS_NOT_PAID ? STATUS_PARTIAL_PAID
									: registrationDetails.registrationStatus;
					groupIdToRegistrationDetails.get('' + groupOrder.Event_Registration_Sub_Group__r.Event_Registration_Group__c).registrationStatus = registrationStatus;
				}
			}

			List<EventRegistrationWrap> registrationsSolo = sortEventRegistrationsMap(registrationsMapSolo);
			List<EventRegistrationWrap> registrationsGroup = sortEventRegistrationsMap(groupIdToRegistrationDetails);
			system.debug('3 registrationsMapSolo= ' + JSON.serialize(registrationsMapSolo));
			system.debug('3 groupIdToRegistrationDetails= ' + JSON.serialize(groupIdToRegistrationDetails));

			return new Map<String, Object>{
				'result' => true,
				'userId' => userId,
				'contactId' => contactId,
				'accountId' => accountId,
				'registrationsSolo' => registrationsSolo,
				'registrationsGroup' => registrationsGroup,
				'displayRegistrationsSolo' => !registrationsSolo.isEmpty(),
				'displayRegistrationsGroup' => !registrationsGroup.isEmpty(),
				'displayNoRegistrationMessage' => registrationsSolo.isEmpty() && registrationsGroup.isEmpty(),
				'logList' => logList
			};

		} catch (Exception e) { return new Map<String, Object>{'result' => false, 'message' => e.getMessage()}; }
	}

	public static List<EventRegistrationWrap> sortEventRegistrationsMap(Map<String, EventRegistrationWrap> eventRegistrationsMap) {

		Datetime now = System.now();

		Map<String, EventRegistrationWrap> eventRegistrationsMapFirstPriority = new Map<String, EventRegistrationWrap>();
		Map<String, EventRegistrationWrap> eventRegistrationsMapSecondPriority = new Map<String, EventRegistrationWrap>();
		for (String eventRegistrationId : eventRegistrationsMap.keySet()) {
			EventRegistrationWrap eventRegistration = eventRegistrationsMap.get(eventRegistrationId);
			if ((eventRegistration.eventStartTime == null && eventRegistration.eventEndTime == null)
				|| (eventRegistration.eventStartTime != null && eventRegistration.eventStartTime > now)
				|| (eventRegistration.eventEndTime != null && eventRegistration.eventEndTime > now)
			) {
				eventRegistrationsMapFirstPriority.put(eventRegistrationId, eventRegistration);
			} else {
				eventRegistrationsMapSecondPriority.put(eventRegistrationId, eventRegistration);
			}
		}

		List<EventRegistrationWrap> result = new List<EventRegistrationWrap>();
		result.addAll(sortEventRegistrationsMap2(eventRegistrationsMapFirstPriority));
		result.addAll(sortEventRegistrationsMap2(eventRegistrationsMapSecondPriority));
		return result;
	}

	public static List<EventRegistrationWrap> sortEventRegistrationsMap2(Map<String, EventRegistrationWrap> eventRegistrationsMap) {
		List<EventRegistrationWrap> result = new List<EventRegistrationWrap>();
		if (eventRegistrationsMap.isEmpty()) return result;

		List<Datetime> dateTimeListToSort = new List<Datetime>();
		for (EventRegistrationWrap eventRegistration : eventRegistrationsMap.values()) dateTimeListToSort.add(eventRegistration.eventStartTime);	// 	sort by Start Datetime

		dateTimeListToSort.sort();

		for (Datetime eventTime : dateTimeListToSort) {
			for (String eventRegistrationId : eventRegistrationsMap.keySet()) {
				EventRegistrationWrap eventRegistration = eventRegistrationsMap.get(eventRegistrationId);
				if (eventRegistration.eventStartTime == eventTime) {						// 	sort by Start Datetime
					result.add(eventRegistration);
					eventRegistrationsMap.remove(eventRegistrationId);
					break;
				}
			}
		}

		if (!eventRegistrationsMap.isEmpty()) result.addAll(eventRegistrationsMap.values());
		return result;
	}


	public class EventRegistrationWrap {
		@AuraEnabled public String participantId { get; set; }					// SOLO
		@AuraEnabled public String eventId { get; set; }						// SOLO		// GROUP
		@AuraEnabled public String eventName { get; set; }						// SOLO		// GROUP
		@AuraEnabled public Datetime eventEndTime { get; set; }					// SOLO		// GROUP
		@AuraEnabled public Datetime eventStartTime { get; set; }				// SOLO		// GROUP
		@AuraEnabled public String eventEndDateString { get; set; }				// SOLO		// GROUP
		@AuraEnabled public String eventStartDateString { get; set; }			// SOLO		// GROUP
		@AuraEnabled public String eventEndTimeString { get; set; }				// SOLO		// GROUP
		@AuraEnabled public String eventStartTimeString { get; set; }			// SOLO		// GROUP
		@AuraEnabled public String registrationType { get; set; }				// SOLO
		@AuraEnabled public String registrationStatus { get; set; }				// SOLO		// GROUP
		@AuraEnabled public String registrationGroupId { get; set; }			// SOLO		// GROUP
		@AuraEnabled public String registrationGroupName { get; set; }			// SOLO		// GROUP
		@AuraEnabled public String registrationGroupLeaderName { get; set; }	// SOLO
		@AuraEnabled public String registrationSubGroupId { get; set; }			// SOLO
		@AuraEnabled public Integer groupExistingParticipants { get; set; }					// GROUP
		@AuraEnabled public Integer groupMaxParticipants { get; set; }						// GROUP
	}


	//	COMMUNITY PAGE: GROUP DETAILS
	@AuraEnabled
	public static Map<String, Object> connectedCallbackGetGroupDetails(Map<String, Object> settings) {

		String userId = settings.containsKey('userId') ? String.valueOf(settings.get('userId')) : '0050E000007hFBsQAM';
		String groupId = settings.containsKey('groupId') ? String.valueOf(settings.get('groupId')) : 'a0H0E0000095GLNUA2';

		String maxParticipantsString = settings.containsKey('maxParticipants') ? String.valueOf(settings.get('maxParticipants')) : null;
		Integer maxParticipants = !String.isBlank(maxParticipantsString) ? Integer.valueOf(maxParticipantsString) : null;

		//	TEST GROUP DEFINITION
		// maxParticipants = 10;

		if (maxParticipants == null) return getExistingGroupDetails(userId, groupId);


		// LOGIC TO PREPARE DATA FOR NEW GROUP
		String uniqueKey1 = 'createNewGroupMode';
		// Integer uniqueKey2 = 0;

		GroupDetailsWrap groupDetails = new GroupDetailsWrap();
		groupDetails.groupId = uniqueKey1;
		// groupDetails.groupName = '';
		// groupDetails.eventName = '';
		// groupDetails.eventEndTime = null;		//	Datetime
		// groupDetails.eventStartTime = null;		//	Datetime
		// groupDetails.eventEndDateString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('dd.MM.yyyy') : '';
		// groupDetails.eventStartDateString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('dd.MM.yyyy') : '';
		// groupDetails.eventEndTimeString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('HH:mm') : '';
		// groupDetails.eventStartTimeString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('HH:mm') : '';
		groupDetails.registrationStatus = 'HARD CODED';
		groupDetails.totalGroupExistingParticipants = 0;
		groupDetails.totalGroupMaxParticipants = maxParticipants;

		List<SubGroupParticipantWrap> subGroupParticipantList = new List<SubGroupParticipantWrap>();
		for (Integer index = 0 ; index < maxParticipants ; index++) {
			SubGroupParticipantWrap subGroupParticipant = new SubGroupParticipantWrap();
			subGroupParticipant.participantId = '';
			subGroupParticipant.oldContactId = '';
			subGroupParticipant.oldContactName = '';
			subGroupParticipant.oldContactEmail = '';
			subGroupParticipant.newContactId = '';
			subGroupParticipant.newContactName = '';
			subGroupParticipant.newContactEmail = '';
			subGroupParticipant.uniquekey1 = uniqueKey1;
			subGroupParticipant.uniquekey2 = '' + index;
			subGroupParticipant.disabledToEdit = false;
			subGroupParticipantList.add(subGroupParticipant);
		}
		List<SubGroupDetailsWrap> subGroupList = new List<SubGroupDetailsWrap>();
		SubGroupDetailsWrap newSubGroup = new SubGroupDetailsWrap();
		newSubGroup.subGroupId = uniqueKey1;
		newSubGroup.subGroupExistingParticipants = 0;
		newSubGroup.subGroupMaxParticipants = maxParticipants;
		newSubGroup.subGroupParticipantList = subGroupParticipantList;
		newSubGroup.accordionTitle = 'Please add participants to a new group';
		// newSubGroup.createdDateString = '';
		// newSubGroup.createdTimeString = '';
		subGroupList.add(newSubGroup);

		return new Map<String, Object>{
			'result' => true,
			'groupDetails' => groupDetails,
			'subGroupList' => subGroupList,
			'logList' => new List<String>(),	// DELETE
			'disableDisplayGroupDetails' => true,
			'disableDisplayGroupDefinition' => false,
			'disalbeDisplayAccordions' => true,
			'disalbeDisplayButton1' => false,
			'disalbeDisplayButton2' => true,
			'button1Label' => 'Submit',
			'button2Label' => 'Cancel'
		};

	}

	public static Map<String, Object> getExistingGroupDetails(String userId, String groupId) {

		List<String> logList = new List<String>();	// DELETE

		system.debug('getExistingGroupDetails userId= ' + userId);
		system.debug('getExistingGroupDetails groupId= ' + groupId);
		if (userId == null || String.isBlank(groupId)) {
			return new Map<String, Object>{'result' => false, 'message' => 'User or Group not found.'};
		}

			// Id userId = UserInfo.getUserId();
			List<User> currentUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];
			Id contactId = currentUser[0].ContactId;
			Id accountId = currentUser[0].Contact.AccountId;

			Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();

			List<Participant__c> groupParticipations = [
				SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Email,
					Event_custom__c, Event_custom__r.Name, Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c,
					Event_Registration_Sub_Group__c, Event_Registration_Sub_Group__r.Max_Participants__c, Event_Registration_Sub_Group__r.CreatedDate,
					Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
					Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name,
					(SELECT Id FROM Order_Items__r LIMIT 1)	// to lock record if we have order item for participant
				FROM Participant__c
				WHERE Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:contactId
				AND RecordTypeId !=:g2mRT
				AND Event_Registration_Sub_Group__r.Event_Registration_Group__c =:groupId
				AND Contact__c != null
				AND Event_custom__c != null
				ORDER BY Event_Registration_Sub_Group__r.CreatedDate, LastModifiedDate
			];

		system.debug('groupParticipations= ' + JSON.serialize(groupParticipations));
		system.debug('111 SIZE= ' + groupParticipations.size());

		// delete
				logList.add(
					' 1 LOG= ' + JSON.serialize(groupParticipations) +
					' 2 LOG= ' + groupParticipations.size() +
					' 3 LOG= ' + userId +
					' 4 LOG= ' + groupId
				);


		if (groupParticipations.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Group configuration is not correct.'};

		Integer totalGroupExistingParticipants = 0;
		Integer totalGroupMaxParticipants = 0;
		// String undefinedParticipantContactId = '';

		List<String> subGroupsOrder = new List<String>();
		Map<String, SubGroupDetailsWrap> subGroupIdToDetailsWrap = new Map<String, SubGroupDetailsWrap>();
		for (Participant__c participant : groupParticipations) {
			SubGroupParticipantWrap subGroupParticipant = new SubGroupParticipantWrap();
			subGroupParticipant.participantId = '' + participant.Id;
			subGroupParticipant.oldContactId = '' + participant.Contact__c;
			subGroupParticipant.oldContactName = participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? '' : participant.Contact__r.Name;
			subGroupParticipant.oldContactEmail = '' + participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? '' : participant.Contact__r.Email;
			subGroupParticipant.newContactId = '' + subGroupParticipant.participantId;
			subGroupParticipant.newContactName = '' + subGroupParticipant.oldContactName;
			subGroupParticipant.newContactEmail = '' + subGroupParticipant.oldContactEmail;

			subGroupParticipant.disabledToEdit = !(participant.Order_Items__r).isEmpty();

			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.containsKey('' + participant.Event_Registration_Sub_Group__c)
				? subGroupIdToDetailsWrap.get('' + participant.Event_Registration_Sub_Group__c) : new SubGroupDetailsWrap();
			subGroupDetails.subGroupId = '' + participant.Event_Registration_Sub_Group__c;

			subGroupDetails.subGroupExistingParticipants = subGroupDetails.subGroupExistingParticipants == null ? 0 : subGroupDetails.subGroupExistingParticipants;
			subGroupDetails.subGroupExistingParticipants += participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? 0 : 1;
			totalGroupExistingParticipants += participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? 0 : 1;

			subGroupDetails.subGroupMaxParticipants = subGroupDetails.subGroupMaxParticipants == null ? 1 : subGroupDetails.subGroupMaxParticipants + 1;
			totalGroupMaxParticipants++;

			subGroupDetails.createdDateString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('dd.MM.yyyy');
			subGroupDetails.createdTimeString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('HH:mm');

			// subGroupParticipant.uniquekey1 = subGroupDetails.subGroupId + '_' + subGroupParticipant.participantId + '_key1';
			// subGroupParticipant.uniquekey2 = subGroupDetails.subGroupId + '_' + subGroupParticipant.participantId + '_key2';

			List<SubGroupParticipantWrap> subGroupParticipantList = subGroupDetails.subGroupParticipantList == null ? new List<SubGroupParticipantWrap>() : subGroupDetails.subGroupParticipantList;

			subGroupParticipant.uniquekey1 = subGroupDetails.subGroupId;
			subGroupParticipant.uniquekey2 = '' + subGroupParticipantList.size();	// index of participant in list

			subGroupParticipantList.add(subGroupParticipant);
			subGroupDetails.subGroupParticipantList = subGroupParticipantList;
			
			subGroupIdToDetailsWrap.put('' + participant.Event_Registration_Sub_Group__c, subGroupDetails);
			if (!subGroupsOrder.contains('' + participant.Event_Registration_Sub_Group__c)) subGroupsOrder.add('' + participant.Event_Registration_Sub_Group__c);
		}

		system.debug('subGroupIdToDetailsWrap= ' + JSON.serialize(subGroupIdToDetailsWrap));
		system.debug('222 SIZE= ' + subGroupIdToDetailsWrap.size());

		GroupDetailsWrap groupDetails = new GroupDetailsWrap();
		groupDetails.groupId = groupParticipations[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c;
		groupDetails.groupName = groupParticipations[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
		groupDetails.eventName = groupParticipations[0].Event_custom__r.Name;

		groupDetails.eventEndTime = groupParticipations[0].Event_custom__r.End_Time__c;		//	Datetime
		groupDetails.eventStartTime = groupParticipations[0].Event_custom__r.Start_Time__c;					//	Datetime
		groupDetails.eventEndDateString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('dd.MM.yyyy') : '';
		groupDetails.eventStartDateString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('dd.MM.yyyy') : '';
		groupDetails.eventEndTimeString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('HH:mm') : '';
		groupDetails.eventStartTimeString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('HH:mm') : '';

		groupDetails.registrationStatus = '(TBD) HARD CODED';
		groupDetails.totalGroupExistingParticipants = totalGroupExistingParticipants;
		groupDetails.totalGroupMaxParticipants = totalGroupMaxParticipants;

		List<SubGroupDetailsWrap> subGroupList = new List<SubGroupDetailsWrap>();
		for (String subGroupId : subGroupsOrder) {
			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.get(subGroupId);
			subGroupDetails.accordionTitle = 'Created: ' + subGroupDetails.createdDateString + ' ' + subGroupDetails.createdTimeString +
			' (Selected ' + subGroupDetails.subGroupExistingParticipants + ' of ' + subGroupDetails.subGroupMaxParticipants + ' Participants)';

			subGroupList.add(subGroupDetails);
			// subGroupList.add(subGroupIdToDetailsWrap.get(subGroupId));
		}

		return new Map<String, Object>{
			'result' => true,
			'groupDetails' => groupDetails,
			'subGroupList' => subGroupList,
			'logList' => logList,				// delete
			'disableDisplayGroupDetails' => false,
			'disableDisplayGroupDefinition' => true,
			'disalbeDisplayAccordions' => subGroupList.isEmpty(),
			'disalbeDisplayButton1' => false,
			'disalbeDisplayButton2' => false,
			'button1Label' => 'Submit',
			'button2Label' => 'Cancel'
		};
	}

	//	CLICK SUBMIT
	@AuraEnabled
	public static Map<String, Object> clickButton1Apex(Map<String, Object> params) {
		// String groupDetailsString = params.containsKey('groupDetails') ? String.valueOf(params.get('groupDetails')) : '';
		String subGroupListString = params.containsKey('subGroupList') ? String.valueOf(params.get('subGroupList')) : '';
		String isGroupDefinitionModeString = params.containsKey('isGroupDefinitionMode') ? String.valueOf(params.get('isGroupDefinitionMode')) : '';

		// GroupDetailsWrap groupDetails = !String.isBlank(groupDetailsString) ? (GroupDetailsWrap) JSON.deserialize (groupDetailsString, GroupDetailsWrap.class) : new GroupDetailsWrap();
		List<SubGroupDetailsWrap> subGroupList = !String.isBlank(subGroupListString) ? (List<SubGroupDetailsWrap>) JSON.deserialize (subGroupListString, List<SubGroupDetailsWrap>.class) : new List<SubGroupDetailsWrap>();
		Boolean isGroupDefinitionMode = !String.isBlank(isGroupDefinitionModeString) ? Boolean.valueOf(isGroupDefinitionModeString) : false;

		if (subGroupList.isEmpty() || subGroupList[0].subGroupParticipantList == null || subGroupList[0].subGroupParticipantList.isEmpty()) return new Map<String, Object>{'result' => false};

		if (isGroupDefinitionMode) {
			return new Map<String, Object>{
				'result' => true,
				'participantsString' => generateParticipants(subGroupList[0].subGroupParticipantList)
			};
		}

		//	TODO
		//	MODE EDIT GROUP
		//	UPDATE PARTICIPANTS

		return new Map<String, Object>{
			'result' => true,
			'participantsString' => ''
		};
	}

	//	used in 'GroupDefinitionMode'
	public static String generateParticipants(List<SubGroupParticipantWrap> subGroupParticipantList) {

		List<Participant__c> selectedParticipants = new List<Participant__c>();
		for (SubGroupParticipantWrap subGroupParticipant : subGroupParticipantList) {
			Participant__c newParticipant = new Participant__c();
			newParticipant.Contact__c = subGroupParticipant.newContactId;
			newParticipant.Participant_Email__c = subGroupParticipant.newContactEmail;
			selectedParticipants.add(newParticipant);
		}

		return JSON.serialize(selectedParticipants);
	}


	//	Group
	public class GroupDetailsWrap {
		@AuraEnabled public String groupId { get; set; }
		// @AuraEnabled public String undefinedParticipantContactd { get; set; }		// 'Undefined Participant' (Contact record Id)
		@AuraEnabled public String groupName { get; set; }
		@AuraEnabled public String eventName { get; set; }
		@AuraEnabled public Datetime eventEndTime { get; set; }
		@AuraEnabled public Datetime eventStartTime { get; set; }
		@AuraEnabled public String eventEndDateString { get; set; }
		@AuraEnabled public String eventStartDateString { get; set; }
		@AuraEnabled public String eventEndTimeString { get; set; }
		@AuraEnabled public String eventStartTimeString { get; set; }

		@AuraEnabled public String registrationStatus { get; set; }
		@AuraEnabled public Integer totalGroupExistingParticipants { get; set; }
		@AuraEnabled public Integer totalGroupMaxParticipants { get; set; }
	}

	//	Group Registration
	public class SubGroupDetailsWrap {
		@AuraEnabled public String subGroupId { get; set; }
		@AuraEnabled public Integer subGroupExistingParticipants { get; set; }
		@AuraEnabled public Integer subGroupMaxParticipants { get; set; }
		@AuraEnabled public List<SubGroupParticipantWrap> subGroupParticipantList { get; set; }

		@AuraEnabled public String accordionTitle { get; set; }
		@AuraEnabled public String createdDateString { get; set; }
		@AuraEnabled public String createdTimeString { get; set; }
	}

	//	Sub Group Participant
	public class SubGroupParticipantWrap {
		@AuraEnabled public String participantId { get; set; }
		@AuraEnabled public String oldContactId { get; set; }			//	???		'Undefined Participant' (Contact record Id)
		@AuraEnabled public String oldContactName { get; set; }
		@AuraEnabled public String oldContactEmail { get; set; }
		@AuraEnabled public String newContactId { get; set; }
		@AuraEnabled public String newContactName { get; set; }
		@AuraEnabled public String newContactEmail { get; set; }
		@AuraEnabled public String uniquekey1 { get; set; }				//	subGroupId
		@AuraEnabled public String uniquekey2 { get; set; }				//	index in list (0...)

		@AuraEnabled public Boolean disabledToEdit { get; set; }
	}
}