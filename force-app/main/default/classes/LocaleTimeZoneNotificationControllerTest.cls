@IsTest
public with sharing class LocaleTimeZoneNotificationControllerTest {
    @IsTest public static void showModalCheck(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        Account acc = new Account(Name='Account');
        insert acc;

        Contact contact = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert contact;

        Id nonMemberProfileId = [SELECT Id FROM Profile WHERE Name = 'Non-Member Community User Profile'].Id;

        User user = new User(
                Alias = 'Alias', Email = 'test@email.com',
                EmailEncodingKey = 'UTF-8', LastName = contact.LastName, LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = nonMemberProfileId, Country = 'United States', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'test@email.com',
                CommunityNickname = 'CommunityNickname'
        );
        insert user;

        System.runAs(user){
            Map<String, Object> mapa = LocaleTimeZoneNotificationController.showModalCheck();
            System.debug(mapa.get('result'));
            System.assert((Boolean) mapa.get('result'));
            System.assertEquals(UserInfo.getTimeZone().getDisplayName(), mapa.get('timezone'));
            LocaleTimeZoneNotificationController.writeNotificationTime();
            user = [SELECT Id, Locale_Time_Zone_Notification_Date__c FROM User WHERE Id=:user.Id];
            Datetime dateOfNotification = user.Locale_Time_Zone_Notification_Date__c;
            System.assertEquals(Date.today(), Date.newInstance(dateOfNotification.year(), dateOfNotification.month(), dateOfNotification.day()));
            Map <String, String> mapLocales = LocaleTimeZoneNotificationController.getPicklistValuesMap('User', 'LocaleSidKey');
            System.assertEquals('English (United States)', mapLocales.get('en_US'));
        }
    }
}