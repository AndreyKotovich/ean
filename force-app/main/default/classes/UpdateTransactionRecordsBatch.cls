//Tests located in OneTimeRunBatchTest
public class UpdateTransactionRecordsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateTransactionRecordsBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, JSONResponse__c, Reference_Id__c FROM Transaction__c WHERE Payment_Method__c!=NULL'
        );
    }

    public void execute(Database.BatchableContext bc, List<Transaction__c> records) {
        try{
            for(Transaction__c tr : records){
                if(tr.Reference_Id__c == null && tr.JSONResponse__c!=null){
                    String JSONResponse = tr.JSONResponse__c.replaceAll('\\n', '');
                    if(JSONResponse.contains('transaction-id')) {
                        System.debug('OwnFlag: '+((Map<String, Object>) JSON.deserializeUntyped(tr.JSONResponse__c)).containsKey('payment'));
                        if (((Map<String, Object>) JSON.deserializeUntyped(tr.JSONResponse__c)).containsKey('payment')) {
                            Object payment = ((Map<String, Object>) JSON.deserializeUntyped(tr.JSONResponse__c)).get('payment');
                            if (((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).containsKey('transaction-id') && payment != null) {
                                Object transactionId = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('transaction-id');
                                tr.Reference_Id__c = (String) transactionId;
                            }
                        }
                    }
                }
            }
            update records;
        } catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }

    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}