public with sharing class RefundInvoiceTableController {
    public RefundInvoiceTableController() {
    }
    public String orderId { get; set; }
    public String JSONBody { get; set; }
    public Decimal orderTotalAmount { get; set; }

    public List<Order_Item__c> getOrderItems(){
        List<Order_Item__c> orderItems = new List<Order_Item__c>();

        Map<String,Object> oIOrig = (Map<String,Object>)JSON.deserializeUntyped(JSONBody);

        List<Order_Item__c> oIs = [
            SELECT 
                Id, Name, Total_amount__c, Refund_Amount__c, Event_Participation__r.Contact__r.Id, Event_Participation__r.Contact__r.FirstName, 
                Event_Participation__r.Contact__r.LastName, Session_Participation__r.Role__c, Session_Participation__r.Event_Ticket__r.Ticket__r.Name,
                Event_Participation__r.Event_Ticket__r.Ticket__r.Name, Session_Participation__r.Session__r.Name 
            FROM Order_Item__c 
            WHERE Order_Custom__c = :orderId AND Refund_Amount__c != 0
        ];
        for (Order_Item__c oi : oIs) {
            if (oIOrig.containsKey(oi.Id)) {
                oi.Refund_Amount__c = ((Decimal)oIOrig.get(oi.Id)) * (-1);
                orderTotalAmount += oi.Refund_Amount__c;
                orderItems.add(oi);
            }
        }

        return orderItems;
    }
}
