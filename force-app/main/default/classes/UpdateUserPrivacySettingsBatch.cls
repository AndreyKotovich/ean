public class UpdateUserPrivacySettingsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public List<String> failedUserUpdate = new List<String>();
    public List<String> failedContactUpdate = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateUserPrivacySettingsBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id,UserPreferencesShowStreetAddressToGuestUsers,UserPreferencesShowWorkPhoneToExternalUsers,' +
                        'UserPreferencesShowWorkPhoneToGuestUsers,UserPreferencesShowMobilePhoneToExternalUsers,' +
                        'UserPreferencesShowMobilePhoneToGuestUsers,UserPreferencesShowPostalCodeToExternalUsers,' +
                        'UserPreferencesShowPostalCodeToGuestUsers,UserPreferencesShowStateToExternalUsers,' +
                        'UserPreferencesShowStateToGuestUsers,UserPreferencesShowCityToExternalUsers,' +
                        'UserPreferencesShowCityToGuestUsers,UserPreferencesShowCountryToExternalUsers,' +
                        'UserPreferencesShowCountryToGuestUsers,UserPreferencesShowStreetAddressToExternalUsers,' +
                        'ContactId,Newsletter__c,IsActive' +
                        ' FROM User WHERE IsPortalEnabled = true AND ContactId!=NULL'
        );
    }

    public void execute(Database.BatchableContext bc, List<User> records) {
        try{
            List<Id> contactIds = new List<Id>();
            for(User u : records){
                contactIds.add(u.ContactId);
            }
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, Name, Newsletter__c, HasOptedOutOfEmail FROM Contact WHERE Id IN :contactIds]);

            for(User u : records){
                if(contacts.containsKey(u.ContactId)){
                    Contact c = contacts.get(u.ContactId);
                    u.Newsletter__c = !contacts.get(u.ContactId).HasOptedOutOfEmail;
                    c.Newsletter__c = !contacts.get(u.ContactId).HasOptedOutOfEmail;
                    c.IsCommunityUser__c = u.IsActive;
                }
            }
            Database.SaveResult[] srLis = Database.update(records, false);

            for(Database.SaveResult sr : srLis){
                if(!sr.isSuccess()){
                    failedUserUpdate.add(sr.getId());
                }
            }

            Database.SaveResult[] srLis2 = Database.update(contacts.values(), false);

            for(Database.SaveResult sr : srLis2){
                if(!sr.isSuccess()){
                    failedContactUpdate.add(sr.getId());
                }
            }

        } catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }

    }

    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        if(!failedUserUpdate.isEmpty()){
            log.Message__c+='NOT UPDATED USERS: '+String.join(failedUserUpdate,',');
        }
        if(!failedContactUpdate.isEmpty()){
            log.Message__c+='NOT UPDATED CONTACTS: '+String.join(failedContactUpdate,',');
        }
        update log;
    }
}