public without sharing class PaymentHttpRequest {
    public static Payment_Credentials__mdt paymentCredentials = new Payment_Credentials__mdt();
    @RemoteAction public static String cardsCheck(String orderId) {
        List<Order__c> order = [SELECT Id, Contact__c FROM Order__c WHERE Id = :orderId];
        System.debug(order);
        List<Card__c> cards = [SELECT Id, Masked_Account_Number__c FROM Card__c WHERE Contact__c = :order[0].Contact__c];
        if (cards.isEmpty()) {
            return 'none';
        } else {
            return JSON.serialize(cards);
        }
    }
    @RemoteAction public static String SeamlessURL(String orderId, String cardId, String addressesObject) {
        Map<String, Object> vfdata = new Map<String, Object>();
        Order__c orderRec = [SELECT Id, Total_amount__c, Total_Amount_Gros__c FROM Order__c WHERE Id = :orderId];
        Map<String,Object> showPaidForm = (Map<String,Object>)JSON.deserializeUntyped(showPaymentCheck(orderId));
        if (showPaidForm.get('status') == 'SUCCESS') {
            String s = getSeamlessURLBody(cardId, orderId, addressesObject);
            String seamlessUrl = getSeamlessURLHttp(s, orderId);
            vfdata.put('url', seamlessUrl);
            vfdata.put('price', orderRec.Total_Amount_Gros__c);
        }
        return JSON.serialize(vfdata);
    }
    @RemoteAction public static String showPaymentCheck(String orderId) {
        String resultString = 'SUCCESS';
        List<Order__c> order = [SELECT Id, Total_amount__c, Total_Amount_Gros__c, Status__c, Event_Registration_Sub_Group__c FROM Order__c WHERE Id = :orderId];
        List<Transaction__c> transactions = [SELECT Id, Status__c, Amount__c FROM Transaction__c WHERE Order_Custom__c = :orderId];
        List<Payment_Credentials__mdt> creds = [SELECT Id, Merchant_Account_Id__c, Merchant_PayPal_Account_Id__c, DeveloperName,
            Named_Credentials__c, Payment_Info_PayPal_Named_Credentials__c, Named_Credentials_PayPal__c FROM Payment_Credentials__mdt WHERE Active__c = true];
        Decimal paidAmount = 0;
        Boolean isGroup;
        if (!creds.isEmpty() && !order.isEmpty() && order[0].Status__c == 'Opened') {
            isGroup = !String.isBlank(order[0].Event_Registration_Sub_Group__c);
            choosePaymentCredentials(creds);
            for (Transaction__c trnsaction : transactions) {
                if (trnsaction.Status__c == 'Success') {
                    paidAmount += trnsaction.Amount__c;
                }
                if (trnsaction.Status__c == 'Refund') {
                    resultString = 'ERROR';
                }
            }
            if (order[0].Total_Amount_Gros__c == paidAmount) {
                if(order[0].Total_Amount_Gros__c == 0){
                    resultString = 'ZERO_PAYMENT';
                }else{
                    resultString = 'PAID';
                }
            }
        } else if(!creds.isEmpty() && !order.isEmpty() && (order[0].Status__c == 'Paid' || order[0].Status__c == 'Closed')){
            resultString = 'PAID';
        } else {
            resultString = 'ERROR';
        }
        if(resultString == 'ERROR'){
            String message = 'resultString='+resultString;
            message += '\n'+'orderId: '+orderId;
            message += '\n'+'order: '+JSON.serialize(order);
            message += '\n'+'creds isEmpty?: '+JSON.serialize(creds.isEmpty());
            insert new Log__c(
                Process_Name__c = 'Apex: PaymentHttpRequest.showPaymentCheck()',
                Order__c=orderId, Type__c='Other', Message__c = message,
                Status__c='Success', End_Time__c = Datetime.now()
            );
        }
        return JSON.serialize(new Map<String,Object> { 'status' => resultString, 'isGroup' => isGroup });
    }

    public static void choosePaymentCredentials(List<Payment_Credentials__mdt> creds) {

        if (creds.size() == 0) {
            creds = [SELECT Id, Merchant_Account_Id__c, Merchant_PayPal_Account_Id__c, DeveloperName, Named_Credentials__c,
                Payment_Info_PayPal_Named_Credentials__c, Named_Credentials_Base__c FROM Payment_Credentials__mdt WHERE Active__c = true];
        }

        if (creds.size() >= 2) {
            for (Payment_Credentials__mdt pc : creds) {
                if (pc.DeveloperName == 'Test_Seamless') {
                    paymentCredentials = pc;
                }
            }
        } else if (creds.size() == 1) {
            paymentCredentials = creds[0];
        }
    }
    @RemoteAction public static void createTransaction(Transaction__c newTransaction) {
        OrderUtils.createTransaction(newTransaction);
    }
    public static String getSeamlessURLHttp(String body, String orderId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + paymentCredentials.Named_Credentials__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(body);
        HttpResponse response = http.send(request);
        Log__c log = new Log__c(Process_Name__c = 'REST: Payment getSeamlessURLHttp()', Order__c=orderId, Type__c='REST');
        createLog(log, body, response.getBody(), Datetime.now(), response.getStatusCode());
        return ((Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class)).get('payment-redirect-url');
    }
    public static String getSeamlessURLBody(String cardId, String orderId, String addressesObject) {
        List<Card__c> card = [SELECT Id, Token_Id__c FROM Card__c WHERE Id = :cardId];
        List<Order__c> order = [SELECT Id, Total_amount__c, Total_Amount_Gros__c, VAT_Amount__c, Name, Contact__r.FirstName, Contact__r.LastName FROM Order__c WHERE Id = :orderId];
        List<Order_Item__c> orderItem = [
            SELECT Id, Amount__c, Name__c, Product__c, Membership__c, Membership__r.Name, Product__r.Name, Name, Quantity__c, Total_amount__c,
                Event_Participation__r.Event_Ticket__r.Ticket__c, Event_Participation__r.Event_Ticket__r.Ticket__r.Name, Session_Participation__r.Session__r.Name
            FROM Order_Item__c
            WHERE Order_Custom__c = :orderId
        ];
        List<Map<String, Object>> m = new List<Map<String, Object>>();
        for (Order_Item__c oi : orderItem) {
            m.add(new Map<String, Object>{
                    'amount' => new Map<String, Object>{
                            'currency' => 'EUR', 'value' => oi.Amount__c
                    },
                    'article-number' => oi.Name,
                    'name' => !String.isBlank(oi.Name__c) ? oi.Name__c : 'undefined name',
                    'quantity' => oi.Quantity__c
            });
        }

        if(order[0].VAT_Amount__c != null && order[0].VAT_Amount__c >= 0){
            m.add(new Map<String, Object>{
                    'amount' => new Map<String, Object>{
                            'currency' => 'EUR', 'value' => order[0].VAT_Amount__c
                    },
                    'name' => 'Tax',
                    'quantity' => 1
            });
        }

        List<Map<String, String>> addresses = parseAddresses(addressesObject);
        Map<String, String> shippingAddress = addresses[0];
        Map<String, String> billingAddress = addresses[1];
        String paymentMethod = 'creditcard';
        String requestId = getUUID();
        String merchantAccountId;
        merchantAccountId = paymentCredentials.Merchant_Account_Id__c;
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('payment');
        gen.writeStartObject();
        gen.writeFieldName('merchant-account-id');
        gen.writeStartObject();
        System.debug('merchantAccountId:: ' + merchantAccountId);
        gen.writeStringField('value', merchantAccountId);
        gen.writeEndObject();
        gen.writeStringField('request-id', requestId);
        gen.writeStringField('transaction-type', 'purchase');
        gen.writeFieldName('requested-amount');
        gen.writeStartObject();
        gen.writeStringField('currency', 'EUR');
        gen.writeNumberField('value', order[0].Total_Amount_Gros__c);
        gen.writeEndObject();
        gen.writeFieldName('payment-methods');
        gen.writeStartObject();
        gen.writeObjectField('payment-method', new List<Map<String, String>>{
                new Map<String, String>{
                        'name' => paymentMethod
                }
        });
        gen.writeEndObject();

        if (!card.isEmpty()) {
            gen.writeFieldName('card-token');
            gen.writeStartObject();
            gen.writeObjectField('token-id', card[0].Token_Id__c);
            gen.writeEndObject();
        }

        gen.writeStringField('order-number', order[0].Name);

        gen.writeFieldName('account-holder');
        gen.writeStartObject();
        gen.writeObjectField('address', billingAddress);
        gen.writeEndObject();

        gen.writeFieldName('shipping');
        gen.writeStartObject();
        gen.writeStringField('first-name', order[0].Contact__r.FirstName);
        gen.writeStringField('last-name', order[0].Contact__r.LastName);
        gen.writeObjectField('address', shippingAddress);
        gen.writeEndObject();


        gen.writeFieldName('order-items');
        gen.writeStartObject();
        gen.writeObjectField('order-item', m);
        gen.writeEndObject();

        gen.writeFieldName('three-d');
        gen.writeStartObject();
        gen.writeObjectField('attempt-three-d', false);
        gen.writeEndObject();

        gen.writeFieldName('custom-fields');
        gen.writeStartObject();
        gen.writeObjectField('custom-field', new List<Map<String, Object>>{new Map<String, Object>{'field-name'=>'salesforce-order-id', 'field-value'=>order[0].Id}});
        gen.writeEndObject();

        gen.writeEndObject();
        gen.writeFieldName('options');
        gen.writeStartObject();
        gen.writeStringField('mode', 'seamless');
        gen.writeStringField('frame-ancestor', URL.getSalesforceBaseUrl().toExternalForm());
        gen.writeEndObject();
        String body = gen.getAsString();
        System.debug('body:: ' + body);
        return body;
    }
    @RemoteAction public static void saveCard(String cardDataString) {
        Map<String, Object> cardDataMap = (Map<String, Object>) JSON.deserializeUntyped(cardDataString);
        List<Order__c> orders = [SELECT Id, Contact__c FROM Order__c WHERE Id = :cardDataMap.get('OrderId').toString()];
        List<Card__c> cards = [SELECT Id, Token_Id__c FROM Card__c WHERE Contact__c = :orders[0].Contact__c];
        if (!orders.isEmpty()) {
            Boolean isFound = false;
            for (Card__c c : cards) {
                if (c.Token_Id__c == cardDataMap.get('Token_Id__c').toString()) {
                    isFound = true;
                }
            }
            if (!isFound) {
                String maskedNumber = cardDataMap.get('Masked_Account_Number__c').toString();
                maskedNumber = '******' + maskedNumber.substring(6, maskedNumber.length());
                Card__c cardData = new Card__c(Contact__c = orders[0].Contact__c, Token_Id__c = cardDataMap.get('Token_Id__c').toString(), Masked_Account_Number__c = maskedNumber);
                insert cardData;
            }
        }
    }

    public static String getUUID() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0, 8) + '-' + h.SubString(8, 12) + '-' + h.SubString(12, 16) + '-' + h.SubString(16, 20) + '-' + h.substring(20);
        return guid;
    }

    @RemoteAction public static String getOrderItems(String orderId) {
        List<Order__c> order = [SELECT Id, Total_amount__c, Total_Amount_Gros__c, VAT_Amount__c, Name FROM Order__c WHERE Id = :orderId];
        List<Order_Item__c> orderItems = [
            SELECT Id, Amount__c, Name__c, Product__c, Membership__c, Membership__r.Name, Product__r.Name, Name, Quantity__c, Total_amount__c,
                Event_Participation__r.Event_Ticket__r.Ticket__c, Event_Participation__r.Event_Ticket__r.Ticket__r.Name, Session_Participation__r.Session__r.Name
            FROM Order_Item__c
            WHERE Order_Custom__c = :order[0].Id
        ];
        System.debug('orderItems:: ' + orderItems);
        List<Map<String, Object>> orderItemsMap = new List<Map<String, Object>>();
        for (Order_Item__c oi : orderItems) {
            orderItemsMap.add(new Map<String, Object>{
                    'product' => !String.isBlank(oi.Name__c) ? oi.Name__c : 'undefined name',
                    'quantity' => oi.Quantity__c,
                    'amount' => oi.Amount__c,
                    'total-amount' => oi.Total_amount__c
            });
        }
        System.debug('orderItemsMap:: ' + orderItemsMap);
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('total-amount', order[0].Total_Amount_Gros__c);
        resultMap.put('VAT-amount-total', order[0].VAT_Amount__c);
        resultMap.put('name', order[0].Name);
        resultMap.put('order-items', orderItemsMap);
        return JSON.serialize(resultMap);
    }
    @AuraEnabled public static String getPaymentInfoByRequestId(String requestId, String orderId) {
        List<Payment_Credentials__mdt> creds = [SELECT Id, Merchant_Account_Id__c, Merchant_PayPal_Account_Id__c, DeveloperName, Named_Credentials__c,
            Payment_Info_PayPal_Named_Credentials__c FROM Payment_Credentials__mdt WHERE Active__c = true];
        choosePaymentCredentials(creds);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + paymentCredentials.Payment_Info_PayPal_Named_Credentials__c + '?payment.request-id=' + requestId);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        HttpResponse response = http.send(request);
        String result = parsePaymentInfoAndCreateTransaction(response.getBody(), orderId, requestId);
        insert new Log__c(Process_Name__c = 'REST: Payment getPaymentInfoByRequestId()', Order__c=orderId, Type__c='REST', Message__c = 'getPaymentInfoByRequestId response:\n'+response+'\n\nBody: '+response.getBody()+'\n\nrequest-id:'+requestId);
        return result;
    }
    public static String parsePaymentInfoAndCreateTransaction(String response, String orderCustom, String requestId) {
        String message = 'Page invalid anymore.';
        try {
            List<Transaction__c> trs = [SELECT Id, JSONResponse__c FROM Transaction__c WHERE Order_Custom__c = :orderCustom];
            System.debug('trs:: '+trs);
            Boolean foundFlag = false;
            for (Transaction__c tr : trs) {
                if (tr.JSONResponse__c == response) {
                    foundFlag = true;
                }
            }
            Transaction__c tr = new Transaction__c();
            System.debug('foundFlag:: '+foundFlag);
            if (!foundFlag) {
                Object payment = ((Map<String, Object>) JSON.deserializeUntyped(response)).get('payment');
                Object requestedAmount = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('requested-amount');
                tr.Amount__c = (Decimal) ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(requestedAmount))).get('value');
                Object completionTimeStamp = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('completion-time-stamp');
                tr.Completion_Time_Stamp__c = Datetime.newInstance((Long) (completionTimeStamp));
                tr.Request_Id__c = (String) ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('request-id');
                tr.Reference_Id__c = (String) ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('transaction-id');
                tr.JSONResponse__c = response;
                tr.Order_Custom__c = orderCustom;
                Object statuses = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('statuses');
                Object status = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statuses))).get('status');
                List<Object> statusList = ((List<Object>) JSON.deserializeUntyped(JSON.serialize(status)));
                Object statusCode = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statusList[0]))).get('code');
                tr.Status__c = Decimal.valueOf((String) statusCode) == 201 ? 'Success' : 'Error';
                Object paymentMethods = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('payment-methods');
                Object paymentMethod = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethods))).get('payment-method');
                List<Object> paymentMethodList = ((List<Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethod)));
                Object name = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethodList[0]))).get('name');
                tr.Payment_Method__c = String.valueOf(name);
                OrderUtils.createTransaction(tr);
                return tr.Status__c;
            } else {
                throw new AuraException(message);
            }
        } catch (Exception e) {
            System.debug('In Catch');
            if (e.getMessage() != message) {
                return 'Something went wrong, please, contact your system administrator.';
            } else {
                return message;
            }
        }
    }

    @RemoteAction public static String getPayPalUrl(String orderId, String addressesObject) {
        List<Payment_Credentials__mdt> creds = [SELECT Id, Merchant_Account_Id__c, Merchant_PayPal_Account_Id__c, DeveloperName,
            Named_Credentials__c, Payment_Info_PayPal_Named_Credentials__c, Named_Credentials_PayPal__c FROM Payment_Credentials__mdt WHERE Active__c = true];
        choosePaymentCredentials(creds);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + paymentCredentials.Named_Credentials_PayPal__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        String requestBody = getPayPalUrlBody(orderId, addressesObject);
        request.setBody(requestBody);
        HttpResponse response = http.send(request);
        Log__c log = new Log__c(Process_Name__c = 'REST: Payment getPayPalUrl()', Order__c=orderId, Type__c='REST');
        createLog(log, requestBody, response.getBody(), Datetime.now(), 500);
        return handlePayPalUrlResponse(response.getBody());
    }

    @AuraEnabled public static void createLogAuraEnabled(String log, String request, String response, Datetime endTime, Decimal statusCode){
        Log__c logSobject = (Log__c) JSON.deserialize(log, Log__c.class);
        createLog(logSobject, request, response, endTime, statusCode);
    }

    @RemoteAction public static void createLog(Log__c log, String request, String response, Datetime endTime, Decimal statusCode){
        System.debug('createLog');
        log.Status__c = statusCode==200||statusCode==201||statusCode==202?'Success':'Error';
        if (log.Status__c == 'Error') {
            log.End_Time__c = endTime;
            request = request.replace('\n', '');
            response = response.replace('\n', '');
            log.Message__c = log.Message__c == null ? '' : log.Message__c;
            List<String> jsons = new List<String>{request, response};

            for (Integer i = 0; i < jsons.size(); i++) {

                if (jsons[i].contains('token-id') && jsons[i].contains('card-token')) {

                    if (((Map<String, Object>) JSON.deserializeUntyped(jsons[i])).containsKey('payment')) {

                        Object payment = ((Map<String, Object>) JSON.deserializeUntyped(jsons[i])).get('payment');

                        if (((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).containsKey('card-token') && payment != null) {

                            Object cardToken = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('card-token');

                            if (((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cardToken))).containsKey('token-id') && cardToken != null) {

                                Object tokenId = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cardToken))).get('token-id');
                                String token = (String) tokenId;
                                jsons[i] = jsons[i].replace(token, 'XXXXXXXX');
                            }
                        }
                    }
                }
            }

            log.Message__c += 'REQUEST:' + '\n' + jsons[0];
            log.Message__c += '\n\n' + 'RESPONSE:' + '\n' + jsons[1];
            insert log;
        }
    }

    @AuraEnabled public static void insertLog(String log){
        Log__c logSobject = (Log__c) JSON.deserialize(log, Log__c.class);
        insert logSobject;
    }

    @RemoteAction public static void insertLogRemote(String log){
        insertLog(log);
    }

    public static String getPayPalUrlBody(String orderId, String addressesObject) {
        String communityOriginURL = getCommunityOriginUrl('Community');
        String communityURL = getCommunityHomeUrl();
        List<Order__c> order = [
                SELECT Id, Total_amount__c, Total_Amount_Gros__c, Name, Contact__r.FirstName, Contact__r.LastName, VAT_Amount__c
                FROM Order__c
                WHERE Id = :orderId
        ];

        List<Order_Item__c> orderItem = [
            SELECT Id, Amount__c, Name__c, Product__c, Membership__c, Membership__r.Name, Product__r.Name, Name, Quantity__c, Total_amount__c,
                Event_Participation__r.Event_Ticket__r.Ticket__c, Event_Participation__r.Event_Ticket__r.Ticket__r.Name
            FROM Order_Item__c
            WHERE Order_Custom__c = :orderId
        ];

        List<Map<String, Object>> orderItems = new List<Map<String, Object>>();
        for (Order_Item__c oi : orderItem) {
            orderItems.add(new Map<String, Object>{
                    'amount' => new Map<String, Object>{
                            'currency' => 'EUR', 'value' => oi.Amount__c
                    },
                    'article-number' => oi.Name,
                    'name' => !String.isBlank(oi.Name__c) ? oi.Name__c : 'undefined name',
                    'quantity' => oi.Quantity__c
            });
        }

        if(order[0].VAT_Amount__c != null && order[0].VAT_Amount__c >= 0){
            orderItems.add(new Map<String, Object>{
                    'amount' => new Map<String, Object>{
                            'currency' => 'EUR', 'value' => order[0].VAT_Amount__c
                    },
                    'name' => 'Tax',
                    'quantity' => 1
            });
        }

        List<Map<String, String>> addresses = parseAddresses(addressesObject);
        Map<String, String> shippingAddress = addresses[0];
        Map<String, String> billingAddress = addresses[1];

        String paymentMethod = 'paypal';
        String requestId = getUUID();
        String merchantAccountId = paymentCredentials.Merchant_PayPal_Account_Id__c;
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('payment');
        gen.writeStartObject();
        gen.writeFieldName('merchant-account-id');
        gen.writeStartObject();
        gen.writeStringField('value', merchantAccountId);
        gen.writeEndObject();
        gen.writeStringField('request-id', requestId);
        gen.writeStringField('transaction-type', 'debit');
        gen.writeFieldName('requested-amount');
        gen.writeStartObject();
        gen.writeStringField('currency', 'EUR');
        gen.writeNumberField('value', order[0].Total_Amount_Gros__c);
        gen.writeEndObject();
        gen.writeFieldName('payment-methods');
        gen.writeStartObject();
        gen.writeObjectField('payment-method', new List<Map<String, String>>{
                new Map<String, String>{
                        'name' => paymentMethod
                }
        });
        gen.writeEndObject();
        gen.writeStringField('order-number', order[0].Name);

        gen.writeFieldName('account-holder');
        gen.writeStartObject();
        gen.writeObjectField('address', billingAddress);
        gen.writeEndObject();

        gen.writeFieldName('shipping');
        gen.writeStartObject();
        gen.writeStringField('first-name', order[0].Contact__r.FirstName);
        gen.writeStringField('last-name', order[0].Contact__r.LastName);
        gen.writeObjectField('address', shippingAddress);
        gen.writeEndObject();

        gen.writeFieldName('order-items');
        gen.writeStartObject();
        gen.writeObjectField('order-item', orderItems);
        gen.writeEndObject();
        gen.writeStringField('success-redirect-url', communityOriginURL + '/s/payment-redirect' + '?oi=' + orderId + '&ri=' + requestId);
        gen.writeStringField('fail-redirect-url', communityOriginURL + '/s/payment-redirect' + '?oi=' + orderId + '&ri=' + requestId);
        gen.writeStringField('cancel-redirect-url', communityURL + '/s/');

        gen.writeFieldName('custom-fields');
        gen.writeStartObject();
        gen.writeObjectField('custom-field', new List<Map<String, Object>>{new Map<String, Object>{'field-name'=>'salesforce-order-id', 'field-value'=>order[0].Id}});
        gen.writeEndObject();

        gen.writeEndObject();
        String body = gen.getAsString();
        return body;
    }
    public static String handlePayPalUrlResponse(String body) {
        String returnStatement = 'error';
        Object payment = ((Map<String, Object>) JSON.deserializeUntyped(body)).get('payment');
        Object statuses = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('statuses');
        Object status = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statuses))).get('status');
        List<Object> statusList = ((List<Object>) JSON.deserializeUntyped(JSON.serialize(status)));
        Object statusCode = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statusList[0]))).get('code');
        if (Decimal.valueOf((String) statusCode) == 201) {
            Object paymentMethods = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payment))).get('payment-methods');
            Object paymentMethod = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethods))).get('payment-method');
            List<Object> paymentMethodList = ((List<Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethod)));
            Object name = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethodList[0]))).get('name');
            if (name == 'paypal') {
                Object url = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethodList[0]))).get('url');
                returnStatement = String.valueOf(url);
            }
            return returnStatement;
        } else {
            return returnStatement;
        }
    }
    // @RemoteAction public static List<Order__c> getOrderInfo(String orderId) {
    //     List<Order__c> order = [SELECT Id, Name, Contact__r.FirstName, Contact__r.LastName, Invoice_Number__c, Total_amount__c, Payment_Method__c, CreatedDate FROM Order__c WHERE Id = :orderId];
    //     return order;
    // }
    //  'Membership Renewal' updates

    @RemoteAction public static Map<String, Object> getOrderInfo(String orderId) {
        return getOrderInfoUpdated(orderId, true);
    }

    public static Map<String, Object> getOrderInfoUpdated(String orderId, Boolean insertEmailActivityForRenewal) {
        Map<String, Object> result = new Map<String, Object>();
        List<Order__c> order = [
            SELECT Id, Name, Contact__c, Contact__r.Email, Contact__r.FirstName, Contact__r.LastName, Invoice_Number__c,
                Total_amount__c, Payment_Method__c, CreatedDate, Type__c, Total_Amount_Gros__c
            FROM Order__c
            WHERE Id = :orderId
        ];
        String nextYearString = System.now().addYears(1).format('YYYY');
        String orderType = !order.isEmpty() && !String.isBlank(order[0].Type__c) ? order[0].Type__c : '';
        result.put('singleOrderInList', order);
        result.put('nextYearString', nextYearString);
        result.put('orderType', orderType);

        if (orderType == 'Renewal' && insertEmailActivityForRenewal && !order.isEmpty() && order[0].Contact__c != null && order[0].Total_Amount_Gros__c != 0) {
            List<Email_Activity__c> existingEmailActivity = [SELECT Id FROM Email_Activity__c WHERE Contact__c =:order[0].Contact__c AND Order__c =:order[0].Id LIMIT 1];
            if (!existingEmailActivity.isEmpty()) return result;
            insert new Email_Activity__c(
                Contact__c = order[0].Contact__c,
                Order__c = order[0].Id,
                // Email_Sent__c = !String.isBlank(order[0].Contact__r.Email),
                Send_To_Email__c = order[0].Contact__r.Email,
                Type__c = 'Membership Renewal Bank Transfer Payment Pending'
            );
        }

        return result;
    }

    @RemoteAction public static void updatePaymentMethodForOrder(String orderId, String method) {
        try {
            String paymentMethod = method == 'card-method' ? 'creditcard' :
                method == 'paypal-method' ? 'paypal' :
                method == 'bank-transfer-method'? 'Bank Transfer' :  '';

            update new Order__c(Id = orderId, Payment_Method__c = paymentMethod);
        } catch (Exception e) {
            System.debug('catch ' + e.getMessage());
        }
    }

    @AuraEnabled public static String getCommunityHomeUrlAuraEnabled(){
        if([SELECT Id, IsSandbox, Name FROM Organization LIMIT 1].IsSandbox){
            return getCommunityOriginUrl('Community');
        } else {
            return getCommunityOriginUrl('SitesRuntime');
        }
    }
    @RemoteAction public static String getCommunityHomeUrl() {
        String result;
        if (!Test.isRunningTest()) {
            Network myNetwork = [SELECT Id FROM Network WHERE Name = 'ean'];
            ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork.Id);
            result = myCommunity.siteUrl;
        }else {
            result = 'community.com';
        }
        return result;
    }
    public static String getCommunityOriginUrl(String param){
        String domain = [SELECT Domain, HttpsOption FROM Domain WHERE HttpsOption = :param LIMIT 1].Domain;
        String communityPrefix = [SELECT UrlPathPrefix FROM Network WHERE Name = 'ean' LIMIT 1].UrlPathPrefix;
        String communityUrl = 'https://'+domain;
        if(communityPrefix != null){
            communityUrl += '/'+communityPrefix;
        }
        return communityUrl;
    }
    @RemoteAction public static String getContactAddress(String orderId) {
        List<Order__c> order = [SELECT Id, Contact__c FROM Order__c WHERE Id = :orderId];
        if (!order.isEmpty()) {
            //old implementation
//            List<Contact> contact = [
//                    SELECT Id, Mailing_address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
//                            OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Primary_Workplace__r.ShippingStreet,
//                            Primary_Workplace__r.ShippingCity, Primary_Workplace__r.ShippingState, Primary_Workplace__r.ShippingPostalCode,
//                            Primary_Workplace__r.ShippingCountry, Residency__c
//                    FROM Contact
//                    WHERE Id = :order[0].Contact__c
//            ];
            List<Contact> contact = [
                    SELECT Id, Mailing_address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                            OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Work_Zip_Postal_Code__c,
                            Work_Street__c, Work_State_Province__c, Work_Country__c, Work_City__c, Residency__c
                    FROM Contact
                    WHERE Id = :order[0].Contact__c
            ];
            if (!contact.isEmpty()) {
                return JSON.serialize(contact[0]);
            } else {
                return 'error';
            }
        } else {
            return 'error';
        }
    }

    @RemoteAction public static String getCountries() {
        List<Country__mdt> countries = [SELECT Id, Country__c, Country_code__c FROM Country__mdt ORDER BY Country__c ASC];
        return JSON.serialize(countries);
    }

    public static List<Map<String, String>> parseAddresses(String addressesObject) {
        Map<String, Object> addressesMap = (Map<String, Object>) JSON.deserializeUntyped(addressesObject);
        List<Map<String, String>> result = new List<Map<String, String>>();
        result.add(new Map<String, String>{
                'street1' => (String) addressesMap.get('mailing-street'),
                'city' => (String) addressesMap.get('mailing-city'),
                'state' => (String) addressesMap.get('mailing-state'),
                'country' => (String) addressesMap.get('mailing-country'),
                'postal-code' => (String) addressesMap.get('mailing-code')
        });
        result.add(new Map<String, String>{
                'street1' => (String) addressesMap.get('billing-street'),
                'city' => (String) addressesMap.get('billing-city'),
                'state' => (String) addressesMap.get('billing-state'),
                'country' => (String) addressesMap.get('billing-country'),
                'postal-code' => (String) addressesMap.get('billing-code')
        });
        return result;
    }

    @RemoteAction public static Map<String, Object> determineSuccessScreen(String orderId){
        return OrderUtils.determineSuccessScreen(orderId);
    }

    @RemoteAction public static String generateBankCredsPdfDownloadLink(String orderId){

        //  'Membership Renewal' updates
        Map<String, Object> orderInfo = getOrderInfoUpdated(orderId, false);   //  false == do not insert new Email_Activity record
        List<Order__c> order = (List<Order__c>) orderInfo.get('singleOrderInList');
        String nextYearString = String.valueOf(orderInfo.get('nextYearString'));
        String orderType = String.valueOf(orderInfo.get('orderType'));

        String attachmentLink = 'javascript:void(0);';
        if(!order.isEmpty()){
            // Boolean isTypeOc = order[0].Invoice_Number__c != null && order[0].Invoice_Number__c.contains( 'EAN' + String.valueOf(Date.today().year()).right(2) + '-OC');
            //  https://jira.towa-digital.com/browse/EANER-19   use EAN21-F-#### (= Invoice Number) 
            Boolean isTypeOc = order[0].Invoice_Number__c != null && order[0].Invoice_Number__c.contains( 'EAN' + String.valueOf(Date.today().year()).right(2) + '-F');
            String template = isTypeOc ? 'BankTransferRegistrationPdf' : 'BankTransferCredentialsPdf';
            if (orderType == 'Renewal') template = 'BankTransferRenewalCredentialsPdf';
            PageReference defaultPage = new PageReference('/apex/' + template);

            defaultPage.getParameters().put('orderName', order[0].Name);
            defaultPage.getParameters().put('orderInvoiceNumber', order[0].Invoice_Number__c);
            defaultPage.getParameters().put('orderAmount', String.valueOf(order[0].Total_Amount_Gros__c));
            defaultPage.getParameters().put('firstName', String.valueOf(order[0].Contact__r.FirstName));
            defaultPage.getParameters().put('lastName', String.valueOf(order[0].Contact__r.LastName));
            String orderDeadline= order[0].CreatedDate.addDays(7).format('MM.dd.yyyy');
            defaultPage.getParameters().put('orderDeadline', orderDeadline);

            //  'Membership Renewal' updates
            defaultPage.getParameters().put('nextYearString', nextYearString);
            defaultPage.getParameters().put('orderType', orderType);

            Blob pageData;
            if (Test.isRunningTest()) {
                pageData = Blob.valueOf('Unit.Test');
            } else {
                pageData = defaultPage.getContent();
            }
            ContentVersion newCredsPage = new ContentVersion(
                    VersionData = pageData,
                    Title = 'EAN_Bank_Credentials.pdf',
                    PathOnClient = '/EAN_Bank_Credentials.pdf',
                    IsMajorVersion = true,
                    SharingPrivacy = 'N',
                    ContentLocation = 'S'
            );
            insert newCredsPage;
            List<ContentVersion> attachments  = [
                    SELECT Id, ContentDocumentId FROM ContentVersion
                    WHERE Id = :newCredsPage.Id
            ];
            String communityUrl='';
            if(Test.isRunningTest()){
                communityUrl = 'community.com';
            } else{
                Network myNetwork = [SELECT Id FROM Network WHERE Name = 'ean'];
                ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
                communityUrl = myCommunity.siteUrl;
            }

            if (!attachments.isEmpty()) {
                attachmentLink = communityUrl
                        + '/sfc/servlet.shepherd/document/download/'
                        + attachments[0].ContentDocumentId;
            }
        }
        return attachmentLink;
    }

    @RemoteAction public static void writeOrderBillingAddress(String orderId, String addressesObject){
        OrderUtils.writeOrderBillingAddress(orderId, addressesObject);
    }

    public static Map<String, String> refundTransaction(String orderRefunedId, String orderCancelledId, Decimal amount) {
        Transaction__c tr = new Transaction__c();
        try {
            List<Order__c> ords = [
                SELECT Id, Status__c,
                    (
                        SELECT Id, Amount__c, Status__c, Payment_Method__c, Request_Id__c, Reference_Id__c
                        FROM Transactions__r
                        WHERE Status__c = 'Success'
                    )
                FROM Order__c WHERE Id = :orderRefunedId
            ];

            if (ords.size() == 0 || ords[0].Transactions__r.size() == 0 || String.isBlank(ords[0].Transactions__r[0].Payment_Method__c)) {
                return new Map<String, String> {
                    'status' => 'Error',
                    'message' => 'Transaction for refund not found'
                };
            }

            choosePaymentCredentials( new List<Payment_Credentials__mdt>() );

            Decimal refundAmount = amount == 0 ? ords[0].Transactions__r[0].Amount__c : amount;
            Boolean isPayPal = ords[0].Transactions__r[0].Payment_Method__c == 'paypal';
            String apiUrl = paymentCredentials.Named_Credentials_Base__c;
            String merchantAccountId = isPayPal ? paymentCredentials.Merchant_PayPal_Account_Id__c : paymentCredentials.Merchant_Account_Id__c;
            String tranType = isPayPal ? 'refund-debit' : 'refund-purchase';
            String paymentMethod = isPayPal ? 'paypal' : 'creditcard';
            String invoiceNum = 'EAN' + String.valueOf(Date.today().year()).right(2) + '-CN-%';
            Integer oIEANNumber;

            List<Transaction__c> oIEAN = [
                SELECT Refund_Invoice__c
                FROM Transaction__c
                WHERE Refund_Invoice__c != NULL AND Refund_Invoice__c LIKE :invoiceNum
                ORDER BY Refund_Invoice__c DESC
                LIMIT 10
            ];

            if (oIEAN.isEmpty()) { invoiceNum = invoiceNum.substring(0,invoiceNum.length()-1) + '000001'; }
            if (!oIEAN.isEmpty()) {
                for (Transaction__c o : oIEAN) {
                    String invoiceNumb = o.Refund_Invoice__c.right(6);
                    if (invoiceNumb.isNumeric()) {
                        oIEANNumber = Integer.valueOf(invoiceNumb);
                        break;
                    }
                }

                oIEANNumber++;

				String oIEANStr = String.valueOf(oIEANNumber);
				while (oIEANStr.length() < 6) {
					oIEANNumber++;
					oIEANStr = '0' + oIEANStr;
				}

				invoiceNum = invoiceNum.substring(0,invoiceNum.length()-1) + oIEANStr;
            }

            if (ords[0].Transactions__r[0].Payment_Method__c == 'Bank Transfer') {
                tr = new Transaction__c();
                tr.Amount__c = (-1) * refundAmount;
                tr.Order_Custom__c = orderCancelledId;
                tr.Completion_Time_Stamp__c = Datetime.now();
                tr.Status__c = 'Refund';
                tr.Payment_Method__c = 'Bank Transfer';
                tr.Refund_Invoice__c = invoiceNum;

                insert tr;

                return new Map<String, String> {
                    'status' => 'Success',
                    'id' => String.valueOf(tr.Id)
                };
            }

            String requestBody = JSON.serialize( new Map<String,Object> {
                'payment' => new Map<String,Object> {
                    'merchant-account-id' => new Map<String,Object> { 'value' => merchantAccountId },
                    'request-id' => getUUID(),
                    'transaction-type' => tranType,
                    'parent-transaction-id' => ords[0].Transactions__r[0].Reference_Id__c,
                    'payment-methods' => new Map<String,Object> {
                        'payment-method' => new List<Map<String,Object>>{
                            new Map<String,Object> { 'name' => paymentMethod}
                        }
                    },
                    'requested-amount' => new Map<String, Object>{
                        'currency' => 'EUR',
                        'value' => refundAmount
                    }
                }
            });
            if (String.isBlank(apiUrl)) { apiUrl = 'baseUrlWireCard_test';}
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:' + apiUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setBody(requestBody);
            HttpResponse response = http.send(request);

            Log__c log = new Log__c(Process_Name__c = 'REST: Payment Refund', Order__c = orderRefunedId, Type__c = 'REST');
            createLog(log, requestBody, response.getBody(), Datetime.now(), response.getStatusCode());

            tr = new Transaction__c();
            Map<String, Object> payments = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('payment')));
            Map<String, Object> requestedAmount = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payments.get('requested-amount')));
            tr.Amount__c = (-1) * (Decimal) requestedAmount.get('value');
            Object completionTimeStamp = payments.get('completion-time-stamp');
            tr.Completion_Time_Stamp__c = Datetime.newInstance((Long) (completionTimeStamp));
            tr.Request_Id__c = (String) payments.get('request-id');
            tr.Reference_Id__c = (String) payments.get('transaction-id');
            tr.JSONResponse__c = (response.getBody()).replaceAll(',', ',\r\n');
            tr.Order_Custom__c = orderCancelledId;
            Object statuses = payments.get('statuses');
            Object status = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statuses))).get('status');
            List<Object> statusList = ((List<Object>) JSON.deserializeUntyped(JSON.serialize(status)));
            Object statusCode = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(statusList[0]))).get('code');
            tr.Status__c = Decimal.valueOf((String) statusCode) == 201 ? 'Refund' : 'Error';
            Map<String, Object> paymentMethods = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payments.get('payment-methods')));
            List<Object> paymentMethodList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethods.get('payment-method')));
            String name = (String) ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethodList[0]))).get('name');
            tr.Payment_Method__c = String.valueOf(name);
            tr.Refund_Invoice__c = invoiceNum;

            insert tr;
            System.debug('response.getBody()' + response.getBody());

            return new Map<String, String> {
                'status' => Decimal.valueOf((String) statusCode) == 201 ? 'Success' : 'Error',
                'id' => String.valueOf(tr.Id)
            };
        }
        catch(Exception e) {
            System.debug('catch ' + e.getMessage());

            return new Map<String, String> {
                'status' => 'Error',
                'message' => e.getMessage()
            };
        }
    }
}