public with sharing class OrderInvoiceTableController {
    public OrderInvoiceTableController() {
    }
    public String orderId { get; set; }
    public Decimal orderTotalAmount { get{
        List<Order__c> orders = [
            SELECT Id, Total_amount__c FROM Order__c WHERE Id = :orderId
        ];
        if(orders.size() > 0){
            orderTotalAmount = orders[0].Total_amount__c;
        }
        return orderTotalAmount.setScale(2);
    } set; }

    public List<Order_Item__c> getOrderItems(){
        List<Order_Item__c> orderItems = [
            SELECT Id, Name, Total_amount__c FROM Order_Item__c WHERE Order_Custom__c = :orderId
        ];
        return orderItems;
    }
}