@isTest
public with sharing class CertificatePDFGeneratorTest {
    @isTest
    public static void generateCertificatePDFsTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account acc = new Account(Name = 'Test');
        insert acc;

        Id groupRTId = Schema.SObjectType.Group__c.getRecordTypeInfosByName().get('Level 1 Board (EAN Board)').getRecordTypeId();
        Group__c eanBoard = new Group__c(Name = 'TestEanBoard', RecordTypeId = groupRTId);
        insert  eanBoard;

        Contact contact = new Contact(FirstName = 'Certificate', LastName = 'TestC', Email = 'testCer@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany', Expected_Date_Of_Graduation__c = Date.today(), AccountId=acc.Id);
        insert contact;

        Id comUserId = [SELECT Id FROM profile WHERE Name = 'Non-Member Community User Profile'].Id;
        User user = new User(
                Alias = 'cUser911', Email = 'test911@testemail.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'Community', LastName = 'User', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = comUserId, Country = 'Germany', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'Europe/Berlin', Username = 'comuser@testemail.com'
        );
        insert user;

        Contact contact2 = new Contact(FirstName = 'MyTest', LastName = 'President', Email = 'testpresident@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert contact2;

        Contact contact3 = new Contact(FirstName = 'MyTest', LastName = 'Secretary', Email = 'testsecretary@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111', MailingCountry = 'Germany');
        insert contact3;

        Id groupMemberRTId = Schema.SObjectType.GroupChatterGroupAssotiation__c.getRecordTypeInfosByName().get('Level 1 Board (EAN Board)').getRecordTypeId();
        GroupChatterGroupAssotiation__c gca1 = new GroupChatterGroupAssotiation__c(Contact__c = contact2.Id,
                Group__c = eanBoard.Id, RecordTypeId = groupMemberRTId, Role__c = 'President');
        insert gca1;

        GroupChatterGroupAssotiation__c gca2 = new GroupChatterGroupAssotiation__c(Contact__c = contact3.Id,
                Group__c = eanBoard.Id, RecordTypeId = groupMemberRTId, Role__c = 'Secretary general');
        insert gca2;

        Membership__c membership = new Membership__c(Name = 'Resident and Research Membership', API__c = 'resident_and_research_membership');
        insert  membership;

        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Certificate',
                Last_name__c = 'TestC',
                Date_of_birth__c = Date.today().addYears(-18),
                Gender__c = 'Male',
                Email__c = 'testCer@test.com',
                Nationality__c = 'Germany',
                Residency__c = 'Germany',
                ZIP_Postal_code__c = '11111',
                City__c = 'TestCity',
                Membership__c = membership.Id,
                Street__c = 'TestStreet',
                Profession__c = 'Other',
                Contact__c = contact.Id);
        insert appForm;

        Test.startTest();
        appForm.Form_Status__c = 'Approved';
        update appForm;
        Test.stopTest();

        List<MembershipContactAssotiation__c> testRecords = [SELECT Id FROM MembershipContactAssotiation__c WHERE Application_form__c = :appForm.Id];
        List<ContentVersion> certificates = [SELECT Id FROM ContentVersion WHERE Title LIKE 'Certificate_%'];
        System.assertEquals(1, testRecords.size());
        System.assertEquals(1, certificates.size());

        CertificatePDFGenerator.generateCertificatePDFs(new Set<Id>{testRecords[0].Id});
    }

    @IsTest public static void assignCorrectProfileOnUpdateMemStatusRecordsTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        Account acc = new Account(Name='Account');
        insert acc;

        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<20; i++){
            contacts.add(new Contact(FirstName='Test', LastName='Contact'+i, AccountId=acc.Id));
        }
        insert contacts;

        Membership__c membership = new Membership__c(Name='Test', API__c='Test');
        insert membership;

        List<MembershipContactAssotiation__c> membershipStatuses = new List<MembershipContactAssotiation__c>();
        for(Contact c : contacts){
            membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c=c.Id, Membership__c=membership.Id, Endless_Activation__c = false));
        }
        insert membershipStatuses;

        Id nonMemberProfileId = [SELECT Id FROM Profile WHERE Name = 'Non-Member Community User Profile'].Id;

        List<User> users = new List<User>();
        for(Integer i=0; i<contacts.size(); i++){
            users.add(new User(
                    Alias = 'Alias'+i, Email = i+'test@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = contacts[i].LastName, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = nonMemberProfileId, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@email.com',
                    CommunityNickname = 'CommunityNickname'+i
            ));
        }
        insert users;

        for(MembershipContactAssotiation__c mca : membershipStatuses){
            mca.Endless_Activation__c = true;
        }

        Test.startTest();
            update membershipStatuses;
        Test.stopTest();

        users = [SELECT Id, ProfileId FROM User WHERE Id IN :users];
        Id memberProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Member Community User Profile'].Id;

        for(User u: users){
            System.assertEquals(memberProfileId, u.ProfileId);
        }
    }
}