public without sharing class ChangeRequestHelper {
	public static void createChangeRequestOrder(List<Change_Request__c> changeRequests) {
		Map<Id, Id> partToChanges = new Map<Id, Id>();
		Map<Id, Id> ordToChanges = new Map<Id, Id>();

		for(Change_Request__c c: changeRequests) {
			if (c.Status__c == 'Approved' && !String.isBlank(c.Event_Participation__c)) {
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
}