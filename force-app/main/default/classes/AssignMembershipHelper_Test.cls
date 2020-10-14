@IsTest
public with sharing class AssignMembershipHelper_Test {
    @TestSetup public static void setup(){
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@eamil.com');
        insert contact;
        Membership__c membership = new Membership__c(Name = 'Test Membership', API__c = 'test_membership');
        insert membership;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Test', Last_name__c = 'Contact', Date_of_birth__c = Date.today(),
                Gender__c = 'Male', Email__c = 'test@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = contact.Id, Membership__c = membership.Id,
                Profession__c = 'Other', Street__c = 'TestStreet', Form_Status__c = 'Draft');
        insert appForm;
    }
    @IsTest public static void assignMembershipTest(){
        Application_form__c appForm = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Contact__r.Name = 'Test Contact' AND Membership__r.API__c='test_membership'];
        appForm.Form_Status__c = 'Approved';
        System.assertEquals(0, [SELECT count() FROM MembershipContactAssotiation__c WHERE Application_form__c = :appForm.Id]);
        update appForm;
        List<MembershipContactAssotiation__c> memStatus = [SELECT Expiration_date__c, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Application_form__c = :appForm.Id LIMIT 1];
        System.assertEquals(Date.newInstance(Date.today().year()+1,12,31), memStatus[0].Expiration_date__c);
        System.assertEquals('test_membership', memStatus[0].Membership__r.API__c);
    }
    @IsTest public static void documentsMissingEmailCheckTest(){
        Application_form__c appForm = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Contact__r.Name = 'Test Contact' AND Membership__r.API__c='test_membership'];
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(appForm.Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        System.assert(result.isSuccess());
        Test.startTest();
        appForm.Form_Status__c = 'Further Information Required';
        update appForm;
        Test.stopTest();
        System.assertEquals('Further Information Required', [SELECT Id, Form_Status__c FROM Application_form__c WHERE Id =:appForm.Id].Form_Status__c);
    }
    @IsTest public static void documentsMissingEmailCheckErrorTest(){
        Application_form__c appForm = [SELECT Id, Form_Status__c, Contact__r.Email FROM Application_form__c WHERE Contact__r.Name = 'Test Contact' AND Membership__r.API__c='test_membership'];
        appForm.Contact__r.Email = '';
        update appForm.Contact__r;
        Approval.lock(appForm.Id);
        System.debug('isLocked:: '+Approval.isLocked(appForm.Id));
        Test.startTest();
        appForm.Form_Status__c = 'Further Information Required';
        update appForm;
        Test.stopTest();
        System.assertEquals('Further Information Required', [SELECT Id, Form_Status__c FROM Application_form__c WHERE Id =:appForm.Id].Form_Status__c);
    }
    @IsTest public static void rejectionLetterEmailCheckTest(){
        Application_form__c appForm = [SELECT Id, Form_Status__c FROM Application_form__c WHERE Contact__r.Name = 'Test Contact' AND Membership__r.API__c='test_membership'];
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(appForm.Id);
        req1.setSubmitterId(UserInfo.getUserId());
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        System.assert(result.isSuccess());
        Test.startTest();
        appForm.Form_Status__c = 'Declined';
        update appForm;
        Test.stopTest();
        System.assertEquals('Declined', [SELECT Id, Form_Status__c FROM Application_form__c WHERE Id =:appForm.Id].Form_Status__c);
    }


}