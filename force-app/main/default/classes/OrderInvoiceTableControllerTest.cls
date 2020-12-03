@isTest
private with sharing class OrderInvoiceTableControllerTest {
    public OrderInvoiceTableControllerTest() {

    }

    @TestSetup
    static void Setup(){
        Contact testContact = new Contact(
            LastName = 'Test',
            Email = 'testmail@mail.com'
        );
        insert testContact;
        Event__c event = new Event__c(
            Name = 'Test event'
        );
        insert event;
        Ticket__c testTicket = new Ticket__c();
        insert testTicket;
        Event_Ticket__c testEventTicket = new Event_Ticket__c(
            Event_custom__c = event.Id,
            Participation__c = 'Onsite',
            Ticket__c = testTicket.Id
        );
        insert testEventTicket;
        Participant__c testParticipant = new Participant__c(
            Contact__c = testContact.Id,
            Event_custom__c = event.Id,
            Status__c = 'Registered',
            Badge_Retrieval__c = 'onsite',
            Event_Ticket__c = testEventTicket.Id
        );
        insert testParticipant;
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 1; i <= 5; i++) {
            Order__c order = new Order__c(
                Contact__c = testContact.Id,
                Status__c = 'Opened',
                Type__c = 'Event registration',
                Event_custom__c = event.Id
            );
            orders.add(order);
        }
        insert orders;
        List<Order_Item__c> orderItems = new List<Order_Item__c>();
        for (Order__c order : orders) {
            for (Integer i = 1; i <=4; i++) {
                Order_Item__c orderItem = new Order_Item__c(
                    Amount__c = i +0.5,
                    Quantity__c = 1,
                    Order_Custom__c = order.Id,
                    Event_Participation__c = testParticipant.Id
                );
                orderItems.add(orderItem);
            }
        }
        insert orderItems;
    }

    @isTest
    static void getOrderItemsTest(){
        List<Order__c> orders = [
            SELECT Id
            FROM Order__c
        ];
        for (Order__c order : orders){
            OrderInvoiceTableController OrderInvoiceTable = new OrderInvoiceTableController();
            OrderInvoiceTable.orderId = order.Id;
            List<OrderInvoiceTableController.OrderItemWrapper> wraperInstances = OrderInvoiceTable.getOrderItems();
            for (OrderInvoiceTableController.OrderItemWrapper wraperInstance : wraperInstances) {
                System.assert(wraperInstance.participantContactEmail == 'testmail@mail.com');
            }
        }
    }
}