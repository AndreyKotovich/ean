@IsTest
public class EventInvoiceControllerTest {

    @IsTest
    static void testEventInvoice() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'info@test.com');
        insert contact;

        Order__c order = new Order__c(
                Contact__c = contact.Id,
                Payment_Method__c = 'creditcard',
                Status__c = 'Opened',
                Event_custom__c = event.Id,
                Purchase_Type__c = 'New',
                Type__c = 'Event registration'
            );
        insert order;

        PageReference invoicePage = new PageReference('/apex/EventInvoice');
        invoicePage.getParameters().put('orderId', order.Id);
        invoicePage.getParameters().put('contactId', order.Contact__c);
        invoicePage.getParameters().put('eventId', order.Event_Custom__c);
        invoicePage.getParameters().put('isOrderItemsSame', 'false');
        Test.setCurrentPage(invoicePage);
        Test.startTest();
        EventInvoiceController eventInvoicePage = new EventInvoiceController();
        Test.stopTest();
        System.assert(eventInvoicePage.orderId == order.Id);
        System.assert(eventInvoicePage.contactId == order.Contact__c);
        System.assert(eventInvoicePage.eventId == order.Event_Custom__c);
        System.assert(eventInvoicePage.isOrderItemsSame == false);
    }

}