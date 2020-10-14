@IsTest
public with sharing class setEANDefaultAvatarTest {
    //BEFORE RUN TEST IT'S REQUIRED TO INSERT ON ORG CONTENT DOCUMENT AND CREATE Default_EAN_Avatar__c
    @IsTest(SeeAllData=true)
    public static void assignDefaultAvatarTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        Account acc = new Account(Name='Account');
        insert acc;

        Contact contact = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert contact;

        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Non-Member Community User Profile'];
        User u = new User(
                Alias = 'Alias', Email = 'test@email.com',
                EmailEncodingKey = 'UTF-8', LastName = contact.LastName, LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = profile.Id, Country = 'United States', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'test@email.com',
                CommunityNickname = 'CommunityNickname'
        );
        insert u;

        System.assert(setEANDefaultAvatar.isSalesforceDefaultAvatar(u.Id));

        System.runAs(u){
            System.assert(setEANDefaultAvatar.assignDefaultAvatar());
        }
    }
}