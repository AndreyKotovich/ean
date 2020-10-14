@IsTest
public with sharing class SecretaryGeneralCommentController_Test {
    @IsTest public static void insertCommentTest() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account acc = new Account(Name = 'Test');
        insert acc;
        Membership__c membership = new Membership__c(Name = 'Test', API__c = 'test');
        insert membership;
        Contact contact = new Contact(LastName = 'Test', AccountId = acc.Id);
        insert contact;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today().addDays(-1),
                Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = membership.Id,
                Profession__c = 'Other', Street__c = '123Street', Form_Status__c = 'Draft');
        insert appForm;
        Id sg = [SELECT Id FROM Profile WHERE Name = 'Secretary General'].Id;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sg, Country = 'Belarus', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
        String ownerId = UserInfo.getUserId();
        System.runAs(user) {
            try{
                SecretaryGeneralCommentController.insertComment(appForm.Id, 'test comment');
            } catch (Exception e) {
                System.assertEquals('Something went wrong, contact your system administrator', e.getMessage());
            }
            List<Application_form__c> app = [SELECT Id, Comments__c FROM Application_form__c WHERE Id = :appForm.Id];
            System.assertEquals('test comment', app[0].Comments__c);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(appForm.Id);
            req1.setSubmitterId(ownerId);
            Approval.ProcessResult result = Approval.process(req1);
            if(result.isSuccess()){
                Map<String, Object> m = SecretaryGeneralCommentController.checkApprovalStep(appForm.Id);
                System.assert(m.isEmpty());
                SecretaryGeneralCommentController.approveRecord(appForm.Id);
                app = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Id = :appForm.Id];
                System.assertEquals('Complete', app[0].Form_Status__c);
                m = SecretaryGeneralCommentController.checkApprovalStep(appForm.Id);
                System.assertEquals('Pending', m.get('stepStatus'));
                System.assertEquals('SG_comment', m.get('stepName'));
            }
        }
    }
}