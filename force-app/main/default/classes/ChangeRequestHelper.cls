public without sharing class ChangeRequestHelper {
	public static void createChangeRequestOrder(List<Change_Request__c> changeRequestNew,  Map<Id, Change_Request__c> changeRequestOldMap) {
		Map<Id, Id> partToChanges = new Map<Id, Id>();
		Map<Id, Id> ordToChanges = new Map<Id, Id>();

		for(Change_Request__c c: changeRequestNew) {
			if (c.Status__c == 'Approved' && c.Status__c != changeRequestOldMap.get(c.Id).Status__c && !String.isBlank(c.Event_Participation__c)) {
				partToChanges.put(c.Event_Participation__c, c.Id);
			}
		}

		if (!partToChanges.isEmpty()) {
			for(Participant__c p : [SELECT Id, (SELECT Id, Order_Custom__c FROM Order_Items__r) FROM Participant__c WHERE Id IN :partToChanges.keySet()]) {
				List<Order_Item__c> oi = p.Order_Items__r;
				if ( oi.size() > 0 && !String.isBlank(oi[0].Order_Custom__c)) {
					ordToChanges.put(oi[0].Order_Custom__c, partToChanges.get(p.Id));
				}
			}
			if (!ordToChanges.isEmpty()) { OrderHelper.cancelledOrder(ordToChanges); }
		}
	}
	public static void sendEmailIfStatusChanged(List<Change_Request__c> changeRequestNew,  Map<Id, Change_Request__c> changeRequestOldMap) {
		List<Change_Request__c> changeRequestsStatusChanged = new List<Change_Request__c>();
		for (Change_Request__c changeRequest : changeRequestNew) {
			if ((changeRequest.Status__c == 'Rejected' || changeRequest.Status__c == 'Approved')
				&& changeRequestOldMap.get(changeRequest.Id).Status__c != changeRequest.Status__c) {
					changeRequestsStatusChanged.add(changeRequest);
			}
		}
		List<Email_activity__c> emailActivities = new List<Email_activity__c>();
		for (Change_Request__c changeRequest : changeRequestsStatusChanged) {
			Email_activity__c emailActivity = new Email_activity__c();
			emailActivity.Change_Request__c = changeRequest.Id;
			emailActivity.Contact__c = changeRequest.Contact__c;
			emailActivity.Event_custom__c = changeRequest.Event_custom__c;				
			emailActivity.Event_Registration_Group__c = changeRequest.Event_Registration_Group__c;
			emailActivity.Status__c = changeRequest.Status__c;
			emailActivity.Type__c = changeRequest.Type__c;
			emailActivity.TransferFromContact__c = changeRequest.TransferFromContact__c;
			emailActivity.TransferToContact__c = changeRequest.TransferToContact__c;
			emailActivity.TransferFromEmail__c = changeRequest.TransferFromEmail__c;
			emailActivity.TransferToEmail__c = changeRequest.TransferToEmail__c;
			emailActivities.add(emailActivity);
		}
		insert emailActivities;
	}
}