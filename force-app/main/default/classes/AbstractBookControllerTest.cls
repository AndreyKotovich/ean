@isTest
public with sharing class AbstractBookControllerTest {

    @TestSetup
    static void makeData(){

        List<String> pickListValues = new List<String>();
        List<Schema.PicklistEntry> ple = Reviewer__c.Topics__c.getDescribe().getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
			pickListValues.add(pickListVal.getLabel());
        }
        List<Contact> contacts = new List<Contact>();
        for (Integer i =0; i < pickListValues.size(); i++) {
            Contact cont = new Contact(
                LastName = 'Test_abstract' + i,
                Email = 'testabstract' + i + '@test.ru'
            );
            contacts.add(cont);
        }
        insert contacts;

        Event__c eventTest = new Event__c(
            Name = 'Test event',
            Abstract_Submission_Deadline__c = Datetime.now().addDays(5),
            Late_Breaking_Submission_Deadline__c = Datetime.now().addDays(10),
            Number_of_Reviewers__c = 2,
            Number_of_Reviewers_Late_Breaking__c = 0
        );
        insert eventTest;

        List<Reviewer__c> reviewers = new List<Reviewer__c>();
        Integer loopCounter = 0;
        for (String  pickListValue : pickListValues) {
            Reviewer__c reviewer = new Reviewer__c(
                Review_Capacity__c = '0-100',
                Event__c = eventTest.Id,
                Contact__c = contacts[loopCounter].Id,
                Status__c = 'Accepted',
                Topics__c = pickListValue
            );
            reviewers.add(reviewer);
            loopCounter = loopCounter + 1;
        }
        insert reviewers;

        Contact contactAbstractSubmitter = new Contact(
                LastName = 'Test_abstract_submitter',
                Email = 'testabstract.submitter@test.ru'
            );
        insert contactAbstractSubmitter;

        Contact contactAbstractPresenter = new Contact(
                LastName = 'Test_abstract_presenter',
                Email = 'testabstract.presenter@test.ru'
            );
        insert contactAbstractPresenter;

        List<String> abstractPickListValues = new List<String>();
        List<Schema.PicklistEntry> abstractPle = Abstract__c.Abstract_Topic__c.getDescribe().getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
			abstractPickListValues.add(pickListVal.getLabel());
        }
        List<Abstract__c> abstracts = new List<Abstract__c>();
        for (String abstractPickListValue : abstractPickListValues) {
            Abstract__c abstractItem = new Abstract__c(
                Event__c = eventTest.Id,
                Abstract_Topic__c = abstractPickListValue,
                Stage__c = 'Submitted',
                Status__c = 'Pending',
                Type__c = 'Poster',
                Submitter__c = contactAbstractSubmitter.Id,
                Abstract_Presenter__c = contactAbstractPresenter.Id
            );
            abstracts.add(abstractItem);
        }
        insert abstracts;

        Contact contactAbstractAuthor = new Contact(
                FirstName = 'FirstName',
            	LastName = 'Test_abstract_author',
                Email = 'testabstract.author@test.ru',
            	Department_Name__c = 'qwe'
            );
        Contact contactAbstractAuthor1 = new Contact(
                FirstName = 'FirstName',
            	LastName = 'Test_abstract_author',
                Email = 'testabstract.author@test.ru',
            	Department_Name__c = 'qwe'
            );
        Contact contactAbstractAuthor2 = new Contact(
                FirstName = 'FirstName',
            	LastName = 'Test_abstract_author',
                Email = 'testabstract.author@test.ru'
        );
        insert new List<Contact> { contactAbstractAuthor, contactAbstractAuthor1, contactAbstractAuthor2 };

        List<Abstract_Author__c> abstractAuthors = new List<Abstract_Author__c>();
        for (Abstract__c abstractItem : abstracts) {
            abstractAuthors.add(new Abstract_Author__c(
                Abstract__c = abstractItem.Id,
                Abstract_Author__c = contactAbstractAuthor.Id
            ));
            abstractAuthors.add(new Abstract_Author__c(
                Abstract__c = abstractItem.Id,
                Abstract_Author__c = contactAbstractAuthor1.Id
            ));
            abstractAuthors.add(new Abstract_Author__c(
                Abstract__c = abstractItem.Id,
                Abstract_Author__c = contactAbstractAuthor2.Id
            ));
        }
        insert abstractAuthors;
        
        insert new Abstract_Review__c( Reviewer__c = reviewers[0].Id , Abstract__c= abstracts[0].Id, Stage__c='Assigned');
        
        List<Session__c> extraSessions = new List<Session__c>();

        extraSessions.add(new Session__c(Name = 'Session Extra 1', Type__c = 'Payable', Session_Type__c = 'Special Session',
        	Max_Participants__c = 50, Event_custom__c = eventTest.Id, Session_Start__c = Datetime.now(),
            Session_End__c = Datetime.now().addDays(1)));
        
        insert extraSessions;
         
        Lecture__c lecture = new Lecture__c(Event_custom__c = eventTest.Id, Session__c = extraSessions[0].Id, Abstract__c = abstracts[0].Id);
        insert lecture;
        
    }
    @isTest 
    static void testGetData() {
        PageReference pageRef = Page.AbstractBooks;
        pageRef.getParameters().put('type','AbstractStaff');
        Test.setCurrentPage(pageRef);
        
        AbstractBookController controller = new AbstractBookController();
        System.assertEquals(1, controller.abAll.size());
        
    }
}