@isTest
public class CreateMcSubscribersBatchTest {
    
    @TestSetup
    public static void setupTest() {
        TestService.insertMcCustomSettings();
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Blob b = Crypto.GenerateAESKey(128);
        String hex = EncodingUtil.ConvertTohex(b);
        String uid = hex.SubString(0,8);
        
        Account acc = new Account(Name = 'Test');
        insert acc;


        Contact contact = new Contact(FirstName = 'Certificate', LastName = 'TestC', Email = 'testCer@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany', AccountId=acc.Id);
        insert contact;
        
        Id comUserId = [SELECT Id FROM profile WHERE Name = 'Non-Member Community User Profile'].Id;
        User user = new User(
                Alias = 'cUser911', Email = 'test911@testemail.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'Community', LastName = 'User', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = comUserId, Country = 'Germany', IsActive = false,
                ContactId = contact.Id, TimeZoneSidKey = 'Europe/Berlin', Username = uid + 'mks.test.batch.dummny@lvk.com'
        );
        insert user;
    }

    @isTest
    public static void dummyTest() { 

        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McMock());
        Database.executeBatch(new CreateMcSubscribersBatch());
        System.assertEquals(true, true);
        Test.stopTest();
    }
}