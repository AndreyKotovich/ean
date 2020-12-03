@IsTest
public with sharing class OrderReminderBatchTest {

    @TestSetup
    static void Setup(){
        Contact testContact = new Contact(
            LastName = 'Test',
            Email = 'testmail@mail.com'
        );
        insert testContact;
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 5; i <= 15; i++) {
            Order__c order = new Order__c(
                Contact__c = testContact.Id,
                Status__c = 'Opened',
                Type__c = 'Event registration'
            );
            orders.add(order);
        }
        insert orders;
        Integer i = 5;
        for (Order__c order : orders) {
            Test.setCreatedDate(order.Id, Datetime.newInstance(Date.today().addDays(-i), Time.newInstance(0, 0, 0, 0)));
            i = i +1;
        }
         
    }

    @IsTest
    public static void OrderReminderBatchTest(){
        Test.startTest();
        Database.executeBatch(new OrderReminderBatch());
        Test.stopTest();
        List<Order__c> orders = [
            SELECT Id, Contact__c, Type__c, Status__c
            FROM Order__c
            WHERE Status__c = 'overdue'
        ];
        System.assert(orders.size() == 1);
        List<Email_Activity__c> emailActivities = [
            SELECT Contact__c, Send_To_Email__c, Type__c
            FROM Email_Activity__c
        ];
        System.assert(emailActivities.size() == 1);
        System.assert(emailActivities[0].Type__c == 'Open order reminder');
        System.assert(emailActivities[0].Send_To_Email__c == 'testmail@mail.com');
    }

}