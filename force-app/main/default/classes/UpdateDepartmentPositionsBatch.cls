//Update department position batch AFTER MIGRATION
global class UpdateDepartmentPositionsBatch implements Database.Batchable<sObject>, Database.Stateful{
    global Log__c log = new Log__c();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateDepartmentPositionsBatch';
        log.Start_Time__c = Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, Account__c, Account__r.ParentId, Hospital__c FROM Contact_Role__c WHERE RecordType.DeveloperName = \'Department\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact_Role__c> records) {
        try {
            for(Contact_Role__c cr : records){
                if(cr.Account__c != null){
                    cr.Hospital__c = cr.Account__r.ParentId;
                }
            }
            update records;
        }catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }
    global void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}