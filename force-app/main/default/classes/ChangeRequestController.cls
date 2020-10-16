public with sharing class ChangeRequestController {

	public static final String CHANGE_REQUEST_OBJECT_API_NAME = 'Change_Request__c';
	public static final String PICKLIST_FIELD_API_NAME = 'Type__c';

	@AuraEnabled
	public static Map<String, Object> getPreparedData(Map<String, Object> settings) {
		try {

			//	FIRST PRIORITY	//	becomes from QuickAction	if our manager click 'New Change Request' button on 'Contact' record
			String recordId = settings.containsKey('recordId') ? String.valueOf(settings.get('recordId')) : '';

			//	SECOND PRIORITY
			String userId = '' + UserInfo.getUserId();	//	eanStaffUserId OR communityUserId

			List<User> communityUser = !String.isBlank(recordId) ? [SELECT Id, ContactId, Contact.AccountId FROM User WHERE ContactId =:recordId LIMIT 1]
				: [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id =:userId LIMIT 1];

			String communityContactId = '' + communityUser[0].ContactId;	// Id communityAccountId = communityUser[0].Contact.AccountId;
			Boolean executedNotAtCommunity = userId != '' + communityUser[0].Id;

			system.debug('executedNotAtCommunity= ' + executedNotAtCommunity);
			system.debug('userId= ' + userId);
			system.debug('communityUser[0].Id= ' + '' + communityUser[0].Id);

			List<Change_Request__c> changeRequests = [
				SELECT Id, Name, CreatedDate, Description__c, Event_Participation__c, Status__c,
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
				cr.enabledToRevoke = cr.crStatus == 'Requested';
				changeRequestsList.add(cr);
			}

			return new Map<String, Object>{
				'result' => true,

				//	DEBUG
				'userId' => userId,
				'communityUser' => communityUser,
				'communityContactId' => communityContactId,
				'changeRequests' => changeRequests,

				'changeRequestsList' => changeRequestsList,
				'displayNoRecordsMessage' => changeRequestsList.isEmpty(),
				'displayChangeRequestsList' => !changeRequestsList.isEmpty(),
				'requestsTypeListMap' => getPicklistValues(CHANGE_REQUEST_OBJECT_API_NAME, PICKLIST_FIELD_API_NAME),
				'componentLabel' => executedNotAtCommunity ? 'Community User Change Requests' : 'My Change Requests',
				'displayTopButtons' => !executedNotAtCommunity,
				'displayBottomButtons' => executedNotAtCommunity
			};

		} catch (Exception e) { return new Map<String, Object>{'result' => false, 'message' => e.getMessage(), 'messageStack' => e.getStackTraceString()}; }
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
		@AuraEnabled public Boolean enabledToRevoke { get; set; }
	}

}