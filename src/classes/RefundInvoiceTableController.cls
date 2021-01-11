public with sharing class RefundInvoiceTableController {
    public RefundInvoiceTableController() {
    }
    public String orderId { get; set; }
    public String JSONBody { get; set; }
    public String orderNum { get; set; }
    
    public Decimal orderTotalAmount { get{
        return orderTotalAmount.setScale(2);
    } set; }
    public Decimal orderSubTotal { get{
        return orderSubTotal.setScale(2);
    } set; }
    public Decimal orderVATs { get{
        return orderVATs.setScale(2);
    } set; }
    public Decimal vatValue { get{
        return vatValue.setScale(2);
    } set; }


    public List<Order_Item__c> getOrderItems(){
        List<Order_Item__c> orderIs = new List<Order_Item__c>();        
        vatValue = 0;
        orderVATs = 0;
        orderSubTotal = 0;
        orderTotalAmount = 0;
        Map<String,Object> oIOrig = (Map<String,Object>)JSON.deserializeUntyped(JSONBody);

        List<Transaction__c> trs = [
                SELECT Id, Order_Custom__c, Status__c, Refund_Invoice__c, CreatedDate  
                FROM Transaction__c 
                WHERE Order_Custom__c = :orderId AND Status__c = 'Refund' ORDER BY CreatedDate DESC
            ];
        if (trs.size() > 0) {
            orderNum = trs[0].Refund_Invoice__c;
        }
        
        List<Order_Item__c> oIs = [
            SELECT 
                Id, Name, Total_amount__c, Refund_Amount__c, Order_Custom__r.Contact__r.Id, Order_Custom__r.Contact__r.FirstName, 
                Order_Custom__r.Contact__r.LastName, Session_Participation__r.Role__c, Session_Participation__r.Event_Ticket__r.Ticket__r.Name,
                Event_Participation__r.Event_Ticket__r.Ticket__r.Name, Session_Participation__r.Session__r.Name, Order_Custom__r.VATamount__c,
                    Order_Custom__r.Event_custom__r.VAT_Amount__c
            FROM Order_Item__c 
            WHERE Order_Custom__c = :orderId
		];
        
        vatValue = !oIs.isEmpty() ? oIs[0].Order_Custom__r.Event_custom__r.VAT_Amount__c : 0;
        
        for (Integer i = (oIs.size()-1) ; i>= 0 ; i--){
			if (oIOrig.containsKey(oIs[i].Id)) {
                Decimal refPrice = ((Decimal)oIOrig.get(oIs[i].Id)).setScale(2);
                oIs[i].Refund_Amount__c =  (refPrice / (1 + vatValue / 100)).setScale(2);
                orderTotalAmount += refPrice;
            } else {
				oIs.remove(i);
			}
        }
        if (!oIs.isEmpty()) {
            orderVATs = orderTotalAmount - (orderTotalAmount / (1 + vatValue / 100)).setScale(2); 
            orderSubTotal = orderTotalAmount - orderVATs;        
        } 
       
        return oIs;
    }
}