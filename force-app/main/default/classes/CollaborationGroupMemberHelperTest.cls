@IsTest
public with sharing class CollaborationGroupMemberHelperTest {
    @IsTest public static void setNotificationFrequencyTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id MCUP = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id);
        insert con;
        User user = new User(
                Alias = 'test', Email = 'test_un@email.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Test_un', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'test_un@email.com');
        insert user;

        String communityId = [SELECT Id, Name FROM Network WHERE Name = 'ean' LIMIT 1].Id;
        CollaborationGroup cg = new CollaborationGroup(Name = 'Test Group Unique', NetworkId = communityId, CollaborationType = 'Public');
        insert cg;

        CollaborationGroupMember cgm = new CollaborationGroupMember(MemberId = user.Id, CollaborationGroupId = cg.Id);
        insert cgm;

        System.assertEquals(2, [SELECT COUNT() FROM CollaborationGroupMember WHERE CollaborationGroupId = :cg.Id]);
    }

}