@IsTest
public with sharing class ClinicalFellowshipAppController_Test {
    @TestSetup public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account acc = new Account(Name = 'Test');
        insert acc;
        Contact contact = new Contact(LastName = 'test', AccountId = acc.Id);
        insert contact;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        User u = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com',
                CommunityNickname = 'commnick');
        insert u;
    }
    @IsTest public static void initWithoutContact(){
        try{
            ClinicalFellowshipApplicationController.getContact();
        } catch (Exception e){
            System.assertEquals(e.getMessage(), 'User do not have a contact');
        }
    }
    @IsTest public static void initWithContact(){
        User communityUser = [SELECT Id, ContactId FROM User WHERE Username='tester@noemail.com'];
        System.runAs(communityUser){
            Map<String, String> init = ClinicalFellowshipApplicationController.init();
            System.assertEquals(true, init.get('contact').contains('"Id":"'+communityUser.ContactId+'"'));
        }
    }
    @IsTest public static void createAppFormAndSubmitForApprovalTest(){
        RecordType clinFellRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship__c' AND DeveloperName = 'Clinical_Fellowship'];
        RecordType clinFellAppFormRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship_Applications_Form__c' AND DeveloperName = 'Clinical_Fellowship_Application_Form'];
        Fellowship__c fellowship = new Fellowship__c(Name__c = 'Test', RecordTypeId = clinFellRT.Id);
        insert fellowship;
        Contact contact = [SELECT Id FROM Contact WHERE LastName='test'];
        Fellowship_Applications_Form__c fellowshipApplicationForm = ClinicalFellowshipApplicationController.createAppForm(new Fellowship_Applications_Form__c(Fellowship__c = fellowship.Id, Contact__c = contact.Id, RecordTypeId = clinFellAppFormRT.Id));
        System.assertNotEquals('', fellowshipApplicationForm.Id);
        System.assertEquals(true, ClinicalFellowshipApplicationController.submitRecordForApproval(fellowshipApplicationForm.Id));
    }
}