@IsTest
public with sharing class OrderUtils_Test {
    @TestSetup public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Contact c = new Contact(LastName = 'testLastName');
        insert c;
        Membership__c m = new Membership__c(Name='test', API__c='test');
        insert m;
        Order__c order = new Order__c(Contact__c=c.Id);
        insert order;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c=100, Quantity__c = 1, Membership__c = m.Id);
        insert orderItem;
    }
    @IsTest public static void generateOrderTest(){
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'testLastName' LIMIT 1];
        Membership__c membership = [SELECT Id FROM Membership__c LIMIT 1];
        List<Map<String,Object>> objects = new List<Map<String,Object>>();
        for(Integer i =0; i<10;i++){
            objects.add(new Map<String, Object>{'Membership__c'=>membership.Id, 'Amount__c'=>10, 'Quantity__c'=>1});
        }
        String orderId = OrderUtils.generateOrder(contact.Id, objects, 'New');
        System.assertNotEquals([SELECT Id FROM Order__c WHERE Id=:orderId], null);
        System.assertEquals([SELECT Id FROM Order_Item__c WHERE Order_Custom__c=:orderId].size(), 10);
    }
    @IsTest public static void createTransactionTestSuccessWithFullAmount(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'testLastName'];
        OrderUtils.createTransaction(new Transaction__c(Order_Custom__c=order.Id, Amount__c = 100, Status__c='Success'));
        System.assertEquals([SELECT Id FROM Transaction__c WHERE Order_Custom__c =:order.Id].size(), 1);
        Order__c updatedOrder = [SELECT Id, Status__c, Payment_Date__c FROM Order__c WHERE Id = :order.Id];
        System.assertEquals(updatedOrder.Status__c, 'Paid');
        System.assertEquals(
                Date.newInstance(updatedOrder.Payment_Date__c.year(), updatedOrder.Payment_Date__c.month(), updatedOrder.Payment_Date__c.day()),
                Date.today()
        );
    }
    @IsTest public static void createTransactionTestSuccessWithNotFullAmount(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'testLastName'];
        OrderUtils.createTransaction(new Transaction__c(Order_Custom__c=order.Id, Amount__c = 99, Status__c='Success'));
        System.assertEquals([SELECT Id FROM Transaction__c WHERE Order_Custom__c =:order.Id].size(), 1);
        Order__c updatedOrder = [SELECT Id, Status__c, Payment_Date__c FROM Order__c WHERE Id = :order.Id];
        System.assertNotEquals(updatedOrder.Status__c, 'Paid');
        System.assertEquals(updatedOrder.Payment_Date__c, null);
    }
    @IsTest public static void writeOrderBillingAddressTest(){
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        PaymentHttpRequest.writeOrderBillingAddress(order.Id, PaymentHttpRequest_Test.addressesObject);
        order = [SELECT Id, Billing_address__c FROM Order__c LIMIT 1];
        System.assertNotEquals(null, order.Billing_address__c);
    }
}