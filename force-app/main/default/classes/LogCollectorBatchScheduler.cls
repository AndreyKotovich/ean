public class LogCollectorBatchScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LogCollectorBatch(), 200);
    }
}