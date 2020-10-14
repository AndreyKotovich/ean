@isTest
public with sharing class InvoicePDFGeneratorTest {
    @isTest(SeeAllData = true)
    public static void generateInvoicePDFsTest() {
        Test.startTest();
        Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert c;
        Membership__c membership = new Membership__c(Name = 'Full Membership', API__c = 'full_membershipp');
        insert membership;
        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'New');
        insert order;
        Order__c order2 = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'New', Invoice_Number__c = 'EIMF ' + String.valueOf(Date.today().year()) + '/0000');
        insert order2;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Test',
                Last_name__c = 'TestLast',
                Date_of_birth__c = Date.today(),
                Gender__c = 'Male',
                Email__c = 'test@test.com',
                Nationality__c = 'United States',
                Residency__c = 'United States',
                ZIP_Postal_code__c = '1111',
                City__c = 'City',
                Membership__c = membership.Id,
                Contact__c = c.Id,
                Profession__c = 'Neurologist',
                Street__c = 'test street',
                Form_Status__c = 'Further Information Required',
                Order__c = order.Id
        );
        insert appForm;
        Product2 product = new Product2(Name = 'TestProduct');
        insert product;
        Product2 product2 = new Product2(Name = 'TestProduct2');
        insert product2;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 111, Product__c = product.Id, Quantity__c = 3);
        insert orderItem;
        Order_Item__c orderItem2 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 15,  Product__c = product2.Id, Quantity__c = 7);
        insert orderItem2;
        Order_Item__c orderItem3 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 214, Membership__c = membership.Id, Quantity__c = 1);
        insert orderItem3;

        order.Status__c = 'Paid';
        update order;
        Test.stopTest();
        List<Order__c> orders = [
                SELECT Id, Name
                FROM Order__c
                WHERE Contact__c = :c.Id
                    AND Payment_Date__c = :Date.today().addDays(-17)
                    AND Total_amount__c = 652 AND Status__c = 'Paid'
        ];
        String expectedAttName = 'Invoice_' + orders[0].Name + '.pdf';
        List<ContentVersion> attachments = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments.size());
        InvoicePDFGenerator.generateInvoicePDFs(new List<Id>{ orders[0].Id });
        List<ContentVersion> attachments2 = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments2.size());
    }
    @isTest(SeeAllData = true)
    public static void generateInvoicePDFsTest2() {
        Test.startTest();
        Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert c;
        Membership__c membership = new Membership__c(Name = 'Full Membership', API__c = 'full_membershipp');
        insert membership;
        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'Update');
        insert order;
        Order__c order2 = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'Update', Invoice_Number__c = 'REIMF ' + String.valueOf(Date.today().year()) + '/0000');
        insert order2;
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'Test',
                Last_name__c = 'TestLast',
                Date_of_birth__c = Date.today(),
                Gender__c = 'Male',
                Email__c = 'test@test.com',
                Nationality__c = 'United States',
                Residency__c = 'United States',
                ZIP_Postal_code__c = '1111',
                City__c = 'City',
                Membership__c = membership.Id,
                Contact__c = c.Id,
                Profession__c = 'Neurologist',
                Street__c = 'test street',
                Form_Status__c = 'Further Information Required',
                Order__c = order.Id
        );
        insert appForm;
        Product2 product = new Product2(Name = 'TestProduct');
        insert product;
        Product2 product2 = new Product2(Name = 'TestProduct2');
        insert product2;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 111, Product__c = product.Id, Quantity__c = 3);
        insert orderItem;
        Order_Item__c orderItem2 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 15,  Product__c = product2.Id, Quantity__c = 7);
        insert orderItem2;
        Order_Item__c orderItem3 = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 214, Membership__c = membership.Id, Quantity__c = 1);
        insert orderItem3;
        order.Status__c = 'Paid';
        update order;
        Test.stopTest();
        List<Order__c> orders = [
                SELECT Id, Name
                FROM Order__c
                WHERE Contact__c = :c.Id
                AND Payment_Date__c = :Date.today().addDays(-17)
                AND Total_amount__c = 652 AND Status__c = 'Paid'
        ];
        String expectedAttName = 'Invoice_' + orders[0].Name + '.pdf';
        List<ContentVersion> attachments = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments.size());
        InvoicePDFGenerator.generateInvoicePDFs(new List<Id>{ orders[0].Id });
        List<ContentVersion> attachments2 = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments2.size());
    }

}