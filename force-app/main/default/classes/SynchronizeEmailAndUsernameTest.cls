@isTest public with sharing class SynchronizeEmailAndUsernameTest {
    @TestSetup public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account account = new Account(Name = 'Individuals (Contacts)');
        insert  account;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'].Id;
        Contact con = new Contact(LastName = 'testCon', AccountId = account.Id);
        insert con;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
    }
    /*@isTest public static void synchronizeTest(){
        User user = [SELECT Id, Email, Username FROM User WHERE Username = 'tester@noemail.com'];
        System.runAs(user){
            try{
                SynchronizeEmailAndUsername.synchronize();
                user = [SELECT Id, Email, Username FROM User WHERE Id = :user.Id];
                System.assertEquals(user.Email, user.Username);
                SynchronizeEmailAndUsername.synchronize();
            }catch (Exception e){
                System.assertEquals('Username and Email already synchronized.', e.getMessage());
            }
        }
    }*/
}