public without sharing class ChangeRequestController {

	public static final String CHANGE_REQUEST_OBJECT_API_NAME = 'Change_Request__c';
	public static final String PICKLIST_FIELD_API_NAME = 'Type__c';

	public static final String CR_TYPE_SOLO_CANCELLATION = 'Solo Registration Cancellation';
	public static final String CR_TYPE_GROUP_CANCELLATION = 'Group Registration Cancellation';
	public static final String CR_TYPE_SOLO_TRANSFER = 'Solo Registration Transfer';
	public static final String CR_TYPE_GROUP_TRANSFER = 'Group Registration Transfer';

	@AuraEnabled
	public static Map<String, Object> getPreparedData(Map<String, Object> settings) {
		try {

			//	FIRST PRIORITY	//	becomes from QuickAction	if our manager click 'New Change Request' button on 'Contact' record
			String recordId = settings.containsKey('recordId') ? String.valueOf(settings.get('recordId')) : '';

			//	SECOND PRIORITY
			String userId = '' + UserInfo.getUserId();	//	eanStaffUserId OR communityUserId

			List<User> communityUser = !String.isBlank(recordId) ? [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.AccountId FROM User WHERE ContactId =:recordId LIMIT 1]
				: [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];

			String communityContactId = '' + communityUser[0].ContactId;	// Id communityAccountId = communityUser[0].Contact.AccountId;
			String communityContactName = communityUser[0].Contact.Name;
			String communityContactEmail = communityUser[0].Contact.Email;
			Boolean executedNotAtCommunity = userId != '' + communityUser[0].Id;

			system.debug('executedNotAtCommunity= ' + executedNotAtCommunity);
			system.debug('userId= ' + userId);
			system.debug('communityUser[0].Id= ' + '' + communityUser[0].Id);

			List<Change_Request__c> changeRequests = [
				SELECT Id, Name, CreatedDate, Description__c, Event_Participation__c, Event_custom__c, Event_custom__r.Name, Status__c,
					TransferFromContact__c, TransferFromEmail__c, TransferToContact__c, TransferToEmail__c, Type__c
				FROM Change_Request__c
				WHERE Contact__c =:communityContactId
				ORDER BY CreatedDate DESC
				LIMIT 200
			];
			List<ChangeRequestWrap> changeRequestsList = new List<ChangeRequestWrap>();
			for (Change_Request__c changeRequest : changeRequests) {
				ChangeRequestWrap cr = new ChangeRequestWrap();
				cr.crId = changeRequest.Id;
				cr.crName = changeRequest.Name;
				cr.crStatus = changeRequest.Status__c;
				cr.crType = changeRequest.Type__c;
				cr.crDescription = changeRequest.Description__c;
				cr.crCreatedDateString = changeRequest.CreatedDate.format('dd.MM.yyyy');
				cr.crCreatedTimeString = changeRequest.CreatedDate.format('HH:mm');
				cr.crEventName = changeRequest.Event_custom__c != null ? changeRequest.Event_custom__r.Name : '';
				cr.enabledToRevoke = cr.crStatus == 'Requested';
				changeRequestsList.add(cr);
			}

			return new Map<String, Object>{
				'result' => true,

				//	DEBUG
				'userId' => userId,
				'communityUser' => communityUser,
				'communityContactId' => communityContactId,
				'communityContactName' => communityContactName,
				'communityContactEmail' => communityContactEmail,
				// 'changeRequests' => changeRequests,

				'changeRequestsList' => changeRequestsList,
				'displayNoRecordsMessage' => changeRequestsList.isEmpty(),
				'displayChangeRequestsList' => !changeRequestsList.isEmpty(),
				'requestsTypeListMap' => getPicklistValues(CHANGE_REQUEST_OBJECT_API_NAME, PICKLIST_FIELD_API_NAME),
				'componentLabel' => executedNotAtCommunity ? 'Community User Change Requests' : 'My Change Requests',
				'displayTopButtons' => !executedNotAtCommunity,
				'displayBottomButtons' => executedNotAtCommunity
			};

		} catch (Exception e) {
			system.debug('ChangeRequestController getPreparedData ERROR message: ' + e.getMessage());
			system.debug('ChangeRequestController getPreparedData ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> clickOnRevoke(Map<String, Object> params) {
		try {
			String selectedChangeRequestId = params.containsKey('selectedChangeRequestId') ? String.valueOf(params.get('selectedChangeRequestId')) : '';
			List<Change_Request__c> selectedChangeRequest = [SELECT Id, Name, Status__c FROM Change_Request__c WHERE Status__c = 'Requested' AND Id =:selectedChangeRequestId LIMIT 1];
			if (selectedChangeRequest.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Change Request Not Found'};

			selectedChangeRequest[0].Status__c = 'Revoked';
			update selectedChangeRequest;
			return new Map<String, Object>{'result' => true, 'message' => 'Change Request: ' + selectedChangeRequest[0].Name + ' successfully revoked.'};
		} catch (Exception e) {
			system.debug('ChangeRequestController clickOnRevoke ERROR message: ' + e.getMessage());
			system.debug('ChangeRequestController clickOnRevoke ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> submitSoloCancellation(Map<String, Object> params) {
		try {
			String selectedContactId = params.containsKey('selectedContactId') ? String.valueOf(params.get('selectedContactId')) : '';
			String crDescription = params.containsKey('crDescription') ? String.valueOf(params.get('crDescription')) : '';
			String selectedParticipantId = params.containsKey('selectedParticipantId') ? String.valueOf(params.get('selectedParticipantId')) : '';

			List<Participant__c> participant = [SELECT Id, Event_custom__c FROM Participant__c WHERE Id =:selectedParticipantId LIMIT 1];
			if (participant.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Participant Not Found. Id: ' + selectedParticipantId};

			Change_Request__c newChangeRequest = new Change_Request__c(
				Contact__c = selectedContactId,
				Description__c = crDescription,
				Event_Participation__c = selectedParticipantId,
				Event_custom__c = participant[0].Event_custom__c,
				Status__c = 'Requested',
				Type__c = CR_TYPE_SOLO_CANCELLATION
			);
			insert newChangeRequest;
			newChangeRequest = [SELECT Id, Name FROM Change_Request__c WHERE Id =:newChangeRequest.Id LIMIT 1];

			return new Map<String, Object> {
				'result' => true,
				'message' => 'Change Request: ' + newChangeRequest.Name + ' successfully created.'
			};
		} catch (Exception e) {
			system.debug('ChangeRequestController submitSoloCancellation ERROR message: ' + e.getMessage());
			system.debug('ChangeRequestController submitSoloCancellation ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> submitGroupCancellation(Map<String, Object> params) {
		try {
			String selectedContactId = params.containsKey('selectedContactId') ? String.valueOf(params.get('selectedContactId')) : '';
			String crDescription = params.containsKey('crDescription') ? String.valueOf(params.get('crDescription')) : '';
			String selectedGroupId = params.containsKey('selectedGroupId') ? String.valueOf(params.get('selectedGroupId')) : '';

			List<Event_Registration_Group__c> selectedGroup = [SELECT Id, (SELECT Id FROM Event_Registration_Sub_Groups__r LIMIT 1) FROM Event_Registration_Group__c WHERE Id =:selectedGroupId LIMIT 1];
			if (selectedGroup.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Group Not Found. Id: ' + selectedGroupId};
			String subGroupId = !selectedGroup[0].Event_Registration_Sub_Groups__r.isEmpty() ? '' + selectedGroup[0].Event_Registration_Sub_Groups__r[0].Id : '';
			List<Participant__c> participant = !String.isBlank(subGroupId)
				// ? [SELECT Id FROM Participant__c WHERE Event_Registration_Sub_Group__c =:subGroupId LIMIT 1]
				? [SELECT Id, Event_custom__c, Event_Registration_Sub_Group__c FROM Participant__c WHERE Event_Registration_Sub_Group__c =:subGroupId LIMIT 1]
					: new List<Participant__c>();

			Change_Request__c newChangeRequest = new Change_Request__c(
				Contact__c = selectedContactId,
				Description__c = crDescription,
				Event_Registration_Group__c = selectedGroupId,
				Event_custom__c = !participant.isEmpty() ? participant[0].Event_custom__c : null,
				Status__c = 'Requested',
				Type__c = CR_TYPE_GROUP_CANCELLATION
			);
			insert newChangeRequest;
			newChangeRequest = [SELECT Id, Name FROM Change_Request__c WHERE Id =:newChangeRequest.Id LIMIT 1];

			return new Map<String, Object> {
				'selectedGroup' => JSON.serialize(selectedGroup),
				'subGroupId' => subGroupId,
				'participant' => participant,
				// 'participant[0].Event_custom__c' => participant[0].Event_custom__c,
				'result' => true,
				'message' => 'Change Request: ' + newChangeRequest.Name + ' successfully created.'
			};
		} catch (Exception e) {
			system.debug('ChangeRequestController submitGroupCancellation ERROR message: ' + e.getMessage());
			system.debug('ChangeRequestController submitGroupCancellation ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> submitSoloTransfer(Map<String, Object> params) {
		try {

			String selectedParticipantId = params.containsKey('selectedParticipantId') ? String.valueOf(params.get('selectedParticipantId')) : '';
			String communityContactId = params.containsKey('communityContactId') ? String.valueOf(params.get('communityContactId')) : '';
			String communityContactEmail = params.containsKey('communityContactEmail') ? String.valueOf(params.get('communityContactEmail')) : '';
			String requestedContactId = params.containsKey('requestedContactId') ? String.valueOf(params.get('requestedContactId')) : '';
			String requestedContactEmail = params.containsKey('requestedContactEmail') ? String.valueOf(params.get('requestedContactEmail')) : '';
			String crDescription = params.containsKey('crDescription') ? String.valueOf(params.get('crDescription')) : '';

			if (String.isBlank(selectedParticipantId) || String.isBlank(requestedContactEmail)) {
				return new Map<String, Object>{'result' => false, 'message' => 'Not All Params Are Defined (' + selectedParticipantId + ' / ' + communityContactEmail + ' / ' + requestedContactEmail + ')'};
			}

			List<Participant__c> participant = [
				SELECT Id, Event_custom__c, Event_Registration_Sub_Group__c, Event_Registration_Sub_Group__r.Event_Registration_Group__c
				FROM Participant__c
				WHERE Id =:selectedParticipantId
				LIMIT 1
			];
			if (participant.isEmpty()) return new Map<String, Object>{'result' => false, 'message' => 'Participant Not Found. Id: ' + selectedParticipantId};

			Change_Request__c newChangeRequest = new Change_Request__c(
				Contact__c = communityContactId,
				Description__c = crDescription,
				Event_Participation__c = selectedParticipantId,
				Event_custom__c = participant[0].Event_custom__c,
				TransferFromContact__c = communityContactId,
				TransferFromEmail__c = communityContactEmail,
				TransferToContact__c = requestedContactId,
				TransferToEmail__c = requestedContactEmail,
				Event_Registration_Group__c = participant[0].Event_Registration_Sub_Group__c != null ? participant[0].Event_Registration_Sub_Group__r.Event_Registration_Group__c : null,
				Status__c = 'Requested',
				Type__c = CR_TYPE_SOLO_TRANSFER
			);
			insert newChangeRequest;
			newChangeRequest = [SELECT Id, Name FROM Change_Request__c WHERE Id =:newChangeRequest.Id LIMIT 1];

			return new Map<String, Object> {
				'result' => true,
				'message' => 'Change Request: ' + newChangeRequest.Name + ' successfully created.'
			};

		} catch (Exception e) {
			system.debug('ChangeRequestController submitSoloTransfer ERROR message: ' + e.getMessage());
			system.debug('ChangeRequestController submitSoloTransfer ERROR messageStack: ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()};
		}
	}

	@AuraEnabled
	public static Map<String, Object> finalSubmitTransferGroup(Map<String, Object> params) {
		try {
			system.debug('finalSubmitTransferGroup params: ' + JSON.serialize(params));

			String crDescription = params.containsKey('crDescription') ? String.valueOf(params.get('crDescription')) : '';
			String eventparamsString = params.containsKey('eventparams') ? String.valueOf(params.get('eventparams')) : '';

			String communityContactId = params.containsKey('communityContactId') ? String.valueOf(params.get('communityContactId')) : '';
			String selectedGroupId = params.containsKey('selectedGroupId') ? String.valueOf(params.get('selectedGroupId')) : '';

			List<GroupDetailsController.SubGroupDetailsWrap> subGroupDetailsList = !String.isBlank(eventparamsString)
				? (List<GroupDetailsController.SubGroupDetailsWrap>) JSON.deserialize(eventparamsString, List<GroupDetailsController.SubGroupDetailsWrap>.class)
					: new List<GroupDetailsController.SubGroupDetailsWrap>();

			String zeroParticipantId = !subGroupDetailsList.isEmpty() ? subGroupDetailsList[0].subGroupParticipantList[0].participantId : '';
			List<Participant__c> zeroParticipant = !String.isBlank(zeroParticipantId)
				? [SELECT Id, Event_custom__c FROM Participant__c WHERE Id =:zeroParticipantId LIMIT 1] : new List<Participant__c>();
			if (zeroParticipant.isEmpty() || zeroParticipant[0].Event_custom__c == null) {
				return new Map<String, Object>{'result' => false, 'message' => 'Not valid params'};
			}

			List<Change_Request__c> newChangeRequests = new List<Change_Request__c>();
			for (GroupDetailsController.SubGroupDetailsWrap subGroupDetails : subGroupDetailsList) {
				List<GroupDetailsController.SubGroupParticipantWrap> subGroupParticipants = subGroupDetails.subGroupParticipantList != null ? subGroupDetails.subGroupParticipantList : new List<GroupDetailsController.SubGroupParticipantWrap>();
				for (GroupDetailsController.SubGroupParticipantWrap subGroupParticipant : subGroupParticipants) {
					if (!subGroupParticipant.isNewTransferExist) continue;

					newChangeRequests.add(new Change_Request__c (
						Contact__c = communityContactId,
						Description__c = crDescription,
						Event_custom__c = zeroParticipant[0].Event_custom__c,
						Event_Participation__c = subGroupParticipant.participantId,
						Event_Registration_Group__c = selectedGroupId,
						Status__c = 'Requested',
						TransferFromContact__c = subGroupParticipant.oldContactId,
						TransferFromEmail__c = subGroupParticipant.oldContactEmail,
						TransferToContact__c = subGroupParticipant.newTransferDetails.crContactId,
						TransferToEmail__c = subGroupParticipant.newTransferDetails.crContactEmail,
						Type__c = CR_TYPE_GROUP_TRANSFER
					));
				}
			}
			insert newChangeRequests;
			return new Map<String, Object> {
				'result' => true,
				'message' => 'Change Requests successfully created.'
			};

		} catch (Exception e) { 
			system.debug('!!! ERROR !!! : ' + e.getMessage());
			system.debug('!!! ERROR !!! : ' + e.getStackTraceString());
			return new Map<String, Object>{'result' => false, 'message' => e.getStackTraceString()};
		}
	}


	//	TODO: Move to UTILS Apex class
	public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName){
		Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName);
		Schema.DescribeSObjectResult r = s.getDescribe();
		Map<String,Schema.SObjectField> fields = r.fields.getMap();
		Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		List<Map<String, String>> listValues = new List<Map<String, String>>();
		for(Schema.PicklistEntry pickListVal : ple){
			listValues.add(new Map<String, String>{'label' => pickListVal.getLabel(), 'value' => pickListVal.getValue()});
		}
		return listValues;
	}

	public class ChangeRequestWrap {
		@AuraEnabled public String crId { get; set; }
		@AuraEnabled public String crName { get; set; }
		@AuraEnabled public String crStatus { get; set; }
		@AuraEnabled public String crType { get; set; }
		@AuraEnabled public String crDescription { get; set; }
		@AuraEnabled public String crCreatedDateString { get; set; }
		@AuraEnabled public String crCreatedTimeString { get; set; }
		@AuraEnabled public String crEventName { get; set; }
		@AuraEnabled public Boolean enabledToRevoke { get; set; }
	}

}