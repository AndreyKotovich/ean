@isTest
public with sharing class UtilsTest {
    @TestSetup
    static void makeData(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        RecordType iprRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Industry_Partner'];
        Account acc = new Account(Name = 'Test', RecordTypeId = iprRT.Id);
        insert acc;

        Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'info@test.com', AccountId = acc.Id, IsCommunityUser__c = true);
        insert contact;   
        
        Id memberProfileId = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;

        User communityUser = new User(
                    Alias = 'test', Email = 'info@test.com',
                    EmailEncodingKey = 'UTF-8', FirstName = 'FirstName', LastName = 'LastName', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = memberProfileId, Country = 'Germany', IsActive = true,
                    ContactId = contact.Id, TimeZoneSidKey = 'Europe/Berlin', Username = 'info@test.com'
        );
        insert communityUser;
    }
    @isTest
    public static void picklistValuesTest() { 
        List<Map<String, String>> picklistValuesListMap = Utils.picklistValues('Contact', 'Salutation');
        System.assertNotEquals(null, picklistValuesListMap.size());
    }

    @isTest
    public static void getContactMembershipsTest() {        
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];

        Membership__c membership = new Membership__c(Name = 'Test Membership', API__c = 'test');
        insert membership;
        MembershipContactAssotiation__c membershipStatus = new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = membership.Id, Endless_Activation__c = true);
        insert membershipStatus;

        List<MembershipContactAssotiation__c> contactsMemebrships = Utils.getUserMemberships();
        System.assertEquals(0, contactsMemebrships.size()); 
    }
    
    @isTest
    public static void startOrderReminderTest() {        
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];

        Order__c order = new Order__c(Contact__c = contacts[0].Id);
        insert order;

        Utils.startOrderReminder();
    }
    
}