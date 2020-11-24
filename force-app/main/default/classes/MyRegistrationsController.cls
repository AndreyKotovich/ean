public without sharing class MyRegistrationsController {

	public static final String STATUS_PAID = 'Paid';					//	on order and on 'my registrations'
	// public static final String STATUS_NOT_PAID = 'Not Paid';			//	on 'my registrations'
	public static final String STATUS_NOT_PAID = 'Payment Pending';			//	on 'my registrations'
	public static final String STATUS_PARTIAL_PAID = 'Partial Paid';	//	on 'my registrations'
	public static final String STATUS_NO_ORDERS = 'No Orders';			//	on 'my registrations'

	public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';

	public static final String CR_TYPE_SOLO_CANCELLATION = 'Solo Registration Cancellation';
	public static final String CR_TYPE_GROUP_CANCELLATION = 'Full Group Registration Cancellation';
	public static final String CR_TYPE_SOLO_TRANSFER = 'Solo Registration Transfer';
	public static final String CR_TYPE_GROUP_TRANSFER = 'Group Registration Transfer';
	public static final String CR_TYPE_GROUP_INDIVIDUAL_CANCELLATION = 'Individual Participant Group Registration Cancellation';

	public static final String MY_REGISTRATIONS_TABLE_LABEL = 'My Registrations';
	public static final String MY_REGISTERED_GROUPS_TABLE_LABEL = 'My Registered Groups';

	public static final String AVAILABLE_MY_REGISTRATIONS_FOR_CR_LABEL = 'Click on the available Registration to associate with Change Request';
	public static final String AVAILABLE_MY_GROUPS_FOR_CR_LABEL = 'Click on the available Registered Group to associate with Change Request';
	public static final String NO_AVAILABLE_MY_REGISTRATIONS_FOR_CR_LABEL = 'You have no available registrations to create a new Solo Change Request';
	public static final String NO_AVAILABLE_MY_GROUPS_FOR_CR_LABEL = 'You have no available groups to create a new Group Change Request';

	//	COMMUNITY COMPONENT: MY REGISTRAIONS
	@AuraEnabled
	public static Map<String, Object> getMyRegistrations(Map<String, Object> settings) {
		try {
			String paramsString = settings.containsKey('params') ? String.valueOf(settings.get('params')) : '';
			Map<String, String> params = !String.isBlank(paramsString) ? (Map<String, String>) JSON.deserialize(paramsString, Map<String, String>.class) : new Map<String, String>();
			String selectedCRType = params.containsKey('selectedCRType') ? String.valueOf(params.get('selectedCRType')) : '';

			//	FIRST PRIORITY	//	becomes from QuickAction	if our manager click 'New Change Request' button on 'Contact' record
			String contactRecordId = params.containsKey('contactRecordId') ? String.valueOf(params.get('contactRecordId')) : '';

			//	SECOND PRIORITY
			String userId = '' + UserInfo.getUserId();	//	eanStaffUserId OR communityUserId

			List<User> communityUser = !String.isBlank(contactRecordId) ? [SELECT Id, ContactId, Contact.AccountId FROM User WHERE ContactId =:contactRecordId LIMIT 1]
				: [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];
			Id communityContactId = !Test.isRunningTest() ? communityUser[0].ContactId : Id.valueOf(contactRecordId);	//	Id accountId = communityUser[0].Contact.AccountId;

			List<Participant__c> allMyParticipations = queryParticipants(communityContactId, selectedCRType);

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
				if (participation.Contact__c == communityContactId) {
					myRegistration.registrationType = participation.Event_Registration_Sub_Group__c != null ? 'Group' : 'Solo';
					registrationsMapSolo.put(myRegistration.participantId, myRegistration);
				}

				//	event participations where the user is group leader
				if (participation.Event_custom__c != null && participation.Event_Registration_Sub_Group__c != null && participation.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c == communityContactId) {

					myRegistration.registrationType = 'Group';

					List<String> processedSubGroups = groupIdToProcessedSubGroups.containsKey(myRegistration.registrationGroupId) ? groupIdToProcessedSubGroups.get(myRegistration.registrationGroupId) : new List<String>();
					Integer groupMaxParticipants = groupIdToMaxParticipants.containsKey(myRegistration.registrationGroupId) ? groupIdToMaxParticipants.get(myRegistration.registrationGroupId) : 0;
					Integer groupExistingParticipants = groupIdToExistingParticipants.containsKey(myRegistration.registrationGroupId) ? groupIdToExistingParticipants.get(myRegistration.registrationGroupId) : 0;

					groupMaxParticipants++;
					if (!String.isBlank(participation.Participant_Email__c) || participation.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME) groupExistingParticipants++;

					processedSubGroups.add(myRegistration.registrationSubGroupId);

					groupIdToProcessedSubGroups.put(myRegistration.registrationGroupId, processedSubGroups);
					groupIdToMaxParticipants.put(myRegistration.registrationGroupId, groupMaxParticipants);
					groupIdToExistingParticipants.put(myRegistration.registrationGroupId, groupExistingParticipants);

					myRegistration.groupMaxParticipants = groupMaxParticipants;
					myRegistration.groupExistingParticipants = groupExistingParticipants;

					EventRegistrationWrap cloned = myRegistration.clone();
					groupIdToRegistrationDetails.put(myRegistration.registrationGroupId, cloned);
				}
			}

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
					if (registrationsMapSolo.containsKey(participantId)) registrationsMapSolo.get(participantId).registrationStatus = registrationStatus;
				}
			}


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

			String crUnavailableMessage = (selectedCRType == CR_TYPE_GROUP_CANCELLATION || selectedCRType == CR_TYPE_GROUP_TRANSFER) && registrationsGroup.isEmpty()
				? NO_AVAILABLE_MY_GROUPS_FOR_CR_LABEL
					: (selectedCRType == CR_TYPE_SOLO_CANCELLATION || selectedCRType == CR_TYPE_SOLO_TRANSFER) && registrationsSolo.isEmpty()
						? NO_AVAILABLE_MY_REGISTRATIONS_FOR_CR_LABEL : '';

			return new Map<String, Object>{
				'result' => true,
				'userId' => userId,
				'contactId' => communityContactId,
				'registrationsSolo' => registrationsSolo,
				'registrationsGroup' => registrationsGroup,
				'displayRegistrationsSolo' => !registrationsSolo.isEmpty() && selectedCRType != CR_TYPE_GROUP_CANCELLATION && selectedCRType != CR_TYPE_GROUP_TRANSFER,
				'displayRegistrationsGroup' => !registrationsGroup.isEmpty() && selectedCRType != CR_TYPE_SOLO_CANCELLATION && selectedCRType != CR_TYPE_SOLO_TRANSFER,
				'displayNoRegistrationMessage' => registrationsSolo.isEmpty() && registrationsGroup.isEmpty() && String.isBlank(selectedCRType),
				'myRegistrationsLabel' => String.isBlank(selectedCRType) ? MY_REGISTRATIONS_TABLE_LABEL : AVAILABLE_MY_REGISTRATIONS_FOR_CR_LABEL,
				'myRegisteredGroupsLabel' => String.isBlank(selectedCRType) ? MY_REGISTERED_GROUPS_TABLE_LABEL : AVAILABLE_MY_GROUPS_FOR_CR_LABEL,
				'crUnavailableMessage' => crUnavailableMessage,
				'displayCRUnavailableMessage' => !String.isBlank(crUnavailableMessage),
				'selectedCRType' => selectedCRType
			};

		} catch (Exception e) { 
			system.debug('MyRegistrationsController [getMyRegistrations] Error: ' + e.getMessage());
			system.debug('MyRegistrationsController [getMyRegistrations] Stack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
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

	public static List<Participant__c> queryParticipants(String communityContactId, String changeRequestType) {
		Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();

		String queryString = 'SELECT Id, Name, Contact__c, Contact__r.Name, Participant_Email__c, ' +
			'Event_custom__c, Event_custom__r.Name, Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c, Event_Registration_Sub_Group__c, ' +
			'Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,' +
			'Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name ' +
			'FROM Participant__c ' +
			'WHERE ';

		queryString += String.isBlank(changeRequestType) ? '(Contact__c =:communityContactId OR Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:communityContactId) '
			: changeRequestType == CR_TYPE_SOLO_CANCELLATION || changeRequestType == CR_TYPE_SOLO_TRANSFER ? 'Contact__c =:communityContactId '
				: changeRequestType == CR_TYPE_GROUP_CANCELLATION || changeRequestType == CR_TYPE_GROUP_TRANSFER || changeRequestType == CR_TYPE_GROUP_INDIVIDUAL_CANCELLATION
					? 'Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:communityContactId '
						: '';	// TEST ERROR 

		queryString += 'AND RecordTypeId !=:g2mRT ';
		queryString += 'AND Status__c !=\'Canceled\' ';
		// queryString += 'AND Status__c =\'Registered\' ';
		// queryString += 'AND (Status__c =\'Registered\' OR Status__c =\'Participated\')';
		// queryString += 'AND Status__c !=\'Canceled\' AND Status__c !=\'Participated\'';

		Map<String, SObject> allMyParticipationsMap = new Map<String, SObject>(Database.query(queryString));
		if (String.isBlank(changeRequestType)) return (List<Participant__c>) allMyParticipationsMap.values();

		//	part of logic to prevent SOLO requests (as a group member) if we have a Group Cancellation Request
		Map<String, Set<String>> groupIdToParticipantIdSet = new Map<String, Set<String>>();
		for (String participantId : allMyParticipationsMap.keySet()) {
			Participant__c patricipant = (Participant__c) allMyParticipationsMap.get(participantId);
			if (patricipant.Event_Registration_Sub_Group__c == null) continue;

			Set<String> groupParticipantIdSet = groupIdToParticipantIdSet.containsKey('' + patricipant.Event_Registration_Sub_Group__r.Event_Registration_Group__c)
				? groupIdToParticipantIdSet.get('' + patricipant.Event_Registration_Sub_Group__r.Event_Registration_Group__c)
					: new Set<String>();

			groupParticipantIdSet.add(participantId);
			groupIdToParticipantIdSet.put('' + patricipant.Event_Registration_Sub_Group__r.Event_Registration_Group__c, groupParticipantIdSet);
		}

		List<String> changeRequestTypes = new List<String>{CR_TYPE_SOLO_CANCELLATION, CR_TYPE_SOLO_TRANSFER, CR_TYPE_GROUP_CANCELLATION, CR_TYPE_GROUP_TRANSFER};

		List<Change_Request__c> changeRequestList = [
			SELECT Id, Name, Contact__c, Event_Participation__c, Event_Registration_Group__c,
				TransferFromContact__c, TransferFromEmail__c,
				TransferToContact__c, TransferToEmail__c, Type__c, Status__c
			FROM Change_Request__c
			// WHERE Type__c =:changeRequestType
			WHERE Type__c IN :changeRequestTypes
			AND Status__c !='Done'
			AND Status__c !='Revoked'
			AND Status__c !='Rejected'
			AND Status__c != null
			ORDER BY CreatedDate DESC
			LIMIT 1000
		];

		if (changeRequestType == CR_TYPE_SOLO_CANCELLATION || changeRequestType == CR_TYPE_SOLO_TRANSFER) {
			for (Change_Request__c changeRequest : changeRequestList) {
				if (changeRequest.Event_Participation__c != null && allMyParticipationsMap.containsKey('' + changeRequest.Event_Participation__c))
					allMyParticipationsMap.remove('' + changeRequest.Event_Participation__c);

				//	part of logic to prevent SOLO requests (as a group member) if we have a Group Cancellation Request
				if (changeRequest.Type__c == CR_TYPE_GROUP_CANCELLATION && changeRequest.Event_Registration_Group__c != null) {
					if (groupIdToParticipantIdSet.containsKey('' + changeRequest.Event_Registration_Group__c)) {
						Set<String> groupParticipantIdSet = groupIdToParticipantIdSet.get('' + changeRequest.Event_Registration_Group__c);
						for (String groupParticipantId : groupParticipantIdSet) {
							allMyParticipationsMap.remove(groupParticipantId);
						}
					}
				}
			}
		}

		if (changeRequestType == CR_TYPE_GROUP_CANCELLATION) {
			Set<String> crGroupIds = new Set<String>();
			for (Change_Request__c changeRequest : changeRequestList) {
				if (changeRequest.Event_Registration_Group__c != null && changeRequest.Type__c == CR_TYPE_GROUP_CANCELLATION) crGroupIds.add('' + changeRequest.Event_Registration_Group__c);
			}

			List<Participant__c> queriedParticipants = (List<Participant__c>) allMyParticipationsMap.values();
			List<Participant__c> filteredParticipants = new List<Participant__c>();
			for (Participant__c queriedParticipant : queriedParticipants) {
				if (queriedParticipant.Event_Registration_Sub_Group__c != null && !crGroupIds.contains('' + queriedParticipant.Event_Registration_Sub_Group__r.Event_Registration_Group__c))
					filteredParticipants.add(queriedParticipant);
			}
			return filteredParticipants;
		}

		return (List<Participant__c>) allMyParticipationsMap.values();
	}
}