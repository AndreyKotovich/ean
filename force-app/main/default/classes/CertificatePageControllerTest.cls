@isTest
public with sharing class CertificatePageControllerTest {

    @testSetup
    public static void setup() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id groupRTId = Schema.SObjectType.Group__c.getRecordTypeInfosByName().get('Level 1 Board (EAN Board)').getRecordTypeId();
        Group__c eanBoard = new Group__c(Name = 'TestEanBoard2', RecordTypeId = groupRTId);
        insert  eanBoard;

        Contact contact = new Contact(FirstName = 'Certificate', LastName = 'TestP', Email = 'testCerP@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany', Expected_Date_Of_Graduation__c = Date.today(), Salutation = 'Mr.', Residency__c = 'Germany');
        insert contact;

        Contact contact2 = new Contact(FirstName = 'PageTest', LastName = 'President', Email = 'testpagepresident@test.com',
                MailingStreet = 'TestStreet', MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert contact2;

        Contact contact3 = new Contact(FirstName = 'PageTest', LastName = 'Secretary', Email = 'testpagesecretary@test.com',
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

    @isTest
    public static void mergeAllInfoTest() {
        Application_form__c appForm = [SELECT Id FROM Application_form__c WHERE Last_name__c = 'TestP' AND First_name__c = 'Certificate' LIMIT 1];
        Test.startTest();
        appForm.Form_Status__c = 'Approved';
        update appForm;
        Test.stopTest();
        MembershipContactAssotiation__c msStatus = [SELECT Id FROM MembershipContactAssotiation__c WHERE Application_form__c = :appForm.Id];
        List<GroupChatterGroupAssotiation__c>  groupMemberships = [
                SELECT Id, Contact__r.Name, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE (Role__c = 'President' OR Role__c = 'Secretary general') AND
                Group__r.RecordType.Name = 'Level 1 Board (EAN Board)'
        ];
        String presidentName;
        String secretaryName;
        for (GroupChatterGroupAssotiation__c g : groupMemberships) {
            if (g.Role__c == 'President') {
                presidentName = g.Contact__r.Name;
            } else if (g.Role__c == 'Secretary general') {
                secretaryName = g.Contact__r.Name;
            }

            if (secretaryName != '' && presidentName != ''){
                break;
            }
        }
        PageReference pageRef = Page.CertificatePage;
        pageRef.getParameters().put('ms', msStatus.Id);
        pageRef.getParameters().put('sn', secretaryName);
        pageRef.getParameters().put('pn', presidentName);
        Test.setCurrentPage(pageRef);
        CertificatePageController controller = new CertificatePageController();
        System.assertEquals('Mr.', controller.salutation);
        System.assertEquals('Certificate TestP', controller.memberName);
        System.assertEquals('Germany', controller.nationality);
        System.assertEquals('Resident and Research Membership', controller.membershipName);

    }
}