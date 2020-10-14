@isTest
public with sharing class TestSetPermSetToComLoginUserTrigger {
    @isTest static void assignPermissionSetToCommunityLoginUsersTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Integer assignedPermissionSetsCountBefore = [SELECT count() FROM PermissionSetAssignment];
        Id cclu = [SELECT Id FROM profile WHERE Name = 'Non-Member Community User Profile'].Id;
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        List<Contact> contacts = new List<Contact>();
        Integer amountOfNewUsers = 5;
        for (Integer i = 0; i < amountOfNewUsers; i++) {
            contacts.add(new Contact(LastName = 'testCon ' + i, AccountId = account.Id));
        }
        insert contacts;
        List<User> newUsers = new List<User>();
        for (Integer i = 0; i < contacts.size(); i++) {
            newUsers.add(new User(
                    Alias = 'test' + i, Email = 'test' + i + '@noemail.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing ' + i, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'test' + i + '@noemail.com', CommunityNickname = 'commnick' + i));
        }
        insert newUsers;
        List<String> userIds = new List<String>();
        for (User u : newUsers) {
            userIds.add(u.Id);
        }
        System.assertEquals([SELECT count() FROM PermissionSetAssignment WHERE AssigneeId IN :userIds], amountOfNewUsers);
        System.assertNotEquals(assignedPermissionSetsCountBefore, [SELECT count() FROM PermissionSetAssignment]);
    }
}