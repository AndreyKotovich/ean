public with sharing class MembershipRenewalOrderTableController {
	public MembershipRenewalOrderTableController() {
	}

	public String orderId { get; set; }

	public Decimal orderTotalAmount { get; set; }
	public Decimal orderReceivedAmount { get; set; }
	public Decimal balanceAmount { get; set; }

	public List<OrderItemWrapper> getOrderItems() {

		orderTotalAmount = 0;
		orderReceivedAmount = 0;
		balanceAmount = 0;

		List<Order_Item__c> orderItems = [
			SELECT Id, Name, Name__c, Amount__c , Quantity__c, Total_amount__c, Order_Custom__r.Paid_Amount__c, Order_Custom__r.Total_amount__c, 
				Order_Custom__r.Total_Amount_Gros__c
			FROM Order_Item__c
			WHERE Order_Custom__c = :orderId
		];

		List<OrderItemWrapper> orderItemsList = new List<OrderItemWrapper>();

		orderTotalAmount = orderItems[0].Order_Custom__r.Total_amount__c != null ? orderItems[0].Order_Custom__r.Total_amount__c : 0;
		orderReceivedAmount = orderItems[0].Order_Custom__r.Paid_Amount__c != null ? orderItems[0].Order_Custom__r.Paid_Amount__c : 0;
		balanceAmount = orderTotalAmount - orderReceivedAmount;

		if (orderItems.isEmpty()) return orderItemsList;

		for (Order_Item__c orderItem : orderItems) {
			OrderItemWrapper orderItemWrap = new OrderItemWrapper();
			orderItemWrap.id = orderItem.Id;
			orderItemWrap.name = orderItem.Name__c;
			orderItemWrap.amount = orderItem.Amount__c;
			orderItemWrap.totalAmount = orderItem.Total_amount__c;
			orderItemWrap.quantity = orderItem.Quantity__c;
			orderItemsList.add(orderItemWrap);
		}
		return orderItemsList;
	}

	public class OrderItemWrapper {
		public String id { get; set; }
		public String name { get; set; }
		public Decimal amount { get; set; }
		public Decimal totalAmount { get; set; }
		public Decimal quantity { get; set; }
	}
}