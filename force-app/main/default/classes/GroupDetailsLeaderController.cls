public without sharing class GroupDetailsLeaderController {

	public static final String SYSTEM_GROUP_CONTACT_NAME = 'Undefined Participant';

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
					'groupId' => groupId,
					'communityUser' => communityUser,
					'contactRecordId' => contactRecordId,
					'result' => false,
					'message' => 'Leader Contact or Grounp not found.'
				};

			//	SOQL
			getGroupParticipants(contactRecordId, groupId);
			if (groupParticipants.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Group configuration is not correct.'};

			//	COLLECT GROUP INFO
			collectInfoFromGroupParticipants();

			//	COLLECT INFO FROM ORDERS AND DEFINE ACCORDIONS
			getInfoFromOrdersAndDefineAccordions();

			//	define the main details of Group (to display at the community page)
			GroupDetailsWrap groupDetails = new GroupDetailsWrap();
			groupDetails.groupId = groupParticipants[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c;
			groupDetails.groupName = groupParticipants[0].Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name;
			groupDetails.eventName = groupParticipants[0].Event_custom__r.Name;
			groupDetails.eventId = groupParticipants[0].Event_custom__c;
			groupDetails.eventEndTime = groupParticipants[0].Event_custom__r.End_Time__c;		//	Datetime
			groupDetails.eventStartTime = groupParticipants[0].Event_custom__r.Start_Time__c;					//	Datetime
			groupDetails.eventEndDateString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('dd.MM.yyyy') : '';
			groupDetails.eventStartDateString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('dd.MM.yyyy') : '';
			groupDetails.eventEndTimeString = groupDetails.eventEndTime != null ? (groupDetails.eventEndTime).format('HH:mm') : '';
			groupDetails.eventStartTimeString = groupDetails.eventStartTime != null ? (groupDetails.eventStartTime).format('HH:mm') : '';
			groupDetails.totalGroupExistingParticipants = totalGroupExistingParticipants;
			groupDetails.totalGroupMaxParticipants = totalGroupMaxParticipants;

			List<String> disabledEmailsNotThisGroup = EventRegistrationController.getNotAvailableEventRegistrationEmails(new List<String>{groupDetails.eventId}, orderedSubGroupIds);

			// Set<String> disabledEmailsNotThisGroup = new Set<String>();
			// for (String disabledEmail : disabledEmails) {
			// 	if (!disabledEmailsThisGroup.contains(disabledEmail)) disabledEmailsNotThisGroup.add(disabledEmail);
			// }

			return new Map<String, Object>{
				'result' => true,
				'groupDetails' => groupDetails,
				'subGroupList' => subGroupList,
				// 'disabledEmails' => disabledEmails,
				'disabledEmailsThisGroup' => disabledEmailsThisGroup,
				'disabledEmailsNotThisGroup' => disabledEmailsNotThisGroup,
				'displayAccordions' => !subGroupList.isEmpty(),
				'displayAddMoreTicketsButton' => true
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
				Event_Registration_Sub_Group__r.CreatedDate, Event_Registration_Sub_Group__r.Is_Locked__c,
				Event_Registration_Sub_Group__r.Event_Registration_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name,
				Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__r.Name,
				Invitation_Status_In_Group__c	//	Draft	Invited		Confirmed
			FROM Participant__c
			WHERE Event_Registration_Sub_Group__r.Event_Registration_Group__r.Contact__c =:contactRecordId
			AND RecordTypeId !=:g2mRT
			AND Event_Registration_Sub_Group__r.Event_Registration_Group__c =:groupId
			AND Contact__c != null
			AND Event_custom__c != null
			// ORDER BY Event_Registration_Sub_Group__r.CreatedDate, Invitation_Status_In_Group__c DESC NULLS LAST
			ORDER BY Event_Registration_Sub_Group__r.CreatedDate, Invitation_Status_In_Group__c DESC NULLS LAST, Participant_Email__c DESC NULLS LAST
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

			Boolean isDraftStatus = String.isBlank(participant.Invitation_Status_In_Group__c) || participant.Invitation_Status_In_Group__c == 'Draft';
			ParticipantButtonsWrap buttonsSettings = new ParticipantButtonsWrap();
			buttonsSettings.enableAddInviteButtons = true;
			buttonsSettings.displayAddButton = isDraftStatus && !String.isBlank(subGroupParticipant.oldContactName);
			buttonsSettings.displayInviteButton = isDraftStatus && String.isBlank(subGroupParticipant.oldContactName) && !String.isBlank(subGroupParticipant.oldContactEmail);
			buttonsSettings.displaySaveDraftButton = false;
			buttonsSettings.isDraftStatus = isDraftStatus;	// ???
			buttonsSettings.isInvited = participant.Invitation_Status_In_Group__c == 'Invited';
			buttonsSettings.isConfirmed = participant.Invitation_Status_In_Group__c == 'Confirmed';

			subGroupParticipant.buttonsSettings = buttonsSettings;
			subGroupParticipant.buttonsSettingsInitial = buttonsSettings;

			// @AuraEnabled public ParticipantButtonsWrap buttonsSettings { get; set; }
			// @AuraEnabled public ParticipantButtonsWrap buttonsSettingsInitial { get; set; }



			// subGroupParticipant.displayAddButton = isDraftStatus && !String.isBlank(subGroupParticipant.oldContactName);
			// subGroupParticipant.displayInviteButton = isDraftStatus && String.isBlank(subGroupParticipant.oldContactName) && !String.isBlank(subGroupParticipant.oldContactEmail);
			// subGroupParticipant.displaySaveDraftButton = false;
			// subGroupParticipant.isDraftStatus = isDraftStatus;	// ???
			subGroupParticipant.invitationStatusInGroup = participant.Invitation_Status_In_Group__c;	//	develop moment

			// subGroupParticipant.isInvited = participant.Invitation_Status_In_Group__c == 'Invited';
			// subGroupParticipant.isConfirmed = participant.Invitation_Status_In_Group__c == 'Confirmed';

			subGroupParticipant.disabledToEdit = !isDraftStatus;

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
		//	disable edit participants if 'subgroup' is locked OR 'subgroup order status' == 'Open'
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

			if (isOrderExist) {
				Order__c order = orderSubGroupIdToOrder.get(subGroupId);
				subGroupDetails.accordionTitle = 'Order: ' + order.Name + ' (Status: ' + (order.Status__c == 'Opened' ? 'Not Paid' : order.Status__c) + ')';
				isOrderPaid = order.Status__c == 'Paid';
			} else {
				subGroupDetails.accordionTitle = 'Order Not Found';
			}

			List<SubGroupParticipantWrap> subGroupParticipantList = subGroupDetails.subGroupParticipantList;
			Boolean accordionIsExpanded = false;
			for (SubGroupParticipantWrap subGroupParticipant : subGroupParticipantList) {

				subGroupParticipant.buttonsSettings.enableAddInviteButtons = isOrderPaid;

				ErrorWrap error = new ErrorWrap();
				error.hasError = false;
				error.message = '';
				ErrorWrap errorInitial = new ErrorWrap();
				errorInitial.hasError = false;
				errorInitial.message = 'Please enter email';

				if (isOrderPaid && String.isBlank(subGroupParticipant.oldContactEmail)) {
					errorInitial.hasError = true;
					error.hasError = true;
					error.message = 'Please enter email';
				}
				subGroupParticipant.error = error;
				subGroupParticipant.errorInitial = errorInitial;
				// subGroupParticipant.errorInitial = error;

				subGroupParticipant.buttonsSettings.displayAddButton = subGroupParticipant.buttonsSettings.displayAddButton && isOrderPaid;
				subGroupParticipant.buttonsSettings.displayInviteButton = subGroupParticipant.buttonsSettings.displayInviteButton && isOrderPaid;
				subGroupParticipant.buttonsSettingsInitial = subGroupParticipant.buttonsSettings;
				subGroupParticipant.buttonsSettingsIntermediate = subGroupParticipant.buttonsSettings;

				if (subGroupParticipant.buttonsSettings.isDraftStatus) accordionIsExpanded = true;
			}
			subGroupDetails.accordionIsExpanded = accordionIsExpanded;

		subGroupDetails.accordionIndex = accordionIndex;
		accordionIndex++;
		subGroupList.add(subGroupDetails);
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
		@AuraEnabled public Boolean isDraftStatus { get; set; }
		@AuraEnabled public Boolean isInvited { get; set; }				//	participant.Invitation_Status_In_Group__c == 'Invited'
		@AuraEnabled public Boolean isConfirmed { get; set; }			//	participant.Invitation_Status_In_Group__c == 'Confirmed'
	}

	public class ErrorWrap {
		@AuraEnabled public Boolean hasError { get; set; }
		@AuraEnabled public String message { get; set; }
	}

}