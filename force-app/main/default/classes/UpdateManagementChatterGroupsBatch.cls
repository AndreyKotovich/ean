//One time batch
public class UpdateManagementChatterGroupsBatch implements Database.Batchable<SObject>, Database.Stateful{
    public Log__c log = new Log__c();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateManagementChatterGroupsBatch';
        log.Start_Time__c = Datetime.now();
        log.Status__c='In Progress';
        log.Type__c='Batch';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, Name, MG_Chatter_Group_Accessibility__c, Management_Chatter_Group_Id__c ' +
                        'FROM Group__c ' +
                        'WHERE Enable_management_group__c = TRUE'
        );
    }

    public void execute(Database.BatchableContext bc, List<Group__c> records) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> existedChatterGroupIds = new List<Id>();

            for(Group__c g : records){
                existedChatterGroupIds.add(g.Management_Chatter_Group_Id__c);
                g.Enable_management_group__c = false;
                g.Management_Chatter_Group_Id__c = '';
            }

            update records;

            List<CollaborationGroup> chatterGroups = [SELECT Id FROM CollaborationGroup WHERE Id IN :existedChatterGroupIds];
            delete chatterGroups;

            for(Group__c g : records){
                g.MG_Chatter_Group_Accessibility__c = 'Unlisted';
                g.Enable_management_group__c = true;
            }

            update records;

        } catch (Exception e) {
            Database.rollback(sp);
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }

    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }

}