public class LogCollectorBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: LogCollectorBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        Datetime minimumDate = Datetime.now().addMonths(-2);

        return Database.getQueryLocator(
                'SELECT Id, CreatedDate FROM Log__c WHERE CreatedDate < :minimumDate'
        );
    }
    public void execute(Database.BatchableContext bc, List<Log__c> records) {
        try {
            System.debug(records);
            delete records;
        }catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }
    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}