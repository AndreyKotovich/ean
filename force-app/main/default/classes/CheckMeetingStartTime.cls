/**
 * Created by aleksandr on 6.3.20.
 */

global class CheckMeetingStartTime implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext ctx) {
        System.debug('CheckMeetingStartTime execute');
        ID jobID = System.enqueueJob(new CheckMeetingStartTimeQueueable());
    }
}