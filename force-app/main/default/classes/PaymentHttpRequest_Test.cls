@IsTest
public with sharing class PaymentHttpRequest_Test {
    public static Decimal amount = 100;
    public static String cardToken = 'test-000000-000000';
    public static String addressesObject = '{"mailing-street":"test","mailing-city":"test","mailing-state":"test","mailing-code":"test","mailing-country":"US","billing-street":"test","billing-city":"test","billing-state":"test","billing-code":"test","billing-country":"US"}';
    @TestSetup public static void setup() {
        Contact c = new Contact(LastName = 'test', FirstName='test');
        insert c;
        Order__c order = new Order__c(Contact__c = c.Id);
        insert order;
        Membership__c m = new Membership__c(Name = 'test', API__c = 'test');
        insert m;
        Order_Item__c orderItem = new Order_Item__c(Order_Custom__c = order.Id, Amount__c = amount, Quantity__c = 1, Membership__c = m.Id);
        insert orderItem;
        Card__c card = new Card__c(Contact__c = c.Id, Token_Id__c = cardToken);
        insert card;
    }
    @IsTest public static void getUUIDTest() {
        Set<String> requestIds = new Set<String>();
        for (Integer i = 0; i < 10000; i++) {
            requestIds.add(PaymentHttpRequest.getUUID());
        }
        System.assertEquals(10000, requestIds.size());
    }
    @IsTest public static void getSeamlessURLBodyWithoutCardIdTest() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        Order__c order = [SELECT Id, Total_amount__c FROM Order__c WHERE Contact__c = :c.Id];
        PaymentHttpRequest.showPaymentCheck(order.Id);
        String body = PaymentHttpRequest.getSeamlessURLBody('', order.Id, addressesObject);
        Object payment = ((Map<String, Object>) JSON.deserializeUntyped(body)).get('payment');
        Object requestedAmount = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('requested-amount');
        Object value = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(requestedAmount))).get('value');
        System.assertEquals((Decimal) value, order.Total_amount__c);
    }
    @IsTest public static void getSeamlessURLBodyWithCardIdTest() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        Card__c card = [SELECT Id, Token_Id__c FROM Card__c WHERE Contact__c = :c.Id];
        Order__c order = [SELECT Id,Total_amount__c FROM Order__c WHERE Contact__c = :c.Id];
        PaymentHttpRequest.showPaymentCheck(order.Id);
        String body = PaymentHttpRequest.getSeamlessURLBody(card.Id, order.Id, addressesObject);
        Object payment = ((Map<String, Object>) JSON.deserializeUntyped(body)).get('payment');
        Object requestedAmount = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('requested-amount');
        Object value = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(requestedAmount))).get('value');
        Object cardToken = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('card-token');
        Object tokenId = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cardToken))).get('token-id');
        System.assertEquals((Decimal) value, order.Total_amount__c);
        System.assertEquals((String) tokenId, card.Token_Id__c);
    }
    @IsTest public static void SeamlessURLShowFormTest() {
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpRequestMock());
        String response = PaymentHttpRequest.SeamlessURL(order.Id, '', addressesObject);
        Test.stopTest();
        System.debug('response: '+ response);
        Object price = ((Map<String, Object>) JSON.deserializeUntyped(response)).get('price');
        Object url = ((Map<String, Object>) JSON.deserializeUntyped(response)).get('url');
        System.assertEquals(price, amount);
        System.assertEquals(url, 'https://test.com');
    }
    @IsTest public static void SeamlessURLShowFormErrorTest() {
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpRequestMock());

        addressesObject = addressesObject.replace('US', 'TEST');
        String response = PaymentHttpRequest.SeamlessURL(order.Id, '', addressesObject);
        response.contains('A value of the field "country" is too long');

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        c.FirstName = 'Too long firstname Too long firstname';
        update c;
        response = PaymentHttpRequest.SeamlessURL(order.Id, '', addressesObject);
        response.contains('A value of the field "first-name" is too long');

        c.FirstName = 'test';
        c.LastName = 'Too long lastname Too long lastname';
        update c;
        response = PaymentHttpRequest.SeamlessURL(order.Id, '', addressesObject);
        response.contains('A value of the field "last-name" is too long');

        Test.stopTest();
    }
    @IsTest public static void SeamlessURLHideFormTest() {
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        insert new Transaction__c(Order_Custom__c = order.Id, Status__c = 'Success', Amount__c = amount);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpRequestMock());
        String response = PaymentHttpRequest.SeamlessURL(order.Id, '', addressesObject);
        Test.stopTest();
        System.assertEquals(response, '{}');
    }
    @IsTest public static void createTransactionTest() {
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        PaymentHttpRequest.createTransaction(new Transaction__c(Order_Custom__c = order.Id, Amount__c = 99.99, Status__c = 'Success'));
        System.assertEquals([SELECT Id FROM Transaction__c WHERE Order_Custom__c = :order.Id].size(), 1);
    }
    @IsTest public static void cardsCheckWithCardsTest() {
        Order__c order = [SELECT Id, Contact__c FROM Order__c WHERE Contact__r.LastName = 'test'];
        String result = PaymentHttpRequest.cardsCheck(order.Id);
        System.assertNotEquals(result, 'none');
        List<Object> parsedListResult = (List<Object>) JSON.deserializeUntyped(result);
        Map<String, Object> token = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(parsedListResult[0]));
        Card__c card = [SELECT Id, Token_Id__c FROM Card__c WHERE Id = :(String) token.get('Id')];
        System.assertNotEquals(null, (String) token.get('Id'));
        System.assertEquals(cardToken, card.Token_Id__c);
    }
    @IsTest public static void cardsCheckEmptyTest() {
        Contact cont = new Contact(Lastname = 'test2');
        insert cont;
        Order__c order = new Order__c(Contact__c = cont.Id);
        insert order;
        String result = PaymentHttpRequest.cardsCheck(order.Id);
        System.assertEquals(result, 'none');
    }
    @IsTest public static void saveCardTest() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        Order__c newOrder = new Order__c(Contact__c = c.Id);
        insert newOrder;
        PaymentHttpRequest.saveCard('{"OrderId":"' + newOrder.Id + '","Token_Id__c":"0000000000000000","Masked_Account_Number__c":"000000******0000"}');
        System.assertEquals([SELECT Id FROM Card__c WHERE Contact__c = :c.Id AND Token_Id__c = '0000000000000000'].size(), 1);
        PaymentHttpRequest.saveCard('{"OrderId":"' + newOrder.Id + '","Token_Id__c":"0000000000000000","Masked_Account_Number__c":"000000******0000"}');
        List<Card__c> cards = [SELECT Id, Masked_Account_Number__c FROM Card__c WHERE Contact__c = :c.Id AND Token_Id__c = '0000000000000000'];
        System.assertNotEquals(cards.size(), 2);
        System.assertEquals(cards[0].Masked_Account_Number__c, '************0000');
    }
    @IsTest public static void getOrderItemsTest() {
        Product2 product = new Product2(Name = 'Test Product', IsActive = true, Product_use__c = 'Membership Application');
        insert product;
        List<Order__c> order = [SELECT Id, Name FROM Order__c WHERE Contact__r.LastName = 'test'];
        insert new Order_Item__c(Order_Custom__c = order[0].Id, Product__c = product.Id, Amount__c = 75, Quantity__c = 1);
        String result = PaymentHttpRequest.getOrderItems(order[0].Id);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(m.get('total-amount'), amount + 75);
        System.assertEquals(m.get('name'), order[0].Name);
        List<Object> orderItems = (List<Object>) JSON.deserializeUntyped(JSON.serialize(m.get('order-items')));
        System.assertEquals(orderItems.size(), 2);
        System.assertEquals(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orderItems[0]))).get('product'), 'test');
        System.assertEquals(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orderItems[1]))).get('product'), 'Test Product');
    }
    @IsTest public static void getPaymentInfoByRequestIdSuccessTest() {
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpInfoRequestMock());
        String response = PaymentHttpRequest.getPaymentInfoByRequestId('test', order.Id);
        System.assertEquals(response, 'Success');
        Test.stopTest();
        String errorParseResult = PaymentHttpRequest.parsePaymentInfoAndCreateTransaction(response, order.Id, 'test');
        System.assertEquals(1, [SELECT Id FROM Transaction__c WHERE Order_Custom__c = :order.Id].size());
        System.assertEquals('Something went wrong, please, contact your system administrator.', errorParseResult);
        PaymentHttpInfoRequestMock p = new PaymentHttpInfoRequestMock();
        String response2 = PaymentHttpRequest.parsePaymentInfoAndCreateTransaction(p.body, order.Id, 'test');
        System.assertEquals('Page invalid anymore.', response2);
    }
    @IsTest public static void getPayPalUrlSuccessTest(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpGetPayPalUrlMock());
        String response = PaymentHttpRequest.getPayPalUrl(order.Id, addressesObject);
        Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response);
        System.assertEquals((String)responseJSON.get('url'), 'https://www.sandbox.paypal.com/');
        Test.stopTest();
    }
    @IsTest public static void getPayPalUrlErrorTest(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PaymentHttpGetPayPalUrlMock());
        String response = PaymentHttpRequest.getPayPalUrl(order.Id, addressesObject);
        Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response);
        System.assertEquals((String)responseJSON.get('url'), 'https://www.sandbox.paypal.com/');

        addressesObject = addressesObject.replace('US', 'TEST');
        response = PaymentHttpRequest.getPayPalUrl(order.Id, addressesObject);
        response.contains('A value of the field "country" is too long');

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        c.FirstName = 'Too long firstname Too long firstname';
        update c;
        response = PaymentHttpRequest.getPayPalUrl(order.Id, addressesObject);
        response.contains('A value of the field "first-name" is too long');

        c.FirstName = 'test';
        c.LastName = 'Too long lastname Too long lastname';
        update c;
        response = PaymentHttpRequest.getPayPalUrl(order.Id, addressesObject);
        response.contains('A value of the field "last-name" is too long');

        Test.stopTest();
    }
    @IsTest public static void getOrderInfoTest(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        Map<String, Object> orderInfo = PaymentHttpRequest.getOrderInfo(order.Id);
        List<Order__c> orders = (List<Order__c>) orderInfo.get('singleOrderInList');
        System.assertEquals(false, orders.isEmpty());
    }
    @IsTest public static void getContactAddressTestSuccess(){
        Order__c order = [SELECT Id, Contact__c FROM Order__c WHERE Contact__r.LastName = 'test'];
        String result = PaymentHttpRequest.getContactAddress(order.Id);
        System.assertEquals(true, result.contains(order.Contact__c));
    }
    @IsTest public static void getContactAddressTestError(){
        String result = PaymentHttpRequest.getContactAddress('orderId');
        System.assertEquals('error', result);
    }
    @IsTest public static void getCountriesTest(){
        String result = PaymentHttpRequest.getCountries();
        System.assertEquals(true, result.contains('Austria'));
    }
    @IsTest public static void determineSuccessScreenTest(){
        Membership__c membership = new Membership__c(Name = 'Test1', API__c = 'test1');
        insert membership;
        Order__c order = [SELECT Id, Contact__c FROM Order__c WHERE Contact__r.LastName = 'test'];
        System.assertEquals('ORDER', PaymentHttpRequest.determineSuccessScreen(order.Id).get('type'));
        order.Type__c = 'Event registration';
        update order;
        System.assertEquals('EVENT_REGISTRATION', PaymentHttpRequest.determineSuccessScreen(order.Id).get('type'));
        Application_form__c appForm = new Application_form__c(
                First_name__c = 'test', Last_name__c = 'testlast', Date_of_birth__c = Date.today(),
                Gender__c = 'Male', Email__c = 'email@email.com', Nationality__c = 'United States',
                Residency__c = 'United States', ZIP_Postal_code__c = '111', City__c = 'Test', Contact__c = order.Contact__c, Membership__c = membership.Id,
                Profession__c = 'Other', Street__c = '123Street', Form_Status__c = 'Draft', Order__c = order.Id);
        insert appForm;
        System.assertEquals('ORDER_WITH_APP_FORM', PaymentHttpRequest.determineSuccessScreen(order.Id).get('type'));
    }
    @IsTest public static void generateBankCredsPdfDownloadLinkTest(){
        Order__c order = [SELECT Id FROM Order__c WHERE Contact__r.LastName = 'test'];
        String link = PaymentHttpRequest.generateBankCredsPdfDownloadLink(order.Id);
        System.assert(link.contains('/sfc/servlet.shepherd/document/download/'));
        List<ContentVersion> certificates = [SELECT Id FROM ContentVersion WHERE Title LIKE 'EAN_Bank_Cred%'];
        System.assertEquals(1, certificates.size());
    }
    @IsTest public static void createLogTest(){
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'test'];
        Order__c order = [SELECT Id, Total_amount__c FROM Order__c WHERE Contact__c = :c.Id];
        Log__c log = new Log__c(Process_Name__c = 'REST: Test', Order__c=order.Id, Type__c='REST');
        PaymentHttpRequest.createLogAuraEnabled(JSON.serialize(log), '', '{"payment":{"card-token":{"token-id":"1234567890"}}}', Datetime.now(), 500);
        log = [SELECT Id, Message__c FROM Log__c WHERE Order__c = :order.Id LIMIT 1];
        System.assert(log.Message__c.contains('XXXXXXXX'));
    }
    @IsTest public static void insertLogTest(){
        String log = JSON.serialize(new Log__c(Process_Name__c = 'Visualforce: paymentHandle page init() function', Type__c = 'Other', Message__c = 'Test', Status__c = 'Error'));
        PaymentHttpRequest.insertLogRemote(log);
        System.assertEquals(1, [SELECT Id FROM Log__c WHERE Process_Name__c = 'Visualforce: paymentHandle page init() function'].size());
    }

}