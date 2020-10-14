@IsTest
public with sharing class ApprovalCommentsController_Test {
    @TestSetup public static void setup() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Account acc = new Account(Name = 'Test');
        insert acc;
        Contact contact = new Contact(LastName = 'test lastname', AccountId = acc.Id);
        insert contact;
        Membership__c membership = new Membership__c(Name = 'Test1', API__c = 'test1');
        insert membership;
        RecordType clinFellRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship__c' AND DeveloperName = 'Clinical_Fellowship'];
        RecordType clinFellAppFormRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship_Applications_Form__c' AND DeveloperName = 'Clinical_Fellowship_Application_Form'];
        Fellowship__c fellowship = new Fellowship__c(Name__c = 'Test1', RecordTypeId = clinFellRT.Id);
        insert fellowship;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        User u = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = contact.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com',
                CommunityNickname = 'commnick');
        insert u;
        System.runAs(u){
            Application_form__c appForm = new Application_form__c(
                    First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today(),
                    Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                    Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = membership.Id,
                    Profession__c = 'Other', Street__c = '123Street', Form_Status__c = 'Draft');
            insert appForm;
            Fellowship_Applications_Form__c appFellForm = new Fellowship_Applications_Form__c(Contact__c = contact.Id, Fellowship__c = fellowship.Id, RecordTypeId=clinFellAppFormRT.Id);
            insert appFellForm;
        }

    }
    @IsTest public static void sObjectCheckTest() {
        List<Contact> contact = [SELECT Id FROM Contact WHERE LastName = 'test lastname'];
        List<Application_form__c> appForm = [SELECT Id, OwnerId, Form_Status__c, CreatedById FROM Application_form__c WHERE Contact__c = :contact[0].Id];
        List<Fellowship_Applications_Form__c> appFellForm = [SELECT Id, Approval_Status__c FROM Fellowship_Applications_Form__c WHERE Contact__c = :contact[0].Id];
        Boolean result = ApprovalCommentsController.sObjectCheck(appForm[0].Id);
        System.assertEquals(false, result);
        Boolean result2 = ApprovalCommentsController.sObjectCheck(appFellForm[0].Id);
        System.assertEquals(false, result2);
        appForm[0].Form_Status__c = 'Further Information Required';
        update appForm;
        appFellForm[0].Approval_Status__c = 'Further Information Required';
        update appFellForm;
        result = ApprovalCommentsController.sObjectCheck(appForm[0].Id);
        System.assertEquals(true, result);
        result2 = ApprovalCommentsController.sObjectCheck(appFellForm[0].Id);
        System.assertEquals(true, result2);

        result = ApprovalCommentsController.sObjectCheck(contact[0].Id);
        System.assertEquals(false, result);
    }
    @IsTest public static void getApprovalCommentsTest() {
        List<Contact> contact = [SELECT Id FROM Contact WHERE LastName = 'test lastname'];
        List<Application_form__c> appForm = [SELECT Id, OwnerId, Form_Status__c, CreatedById FROM Application_form__c WHERE Contact__c = :contact[0].Id];
        List<User> user = [SELECT Id FROM User WHERE Username = 'tester@noemail.com'];
        //Submit record for approval
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(appForm[0].Id);
        req1.setSubmitterId(user[0].Id);
        Approval.ProcessResult result = Approval.process(req1);
        System.assert(result.isSuccess());
        System.assertEquals(
                'Pending', result.getInstanceStatus(),
                'Instance Status'+result.getInstanceStatus());
        //Reject record with Further Information Required
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        Approval.ProcessWorkitemRequest req2 =
                new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Reject');
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(req2);
        System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        System.assertEquals(
                'Rejected', result2.getInstanceStatus(),
                'Instance Status'+result2.getInstanceStatus());
        String result3 = ApprovalCommentsController.getApprovalComments(appForm[0].Id);
        System.assertNotEquals('none', result3);
    }
}