@isTest
public with sharing class UserTriggerHelper_Test {
    @testSetup static void setup() {
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        List<Membership__c> memberships = new List<Membership__c>();
        memberships.add(new Membership__c(Name = 'Test1', API__c = 'test1'));
        memberships.add(new Membership__c(Name = 'Test2', API__c = 'test2'));
        insert memberships;
        Contact contact = new Contact(FirstName = 'New', LastName = 'Contact', AccountId = account.Id);
        insert contact;
        List<Application_form__c> af = new List<Application_form__c>();
        af.add(new Application_form__c(
                First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today(),
                Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = memberships[0].Id,
                Profession__c = 'Other', Street__c = '123Street'));
        af.add(new Application_form__c(
                First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today(),
                Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = memberships[0].Id,
                Profession__c = 'Other', Street__c = '123Street'));
        insert af;
        Id standardProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        List<User> users = new List<User>();
        for(Integer i =0; i<2; i++){
            users.add(new User(
                    Alias = 'test123', Email = i+'test@noemail.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Test'+i, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = standardProfileId, Country = 'United States', IsActive = true,
                    TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@noemail.com'));
        }
        insert users;
    }
    @isTest public static void assignMembershipTest() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        System.assertEquals([SELECT Id FROM MembershipContactAssotiation__c WHERE Contact__c = :contact.Id].size(), 0);
        List<Application_form__c> af = [SELECT Id, Form_Status__c, Membership__c FROM Application_form__c];
        af[0].Form_Status__c = 'Approved';
        af[1].Form_Status__c = 'Declined';
        update af;
        List<MembershipContactAssotiation__c> mca = [SELECT Id, Membership__c FROM MembershipContactAssotiation__c WHERE Contact__c = :contact.Id];
        System.assertEquals(mca.size(), 1);
        System.assertEquals(mca[0].Membership__c, af[0].Membership__c);
    }
    @IsTest public static void emailDuplicateValidationInsertTest() {
        try {
            Id standardProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
            insert new User(
                    Alias = 'test123', Email = '0test@noemail.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = standardProfileId, Country = 'United States', IsActive = true,
                    TimeZoneSidKey = 'America/Los_Angeles', Username = 'test@noemail.com');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('already exists'));
        }
    }
    @IsTest public static void emailDuplicateValidationUpdateTest() {
        try{
            User user = [SELECT Id FROM User WHERE Email = '0test@noemail.com'];
            user.Email = '1test@noemail.com';
            update user;
        }catch (Exception e){
            System.assert(e.getMessage().contains('already exists'));
        }
    }
}