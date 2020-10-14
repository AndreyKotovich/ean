global class SetCommunityUsersProfilesBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Log__c log = new Log__c();
    global Id memberProfileId;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        memberProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        log.Process_Name__c='Batch: SetCommunityUsersProfilesBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, (SELECT Id FROM MembershipContactAssotiations__r) ' +
                'FROM Contact'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> records) {
        try {
            List<Contact> contactsToUpdate  = new List<Contact>();
            for(Contact c : records){
                if(c.MembershipContactAssotiations__r.size()>0){
                    contactsToUpdate.add(c);
                }
            }
            List<User> usersToUpdate = [SELECT Id, ProfileId, Profile.Name FROM User WHERE IsActive = TRUE AND ContactId IN :contactsToUpdate];
            for(User u : usersToUpdate){
                if(u.ProfileId != memberProfileId){
                    u.ProfileId = memberProfileId;
                }
            }
            update usersToUpdate;
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