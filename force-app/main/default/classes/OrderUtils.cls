public without sharing class OrderUtils {
    @AuraEnabled public static String generateOrder(String ContactId, List<Object> orderItemsObject, String purchaseType) {
        System.debug('orderItemsObject:: '+orderItemsObject);
        List<Order_Item__c> orderItems = new List<Order_Item__c>();
        for (Object item : orderItemsObject) {
            Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(item));
            Order_Item__c oi = new Order_Item__c();
            for (String key : itemMap.keySet()) {
                oi.put(key, itemMap.get(key));
            }
            orderItems.add(oi);
        }
        String orderId = createOrder(ContactId, purchaseType);
        createOrderItems(orderId, orderItems);
        System.debug(orderItems);
        return orderId;
    }
    public static String createOrder(String ContactId, String purchaseType) {
        Order__c o = new Order__c(Contact__c = ContactId, Purchase_Type__c=purchaseType);
        insert o;
        return o.Id;
    }
    public static void createOrderItems(String orderId, List<Order_Item__c> orderItems) {
        for (Order_Item__c oi : orderItems) {
            oi.Order_Custom__c = orderId;
        }
        insert orderItems;
    }
    public static void createTransaction(Transaction__c newTransaction) {
        insert newTransaction;
        List<Transaction__c> trans = [SELECT Id, Status__c, Amount__c FROM Transaction__c WHERE Order_Custom__c = :newTransaction.Order_Custom__c AND Status__c = 'Success'];
        Decimal sucTransTotal = 0;
        for(Transaction__c t : trans){
            sucTransTotal += t.Amount__c;
        }
        List<Order__c> order = [SELECT Total_amount__c, Status__c, Payment_Date__c FROM Order__c WHERE Id = :newTransaction.Order_Custom__c];
        if(order[0].Total_amount__c == sucTransTotal && order[0].Status__c != 'Paid'){
            System.debug('here');
            order[0].Status__c = 'Paid';
            order[0].Payment_Date__c = Datetime.now();
            update order;
        }
    }
    @AuraEnabled public static Map<String, Object> determineSuccessScreen(String orderId){
        Map<String, Object> resultMap = new Map<String, Object>();
        String result = 'ORDER';
        List<Order__c> order = [SELECT Id, Type__c, Total_amount__c, Invoice_Number__c, Event_custom__r.www__c,
        (SELECT Id, Membership__c, Membership__r.Name FROM Applications_Forms__r LIMIT 1) FROM Order__c WHERE Id = :orderId];
        resultMap.put('order', order);

        if(!order.isEmpty()){

            if (order[0].Applications_Forms__r.isEmpty()){

                if(order[0].Type__c == 'Event registration'){
                    result = 'EVENT_REGISTRATION';
                }

            } else {
                //  part of 'Membership Renewal'
                if (order[0].Applications_Forms__r[0].Membership__c != null && order[0].Type__c == 'Renewal' &&
                        order[0].Applications_Forms__r[0].Membership__r.Name != 'Student Membership') {
                    resultMap.put('type', result);
                    return resultMap;
                }

                result+='_WITH_APP_FORM';
            }

        } else {
            result = 'ERROR';
        }

        resultMap.put('type', result);

        return resultMap;
    }
    @AuraEnabled public static void updateOrderItems(String orderId, List<Order_Item__c> orderItems){
        List<Order_Item__c> existedOrderItems = [SELECT Id FROM Order_Item__c WHERE Order_Custom__c = :orderId];
        if(!existedOrderItems.isEmpty()){
            delete existedOrderItems;
        }
        createOrderItems(orderId, orderItems);
    }
    public static void writeOrderBillingAddress(String orderId, String addressesObject){
        Map<String, Object> addressesMap = (Map<String, Object>) JSON.deserializeUntyped(addressesObject);
        List<Country__mdt> countries = [SELECT Id, Country__c, Country_code__c FROM Country__mdt ORDER BY Country__c ASC];

        String billingAddress = '';
        billingAddress += (String) addressesMap.get('billing-street') + '\n';

        String billingState = (String) addressesMap.get('billing-state');
        billingState = billingState == null ? '' : billingState;

        billingAddress += (String) addressesMap.get('billing-code') + ' ' + (String) addressesMap.get('billing-city') + ' ' + billingState + '\n';

        String billingCountry = (String) addressesMap.get('billing-country');

        for(Country__mdt country : countries){
            if(country.Country_code__c == billingCountry){
                billingCountry = country.Country__c;
                break;
            }
        }

        billingAddress += billingCountry;

        update new Order__c(Id = orderId, Billing_address__c = billingAddress);
    }
}