public without sharing class GroupDetailsLeaderController {

	public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';

	public static String undefinedParticipantId = '';

	public static final Set<String> ALLOWED_PARTICIPANT_STATUSES = new Set<String>{'Registered', 'Pending', 'Registered Draft'};

	//	COMMUNITY PAGE: GROUP DETAILS
	@AuraEnabled
	public static Map<String, Object> getGroupDetails(Map<String, Object> params) {
		try {
			String groupId = params.containsKey('groupId') ? String.valueOf(params.get('groupId')) : '';

			//	FIRST PRIORITY
			String contactRecordId = params.containsKey('contactRecordId') ? String.valueOf(params.get('contactRecordId')) : '';

			//	SECOND PRIORITY
			List<User> communityUser = !String.isBlank(contactRecordId) ? [SELECT Id, ContactId, Contact.AccountId FROM User WHERE ContactId =:contactRecordId LIMIT 1]
				: [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];

			contactRecordId = Test.isRunningTest() ? contactRecordId : (!communityUser.isEmpty() ? '' + communityUser[0].ContactId : contactRecordId);
			if (String.isBlank(contactRecordId) || String.isBlank(groupId))
				return new Map<String, Object>{
					'groupId' => groupId, 'communityUser' => communityUser, 'contactRecordId' => contactRecordId,
					'result' => false, 'message' => 'Leader Contact or Group not found.'
				};

        	List<Contact> undefinedParticipant = [SELECT Id FROM Contact WHERE Name =:SYSTEM_GROUP_CONTACT_NAME LIMIT 1];
        	undefinedParticipantId = undefinedParticipant.isEmpty() ? '' : '' + undefinedParticipant[0].Id;

			//	SOQL
			getGroupParticipants(contactRecordId, groupId);
			if (groupParticipants.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Group configuration is not correct.'};

			//	COLLECT GROUP INFO
			collectInfoFromGroupParticipants();

			//	COLLECT INFO FROM ORDERS AND DEFINE ACCORDIONS
			getInfoFromOrdersAndDefineAccordions();

			String groupName = groupParticipants[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
			String eventName = groupParticipants[0].Event_custom__r.Name;

			//	define the main details of Group (to display at the community page)
			GroupDetailsWrap groupDetails = new GroupDetailsWrap();
			groupDetails.groupId = groupParticipants[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c;
			groupDetails.groupName = groupName;
			groupDetails.groupNameInitial = groupParticipants[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
			groupDetails.eventName = eventName;
			groupDetails.eventId = groupParticipants[0].Event_custom__c;
			groupDetails.eventEndTime = groupParticipants[0].Event_custom__r.End_Time__c;		//	Datetime
			groupDetails.eventStartTime = groupParticipants[0].Event_custom__r.Start_Time__c;					//	Datetime
			groupDetails.eventEndDateString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('dd.MM.yyyy') : '';
			groupDetails.eventStartDateString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('dd.MM.yyyy') : '';
			groupDetails.eventEndTimeString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('HH:mm') : '';
			groupDetails.eventStartTimeString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('HH:mm') : '';
			groupDetails.totalGroupExistingParticipants = totalGroupExistingParticipants;
			groupDetails.totalGroupMaxParticipants = totalGroupMaxParticipants;


			List<Order__c> otherGroupOrders = [
				SELECT Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name
				FROM Order__c
				WHERE Event_custom__c != null
				AND Event_custom__r.Name !=:eventName
				AND Event_Registration_Sub_Group__c != null
				AND Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name !=:groupName
			];
			Set<String> disabledGroupNames = new Set<String>();
			for (Order__c otherGroupOrder : otherGroupOrders) disabledGroupNames.add(otherGroupOrder.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name);

			List<String> disabledEmailsNotThisGroup = EventRegistrationController.getNotAvailableEventRegistrationEmails(new List<String>{groupDetails.eventId}, orderedSubGroupIds);

			return new Map<String, Object>{
				'result' => true,
				'groupDetails' => groupDetails,
				'subGroupList' => subGroupList,
				'disabledEmailsThisGroup' => disabledEmailsThisGroup,
				'disabledEmailsNotThisGroup' => disabledEmailsNotThisGroup,
				'displayAccordions' => !subGroupList.isEmpty(),
				'displayAddMoreTicketsButton' => true,
				'disabledGroupNames' => disabledGroupNames
			};

		} catch (Exception e) { 
			system.debug('GroupDetailsLeaderController Error: ' + e.getMessage());
			system.debug('GroupDetailsLeaderController Stack : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	public static List<Participant__c> groupParticipants = new List<Participant__c>();

	public static Integer totalGroupExistingParticipants = 0;
	public static Integer totalGroupMaxParticipants = 0;
	public static List<String> orderedSubGroupIds = new List<String>();
	public static Map<String, SubGroupDetailsWrap> subGroupIdToDetailsWrap = new Map<String, SubGroupDetailsWrap>();
	public static List<SubGroupDetailsWrap> subGroupList = new List<SubGroupDetailsWrap>();
	public static Set<String> disabledEmailsThisGroup = new Set<String>();

	public static void getGroupParticipants(String contactRecordId, String groupId) {
		Id g2mRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('G2M').getRecordTypeId();

		groupParticipants = [
			SELECT Id, Name, Participant_Email__c, Contact__c, Contact__r.Name, Contact__r.Email,
				Event_custom__c, Event_custom__r.Name, Event_custom__r.End_Time__c, Event_custom__r.Start_Time__c,
				Event_Registration_Sub_Group__c,
				Event_Registration_Sub_Group__r.CreatedDate,
				Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
				Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name,
				Status__c, (SELECT Id, Name__c, Amount__c, Order_Custom__c, Order_Custom__r.Status__c FROM Order_Items__r)
				// Invitation_Status_In_Group__c	//	Draft	Invited		Confirmed
			FROM Participant__c
			WHERE Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:contactRecordId
			AND RecordTypeId !=:g2mRT
			AND Event_Registration_Sub_Group__r.Event_Registration_Group__c =:groupId
			AND Contact__c != null
			AND Event_custom__c != null
			AND Status__c IN :ALLOWED_PARTICIPANT_STATUSES
			ORDER BY Event_Registration_Sub_Group__r.CreatedDate, Status__c ASC NULLS LAST, Participant_Email__c DESC NULLS LAST
			// ORDER BY Event_Registration_Sub_Group__r.CreatedDate, Invitation_Status_In_Group__c DESC NULLS LAST, Participant_Email__c DESC NULLS LAST
		];
	}

	public static void collectInfoFromGroupParticipants() {
		for (Participant__c participant : groupParticipants) {
			SubGroupParticipantWrap subGroupParticipant = new SubGroupParticipantWrap();

			subGroupParticipant.participantId = '' + participant.Id;
			subGroupParticipant.oldContactId = '' + participant.Contact__c;
			subGroupParticipant.oldContactName = participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME ? '' : participant.Contact__r.Name;

			subGroupParticipant.oldContactEmail = participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME ? participant.Contact__r.Email
				: !String.isBlank(participant.Participant_Email__c) ? participant.Participant_Email__c : '';

			subGroupParticipant.newContactId = '' + subGroupParticipant.oldContactId;
			subGroupParticipant.newContactName = '' + subGroupParticipant.oldContactName;
			subGroupParticipant.newContactEmail = '' + subGroupParticipant.oldContactEmail;

			if (!String.isBlank(subGroupParticipant.oldContactEmail)) disabledEmailsThisGroup.add(subGroupParticipant.oldContactEmail);

			// Boolean isDraftStatus = String.isBlank(participant.Invitation_Status_In_Group__c) || participant.Invitation_Status_In_Group__c == 'Draft';
			Boolean isDraftStatus = String.isBlank(participant.Status__c) || participant.Status__c == 'Pending' || participant.Status__c == 'Registered Draft';
			ParticipantButtonsWrap buttonsSettings = new ParticipantButtonsWrap();
			buttonsSettings.enableAddInviteButtons = true;
			buttonsSettings.displayAddButton = isDraftStatus && !String.isBlank(subGroupParticipant.oldContactName);
			buttonsSettings.displayInviteButton = isDraftStatus && String.isBlank(subGroupParticipant.oldContactName) && !String.isBlank(subGroupParticipant.oldContactEmail);
			buttonsSettings.displaySaveDraftButton = false;
			// buttonsSettings.isDraftStatus = isDraftStatus;
			// buttonsSettings.isInvited = participant.Invitation_Status_In_Group__c == 'Invited';
			// buttonsSettings.isConfirmed = participant.Invitation_Status_In_Group__c == 'Confirmed';
			buttonsSettings.isInvited = participant.Status__c == 'Registered' && participant.Contact__r.Name == SYSTEM_GROUP_CONTACT_NAME;
			buttonsSettings.isConfirmed = participant.Status__c == 'Registered' && participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME;

			subGroupParticipant.buttonsSettings = buttonsSettings;
			subGroupParticipant.buttonsSettingsInitial = buttonsSettings;

			// subGroupParticipant.invitationStatusInGroup = participant.Invitation_Status_In_Group__c;	//	develop moment

			subGroupParticipant.disabledToEdit = !isDraftStatus;

			//EANER-157
			if (isDraftStatus && participant.Order_Items__r.size() > 0 &&
				participant.Order_Items__r[0].Order_Custom__r.Status__c != 'Paid' &&
				participant.Order_Items__r[0].Amount__c > 0 &&
				participant.Order_Items__r[0].Name__c != 'Group Registration' &&
				participant.Contact__r.Name != 'Undefined Participant') {
					subGroupParticipant.disabledToEdit = true;
			}

			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.containsKey('' + participant.Event_Registration_Sub_Group__c)
				? subGroupIdToDetailsWrap.get('' + participant.Event_Registration_Sub_Group__c) : new SubGroupDetailsWrap();
			subGroupDetails.subGroupId = '' + participant.Event_Registration_Sub_Group__c;

			subGroupDetails.subGroupExistingParticipants = subGroupDetails.subGroupExistingParticipants == null ? 0 : subGroupDetails.subGroupExistingParticipants;
			subGroupDetails.subGroupExistingParticipants += participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME || !String.isBlank(participant.Participant_Email__c) ? 1 : 0;
			totalGroupExistingParticipants += participant.Contact__r.Name != SYSTEM_GROUP_CONTACT_NAME || !String.isBlank(participant.Participant_Email__c) ? 1 : 0;

			subGroupDetails.subGroupMaxParticipants = subGroupDetails.subGroupMaxParticipants == null ? 1 : subGroupDetails.subGroupMaxParticipants + 1;
			totalGroupMaxParticipants++;

			subGroupDetails.createdDateString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('dd.MM.yyyy');
			subGroupDetails.createdTimeString = (participant.Event_Registration_Sub_Group__r.CreatedDate).format('HH:mm');

			List<SubGroupParticipantWrap> subGroupParticipantList = subGroupDetails.subGroupParticipantList == null ? new List<SubGroupParticipantWrap>() : subGroupDetails.subGroupParticipantList;

			subGroupParticipant.uniquekey1 = subGroupDetails.subGroupId;
			subGroupParticipant.uniquekey2 = '' + subGroupParticipantList.size();	// index of participant in list

			subGroupParticipantList.add(subGroupParticipant);
			subGroupDetails.subGroupParticipantList = subGroupParticipantList;

			subGroupIdToDetailsWrap.put('' + participant.Event_Registration_Sub_Group__c, subGroupDetails);
			if (!orderedSubGroupIds.contains('' + participant.Event_Registration_Sub_Group__c)) orderedSubGroupIds.add('' + participant.Event_Registration_Sub_Group__c);

		}
	}

	//	create 'subGroupList' ordered by 'orderedSubGroupIds'
	//	define titles on Accordions
	public static void getInfoFromOrdersAndDefineAccordions() {
		List<Order__c> orders = !orderedSubGroupIds.isEmpty() ? [
				SELECT Id, Name, Status__c, Event_Registration_Sub_Group__c
				FROM Order__c
				WHERE Event_Registration_Sub_Group__c IN :orderedSubGroupIds]
			: new List<Order__c>();

		Map<String, Order__c> orderSubGroupIdToOrder = new Map<String, Order__c>();
		for (Order__c order : orders) {
			orderSubGroupIdToOrder.put('' + order.Event_Registration_Sub_Group__c, order);
		}

		Integer accordionIndex = 0;
		for (String subGroupId : orderedSubGroupIds) {
			SubGroupDetailsWrap subGroupDetails = subGroupIdToDetailsWrap.get(subGroupId);

			//	define titles on Accordions
			subGroupDetails.accordionIsExpanded = true;

			Boolean isOrderExist = orderSubGroupIdToOrder.containsKey(subGroupId);
			Boolean isOrderPaid = isOrderExist;
			Boolean isDisabledOrder = false;

			if (isOrderExist) {
				Order__c order = orderSubGroupIdToOrder.get(subGroupId);
				subGroupDetails.accordionTitle = 'Order: ' + order.Name + ' (Status: ' + (order.Status__c == 'Opened' ? 'Payment Pending' : order.Status__c) + ')';
				isOrderPaid = order.Status__c == 'Paid';
				isDisabledOrder = order.Status__c == 'Cancelled' || order.Status__c == 'Closed';
			} else {
				subGroupDetails.accordionTitle = 'Order Not Found';
			}

			List<SubGroupParticipantWrap> subGroupParticipantList = subGroupDetails.subGroupParticipantList;
			Boolean accordionIsExpanded = false;
			for (SubGroupParticipantWrap subGroupParticipant : subGroupParticipantList) {

				subGroupParticipant.buttonsSettings.enableAddInviteButtons = isOrderPaid;

				subGroupParticipant.buttonsSettings.enableWarningMessage = !isOrderPaid;
				subGroupParticipant.buttonsSettings.displayWarningMessage = !String.isBlank(subGroupParticipant.oldContactId) && subGroupParticipant.oldContactId != undefinedParticipantId;

				ErrorWrap error = new ErrorWrap();
				error.hasError = false;
				error.message = '';
				ErrorWrap errorInitial = new ErrorWrap();
				errorInitial.hasError = false;
				errorInitial.message = 'Please enter email';

				if (!isDisabledOrder && isOrderPaid && String.isBlank(subGroupParticipant.oldContactEmail)) {
					errorInitial.hasError = true;
					error.hasError = true;
					error.message = 'Please enter email';
				}
				subGroupParticipant.error = error;
				subGroupParticipant.errorInitial = errorInitial;
				// subGroupParticipant.errorInitial = error;

				subGroupParticipant.buttonsSettings.displayAddButton = subGroupParticipant.buttonsSettings.displayAddButton && isOrderPaid && !isDisabledOrder;
				subGroupParticipant.buttonsSettings.displayInviteButton = subGroupParticipant.buttonsSettings.displayInviteButton && isOrderPaid && !isDisabledOrder;
				subGroupParticipant.buttonsSettingsInitial = subGroupParticipant.buttonsSettings;
				subGroupParticipant.buttonsSettingsIntermediate = subGroupParticipant.buttonsSettings;

				// if (subGroupParticipant.buttonsSettings.isDraftStatus) accordionIsExpanded = true;
				if (!subGroupParticipant.disabledToEdit) accordionIsExpanded = true;
				if (isDisabledOrder) subGroupParticipant.disabledToEdit = true;
			}
			subGroupDetails.accordionIsExpanded = accordionIsExpanded && !isDisabledOrder;

		subGroupDetails.accordionIndex = accordionIndex;
		accordionIndex++;
		subGroupList.add(subGroupDetails);
		}
	}


	@AuraEnabled
	public static Map<String, Object> addButtonClick(Map<String, Object> params) {
		try {
			String groupId = params.containsKey('subGroupId') ? String.valueOf(params.get('subGroupId')) : '';
			String participantDetailsString = params.containsKey('participantDetailsString') ? String.valueOf(params.get('participantDetailsString')) : '';

			if (String.isBlank(groupId) || String.isBlank(participantDetailsString))
				return new Map<String, Object>{'result' => false, 'message' => 'Not Exists All Params. /' + groupId + ' / ' + participantDetailsString + ' / '};

			SubGroupParticipantWrap participantDetails = (SubGroupParticipantWrap) JSON.deserialize (participantDetailsString, SubGroupParticipantWrap.class);
			update new Participant__c(
				Id = participantDetails.participantId,
				Contact__c = participantDetails.newContactId,
				Participant_Email__c = participantDetails.newContactEmail,
				Status__c = 'Registered'
			);

			List<Participant__c> updatedParticipant = [SELECT Id, Name FROM Participant__c WHERE Id =:participantDetails.participantId LIMIT 1];

			return new Map<String, Object>{'result' => true, 'message' => updatedParticipant[0].Name + ' Successfully registered for the event'};

		} catch (Exception e) { 
			system.debug('GroupDetailsLeaderController Error: ' + e.getMessage());
			system.debug('GroupDetailsLeaderController Stack : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}


	@AuraEnabled
	public static Map<String, Object> inviteButtonClick(Map<String, Object> params) {
		try {
			String groupId = params.containsKey('subGroupId') ? String.valueOf(params.get('subGroupId')) : '';
			String participantDetailsString = params.containsKey('participantDetailsString') ? String.valueOf(params.get('participantDetailsString')) : '';

			if (String.isBlank(groupId) || String.isBlank(participantDetailsString))
				return new Map<String, Object>{'result' => false, 'message' => 'Not Exists All Params. /' + groupId + ' / ' + participantDetailsString + ' / '};

			List<Contact> undefinedParticipant = [SELECT Id FROM Contact WHERE Name =:SYSTEM_GROUP_CONTACT_NAME LIMIT 1];
			SubGroupParticipantWrap participantDetails = (SubGroupParticipantWrap) JSON.deserialize (participantDetailsString, SubGroupParticipantWrap.class);
			update new Participant__c(
				Id = participantDetails.participantId,
				Contact__c = String.isBlank(participantDetails.newContactId) ? undefinedParticipant[0].Id : participantDetails.newContactId,
				Participant_Email__c = participantDetails.newContactEmail,
				Status__c = 'Registered'
			);

			List<Participant__c> updatedParticipant = [SELECT Id, Name FROM Participant__c WHERE Id =:participantDetails.participantId LIMIT 1];

			return new Map<String, Object>{'result' => true, 'message' => updatedParticipant[0].Name + ' Successfully invited to the community and to the event'};

		} catch (Exception e) { 
			system.debug('GroupDetailsLeaderController Error: ' + e.getMessage());
			system.debug('GroupDetailsLeaderController Stack : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> saveButtonClick(Map<String, Object> params) {
		try {
			String groupId = params.containsKey('subGroupId') ? String.valueOf(params.get('subGroupId')) : '';
			String participantDetailsString = params.containsKey('participantDetailsString') ? String.valueOf(params.get('participantDetailsString')) : '';

			if (String.isBlank(groupId) || String.isBlank(participantDetailsString))
				return new Map<String, Object>{'result' => false, 'message' => 'Not Exists All Params. /' + groupId + ' / ' + participantDetailsString + ' / '};

			List<Contact> undefinedParticipant = [SELECT Id FROM Contact WHERE Name =:SYSTEM_GROUP_CONTACT_NAME LIMIT 1];
			SubGroupParticipantWrap participantDetails = (SubGroupParticipantWrap) JSON.deserialize (participantDetailsString, SubGroupParticipantWrap.class);
			update new Participant__c(
				Id = participantDetails.participantId,
				Contact__c = String.isBlank(participantDetails.newContactId) ? undefinedParticipant[0].Id : participantDetails.newContactId,
				Participant_Email__c = participantDetails.newContactEmail
			);

			List<Participant__c> updatedParticipant = [SELECT Id, Name FROM Participant__c WHERE Id =:participantDetails.participantId LIMIT 1];

			return new Map<String, Object>{'result' => true, 'message' => updatedParticipant[0].Name + ' Successfully saved as a Draft. You can change this participant later.'};

		} catch (Exception e) { 
			system.debug('GroupDetailsLeaderController Error: ' + e.getMessage());
			system.debug('GroupDetailsLeaderController Stack : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> groupNameSave(Map<String, Object> params) {
		try {
			String groupId = params.containsKey('groupId') ? String.valueOf(params.get('groupId')) : '';
			String groupName = params.containsKey('groupName') ? String.valueOf(params.get('groupName')) : '';
			String eventName = params.containsKey('eventName') ? String.valueOf(params.get('eventName')) : '';

			if (String.isBlank(groupId) || String.isBlank(groupName))
				return new Map<String, Object>{'result' => false, 'message' => 'Not Exists All Params. /' + groupId + ' / ' + groupName + ' / '};

			update new Event_Registration_Group__c(
				Id = groupId,
				Name = groupName
			);

			List<Order__c> otherGroupOrders = [
				SELECT Id, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name
				FROM Order__c
				WHERE Event_custom__c != null
				AND Event_custom__r.Name !=:eventName
				AND Event_Registration_Sub_Group__c != null
				AND Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name !=:groupName
			];
			Set<String> disabledGroupNames = new Set<String>();
			for (Order__c otherGroupOrder : otherGroupOrders) disabledGroupNames.add(otherGroupOrder.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name);


			return new Map<String, Object>{'result' => true, 'message' => ' Successfully updated group name.', 'disabledGroupNames' => disabledGroupNames};

		} catch (Exception e) { 
			system.debug('GroupDetailsLeaderController Error: ' + e.getMessage());
			system.debug('GroupDetailsLeaderController Stack : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}


	//	Group
	public class GroupDetailsWrap {
		@AuraEnabled public String groupId { get; set; }
		@AuraEnabled public String groupName { get; set; }
		@AuraEnabled public String groupNameInitial { get; set; }
		@AuraEnabled public String eventName { get; set; }
		@AuraEnabled public String eventId { get; set; }
		@AuraEnabled public Datetime eventEndTime { get; set; }
		@AuraEnabled public Datetime eventStartTime { get; set; }
		@AuraEnabled public String eventEndDateString { get; set; }
		@AuraEnabled public String eventStartDateString { get; set; }
		@AuraEnabled public String eventEndTimeString { get; set; }
		@AuraEnabled public String eventStartTimeString { get; set; }

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

		@AuraEnabled public String accordionTitle { get; set; }			//	CUSTOM ACCORDIONS
		@AuraEnabled public Boolean accordionIsExpanded { get; set; }
		@AuraEnabled public Integer accordionIndex { get; set; }
	}

	//	Sub Group Participant
	public class SubGroupParticipantWrap {
		@AuraEnabled public String participantId { get; set; }
		@AuraEnabled public String oldContactId { get; set; }			//	'Undefined Participant' (Contact record Id)
		@AuraEnabled public String oldContactName { get; set; }
		@AuraEnabled public String oldContactEmail { get; set; }
		@AuraEnabled public String newContactId { get; set; }
		@AuraEnabled public String newContactName { get; set; }
		@AuraEnabled public String newContactEmail { get; set; }
		@AuraEnabled public Boolean disabledToEdit { get; set; }		//	Invited or Confirmed
		@AuraEnabled public String uniquekey1 { get; set; }				//	subGroupId
		@AuraEnabled public String uniquekey2 { get; set; }				//	index in list (0...)

		@AuraEnabled public ParticipantButtonsWrap buttonsSettings { get; set; }
		@AuraEnabled public ParticipantButtonsWrap buttonsSettingsInitial { get; set; }
		@AuraEnabled public ParticipantButtonsWrap buttonsSettingsIntermediate { get; set; }

		@AuraEnabled public ErrorWrap error { get; set; }
		@AuraEnabled public ErrorWrap errorInitial { get; set; }		//	used ONLY if order is paid and the user was deleted the participant email in input field

		@AuraEnabled public String invitationStatusInGroup { get; set; }
	}

	public class ParticipantButtonsWrap {
		@AuraEnabled public Boolean enableAddInviteButtons { get; set; }
		@AuraEnabled public Boolean displayAddButton { get; set; }
		@AuraEnabled public Boolean displayInviteButton { get; set; }
		@AuraEnabled public Boolean displaySaveDraftButton { get; set; }
		// @AuraEnabled public Boolean isDraftStatus { get; set; }
		@AuraEnabled public Boolean isInvited { get; set; }
		@AuraEnabled public Boolean isConfirmed { get; set; }
		@AuraEnabled public Boolean enableWarningMessage { get; set; }
		@AuraEnabled public Boolean displayWarningMessage { get; set; }	//	NOT PAID orders with Participant__r.Contact__r.Name != 'Undefined Participant'

	}

	public class ErrorWrap {
		@AuraEnabled public Boolean hasError { get; set; }
		@AuraEnabled public String message { get; set; }
	}

}