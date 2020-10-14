global class ScheduledSyncMembershipChatterBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        Map<Id, Membership__c> syncMemberships = new Map<Id, Membership__c>([SELECT Id FROM Membership__c WHERE Enable_synchronization__c = TRUE]);

        if(!syncMemberships.isEmpty()){
            SyncMembershipToChatterMembersBatch b = new SyncMembershipToChatterMembersBatch();
            b.membershipsIds = new List<Id>(syncMemberships.keySet());
            Database.executeBatch(b, 200);
        }
    }
}