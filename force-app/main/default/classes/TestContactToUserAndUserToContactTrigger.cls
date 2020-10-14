@isTest
public class TestContactToUserAndUserToContactTrigger {
    @isTest public static void userToContactAndViceVersaTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id cclu = [SELECT Id FROM profile WHERE Name = 'Member Community User Profile'].Id;
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        Contact con = new Contact(LastName = 'testCon', AccountId = account.Id);
        insert con;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        user.City = 'Brest';
        user.Country = 'Belarus';
        System.RunAs(user) {
            update user;
            user = [SELECT Id, Contact.Id, City, Country, Contact.MailingCity, Contact.MailingCountry FROM User WHERE LastName = 'Testing' LIMIT 1];
            System.assertEquals(user.Contact.MailingCity, user.City);
            System.assertEquals(user.Contact.MailingCountry, user.Country);
        }
    }
}