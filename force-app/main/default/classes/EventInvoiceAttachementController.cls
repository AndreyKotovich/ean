public with sharing class EventInvoiceAttachementController {
    public EventInvoiceAttachementController() {

    }
    public String orderId { get; set; }
    public String contactId { get; set; }
    public String eventId { get; set; }
    public Contact contactRecord {get {
        if (String.isNotBlank(contactId)) {
            List<Contact> contacts = [
                SELECT Id, Salutation, FirstName, LastName, Department_Name__c, Work_Street__c, Work_Zip_Postal_Code__c, Work_City__c, Work_Country__c, VAT_Number__c
                FROM Contact
                WHERE Id = :contactId
            ];
            if (contacts.size() == 1) {
                return contacts[0];
            }
        }
        return null;
    } set;}

    public Order__c orderRecord {get {
        if (String.isNotBlank(orderId)) {
            List<Order__c> orders = [
                SELECT Id, Invoice_Number__c
                FROM Order__c
                WHERE Id = :orderId
            ];
            if (orders.size() == 1) {
                return orders[0];
            }
        }
        return null;
    } set;}

    public Event__c eventRecord {get {
        if (String.isNotBlank(eventId)) {
            List<Event__c> events = [
                SELECT Id, Name, Start_Time__c, End_Time__c
                FROM Event__c
                WHERE Id = :eventId
            ];
            if (events.size() == 1) {
                return events[0];
            }
        }
        return null;
    } set;}
    public Date Today { get { return Date.today(); } set;}
}