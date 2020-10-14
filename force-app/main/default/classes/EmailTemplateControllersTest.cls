@IsTest public with sharing class EmailTemplateControllersTest {
    @TestSetup public static void setup(){
        Account account = new Account(Name = 'Individuals (Contacts)');
        insert  account;
        Contact contact = new Contact(FirstName = 'Certificate', LastName = 'TestP', Email = 'testCerP@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany', Expected_Date_Of_Graduation__c = Date.today(), Salutation = 'Mr.',
                Residency__c = 'Germany', AccountId = account.Id);
        insert contact;
        Membership__c membership = new Membership__c(Name = 'Resident and Research Membership', API__c = 'resident_and_research_membership');
        insert  membership;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Certificate',
                Last_name__c = 'TestP',
                Date_of_birth__c = Date.today().addYears(-18),
                Gender__c = 'Male',
                Email__c = 'testCerP@test.com',
                Nationality__c = 'Germany',
                Residency__c = 'Germany',
                ZIP_Postal_code__c = '11111',
                City__c = 'TestCity',
                Membership__c = membership.Id,
                Street__c = 'TestStreet',
                Profession__c = 'Neurologist',
                Contact__c = contact.Id);
        insert appForm;
    }
    @IsTest public static void DocumentsMissingEmailControllerTest(){
        Contact con = [SELECT Id FROM Contact WHERE Email='testCerP@test.com'];
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE Contact__c = :con.Id];
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(appForm.Id);
        req1.setSubmitterId(UserInfo.getUserId());
        Approval.ProcessResult result = Approval.process(req1);
        if(result.isSuccess()){
            DocumentsMissingEmailController dmec = new DocumentsMissingEmailController();
            dmec.appForm = appForm;
            System.assertEquals(appForm.Id, dmec.appForm.Id);
            System.assertEquals('Submitting request for approval.', dmec.approvalComment);
            System.assertEquals('community.com', dmec.communityUrl);
        }
    }
    @IsTest public static void JournalOrderConfirmationControllerTest(){
        Contact con = [SELECT Id, MailingStreet FROM Contact WHERE Email='testCerP@test.com'];
        Order__c order = new Order__c(Contact__c = con.Id);
        insert order;
        JournalOrderConfirmationController jocc = new JournalOrderConfirmationController();
        jocc.order = order;
        System.assertEquals(order.Id, jocc.order.Id);
        System.assertEquals(null, jocc.contactId);
        System.assertEquals('link.com', jocc.myEANProfileUrl);
        System.assertEquals(con.MailingStreet, jocc.mailingAddress[2]);
    }
    @IsTest public static void ReceiptOfMembershipApplicationControllerTest(){
        ReceiptOfMembershipApplicationController romac = new ReceiptOfMembershipApplicationController();
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE Contact__r.Email = 'testCerP@test.com'];
        romac.appForm = appForm;
        System.assertEquals(appForm.Id, romac.appForm.Id);
    }
    @IsTest public static void RejectionLetterEmailControllerTest(){
        RejectionLetterEmailController rlec = new RejectionLetterEmailController();
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE Contact__r.Email = 'testCerP@test.com'];
        rlec.appForm = appForm;
        System.assertEquals(appForm.Id, rlec.appForm.Id);
        System.assertNotEquals(null, rlec.defaultSecretaryGeneral);
    }
}