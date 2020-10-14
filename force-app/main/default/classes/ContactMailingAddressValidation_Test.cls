@IsTest
public with sharing class ContactMailingAddressValidation_Test {
    /*@TestSetup public static void setup(){
        insert new Contact(LastName = 'Test');
        RecordType rtDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Department'];
        Account acc = new Account(Name = 'Test Account', RecordTypeId=rtDepartment.Id);
        insert acc;
    }
    @IsTest public static void addressCheckTestErrorWorkAddressEmptyDepartmentPositions(){
        Contact contact = [SELECT Id, Mailing_address__c FROM Contact WHERE LastName='Test'];
        Contact updatedContact = new Contact();
        try {
            contact.Mailing_address__c = 'Work Address';
            update contact;
        } catch (Exception e ){
            Boolean expectedExceptionThrown =  e.getMessage().contains(ContactMailingAddressValidationHelper.message2);
            System.assertEquals(true, expectedExceptionThrown);
            updatedContact = [SELECT Id, Mailing_address__c FROM Contact WHERE Id = :contact.Id];
            System.assertNotEquals('Work Address',updatedContact.Mailing_address__c);
        }
    }
    @IsTest public static void addressCheckTestErrorWorkAddressWithDepartmentPositionsNotSetPWP(){
        Contact contact = [SELECT Id, Mailing_address__c FROM Contact WHERE LastName='Test'];
        Contact updatedContact = new Contact();
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        RecordType rtCRDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        Contact_Role__c cr = new Contact_Role__c(Contact__c=contact.Id, Account__c=a.Id, Role__c='Head', RecordTypeId=rtCRDepartment.Id);
        insert cr;
        try {
            contact.Mailing_address__c = 'Work Address';
            update contact;
        } catch (Exception e ){
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains(ContactMailingAddressValidationHelper.message2);
            System.assertEquals(true, expectedExceptionThrown);
            updatedContact = [SELECT Id, Mailing_address__c FROM Contact WHERE Id = :contact.Id];
            System.assertNotEquals('Work Address',updatedContact.Mailing_address__c);
        }
    }
    @IsTest public static void addressCheckTestErrorWorkAddressWithDepartmentPositionsSetPWP(){
        Contact contact = [SELECT Id, Mailing_address__c FROM Contact WHERE LastName='Test'];
        Contact updatedContact = new Contact();
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        RecordType rtCRDepartment = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact_Role__c' AND DeveloperName = 'Department'];
        Contact_Role__c cr = new Contact_Role__c(Contact__c=contact.Id, Account__c=a.Id, Role__c='Head', is_primary_workplace__c = true,  RecordTypeId=rtCRDepartment.Id);
        insert cr;
        try {
            contact.Mailing_address__c = 'Work Address';
            update contact;
        } catch (Exception e ){
            Boolean expectedExceptionThrown =  e.getMessage().contains(ContactMailingAddressValidationHelper.message1);
            System.assertEquals(true, expectedExceptionThrown);
            updatedContact = [SELECT Id, Mailing_address__c FROM Contact WHERE Id = :contact.Id];
            System.assertNotEquals('Work Address',updatedContact.Mailing_address__c);
        }
    }*/
}