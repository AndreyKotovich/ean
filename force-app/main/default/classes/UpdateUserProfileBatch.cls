global class UpdateUserProfileBatch implements Database.Batchable<SObject>, Database.Stateful{
        global Log__c log = new Log__c();
        global Id memberProfileId;
        global Database.QueryLocator start(Database.BatchableContext bc) {
            memberProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Member Community User Profile'].Id;
            log.Process_Name__c='Batch: UpdateUserProfileBatch';
            log.Start_Time__c=Datetime.now();
            log.Status__c='In Progress';
            insert log;
            log.Status__c='Completed';
            log.Message__c='';

            return Database.getQueryLocator(
                    'SELECT Id, (SELECT Id, IsActive__c FROM MembershipContactAssotiations__r) ' +
                    'FROM Contact'
            );
        }
        global void execute(Database.BatchableContext bc, List<Contact> records) {
            try {
                List<Contact> contactsToUpdate  = new List<Contact>();
                for(Contact c : records){
                    if(c.MembershipContactAssotiations__r.size()>0){
                        for(MembershipContactAssotiation__c mca : c.MembershipContactAssotiations__r){
                            if(mca.IsActive__c){
                                contactsToUpdate.add(c);
                                break;
                            }
                        }
                    }
                }
                List<User> usersToUpdate = [SELECT Id, ProfileId FROM User WHERE ContactId IN :contactsToUpdate];
                for(User u : usersToUpdate){
                    if(u.ProfileId != memberProfileId){
                        u.ProfileId = memberProfileId;
                    }
                }
                if(!usersToUpdate.isEmpty()){
                    update usersToUpdate;
                }
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