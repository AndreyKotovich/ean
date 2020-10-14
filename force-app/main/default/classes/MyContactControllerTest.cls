@isTest
public with sharing class MyContactControllerTest {

    @isTest
    public static void getContactIdTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Test.startTest();
        Id comUserId = [SELECT Id FROM profile WHERE Name = 'Customer Community Login User'].Id;
        Id individualsRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individuals').getRecordTypeId();
        Account acc = new Account(Name = 'Ind Account', RecordTypeId = individualsRTId);
        insert acc;
        Contact con = new Contact(LastName = 'testComCon', AccountId = acc.Id);
        insert con;
        User user = new User(
                Alias = 'cUser911', Email = 'test911@testemail.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'Community', LastName = 'User', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = comUserId, Country = 'Germany', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'Europe/Berlin', Username = 'comuser@testemail.com');
        insert user;
        Test.stopTest();

        System.runAs(user) {
            String response = MyContactController.getContactId();
            System.assertEquals(con.Id, response);
        }
    }
}