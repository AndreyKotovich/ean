//OLD IMPLEMENTATION
/*global class UpdateContactsAfterMigration implements Database.Batchable<sObject>, Database.Stateful{
    global Log__c log = new Log__c();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: SetCommunityUsersProfilesBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        return Database.getQueryLocator(
                'SELECT Id, Mailing_address__c, (SELECT Id FROM Contact_Roles__r WHERE RecordType.DeveloperName = \'Department\') ' +
                        'FROM Contact ' +
                        'WHERE Mailing_address__c = \'Work Address\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> records) {
        try {
            for(Contact c : records){
                System.debug(c.Contact_Roles__r.size());
                if(c.Contact_Roles__r.size()==0){
                    c.Mailing_address__c = '';
                }
            }
            update records;
        }catch (Exception e){
            insert new Log_Item__c(Log__c=log.Id, Message__c=e.getMessage());
            log.Status__c='Error';
        }
    }
    global void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}*/

global class UpdateContactsAfterMigration implements Database.Batchable<sObject>, Database.Stateful{
    global Log__c log = new Log__c();
    global List<String> pickListValuesList = new List<String>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: UpdateContactsAfterMigration';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        Schema.DescribeFieldResult fieldResult = Contact.Work_Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }

        return Database.getQueryLocator(
                'SELECT Id, Mailing_address__c, MailingState, OtherState, HasOptedOutOfEmail, Newsletter__c, '+
                        'Work_Street__c, Work_City__c, Work_State_Province__c, Work_Zip_Postal_Code__c, Work_Country__c, '+
                        '(SELECT Id, Account__r.Name, Account__r.Parent.Name, Account__r.BillingAddress, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.BillingStreet '+
                        'FROM Contact_Roles__r WHERE RecordType.DeveloperName = \'Department\' LIMIT 1) ' +
                        'FROM Contact'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> records) {
        try {

            for(Contact c : records){

                if(c.Contact_Roles__r.size()>0){

                    Map<String, String> fieldMapping = new Map<String, String>{
                            'Work_Street__c'=>'BillingStreet',
                            'Work_Country__c'=>'BillingCountry'
                    };

                    Boolean identical = true;

                    for(String s : fieldMapping.keySet()){

                        if(c.get(s) != c.Contact_Roles__r[0].Account__r.get(fieldMapping.get(s))){
                            identical = false;
                        }
                    }

                    if(identical && c.Contact_Roles__r[0].Account__r.BillingAddress != null){
                        c.Department_Name__c = c.Contact_Roles__r[0].Account__r.Name;
                        c.Hospital_Name__c = c.Contact_Roles__r[0].Account__r.Parent.Name==null?'':c.Contact_Roles__r[0].Account__r.Parent.Name;
                    }
                }

            }
            update records;


            /* AFTER MIGRATION UPDATE
            for(Contact c : records){
                if(c.Contact_Roles__r.size()>0){
                    c.Work_Street__c = c.Contact_Roles__r[0].Account__r.BillingStreet;
                    c.Work_City__c = c.Contact_Roles__r[0].Account__r.BillingCity;
                    c.Work_State_Province__c = c.Contact_Roles__r[0].Account__r.BillingState;
                    c.Work_Zip_Postal_Code__c = c.Contact_Roles__r[0].Account__r.BillingPostalCode;
                    if (!c.HasOptedOutOfEmail) c.Newsletter__c = true;
                    for(String s : pickListValuesList){
                        if(s == c.Contact_Roles__r[0].Account__r.BillingCountry){
                            c.Work_Country__c = c.Contact_Roles__r[0].Account__r.BillingCountry;
                        }
                    }
                }
                if(c.Mailing_address__c != null){
                    c.Mailing_address__c = '';
                }
            }
            update records;*/
/*
            // IN CASE IF WE NEED TO NULL CONTACT STATES
            for(Contact c : records){
                c.MailingState=null;
                c.OtherState=null;
                c.Mailing_address__c = '';
                if(c.Contact_Roles__r.size()>0){
                    c.Work_Street__c = c.Contact_Roles__r[0].Account__r.BillingStreet;
                    c.Work_City__c = c.Contact_Roles__r[0].Account__r.BillingCity;
                    c.Work_State_Province__c = c.Contact_Roles__r[0].Account__r.BillingState;
                    c.Work_Zip_Postal_Code__c = c.Contact_Roles__r[0].Account__r.BillingPostalCode;
                    if (!c.HasOptedOutOfEmail) c.Newsletter__c = true;
                    for(String s : pickListValuesList){
                        if(s == c.Contact_Roles__r[0].Account__r.BillingCountry){
                            c.Work_Country__c = c.Contact_Roles__r[0].Account__r.BillingCountry;
                        }
                    }
                } else if(c.Contact_Roles__r.size()==0 && c.Mailing_address__c == 'Work Address'){
                    c.Mailing_address__c = '';
                }
            }
            System.debug('records: '+records);
            update records;*/

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