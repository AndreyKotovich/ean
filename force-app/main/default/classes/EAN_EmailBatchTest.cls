@isTest
public with sharing class EAN_EmailBatchTest {
    public EAN_EmailBatchTest() {

    }

    @TestSetup
    static void setup(){
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
             LastName = 'Participant',
             FirstName = 'Undefined'
         ));
        contacts.add(new Contact(
             LastName = 'Group Leader Test',
             Email = 'gr.leader@test.com'
         ));
         for (Integer i=1; i <= 10; i++) {
             contacts.add(new Contact(
             LastName = 'Contact' + i,
             FirstName = 'Test'
         ));
         }
        insert contacts;
        Event_Registration_Group__c regGroup;
        Event_Registration_Sub_Group__c regSubGroup;
        for (Contact contact : contacts) {
            if (contact.LastName == 'Group Leader Test') {
                regGroup = new Event_Registration_Group__c();
                regGroup.Contact__c = contact.Id;
                insert regGroup;
                regSubGroup = new Event_Registration_Sub_Group__c();
                regSubGroup.Event_Registration_Group__c = regGroup.Id;
                // regSubGroup.Is_Locked__c = false;
                insert regSubGroup;
            }
        }
        Event__c event = new Event__c();
        event.Start_Time__c = Datetime.newInstance(Date.today().addDays(40), Time.newInstance(0, 0, 0, 0));
        event.End_Time__c = Datetime.newInstance(Date.today().addDays(50), Time.newInstance(0, 0, 0, 0));
        event.Name = 'Test event';
        insert event;
        List<Participant__c> participants = new List<Participant__c>();
        for (Contact contact : contacts) {
            Participant__c participant = new Participant__c();
            participant.Contact__c = contact.Id;
            participant.Event_Registration_Sub_Group__c = regSubGroup.Id;
            participant.Status__c = 'Registered';
            participant.Event_custom__c = event.Id;
            participants.add(participant);
        }
        insert participants;
    }

    @isTest
    static void emailBatchTest(){
        Test.startTest();
        Id batchInstanceId = Database.executeBatch(new EAN_EmailBatch());
        Test.stopTest();
        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchInstanceId ];
        System.assertEquals('Completed', aaj.Status);
        System.assertEquals(0, aaj.NumberOfErrors);
        List<Email_Activity__c> emailActivities = [
            SELECT Type__c, Event_Custom__r.Name
            FROM Email_Activity__c
        ];
        System.assert(emailActivities.size() > 0);
        for (Email_Activity__c emailActivity : emailActivities) {
            System.assert(emailActivity.Type__c == 'Reminder GR add participants');
            System.assert(emailActivity.Event_Custom__r.Name == 'Test event');
        }
    }
}