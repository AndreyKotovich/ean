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
				Order_Custom__r.Contact__r.Email, Order_Custom__r.Total_amount_Gros__c, Order_Custom__r.VAT_Amount__c,
				Order_Custom__r.Total_amount__c
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
				oIW.totalAmount  = oI.Total_amount__c;
				oIW.quantity = oI.Quantity__c;
				oIW.contactId = oI.Order_Custom__r.Contact__r.Id;
				oIW.firstName = oI.Order_Custom__r.Contact__r.FirstName;
                oIW.lastName = oI.Order_Custom__r.Contact__r.LastName;
				oIW.contactEmail = oI.Order_Custom__r.Contact__r.Email;
				oIW.participantLastName = oI.Event_Participation__r.Contact__r.LastName;
				oIW.participantFirstName = oI.Event_Participation__r.Contact__r.FirstName;
				oIW.participantContactId = oI.Event_Participation__r.Contact__r.Id;
				oIW.participantContactEmail = oI.Event_Participation__r.Contact__r.Email;
				orderIs.add( oIW );

			}
			if (orderItems.size() > 0) {
				orderTotal = orderItems[0].Order_Custom__r.Total_amount__c;
				orderTotalAmount = orderItems[0].Order_Custom__r.Total_amount_Gros__c;
				vatAmount = orderItems[0].Order_Custom__r.VAT_Amount__c;         
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
		public String contactEmail { get; set; }
		public String participantLastName { get; set; }
		public String participantFirstName { get; set; }
		public String participantContactId { get; set; }
		public String participantContactEmail { get; set; }
	}
}