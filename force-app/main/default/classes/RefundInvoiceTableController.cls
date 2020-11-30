public with sharing class RefundInvoiceTableController {
    public RefundInvoiceTableController() {
    }
    public String orderId { get; set; }
    public String JSONBody { get; set; }
    public String orderNum { get; set; }
    public Decimal orderTotalAmount { get; set; }

    public List<Order_Item__c> getOrderItems(){
        List<Order_Item__c> orderIs = new List<Order_Item__c>();
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
                Event_Participation__r.Event_Ticket__r.Ticket__r.Name, Session_Participation__r.Session__r.Name 
            FROM Order_Item__c 
            WHERE Order_Custom__c = :orderId
		];
		
		for (Integer i = (oIs.size()-1) ; i>= 0 ; i--){
			if (oIOrig.containsKey(oIs[i].Id)) {
                oIs[i].Refund_Amount__c = ((Decimal)oIOrig.get(oIs[i].Id)) * (-1);
                orderTotalAmount += oIs[i].Refund_Amount__c;
            } else {
				oIs.remove(i);
			}
		} 

        return oIs;
    }
}