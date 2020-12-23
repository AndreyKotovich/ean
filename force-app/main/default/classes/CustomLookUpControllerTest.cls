@isTest
public with sharing class CustomLookUpControllerTest {

    @testSetup static void setup() {

        List<Contact> contactList = new List<Contact>();
        List<Abstract__c> abstractList = new List<Abstract__c>();

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
    }

    @isTest
    public static void fetchLookUpValuesTest(){
        List<Contact> contacts = CustomLookUpController.fetchLookUpValues('test');
        System.assertEquals(contacts.size(), 5);

        System.assertEquals(contacts.get(0).deleted1__c, false);

        for(Integer i = 1; i < 5; i++){
            System.assertEquals(contacts.get(i).deleted1__c, true);
        }
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

        CustomLookUpController.createContact(FirstName, LastName, EmailString, Department, City, Country);

        con = [Select Id FROM Contact WHERE FirstName =: firstName];
        System.assertEquals(con.size(), 1);
        String exceptionFirstName = 'TestFirstName';
        String exceptionLastName = 'TestLastName';
        String exceptionEmailString = '5test@test.com';
        CustomLookUpController.createContact(exceptionFirstName, exceptionLastName, exceptionEmailString, Department, City, Country);
        List<Contact> exceptionCon = [Select Id FROM Contact WHERE FirstName =: exceptionFirstName AND LastName =: exceptionLastName];
        System.assertEquals(exceptionCon.size(), 0);
    }

    @isTest
    public static void getContactTest(){
        List<Abstract__c> abstractList = [SELECT Id, Abstract_Presenter__c FROM Abstract__c];

        for(Abstract__c abstractItem : abstractList){
            Contact con = CustomLookUpController.getContact(abstractItem.Id);
            System.assertNotEquals(con, null);
        }
    }

    @isTest
    public static void getMailingCountriesTest(){
        List<String> countries = CustomLookUpController.getMailingCountries();
        System.assertNotEquals(countries.size(), 0);
    }
}