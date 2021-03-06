public without sharing class GroupDetailsController {

	public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';

	public static final String CR_TYPE_GROUP_CANCELLATION = 'Full Group Registration Cancellation';
	public static final String CR_TYPE_GROUP_INDIVIDUAL_CANCELLATION = 'Individual Participant Group Registration Cancellation';
	public static final String CR_TYPE_GROUP_TRANSFER = 'Group Registration Transfer';

	public static final Set<String> ALLOWED_PARTICIPANT_STATUSES = new Set<String>{'Registered', 'Pending', 'Registered Draft'};

	public static String communityContactId = '';
	//	COMMUNITY PAGE: GROUP DETAILS
	@AuraEnabled
	public static Map<String, Object> getGroupDetails(Map<String, Object> settings) {
		try {
			String paramsString = settings.containsKey('params') ? String.valueOf(settings.get('params')) : '';
			Map<String, String> params = !String.isBlank(paramsString) ? (Map<String, String>) JSON.deserialize(paramsString, Map<String, String>.class) : new Map<String, String>();
			String selectedCRType = params.containsKey('selectedCRType') ? String.valueOf(params.get('selectedCRType')) : '';

			//	TEST GROUP DETAILS AS EAN STAFF (will looks like 'GroupDetailsPage' at community)
			// selectedCRType = '';

			//	FIRST PRIORITY	//	becomes from QuickAction	EAN Staff q-action on 'Contact' record
			String contactRecordId = params.containsKey('contactRecordId') ? String.valueOf(params.get('contactRecordId')) : '';

			//	SECOND PRIORITY
			String userId = '' + UserInfo.getUserId();	//	eanStaffUserId OR communityUserId

			List<User> communityUser = !String.isBlank(contactRecordId) ? [SELECT Id, ContactId, Contact.AccountId FROM User WHERE ContactId =:contactRecordId LIMIT 1]
				: [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];

			// String communityContactId = !communityUser.isEmpty() ? '' + communityUser[0].ContactId : '';	//	Id accountId = communityUser[0].Contact.AccountId;
			communityContactId = Test.isRunningTest() ? contactRecordId : (!communityUser.isEmpty() ? '' + communityUser[0].ContactId : '');

			String groupIdFromParams = params.containsKey('selectedGroupId') ? String.valueOf(params.get('selectedGroupId')) : '';
			String groupId = !String.isBlank(groupIdFromParams) ? groupIdFromParams : settings.containsKey('groupId') ? String.valueOf(settings.get('groupId')) : '';

			String maxParticipantsString = settings.containsKey('maxParticipants') ? String.valueOf(settings.get('maxParticipants')) : null;
			Integer maxParticipants = !String.isBlank(maxParticipantsString) ? Integer.valueOf(maxParticipantsString) : null;

			//	TEST GROUP DEFINITION
			// maxParticipants = 10;

			if (maxParticipants == null && !String.isBlank(groupId)) return getExistingGroupDetails(groupId, selectedCRType);

			//	for group registration flow
			return generateEmptyGroup(maxParticipants);

		} catch (Exception e) { 
			system.debug('!!! ERROR !!! : ' + e.getMessage());
			system.debug('!!! ERROR !!! : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	//	USED ON REGISTRATION FLOW
	public static Map<String, Object> generateEmptyGroup(Integer maxParticipants) {
		// for community builder
		maxParticipants = maxParticipants == null ? 10 : maxParticipants;

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
		// groupDetails.registrationStatus = 'HARD CODED';
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
			subGroupParticipant.disabledToEdit = false;	//	OLD
			subGroupParticipantList.add(subGroupParticipant);
		}
		List<SubGroupDetailsWrap> subGroupList = new List<SubGroupDetailsWrap>();
		SubGroupDetailsWrap newSubGroup = new SubGroupDetailsWrap();
		newSubGroup.subGroupId = uniqueKey1;
		newSubGroup.subGroupExistingParticipants = 0;
		newSubGroup.subGroupMaxParticipants = maxParticipants;
		newSubGroup.subGroupParticipantList = subGroupParticipantList;
		newSubGroup.accordionTitle = 'Please add participants to a new group';
		newSubGroup.accordionIsExpanded = true;
		// newSubGroup.createdDateString = '';
		// newSubGroup.createdTimeString = '';

		newSubGroup.accordionIndex = 0;		// CUSTOM ACCORDIONS
		newSubGroup.disabledToEdit = false;
		subGroupList.add(newSubGroup);

		return new Map<String, Object>{
			'result' => true,
			'groupDetails' => groupDetails,
			'subGroupList' => subGroupList,
			'displayGroupDetails' => false,
			'displayGroupDetailsPartial' => false,
			'displayGroupDefinition' => true,
			'displayAccordions' => false,
			'displayFinalCancel' => false,
			'displayRegistrationSubmit' => true,
			'displayAddMoreTicketsButton' => false,
			'disabledEmails' => new List<String>(),
			'isChangeRequestMode' => false,
			'communityContactId' => communityContactId,
			'displayNotAllowGroupTransferMessage' => false
		};
	}


	public static String transferGroupId = '';
	public static List<Participant__c> groupParticipations = new List<Participant__c>();

	public static Integer totalGroupExistingParticipants = 0;
	public static Integer totalGroupMaxParticipants = 0;
	public static Set<String> disabledEmails = new Set<String>();	// do not allow dublicate emails
	public static Set<String> groupParticipantIds = new Set<String>();
	public static List<String> orderedSubGroupIds = new List<String>();
	public static Map<String, SubGroupDetailsWrap> subGroupIdToDetailsWrap = new Map<String, SubGroupDetailsWrap>();
	public static Map<String, Change_Request__c> participantIdToChangeRequest = new Map<String, Change_Request__c>();

	public static List<SubGroupDetailsWrap> subGroupList = new List<SubGroupDetailsWrap>();

	public static Boolean disableTransfersInGroup = false;

	// public static Set<String> disabledEmails = new Set<String>();	// do not allow dublicate emails

	public static Map<String, Object> getExistingGroupDetails(String groupId, String selectedCRType) {

		//	DEVELOP MOMENT		//	TEST BUTTONS POSITION
		// selectedCRType = '';

		if (String.isBlank(communityContactId) || String.isBlank(groupId)) {
			return new Map<String, Object>{'result' => false, 'message' => 'ContactId or Group not found.'};
		}
		transferGroupId = groupId;

		//	METHOD 1
		//	SOQL
		getGroupParticipations();
		if (groupParticipations.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Group configuration is not correct.'};

		for (Participant__c participant : groupParticipations) {
			if (participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME) continue;
			groupParticipantIds.add('' + participant.Id);
		}

		//	METHOD 2	used only at Change Requests
		//	result:
		//		disableTransfersInGroup
		//		participantIdToChangeRequest
		filterByCreatedChangeRequests(selectedCRType);

		//	METHOD 3
		//	result:
		//		totalGroupExistingParticipants
		//		totalGroupMaxParticipants
		//		disabledEmails
		//		orderedSubGroupIds
		//		subGroupIdToDetailsWrap
		collectInfoFromGroupParticipants(selectedCRType);

		//	METHOD 4
		//	disable edit participants if 'subgroup' is locked OR 'subgroup order status' == 'Open'
		//	logic for 'Group Registration Transfer':	remove not locked subgroups 
		lockSubgroups(selectedCRType);

		//	METHOD 5
		//	create 'subGroupList' order by 'orderedSubGroupIds'
		//	define titles on Accordions
		//	allow 'Submit Button' if sub-group is not locked and all participants are added
		genereteAccordionsAndSubmitButton();

		//	define the main details of Group (to display at the community page)
		GroupDetailsWrap groupDetails = new GroupDetailsWrap();
		groupDetails.groupId = groupParticipations[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c;
		groupDetails.groupName = groupParticipations[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
		groupDetails.eventName = groupParticipations[0].Event_custom__r.Name;
		groupDetails.eventId = groupParticipations[0].Event_custom__c;
		groupDetails.eventEndTime = groupParticipations[0].Event_custom__r.End_Time__c;		//	Datetime
		groupDetails.eventStartTime = groupParticipations[0].Event_custom__r.Start_Time__c;					//	Datetime
		groupDetails.eventEndDateString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('dd.MM.yyyy') : '';
		groupDetails.eventStartDateString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('dd.MM.yyyy') : '';
		groupDetails.eventEndTimeString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('HH:mm') : '';
		groupDetails.eventStartTimeString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('HH:mm') : '';

		groupDetails.totalGroupExistingParticipants = totalGroupExistingParticipants;
		groupDetails.totalGroupMaxParticipants = totalGroupMaxParticipants;

		return new Map<String, Object>{
			'result' => true,
			'groupDetails' => groupDetails,
			'subGroupList' => subGroupList,
			'disabledEmails' => disabledEmails,
			'displayGroupDetails' => String.isBlank(selectedCRType),
			'displayGroupDetailsPartial' => true,
			// 'displayGroupDetailsPartial' => !String.isBlank(selectedCRType),
			'displayGroupDefinition' => false,
			'displayAccordions' => !subGroupList.isEmpty(),
			'displayFinalCancel' => !String.isBlank(selectedCRType),
			'displayAddMoreTicketsButton' => String.isBlank(selectedCRType),
			'displayRegistrationSubmit' => false,
			'isChangeRequestMode' => !String.isBlank(selectedCRType),
			'changeRequestType' => !String.isBlank(selectedCRType) ? selectedCRType : '',
			'communityContactId' => communityContactId,
			'displayNotAllowGroupTransferMessage' => subGroupList.isEmpty() && !String.isBlank(selectedCRType) && selectedCRType == CR_TYPE_GROUP_TRANSFER
		};
	}

	public static void getGroupParticipations() {

		Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();
		groupParticipations = [
			SELECT Id, Name, Participant_Email__c, Contact__c, Contact__r.Name, Contact__r.Email, Status__c,
				Event_custom__c, Event_custom__r.Name, Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c,
				Event_Registration_Sub_Group__c,
				Event_Registration_Sub_Group__r.CreatedDate,
				// Event_Registration_Sub_Group__r.Is_Locked__c,
				Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
				Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name
				// (SELECT Id FROM Order_Items__r LIMIT 1)	// to lock record if we have order item for participant (OLD LOGIC)
			FROM Participant__c
			WHERE Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:communityContactId
			AND RecordTypeId !=:g2mRT
			AND Event_Registration_Sub_Group__r.Event_Registration_Group__c =:transferGroupId
			AND Contact__c != null
			AND Event_custom__c != null
			AND Status__c IN :ALLOWED_PARTICIPANT_STATUSES
			ORDER BY Event_Registration_Sub_Group__r.CreatedDate, LastModifiedDate
		];
	}

	//	result:
	//	disableTransfersInGroup
	//	participantIdToChangeRequest
	public static void filterByCreatedChangeRequests(String selectedCRType) {
		if (String.isBlank(selectedCRType)) return;
		List<Change_Request__c> changeRequestList = [
			SELECT Id, Name, Contact__c, Description__c, Event_Participation__c, Type__c,
				TransferFromContact__c, TransferFromContact__r.Name, TransferFromEmail__c,
				TransferToContact__c, TransferToContact__r.Name, TransferToEmail__c
			FROM Change_Request__c
			WHERE (Event_Participation__c IN :groupParticipantIds OR Event_Registration_Group__c =:transferGroupId)
			AND Status__c !='Done'
			AND Status__c !='Revoked'
			AND Status__c !='Rejected'
			AND Status__c != null
		];

		for (Change_Request__c changeRequest : changeRequestList) {
			if (changeRequest.Type__c == CR_TYPE_GROUP_CANCELLATION) {
				disableTransfersInGroup = true;
				break;
			}
			if (changeRequest.Event_Participation__c == null) continue;
			participantIdToChangeRequest.put('' + changeRequest.Event_Participation__c, changeRequest);
		}
	}

	//	result:
	//		totalGroupExistingParticipants
	//		totalGroupMaxParticipants
	//		disabledEmails
	//		orderedSubGroupIds
	//		groupParticipantIds
	//		subGroupIdToDetailsWrap


	// public static Map<String, Boolean> subGroupIdToIsUndefinedParticipantExist = new Map<String, Boolean>();

	public static void collectInfoFromGroupParticipants(String selectedCRType) {
		for (Participant__c participant : groupParticipations) {

			Boolean isDraftStatus = String.isBlank(participant.Status__c) || participant.Status__c == 'Pending' || participant.Status__c == 'Registered Draft';
			if (isDraftStatus) continue;

			SubGroupParticipantWrap subGroupParticipant = new SubGroupParticipantWrap();
			subGroupParticipant.participantId = '' + participant.Id;
			subGroupParticipant.oldContactId = '' + participant.Contact__c;
			subGroupParticipant.oldContactName = participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? '' : participant.Contact__r.Name;

			subGroupParticipant.oldContactEmail = participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME ? participant.Contact__r.Email
				: !String.isBlank(participant.Participant_Email__c) ? participant.Participant_Email__c : '';
			//	OLD
			// subGroupParticipant.oldContactEmail = '' + participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? '' : participant.Contact__r.Email;

			// subGroupParticipant.newContactId = '' + subGroupParticipant.participantId;
			subGroupParticipant.newContactId = '' + subGroupParticipant.oldContactId;
			subGroupParticipant.newContactName = '' + subGroupParticipant.oldContactName;
			subGroupParticipant.newContactEmail = '' + subGroupParticipant.oldContactEmail;

			subGroupParticipant.isInvited = participant.Status__c == 'Registered' && participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME;
			subGroupParticipant.isConfirmed = participant.Status__c == 'Registered' && participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME;

			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.containsKey('' + participant.Event_Registration_Sub_Group__c)
				? subGroupIdToDetailsWrap.get('' + participant.Event_Registration_Sub_Group__c) : new SubGroupDetailsWrap();
			subGroupDetails.subGroupId = '' + participant.Event_Registration_Sub_Group__c;

			subGroupDetails.subGroupExistingParticipants = subGroupDetails.subGroupExistingParticipants == null ? 0 : subGroupDetails.subGroupExistingParticipants;
			subGroupDetails.subGroupExistingParticipants += participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME || !String.isBlank(participant.Participant_Email__c) ? 1 : 0;
			totalGroupExistingParticipants += participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME || !String.isBlank(participant.Participant_Email__c) ? 1 : 0;
			// subGroupDetails.subGroupExistingParticipants += participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? 0 : 1;
			// totalGroupExistingParticipants += participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? 0 : 1;

			subGroupDetails.subGroupMaxParticipants = subGroupDetails.subGroupMaxParticipants == null ? 1 : subGroupDetails.subGroupMaxParticipants + 1;
			totalGroupMaxParticipants++;

			subGroupDetails.createdDateString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('dd.MM.yyyy');
			subGroupDetails.createdTimeString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('HH:mm');
			subGroupDetails.disabledToEdit = false;

			// collect data for transfer requestes and do not allow enter duplicate email
			disabledEmails.add(subGroupParticipant.oldContactEmail);
			groupParticipantIds.add(subGroupParticipant.participantId);

			List<SubGroupParticipantWrap> subGroupParticipantList = subGroupDetails.subGroupParticipantList == null ? new List<SubGroupParticipantWrap>() : subGroupDetails.subGroupParticipantList;

			subGroupParticipant.uniquekey1 = subGroupDetails.subGroupId;
			subGroupParticipant.uniquekey2 = '' + subGroupParticipantList.size();	// index of participant in list


			// Boolean isDraftStatus = String.isBlank(participant.Status__c) || participant.Status__c == 'Pending' || participant.Status__c == 'Registered Draft';
			// subGroupParticipant.disabledToEdit = !isDraftStatus;

			Boolean isOldTransferExist = participantIdToChangeRequest.containsKey(subGroupParticipant.participantId);
			subGroupParticipant.isOldTransferExist = isOldTransferExist;
			subGroupParticipant.isNewTransferExist = false;

			subGroupParticipant.disabledToEdit = !isDraftStatus || isOldTransferExist;

			if (isOldTransferExist) {
				Change_Request__c existingCR = participantIdToChangeRequest.get(subGroupParticipant.participantId);

				if (!String.isBlank(existingCR.TransferToEmail__c)) disabledEmails.add(existingCR.TransferToEmail__c);

				TransferDetailsWrap oldTransferDetails = new TransferDetailsWrap();
				oldTransferDetails.crId = '' + existingCR.Id;
				oldTransferDetails.crName = existingCR.Name;
				oldTransferDetails.crDescription = existingCR.Description__c;
				oldTransferDetails.crContactId = existingCR.TransferToContact__c;

				oldTransferDetails.crContactEmail = existingCR.TransferToContact__c != null && existingCR.TransferToContact__r.Name != SYSTEM_GROUP_CONTACT_NAME
					? existingCR.TransferToEmail__c : '';

				oldTransferDetails.crContactName = existingCR.TransferToContact__c != null && existingCR.TransferToContact__r.Name != SYSTEM_GROUP_CONTACT_NAME
					? existingCR.Name : '';

				subGroupParticipant.oldTransferDetails = oldTransferDetails;
			}


			subGroupParticipantList.add(subGroupParticipant);
			subGroupDetails.subGroupParticipantList = subGroupParticipantList;
			
			subGroupIdToDetailsWrap.put('' + participant.Event_Registration_Sub_Group__c, subGroupDetails);
			if (!orderedSubGroupIds.contains('' + participant.Event_Registration_Sub_Group__c)) orderedSubGroupIds.add('' + participant.Event_Registration_Sub_Group__c);
		}
	}

	public static Map<String, Order__c> orderSubGroupIdToOrder = new Map<String, Order__c>();

		//		disableTransfersInGroup
		//		participantIdToChangeRequest
	public static void lockSubgroups(String selectedCRType) {
		List<Order__c> orders = !orderedSubGroupIds.isEmpty() ? 
			[SELECT Id, Name, Status__c, Event_Registration_Sub_Group__c FROM Order__c WHERE Event_Registration_Sub_Group__c IN :orderedSubGroupIds]
			: new List<Order__c>();

		for (Order__c order : orders) {
			if (!subGroupIdToDetailsWrap.containsKey('' + order.Event_Registration_Sub_Group__c)) continue;

			//	NEW logic for 'Group Registration Transfer':	remove subgroups with not paid orders
			if (selectedCRType == CR_TYPE_GROUP_TRANSFER && (order.Status__c != 'Paid' && order.Status__c != 'Partially Cancelled')) {
				subGroupIdToDetailsWrap.remove('' + order.Event_Registration_Sub_Group__c);
				Integer subGroupIndex = orderedSubGroupIds.indexOf('' + order.Event_Registration_Sub_Group__c);
				if (subGroupIndex > -1) orderedSubGroupIds.remove(subGroupIndex);
				continue;
			}
			orderSubGroupIdToOrder.put('' + order.Event_Registration_Sub_Group__c, order);
		}
	}

	//	create 'subGroupList' order by 'orderedSubGroupIds'
	//	define titles on Accordions
	//	collect 'disabledEmails'	// REMOVERD
	public static void genereteAccordionsAndSubmitButton() {

		Integer index = 0;
		for (String subGroupId : orderedSubGroupIds) {
			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.get(subGroupId);

			//	define titles on Accordions
			Boolean isOrderExist = orderSubGroupIdToOrder.containsKey(subGroupId);
			Boolean isDisabledOrder = false;
			//	NEW LOGIC
			if (isOrderExist) {
				Order__c order = orderSubGroupIdToOrder.get(subGroupId);
				subGroupDetails.accordionTitle = 'Order: ' + order.Name + ' (Status: ' + (order.Status__c == 'Opened' ? 'Payment Pending' : order.Status__c) + ')';
				isDisabledOrder = order.Status__c == 'Cancelled' || order.Status__c == 'Closed';
			} else {
				subGroupDetails.accordionTitle = 'Order Not Found';
			}

			subGroupDetails.accordionIsExpanded = true;
			subGroupDetails.accordionIndex = index;			//	CUSTOM ACCORDIONS
			subGroupList.add(subGroupDetails);
			index++;
		}
	}

	//	USED AT REGISTRATION FLOW
	//	CLICK SUBMIT
	@AuraEnabled
	public static Map<String, Object> clickSubmitRegistrationFlow(Map<String, Object> params) {
		try {
			String subGroupListString = params.containsKey('subGroupList') ? String.valueOf(params.get('subGroupList')) : '';
			String isGroupDefinitionModeString = params.containsKey('isGroupDefinitionMode') ? String.valueOf(params.get('isGroupDefinitionMode')) : '';

			List<SubGroupDetailsWrap> subGroupList = !String.isBlank(subGroupListString) ? (List<SubGroupDetailsWrap>) JSON.deserialize (subGroupListString, List<SubGroupDetailsWrap>.class) : new List<SubGroupDetailsWrap>();
			Boolean isGroupDefinitionMode = !String.isBlank(isGroupDefinitionModeString) ? Boolean.valueOf(isGroupDefinitionModeString) : false;

			if (subGroupList.isEmpty() || subGroupList[0].subGroupParticipantList == null || subGroupList[0].subGroupParticipantList.isEmpty()) return new Map<String, Object>{'result' => false};

			// if (isGroupDefinitionMode) {
				return new Map<String, Object>{
					'result' => true,
					'participantsString' => generateParticipants(subGroupList[0].subGroupParticipantList)
				};
			// }

		} catch (Exception e) { 
			system.debug('GroupDetailsController [clickSubmitRegistrationFlow] Error: ' + e.getMessage());
			system.debug('GroupDetailsController [clickSubmitRegistrationFlow] Stack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
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

	@AuraEnabled
	public static Map<String, Object> clickRequestCancellationGroupParticipant(Map<String, Object> params) {
		try {
			String participantDetailsString = params.containsKey('participantDetailsString') ? String.valueOf(params.get('participantDetailsString')) : '';
			String subGroupId = params.containsKey('subGroupId') ? String.valueOf(params.get('subGroupId')) : '';
			String description = params.containsKey('description') ? String.valueOf(params.get('description')) : '';
			String contactRecordId = params.containsKey('contactRecordId') ? String.valueOf(params.get('contactRecordId')) : '';

			if (String.isBlank(participantDetailsString) || String.isBlank(subGroupId))
				return new Map<String, Object>{'result' => false, 'message' => 'Not Exists All Params. ' + participantDetailsString + ' / ' + subGroupId + ' / '};

			List<Order__c> subGroupOrder = [
				SELECT Id, Name, Status__c, Event_Registration_Sub_Group__r.Event_Registration_Group__c
				FROM Order__c
				WHERE Event_Registration_Sub_Group__c =:subGroupId
				AND (Status__c = 'Paid' OR Status__c = 'Partially Cancelled')
				LIMIT 1
			];
			if (subGroupOrder.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Order Not Found'};
			SubGroupParticipantWrap participantDetails = (SubGroupParticipantWrap) JSON.deserialize(participantDetailsString, SubGroupParticipantWrap.class);

			List<Participant__c> participant = [
				SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Email, Event_custom__c, Event_Registration_Sub_Group__c, Participant_Email__c
				FROM Participant__c
				WHERE Id = :participantDetails.participantId
				AND Event_Registration_Sub_Group__c =:subGroupId
				LIMIT 1
			];
			if (participant.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Participant Not Found'};

			Change_Request__c newChangeRequest = new Change_Request__c(
				Contact__c = contactRecordId,
				Description__c = description,
				Event_Custom__c = participant[0].Event_custom__c,
				Event_Participation__c = participant[0].Id,
				Event_Registration_Group__c = subGroupOrder[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c,
				Order__c = subGroupOrder[0].Id,
				Status__c = 'Requested',
				TransferFromContact__c = participant[0].Contact__c,
				TransferFromEmail__c = !String.isBlank(participant[0].Contact__r.Email) ? participant[0].Contact__r.Email : participant[0].Participant_Email__c,
				// TransferToContact__c
				// TransferToEmail__c
				Type__c = CR_TYPE_GROUP_INDIVIDUAL_CANCELLATION
			);
			insert newChangeRequest;
			List<Change_Request__c> insertedChangeRequest = [
				SELECT Id, Name
				FROM Change_Request__c
				WHERE Id =:newChangeRequest.Id
				LIMIT 1
			];

			return new Map<String, Object>{
				'result' => true,
				'message' => 'Change Request ' + insertedChangeRequest[0].Name + ' successfully submitted.',
				'changeRequestName' => insertedChangeRequest[0].Name};

		} catch (Exception e) { 
			system.debug('GroupDetailsController [clickRequestCancellationGroupParticipant] Error: ' + e.getMessage());
			system.debug('GroupDetailsController [clickRequestCancellationGroupParticipant] Stack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	//	Group
	public class GroupDetailsWrap {
		@AuraEnabled public String groupId { get; set; }
		@AuraEnabled public String groupName { get; set; }
		@AuraEnabled public String eventName { get; set; }
		@AuraEnabled public String eventId { get; set; }
		@AuraEnabled public Datetime eventEndTime { get; set; }
		@AuraEnabled public Datetime eventStartTime { get; set; }
		@AuraEnabled public String eventEndDateString { get; set; }
		@AuraEnabled public String eventStartDateString { get; set; }
		@AuraEnabled public String eventEndTimeString { get; set; }
		@AuraEnabled public String eventStartTimeString { get; set; }

		// @AuraEnabled public String registrationStatus { get; set; }
		@AuraEnabled public Integer totalGroupExistingParticipants { get; set; }
		@AuraEnabled public Integer totalGroupMaxParticipants { get; set; }
	}

	//	Group Registration
	public class SubGroupDetailsWrap {
		@AuraEnabled public String subGroupId { get; set; }
		@AuraEnabled public Integer subGroupExistingParticipants { get; set; }
		@AuraEnabled public Integer subGroupMaxParticipants { get; set; }
		@AuraEnabled public List<SubGroupParticipantWrap> subGroupParticipantList { get; set; }
		@AuraEnabled public String createdDateString { get; set; }
		@AuraEnabled public String createdTimeString { get; set; }
		@AuraEnabled public Boolean disabledToEdit { get; set; }

		@AuraEnabled public String accordionTitle { get; set; }
		@AuraEnabled public Boolean accordionIsExpanded { get; set; }
		@AuraEnabled public Integer accordionIndex { get; set; }		// CUSTOM ACCORDIONS
		@AuraEnabled public Boolean enableSubmitButton { get; set; }
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

		@AuraEnabled public Boolean disabledToEdit { get; set; }		// NEW

		@AuraEnabled public Boolean isOldTransferExist { get; set; }	// Unable to Create A New Transfer (Transfer Already Exist)
		@AuraEnabled public TransferDetailsWrap oldTransferDetails { get; set; }
		@AuraEnabled public Boolean isNewTransferExist { get; set; }
		@AuraEnabled public TransferDetailsWrap newTransferDetails { get; set; }

		@AuraEnabled public Boolean isInvited { get; set; }
		@AuraEnabled public Boolean isConfirmed { get; set; }

	}

	public class TransferDetailsWrap {
		@AuraEnabled public String crId { get; set; }
		@AuraEnabled public String crName { get; set; }
		@AuraEnabled public String crDescription { get; set; }
		@AuraEnabled public String crContactId { get; set; }
		@AuraEnabled public String crContactEmail { get; set; }
		@AuraEnabled public String crContactName { get; set; }
	}
}