@isTest
public with sharing class AssignReviewersControllerTest {
    public AssignReviewersControllerTest() {

    }

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
        System.debug('contacts --> ' + contacts);

        Event__c eventTetst = new Event__c(
            Name = 'Test event'            
        );
        insert eventTetst;
        System.debug('eventTetst --> ' + eventTetst);

        List<Reviewer__c> reviewers = new List<Reviewer__c>();
        Integer loopCounter = 0;
        for (String  pickListValue : pickListValues) {
            Reviewer__c reviewer = new Reviewer__c(
                Review_Capacity__c = '0-100',
                Event__c = eventTetst.Id,
                Contact__c = contacts[loopCounter].Id,
                Status__c = 'Accepted',
                Topics__c = pickListValue
            );
            reviewers.add(reviewer);
            loopCounter = loopCounter + 1;
        }
        insert reviewers;
        System.debug('reviewers --> ' + reviewers);

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
                Event__c = eventTetst.Id,
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
        System.debug('abstracts --> ' + abstracts);

        Contact contactAbstractAuthor = new Contact(
                LastName = 'Test_abstract_author',
                Email = 'testabstract.author@test.ru'
            );
        insert contactAbstractAuthor;
        System.debug('contactAbstractAuthor --> ' + contactAbstractAuthor);

        List<Abstract_Author__c> abstractAuthors = new List<Abstract_Author__c>();
        for (Abstract__c abstractItem : abstracts) {
            Abstract_Author__c abstractAuthor = new Abstract_Author__c(
                Abstract__c = abstractItem.Id,
                Abstract_Author__c = contactAbstractAuthor.Id
            );
            abstractAuthors.add(abstractAuthor);
        }
        insert abstractAuthors;
        System.debug('abstractAuthors --> ' + abstractAuthors);
    }

    @isTest
    static void getPickListValuesTest(){
        String objectApiName = 'Contact';
        String fieldApiName = 'Salutation';
        String fieldApiNameWhithoutPicklist = 'LastName';
        List<String> fieldApiNames = new List<String>();
        fieldApiNames.add(fieldApiName);
        fieldApiNames.add(fieldApiNameWhithoutPicklist);
        Map<String, List<String>> objectNameToObjectFieldNamesMap = new Map<String, List<String>>();
        objectNameToObjectFieldNamesMap.put(objectApiName, fieldApiNames);
        Map<String, Map<String, List<String>>> result = AssignReviewersController.getPickListValues(objectNameToObjectFieldNamesMap);
        System.assert(result.containsKey(objectApiName));
        System.assert(result.get(objectApiName).containsKey(fieldApiName));
        System.assert(result.get(objectApiName).containsKey(fieldApiNameWhithoutPicklist));
        System.assert(result.get(objectApiName).get(fieldApiName).size() > 0);
        System.assert(result.get(objectApiName).get(fieldApiNameWhithoutPicklist).size() == 0);
    }
    @isTest
    static void getAbstractsTest(){
        String abstractTopic = '';
        String abstractType = '';
        List<Abstract__c> abstractsNotfiltered = AssignReviewersController.getAbstracts(abstractTopic, abstractType);
        System.assert(abstractsNotfiltered.size() > 0);
        abstractTopic = Abstract__c.Abstract_Topic__c.getDescribe().getPicklistValues()[0].getLabel();
        List<Abstract__c> abstractsFiltered = AssignReviewersController.getAbstracts(abstractTopic, abstractType);
        System.assert(abstractsFiltered.size() > 0);
        System.assert(abstractsNotfiltered.size() > abstractsFiltered.size());
    }

    @isTest
    static void getReviewersTest(){
        List<Abstract__c> abstracts = [
            SELECT Id
            FROM Abstract__c
            WHERE Stage__c = 'Submitted'
        ];
        System.debug('getReviewersTest abstracts --> ' + abstracts);
        List<Reviewer__c> reviewers = new List<Reviewer__c>();
        if (abstracts.size() > 0) {
            reviewers = AssignReviewersController.getReviewers(abstracts[0].Id);
        }
        System.assert(reviewers.size() > 0);
    }

    @isTest
    static void getAuthorsDataTest(){
        List<Abstract__c> abstracts = [
            SELECT Id
            FROM Abstract__c
            WHERE Stage__c = 'Submitted'
        ];
        List<Contact> contacts = [
            SELECT Id, Email
            FROM Contact
            WHERE LastName = 'Test_abstract_author'
        ];
        List<Abstract_Author__c> authors = new List<Abstract_Author__c>();
        if (abstracts.size() > 0) {
            authors = AssignReviewersController.getAuthorsData(abstracts[0].Id, contacts[0].Id, contacts[0].Email);
        }
        System.assert(authors.size() > 0);
    }
}