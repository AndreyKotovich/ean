@isTest
public with sharing class TestMembershipApplicationController {
    @testSetup static void setup() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account account = new Account(Name = 'Individuals (Contacts)');
        insert  account;
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Individual', AccountId = account.Id, Email = 'individual@individ.com');
        insert contact;
        Membership__c membership = new Membership__c(Name = 'Full Membership', API__c = 'full_membership', isForUpdateMembershipApplication__c=true, www__c = 'https://www.ean.org/Full-Member.3801.0.html');
        insert membership;
        Country_Price__c countryPrice = new Country_Price__c(Membership__c = membership.Id, Region__c = '', Price_for_Deadline_1__c = 150, Price_for_Deadline_2__c = 75, Price_for_Deadline_3__c = 150);
        insert countryPrice;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Test',
                Last_name__c = 'TestLast',
                Date_of_birth__c = Date.today(),
                Gender__c = 'Male',
                Email__c = 'test@test.com',
                Nationality__c = 'United States',
                Residency__c = 'United States',
                ZIP_Postal_code__c = '1111',
                City__c = 'City',
                Membership__c = membership.Id,
                Contact__c = contact.Id,
                Profession__c = 'Neurologist',
                Street__c = 'test street',
                Form_Status__c = 'Further Information Required'
        );
        insert appForm;

    }
    @isTest static void getContactForFormByIdTest() {
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Individual' LIMIT 1];
        Contact contactFFBI = membershipApplicationController.getContactForFormById(contact.Id);
        Map<String, Object> mapContactFFBI = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contactFFBI));
        List<String> contactFieldForForm = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Contact.FieldSets.Form_fields.getFields()) {
            contactFieldForForm.add(f.getFieldPath());
        }
        Integer counter = 0;
        for (String m : mapContactFFBI.keySet()) {
            for (String fs : contactFieldForForm) {
                if (m == fs) {
                    counter++;
                }
            }
        }
        System.assertNotEquals(counter, 0);
    }
    @isTest static void getCountriesTest() {
        List<Country__mdt> countries = membershipApplicationController.getCountries();
        System.assertNotEquals(countries, null);
        for (Country__mdt c : countries) {
            System.assertNotEquals(c.get('Label'), null);
        }
    }
    @isTest static void getFieldSetsTest() {
        List<List<String>> fs = membershipApplicationController.getFieldSets();
        List<String> fieldSet = new List<String>();
        for (Integer i = 0; i < fs.size(); i++) {
            fieldSet.addAll(fs[i]);
        }
        Schema.DescribeSObjectResult r = Application_form__c.sObjectType.getDescribe();
        List<String> apiNames = new List<String>();
        for (String apiName : r.fields.getMap().keySet()) {
            apiNames.add(Schema.getGlobalDescribe().get('Application_form__c').getDescribe().fields.getMap().get(apiName).getDescribe().getName());
        }
        for (String field : fieldSet) {
            System.assertEquals(apiNames.contains(field), true);
        }
    }
    @isTest static void upsertFormTest() {
        Contact contact = new Contact(FirstName = 'Test FirstName', LastName = 'Test LastName');
        insert contact;
        Membership__c membership = [SELECT Id FROM Membership__c LIMIT 1];
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Test',
                Last_name__c = 'TestLast',
                Date_of_birth__c = Date.today(),
                Gender__c = 'Male',
                Email__c = 'test@test.com',
                Nationality__c = 'United States',
                Residency__c = 'United States',
                ZIP_Postal_code__c = '1111',
                City__c = 'City',
                Membership__c = membership.Id,
                Contact__c = contact.Id,
                Profession__c = 'Neurologist',
                Street__c = 'test street'
        );
        appForm = membershipApplicationController.upsertForm(appForm);
        System.assertNotEquals(null, appForm.Id);
        appForm.Gender__c = 'Female';
        System.assertEquals('Female', membershipApplicationController.upsertForm(appForm).Gender__c);
        try{
            appForm.Date_of_birth__c = Date.today().addDays(1);
            appForm = membershipApplicationController.upsertForm(appForm);
        } catch (Exception e){
            System.assert(e.getMessage().contains('Birthday cannot be in future'));
        }
    }
    @isTest static void updateContactTest() {
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Individual' LIMIT 1];
        contact.LastName = 'Changed LastName';
        membershipApplicationController.updateContact(contact);
        System.assertEquals([SELECT LastName FROM Contact WHERE Id = :contact.Id].LastName, 'Changed LastName');
        try{
            contact.Birthdate = Date.today().addDays(1);
            membershipApplicationController.updateContact(contact);
        } catch (Exception e){
            System.assert(e.getMessage().contains('Birthday cannot be in future'));
        }
    }
    @isTest static void getDeadlineTest() {
        String deadline = membershipApplicationController.getDeadline();
        System.assertNotEquals(Schema.getGlobalDescribe().get('Country_Price__c').getDescribe().fields.getMap().get(deadline.toLowerCase()).getDescribe().getName(), null);
    }
    @isTest static void getMembershipsTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'].Id;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Individuals (Contacts)'];
        Contact con = new Contact(LastName = 'testCon', AccountId = acc.Id);
        insert con;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        System.runAs(user) {
            membershipApplicationWrapper w = membershipApplicationController.getMemberships();
            System.assertEquals(1, w.memberships.size());
            System.assertEquals(1, w.countryPrices.size());
            System.assertEquals(con.Id, w.contact.Id);
            System.assertNotEquals(null, w.fieldMap);
        }
    }
    @IsTest public static void deleteContentDocumentByIdTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Individuals (Contacts)'];
        Contact con = new Contact(LastName = 'testCon', AccountId = acc.Id);
        insert con;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'Belarus', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        System.runAs(user) {
            ContentVersion cv = new ContentVersion(
                    Title = 'Test',
                    PathOnClient = 'Test.jpg',
                    VersionData = Blob.valueof('Test Content Data'),
                    IsMajorVersion = true,
                    NetworkId =[SELECT Id, Name FROM Network LIMIT 1].Id
            );
            insert cv;
            ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            membershipApplicationController.deleteContentDocumentById(contentVersionSelect.ContentDocumentId);
            List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :contentVersionSelect.ContentDocumentId];
            System.assertEquals(0, cd.size());
        }
    }
    @IsTest public static void getExistedFormTest(){
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE First_name__c = 'Test' AND Last_name__c = 'TestLast'];
        Application_form__c fullApplicationForm = membershipApplicationController.getExistedForm(appForm.Id);
        System.assertEquals('United States', fullApplicationForm.Nationality__c);
        System.assertEquals('United States', fullApplicationForm.Residency__c);
        fullApplicationForm.Form_Status__c = 'Draft';
        update fullApplicationForm;
        try{
            fullApplicationForm = membershipApplicationController.getExistedForm(appForm.Id);
        } catch (Exception e){
            System.assertEquals('This application cannot be re-submitted', e.getMessage());
        }
        try {
            fullApplicationForm = membershipApplicationController.getExistedForm('no-id');
        } catch (Exception e){
            System.assertEquals('This application wasn\'t found', e.getMessage());
        }
    }
    @IsTest public static void getContentDocumentsTest(){
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE First_name__c = 'Test' AND Last_name__c = 'TestLast'];
        System.assert(membershipApplicationController.getContentDocuments(appForm.Id).isEmpty());
    }
    @IsTest public static void submitForApprovalTest(){
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE First_name__c = 'Test' AND Last_name__c = 'TestLast'];
        membershipApplicationController.submitForApproval(appForm.Id);
        System.assert(Approval.isLocked(appForm.Id));
    }
    @IsTest public static void attachFileToFormTest(){
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE First_name__c = 'Test' AND Last_name__c = 'TestLast'];
        List<ContentVersion> contentVersionInsert = new List<ContentVersion>();
        for(Integer i = 0; i<2; i++){
            contentVersionInsert.add(new ContentVersion(
                    Title = 'Test'+i,
                    PathOnClient = 'Test'+i+'.jpg',
                    VersionData = Blob.valueOf('Test Content Data'+i),
                    IsMajorVersion = true
            ));
        }
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assert(documents.size()>0);
        List<ContentDocumentLink> cDocumentLink = new List<ContentDocumentLink>();
        cDocumentLink.add(new ContentDocumentLink(ContentDocumentId = documents[0].Id, LinkedEntityId = appForm.Id, ShareType = 'I', Visibility = 'AllUsers'));
        membershipApplicationController.attachFileToForm(cDocumentLink);
        List<ContentDocumentLink> insertedLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :appForm.Id];
        System.assertEquals(1, insertedLinks.size());
        cDocumentLink.add(new ContentDocumentLink(ContentDocumentId = documents[1].Id, LinkedEntityId = appForm.Id, ShareType = 'I', Visibility = 'AllUsers'));
        membershipApplicationController.attachFileToForm(cDocumentLink);
        insertedLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :appForm.Id];
        System.assertEquals(2, insertedLinks.size());
    }
    @IsTest public static void getCommunityHomeUrlTest(){
        System.assertEquals('community.com', membershipApplicationController.getCommunityHomeUrl());
    }
}