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
        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'New', Payment_Method__c = 'creditcard');
        insert order;
        Order__c order2 = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'New', Payment_Method__c = 'Bank Transfer', Invoice_Number__c = 'EIMF ' + String.valueOf(Date.today().year()) + '/0000');
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
                WHERE Id = :order.Id
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
        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'Update', Payment_Method__c = 'Bank Transfer');
        insert order;
        Order__c order2 = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today().addDays(-17), Purchase_Type__c = 'Update', Payment_Method__c = 'creditcard', Invoice_Number__c = 'REIMF ' + String.valueOf(Date.today().year()) + '/0000');
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
                WHERE Id = :order.Id
        ];
        String expectedAttName = 'Invoice_' + orders[0].Name + '.pdf';
        List<ContentVersion> attachments = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments.size());
        InvoicePDFGenerator.generateInvoicePDFs(new List<Id>{ orders[0].Id });
        List<ContentVersion> attachments2 = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments2.size());
    }
    @IsTest
    public static void updateParticipantsStatusTest(){
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;
        Session__c session = new Session__c(Name = 'Test Session', Event_custom__c = event.Id, Type__c = 'Payable');
        insert session;
        Contact contact = new Contact(FirstName='Ilya', LastName='Litovchik');
        insert contact;
        Session_Participation__c sessionParticipation = new Session_Participation__c(Contact__c = contact.Id, Session__c = session.Id, Status__c = 'Pending');
        insert sessionParticipation;

        List<Participant__c> eventParticipation = new List<Participant__c>();

        for(Integer i = 0; i < 5; i++){
            eventParticipation.add(new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id, Status__c = 'Pending'));
        }

        insert eventParticipation;

        Order__c ord = new Order__c();
        ord.Status__c = 'Opened';
        ord.Contact__c = contact.Id;
        ord.Event_custom__c = event.Id;
        ord.Type__c = 'Event registration';
        insert ord;

        List<Order_Item__c> orderItems = new List<Order_Item__c>();

        for(Participant__c participant : eventParticipation){
            orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Event_Participation__c = participant.Id, Quantity__c = 1, Amount__c = 10));
        }

        orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Session_Participation__c = sessionParticipation.Id, Quantity__c = 1, Amount__c = 5));

        insert orderItems;

        ord.Status__c = 'Paid';        
        ord.Payment_Method__c = 'Bank Transfer';
        update ord;
    }

    @IsTest
    public static void sendEmailOrderPaidGroupRegBTTest(){
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;
        Session__c session = new Session__c(Name = 'Test Session', Event_custom__c = event.Id, Type__c = 'Payable');
        insert session;
        Contact contact = new Contact(FirstName='Ilya', LastName='Litovchik');
        insert contact;
        Session_Participation__c sessionParticipation = new Session_Participation__c(Contact__c = contact.Id, Session__c = session.Id, Status__c = 'Pending');
        insert sessionParticipation;

        Event_Registration_Group__c group1 = new Event_Registration_Group__c(Name = 'Group1', Contact__c = contact.Id);
		insert group1;

		Event_Registration_Sub_Group__c subGroup = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = group1.Id);
        insert subGroup;
        
        List<Participant__c> eventParticipation = new List<Participant__c>();

        for(Integer i = 0; i < 5; i++){
            eventParticipation.add(new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id, Status__c = 'Pending'));
        }

        insert eventParticipation;

        Order__c ord = new Order__c();
        ord.Status__c = 'Opened';
        ord.Contact__c = contact.Id;
        ord.Event_custom__c = event.Id;
        ord.Type__c = 'Event registration';
        ord.Payment_Method__c = 'Bank Transfer';
        ord.Event_Registration_Sub_Group__c = subGroup.Id;
        insert ord;

        List<Order_Item__c> orderItems = new List<Order_Item__c>();

        for(Participant__c participant : eventParticipation){
            orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Event_Participation__c = participant.Id, Quantity__c = 1, Amount__c = 10));
        }

        orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Session_Participation__c = sessionParticipation.Id, Quantity__c = 1, Amount__c = 5));

        insert orderItems;

        ord.Status__c = 'Paid';
        update ord;
    }

    @IsTest
    public static void sendInvoiceSoloRegBTTest(){
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;
        Session__c session = new Session__c(Name = 'Test Session', Event_custom__c = event.Id, Type__c = 'Payable');
        insert session;
        Contact contact = new Contact(FirstName='Ilya', LastName='Litovchik');
        insert contact;
        Session_Participation__c sessionParticipation = new Session_Participation__c(Contact__c = contact.Id, Session__c = session.Id, Status__c = 'Pending');
        insert sessionParticipation;

        List<Participant__c> eventParticipation = new List<Participant__c>();

        for(Integer i = 0; i < 5; i++){
            eventParticipation.add(new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id, Status__c = 'Pending'));
        }

        insert eventParticipation;

        Order__c ord = new Order__c();
        ord.Contact__c = contact.Id;
        ord.Event_custom__c = event.Id;
        ord.Type__c = 'Event registration';        
        ord.Status__c = 'Opened';
        insert ord;

        List<Order_Item__c> orderItems = new List<Order_Item__c>();

        for(Participant__c participant : eventParticipation){
            orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Event_Participation__c = participant.Id, Quantity__c = 1, Amount__c = 10));
        }

        orderItems.add(new Order_Item__c(Order_Custom__c = ord.Id, Session_Participation__c = sessionParticipation.Id, Quantity__c = 1, Amount__c = 5));

        insert orderItems;

        ord.Payment_Method__c = 'Bank Transfer';
        update ord;
        ord.Status__c = 'Paid';
        update ord;
        ord.Status__c = 'Opened';
        update ord;
    }

    @IsTest(SeeAllData = true)
    public static void generateInvoiceAndCertificatePDFsTest(){
        Test.startTest();
        Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert c;

        List<Membership__c> memberships = [SELECT Id, Name, API__c FROM Membership__c WHERE API__c = 'full_membership'];
        Membership__c membership;
        if(memberships.isEmpty()){
            membership = new Membership__c(Name = 'Full Membership', API__c = 'full_membership');
            insert membership;
        } else {
            membership = memberships[0];
        }

        Order__c order = new Order__c(Contact__c=c.Id, Payment_Date__c = Date.today(), Purchase_Type__c = 'New', Payment_Method__c = 'Bank Transfer', Type__c = 'Renewal', Status__c = 'Paid');
        insert order;
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
                Form_Status__c = 'Approved',
                Order__c = order.Id,
                Renewal_Start_Date__c = Date.newInstance(Date.today().year()+1, 1,1),
                Renewal_End_Date__c = Date.newInstance(Date.today().year()+2, 1,1)
        );
        insert appForm;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = 214, Membership__c = membership.Id, Quantity__c = 1);
        insert orderItem;
        MembershipContactAssotiation__c mca = new MembershipContactAssotiation__c(Membership__c = membership.Id, Contact__c = c.Id, Application_form__c = appForm.Id);
        insert mca;
        InvoicePDFGenerator.generateInvoicePDFs(new List<Id>{ order.Id });
        Test.stopTest();
        List<Order__c> orders = [
                SELECT Id, Name
                FROM Order__c
                WHERE Id = :order.Id
        ];
        String expectedAttName = 'Invoice_' + orders[0].Name + '.pdf';
        List<ContentVersion> attachments = [SELECT Title FROM ContentVersion WHERE Title = :expectedAttName];
        System.assertEquals(1, attachments.size());
        MembershipContactAssotiation__c membershipStatus = [SELECT Id, Name FROM MembershipContactAssotiation__c WHERE Id =:mca.Id LIMIT 1];
        System.assertEquals(1, [SELECT Title FROM ContentVersion WHERE Title = :'Certificate_' + membershipStatus.Name + '.pdf'].size());
    }

    @IsTest
    static void generateEventInvoiceNumberTest(){
        Contact testContact = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                MailingCity = 'TestCity', MailingPostalCode = '11111',
                MailingCountry = 'Germany');
        insert testContact;
        Event__c testEvent = new Event__c(Name = 'Test Event');
        insert testEvent;
        Test.startTest();
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 0; i < 5; i++) {
            Order__c order = new Order__c(
                Contact__c = testContact.Id,
                Status__c = 'Opened',
                Event_custom__c = testEvent.Id,
                Purchase_Type__c = 'New',
                Type__c = 'Event registration'
            );
            orders.add(order);
        }
        insert orders;
        List<String> orderIds = new List<String>();
        for (Order__c order : orders) {
            orderIds.add(order.Id);
        }
        List<Order__c> afterInsertOrders = [
            SELECT Id, Contact__c, Status__c, Event_custom__c, Purchase_Type__c, Type__c, Invoice_Number__c
            FROM Order__c
            WHERE Id IN :orderIds
        ];
        for (Order__c afterInsertOrder : afterInsertOrders) {
            System.assert(String.isBlank(afterInsertOrder.Invoice_Number__c));
        }
        
        for (Order__c order : orders) {
            order.Status__c = 'Paid';
            orderIds.add(order.Id);
        }
        update orders;
        Test.stopTest();
        List<Order__c> afterUpdtOrders = [
            SELECT Id, Contact__c, Status__c, Event_custom__c, Purchase_Type__c, Type__c, Invoice_Number__c
            FROM Order__c
            WHERE Id IN :orderIds
        ];
        Boolean isInvoiceNumbersDifferent = true; 
        for (Integer i = 0; i < afterUpdtOrders.size(); i++) {
            System.assert(afterUpdtOrders[i].Contact__c == testContact.Id);
            System.assert(afterUpdtOrders[i].Status__c == 'Paid');
            System.assert(afterUpdtOrders[i].Event_custom__c == testEvent.Id);
            System.assert(afterUpdtOrders[i].Purchase_Type__c == 'New');
            System.assert(afterUpdtOrders[i].Type__c == 'Event registration');
            System.assert(String.isNotBlank(afterUpdtOrders[i].Invoice_Number__c));
            System.assert(afterUpdtOrders[i].Invoice_Number__c.contains('EAN' + String.valueOf(Date.today().year()).right(2) + '-F'));
            if (afterUpdtOrders.size() > 1 && i != 0) {
                if (afterUpdtOrders[i].Invoice_Number__c == afterUpdtOrders[i-1].Invoice_Number__c) {
                    isInvoiceNumbersDifferent = false;
                }
            }
        }
        System.assert(isInvoiceNumbersDifferent);
    }

    @IsTest
    static void saveEventInvoicePDFTest(){
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'info@test.com');
        insert contact;

        Test.startTest();
        List<String> orderIds = new List<String>();
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 0; i < 5; i++) {
            Order__c order = new Order__c(
                Contact__c = contact.Id,
                Payment_Method__c = 'creditcard',
                Status__c = 'Opened',
                Event_custom__c = event.Id,
                Purchase_Type__c = 'New',
                Type__c = 'Event registration'
            );
            orders.add(order);
        }
        insert orders;
        for (Order__c order : orders) {
            order.Status__c = 'Paid';
            orderIds.add(order.Id);
        }
        update orders;
        Test.stopTest();
        Map<Id, Order__c> afterUpdtOrdersMap = new Map<Id, Order__c>([
            SELECT Id, Invoice_Number__c
            FROM Order__c
            WHERE Id IN :orderIds
        ]);
        List<ContentDocumentLink> conDocLinks = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :orderIds
        ];
        List<String> contentDocumentIds = new List<String>();
        for (ContentDocumentLink conDocLink : conDocLinks) {
            contentDocumentIds.add(conDocLink.ContentDocumentId);
        }
        Map<Id, ContentDocument> contentDocsMap = new Map<Id, ContentDocument>([
            SELECT Id, Title
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
        ]);
        System.assert(conDocLinks.size() == afterUpdtOrdersMap.size());
        for (ContentDocumentLink conDocLink : conDocLinks) {
            System.assert(contentDocsMap.get(conDocLink.ContentDocumentId).Title == ('Invoice - ' + afterUpdtOrdersMap.get(conDocLink.LinkedEntityId).Invoice_Number__c + '.pdf'));
        }
    }
}