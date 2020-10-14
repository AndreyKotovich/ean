@IsTest
public with sharing class FellowshipApplicationsFormHelper_Test {
    @testSetup static void setup() {
        RecordType clinFellRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship__c' AND DeveloperName = 'Clinical_Fellowship'];
        RecordType clinFellAppFormRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Fellowship_Applications_Form__c' AND DeveloperName = 'Clinical_Fellowship_Application_Form'];
        List<Fellowship__c> fellowships = new List<Fellowship__c>();
        fellowships.add(new Fellowship__c(Name__c = 'Test1', RecordTypeId = clinFellRT.Id));
        insert fellowships;
        Contact contact = new Contact(FirstName = 'New', LastName='Contact');
        insert contact;
        List<Fellowship_Applications_Form__c> af = new List<Fellowship_Applications_Form__c>();
        af.add(new Fellowship_Applications_Form__c(Contact__c = contact.Id, Fellowship__c = fellowships[0].Id, RecordTypeId = clinFellAppFormRT.Id));
        af.add(new Fellowship_Applications_Form__c(Contact__c = contact.Id, Fellowship__c = fellowships[0].Id, RecordTypeId = clinFellAppFormRT.Id));
        insert af;
    }
    @IsTest public static void unlockRecordsTest(){
        List<Fellowship_Applications_Form__c> applicationForms = [SELECT Id, Approval_Status__c FROM Fellowship_Applications_Form__c];
        Approval.lock(applicationForms);
        for(Fellowship_Applications_Form__c af : applicationForms){
            af.Approval_Status__c = 'Further Information Required';
        }
        Test.startTest();
        update applicationForms;
        Test.stopTest();
    }
}