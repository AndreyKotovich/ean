public with sharing class EventInvoiceController {
    public EventInvoiceController() {

    }
    public String orderId {get{
        return ApexPages.currentPage().getParameters().get('orderId');
    } set;}
    public String contactId {get{
        return ApexPages.currentPage().getParameters().get('contactId');
    } set;}
    public String eventId {get{
        return ApexPages.currentPage().getParameters().get('eventId');
    } set;}
    public Boolean isOrderItemsSame {get{
        if (ApexPages.currentPage().getParameters().get('isOrderItemsSame') == 'true') {
            return true;
        } else {
            return false;
        }
        
    } set;}
}