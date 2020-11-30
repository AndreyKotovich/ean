public with sharing class OrderInvoiceTableController {
	public OrderInvoiceTableController() {
	}
	public String orderId { get; set; }
	public Integer orderItemsSize { get; set; }
	public Decimal vatAmount { get; set; }
	public Decimal vatValue { get; set; }
	public Decimal orderTotal { get; set; }
	public Decimal orderTotalAmount { get; set; }

	public List<OrderItemWrapper> getOrderItems() {
		orderTotalAmount = 0;
        vatAmount = 0;
		List<Order_Item__c> orderItems = [
			SELECT Id, Name, Name__c, Amount__c , Quantity__c, Total_amount__c, Event_Participation__r.Contact__r.Id,
				Order_Custom__c, Order_Custom__r.Event_custom__r.VAT_Amount__c, Event_Participation__r.Contact__r.FirstName,
				Event_Participation__r.Contact__r.LastName, Event_Participation__r.Contact__r.Email,
				Order_Custom__r.Contact__r.FirstName, Order_Custom__r.Contact__r.LastName,
				Order_Custom__r.Contact__r.Email 
			FROM Order_Item__c 
			WHERE Order_Custom__c = :orderId
		];
		this.orderItemsSize = orderItems.size();
		List<OrderItemWrapper> orderIs = new List<OrderItemWrapper>();
		if (orderItems.size() > 0) {
			vatValue = orderItems[0].Order_Custom__r.Event_custom__r.VAT_Amount__c != null ? orderItems[0].Order_Custom__r.Event_custom__r.VAT_Amount__c : 0;
			 
			for (Order_Item__c oI : orderItems) {
				OrderItemWrapper oIW = new OrderItemWrapper();
				oIW.id = oI.Id;
				oIW.name = oI.Name__c;
				oIW.amount = oI.Amount__c;
				oIW.totalAmount  = (oI.Total_amount__c - (oI.Total_amount__c * vatValue / 100)).setScale(2);
				oIW.quantity = oI.Quantity__c;
				oIW.contactId = oI.Order_Custom__r.Contact__r.Id;
				oIW.firstName = oI.Order_Custom__r.Contact__r.FirstName;
				oIW.lastName = oI.Order_Custom__r.Contact__r.LastName;
				orderIs.add( oIW );
				orderTotalAmount += oI.Total_amount__c;
			}
			if (orderTotalAmount > 0 && vatValue > 0) {
				vatAmount = (orderTotalAmount * vatValue / 100).setScale(2);
				orderTotal = (orderTotalAmount - vatAmount).setScale(2);                
			}
		}
		return orderIs;
	}

	public class OrderItemWrapper {
		public String id { get; set; }
		public String name { get; set; }
		public Decimal amount { get; set; }
		public Decimal totalAmount { get; set; }
		public Decimal quantity { get; set; }
		public String contactId { get; set; }
		public String firstName { get; set; }
		public String lastName { get; set; }
	}
}

 