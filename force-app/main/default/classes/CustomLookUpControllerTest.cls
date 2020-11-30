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
}