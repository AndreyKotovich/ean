public class InvoicePageController {
    public String name { get; set; }
    public String orderType { get; set; }
    public List<String> address { get; set; }
    public String invoiceNumber { get; set; }
    public Decimal totalAmount { get{
        if(totalAmount == null){
            totalAmount = 0;
        }
        return totalAmount.setScale(2);
    } set; }
    public Decimal paymentReceived { get{
        if(paymentReceived == null){
            paymentReceived = 0;
        }
        return paymentReceived.setScale(2);
    } set; }
    public String invoiceDate { get; set; }
    public List<Order_Item__c> memberships { get; set; }
    public List<Order_Item__c> products { get; set; }

    public InvoicePageController() {
        List<Order__c> order = new List<Order__c>();
        memberships = new List<Order_Item__c>();
        products = new List<Order_Item__c>();
        Id orderId = ApexPages.currentPage().getParameters().get('co');
        String invoNumber = ' ' + ApexPages.currentPage().getParameters().get('in');
        totalAmount = 0;
        address = new List<String>();
        name = '';
        invoiceNumber = '';
        invoiceDate = '';
        orderType = '';

        order = [
                SELECT Id, Total_amount__c, Contact__r.Name, Contact__r.Title, Contact__r.Selected_Mailing_Address__c, Payment_Date__c, Name, Invoice_Number__c, Billing_address__c, Type__c,
                        (SELECT Id, Total_amount__c, Quantity__c, Product__c, Membership__c ,Membership__r.Name, Product__r.Name FROM Order_Items__r ORDER BY CreatedDate DESC)
                FROM Order__c
                WHERE Id = :orderId
        ];

        paymentReceived = (Decimal) [SELECT SUM(Amount__c) FROM Transaction__c WHERE Status__c = 'Success' AND Order_Custom__c = :order[0].Id][0].get('expr0');

        if (!order.isEmpty() && !order[0].Order_Items__r.isEmpty()) {
            Order__c currentOrder = order[0];
            orderType = order[0].Type__c;
            name = currentOrder.Contact__r.Name;
            name += currentOrder.Contact__r.Title==null?'':', '+currentOrder.Contact__r.Title;
            invoiceDate = currentOrder.Payment_Date__c != null ? currentOrder.Payment_Date__c.format('dd MMMM, yyyy') : Datetime.now().format('dd MMMM, yyyy');
            totalAmount = currentOrder.Total_amount__c;
            invoiceNumber = invoNumber != null ? invoNumber : ' EIMF ' + String.valueOf(Date.today().year()) + '/0000';

            for (Order_Item__c oi : currentOrder.Order_Items__r) {
                if (oi.Membership__c != null) {
                    memberships.add(oi);
                } else if (oi.Product__c != null) {
                    products.add(oi);
                }
            }

            if(order[0].Total_amount__c != 0 && currentOrder.Billing_address__c != null){
                address = currentOrder.Billing_address__c.split('\n');
            } else {
                if (currentOrder.Contact__r.Selected_Mailing_Address__c != null) {
                    address = currentOrder.Contact__r.Selected_Mailing_Address__c.split('<br>');
                }
            }

        }
    }
}