@isTest
public class InvoicePageControllerTest {
    @testSetup
    public static void setup(){
        Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany', Mailing_address__c = 'Official Address');
        insert c;
        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-13), Status__c = 'Paid');
        insert order;
        Membership__c membership = new Membership__c(Name = 'Full Membership', API__c = 'full_membership');
        insert membership;
        Product2 product = new Product2(Name = 'TestProduct');
        insert product;
        Product2 product2 = new Product2(Name = 'TestProduct2');
        insert product2;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 111, Product__c = product.Id, Quantity__c = 3);
        insert orderItem;
        Order_Item__c orderItem2 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 75,  Product__c = product2.Id, Quantity__c = 7);
        insert orderItem2;
        Order_Item__c orderItem3 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 234, Membership__c = membership.Id, Quantity__c = 1);
        insert orderItem3;
    }

    @isTest
    public static void generatePageTest(){
        List<Order__c> orders = [
                SELECT Id, Contact__r.MailingAddress, Total_amount__c, Contact__r.Name, Payment_Date__c, Contact__r.Selected_Mailing_Address__c,
                (SELECT Id, Amount__c, Product__c, Membership__c, Membership__r.Name, Product__r.Name FROM Order_Items__r ORDER BY CreatedDate DESC)
                FROM Order__c
                WHERE  Payment_Date__c = :Date.today().addDays(-13)
        ];
        PageReference pageRef = Page.InvoicePage;
        pageRef.getParameters().put('co',orders[0].Id);
        Test.setCurrentPage(pageRef);

        InvoicePageController controller = new InvoicePageController();

        List<String> address = new List<String>();
        address = orders[0].Contact__r.Selected_Mailing_Address__c.split('<br>');

        System.assertEquals(orders[0].Contact__r.Name , controller.name);
        System.assertEquals(address, controller.address);
        System.assertEquals(1, controller.memberships.size());
        System.assertEquals(2, controller.products.size());
        System.assertEquals(orders[0].Total_amount__c, controller.totalAmount);
        System.assertEquals(orders[0].Payment_Date__c.format('MMMM dd, yyyy'),controller.invoiceDate);
    }
}