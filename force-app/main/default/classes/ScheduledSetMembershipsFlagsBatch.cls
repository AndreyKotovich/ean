global class ScheduledSetMembershipsFlagsBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        SetMembershipsFlagsOnContactBatch job = new SetMembershipsFlagsOnContactBatch();
        Database.executeBatch(job, 200);
    }
}