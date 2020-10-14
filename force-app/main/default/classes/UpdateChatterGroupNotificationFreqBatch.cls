public with sharing class UpdateChatterGroupNotificationFreqBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public List<Id> groupsIds = new List<Id>();
    public String notificationFrequency;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateChatterGroupNotificationFreqBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, NotificationFrequency FROM CollaborationGroupMember WHERE CollaborationGroupId IN :groupsIds'
        );
    }
    public void execute(Database.BatchableContext bc, List<CollaborationGroupMember> records) {
        try {

            for(CollaborationGroupMember groupMember : records){
                if(notificationFrequency != null && notificationFrequency != ''){
                    groupMember.NotificationFrequency = notificationFrequency;
                }
            }

            update records;
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