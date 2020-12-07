@isTest
public with sharing class CustomLookUpAuthorControllerTest {
    
    @testSetup static void setup() {

        List<Contact> contactList = new List<Contact>();
        List<Abstract__c> abstractList = new List<Abstract__c>();
        List<Abstract_Author__c> junctions = new List<Abstract_Author__c>();

        for(integer i = 0; i < 10; i++){
            Contact c = new Contact(
                FirstName = 'Test_', LastName = '' + i, Email = '' + i + 'test@test.com', Department_Name__c = 'department_' + i, deleted1__c = false
            );
            contactList.add(c);
        }

        insert contactList; 

        for(Integer i = 0; i < 3; i++){
            Abstract__c abstractItem = new Abstract__c(
                Abstract_Presenter__c = contactList.get(0).Id 
            );

            abstractList.add(abstractItem);
        }      

        insert abstractList;

        for(Integer i = 0; i < 3; i++){
            Abstract_Author__c junction = new Abstract_Author__c(
                Abstract_Author__c = contactList.get(0).Id,
                Abstract__c = abstractList.get(0).Id 
            );

            junctions.add(junction);
        } 

        insert junctions;
    }

    @isTest
    public static void fetchLookUpValuesTest(){
        List<Contact> contacts = CustomLookUpAuthorController.fetchLookUpValues('test', new String[]{'ThisIsNotIdOnContact'});
        System.assertEquals(contacts.size(), 5);

        contacts = CustomLookUpAuthorController.fetchLookUpValues('', new String[]{'ThisIsNotIdOnContact'});
        System.assertEquals(contacts.size(), 5);
    }

    @isTest
    public static void createContactTest(){
        String FirstName = 'Mike';
        String LastName = 'Hottorn';
        String EmailString = 'hottorn@f1.com';
        String Department = 'F1';
        String City = 'Minsk';
        String Country = 'Belarus';

        List<Contact> con = [Select Id FROM Contact WHERE FirstName =: firstName];
        System.assertEquals(con.size(), 0);

        CustomLookUpAuthorController.createContact(FirstName, LastName, EmailString, Department, City, Country);

        con = [Select Id FROM Contact WHERE FirstName =: firstName];
        System.assertEquals(con.size(), 1);
    }

    @isTest
    public static void getContactTest(){
        Abstract__c abstractItem = [SELECT Id FROM Abstract__c].get(0);

        List<Contact> con = CustomLookUpAuthorController.getContacts(abstractItem.Id);

        System.assertNotEquals(con.size(), 0);
    }

    @isTest
    public static void getMailingCountriesTest(){
        List<String> countries = CustomLookUpAuthorController.getMailingCountries();
        System.assertNotEquals(countries.size(), 0);
    }
}