@IsTest
public with sharing class BadgeControllerTest {
    @IsTest
    public static void getTemplateBadgeTest() {

        Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
        Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, 
            Start_Time__c = System.now().addDays(10), End_Time__c = System.now().addDays(20), Status__c = 'Scheduled');
        insert event;

        Id exhibitorRTId = Schema.SObjectType.Event_Badge__c.getRecordTypeInfosByDeveloperName().get('Exhibitor_Badge').getRecordTypeId();
        Event_Badge__c badge = new Event_Badge__c(
            Event_custom__c = event.Id,
            Company__c = 'asd',
            Footer_Definitions__c = 'Non-Member',
            RecordTypeId = exhibitorRTId
        );


        insert badge;
    }
}
