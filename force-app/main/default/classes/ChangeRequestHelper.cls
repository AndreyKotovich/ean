public without sharing class ChangeRequestHelper {
	
	public static void sendEmailIfStatusChanged(List<Change_Request__c> changeRequestNew,  Map<Id, Change_Request__c> changeRequestOldMap) {
		List<Change_Request__c> changeRequestsStatusChanged = new List<Change_Request__c>();
		List<Change_Request__c> changeRequestsTransferApproved = new List<Change_Request__c>();
		List<String> contactIds = new List<String>();
		for (Change_Request__c changeRequest : changeRequestNew) {
			if ((changeRequest.Status__c == 'Rejected' || changeRequest.Status__c == 'Approved')
				&& changeRequestOldMap.get(changeRequest.Id).Status__c != changeRequest.Status__c) {
					changeRequestsStatusChanged.add(changeRequest);
					contactIds.add(changeRequest.Contact__c);
			}
			if (changeRequest.Status__c == 'Approved'
			&& changeRequestOldMap.get(changeRequest.Id).Status__c != changeRequest.Status__c
			&& changeRequest.Type__c == 'Solo Registration Transfer'
			|| changeRequest.Type__c == 'Group Registration Transfer') {
				changeRequestsTransferApproved.add(changeRequest);
				contactIds.add(changeRequest.TransferToContact__c);
			}
		}
		Map<Id, Contact> contactsMap = new Map<ID, Contact>([
			SELECT Id, Email FROM Contact WHERE Id IN :contactIds
		]);
		List<String> contactsWithEmptyEmail = new List<String>();
		for (Id contactId : contactsMap.keySet()) {
			if (String.isBlank(contactsMap.get(contactId).Email)) {
				contactsWithEmptyEmail.add(contactsMap.get(contactId).Id);
			}
		}
		Map<String, Participant__c> participantsToContactIdMap = new Map<String, Participant__c>();
		if (contactsWithEmptyEmail.size() > 0) {
			List<Participant__c> participants = [
				SELECT Id, Contact__c, Participant_Email__c FROM Participant__c WHERE Status__c = 'Registered' AND deleted__c = false AND Contact__c IN :contactsWithEmptyEmail
			];
			for (Participant__c participant : participants) {
				participantsToContactIdMap.put(participant.Contact__c, participant);
			}
		}
		List<Email_activity__c> emailActivities = new List<Email_activity__c>();
		for (Change_Request__c changeRequest : changeRequestsStatusChanged) {
			Email_activity__c emailActivity = new Email_activity__c();
			emailActivity.Change_Request__c = changeRequest.Id;
			emailActivity.Contact__c = changeRequest.Contact__c;
			if (String.isNotBlank(contactsMap.get(changeRequest.Contact__c).Email)) {
				emailActivity.Send_To_Email__c = contactsMap.get(changeRequest.Contact__c).Email;
			} else {
				if (participantsToContactIdMap.containsKey(changeRequest.Contact__c)) {
					emailActivity.Send_To_Email__c = participantsToContactIdMap.get(changeRequest.Contact__c).Participant_Email__c;
				}
			}
			emailActivity.Event_custom__c = changeRequest.Event_custom__c;				
			emailActivity.Type__c = changeRequest.Type__c;
			emailActivities.add(emailActivity);
		}
		insert emailActivities;
	}
}