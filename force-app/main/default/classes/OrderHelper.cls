public without sharing class OrderHelper {

    public static List<Order__c> createNewOrder(Map<String,Object> generalData) {
        
        System.debug('createNewOrder ' + generalData);
        List<Map<String, Object>> participantsPrice = generalData.containsKey('participantsPrice') ?
                (List<Map<String, Object>>)generalData.get('participantsPrice') : new List<Map<String, Object>>();
        
        Map<String,Object> genData = generalData.containsKey('generalData') ? 
            (Map<String,Object>)generalData.get('generalData') : new Map<String,Object>();

        Map<String, Object> sessionParticipantPrice = generalData.containsKey('sessionParticipantPrice') ?
                (Map<String, Object>)generalData.get('sessionParticipantPrice') : new Map<String, Object>();
        
        String contactId = (String)genData.get('contactId');
        String eventId = (String)genData.get('eventId');
        String groupId = (String)genData.get('groupId');
        Double vatRate = Double.valueOf(genData.get('vatRate'));

        Map<Object,Object> discountInfo = genData.containsKey('discountInfo') ? 
            (Map<Object,Object>)genData.get('discountInfo') : new Map<Object,Object>();
            
        List<DiscountHelper.SessionWrapper> sessions = discountInfo.containsKey('sessions') ?
            (List<DiscountHelper.SessionWrapper>)JSON.deserialize(JSON.serialize(discountInfo.get('sessions')), List<DiscountHelper.SessionWrapper>.class) : 
            new List<DiscountHelper.SessionWrapper>();

        Map<Id, DiscountHelper.SessionWrapper> sessionMaps = new Map<Id, DiscountHelper.SessionWrapper>();
        for ( DiscountHelper.SessionWrapper s: sessions) {
            sessionMaps.put(s.id, s);
        }

        List<DiscountHelper.TicketWrapper> tickets = discountInfo.containsKey('tickets') ?
            (List<DiscountHelper.TicketWrapper>)JSON.deserialize(JSON.serialize(discountInfo.get('tickets')), List<DiscountHelper.TicketWrapper>.class) : 
            new List<DiscountHelper.TicketWrapper>();     

        Order__c o = new Order__c(
            Contact__c = contactId,
            Status__c = 'Opened',
            Event_custom__c = eventId,
            Purchase_Type__c = 'New',
            Event_Registration_Sub_Group__c = groupId,
            Type__c = 'Event registration',
            VAT_Rate__c = vatRate
        );
        System.debug('createNewOrder o ' + o);
        insert o;

        Contact updateContact;
        if (genData.containsKey('industryNews')) {
            updateContact = new Contact(Id = contactId);
            updateContact.IndustryNews__c = (Boolean)genData.get('industryNews');
        }
        if(genData.containsKey('vatNumber')){
            if(updateContact == null) updateContact = new Contact(Id = contactId);
            updateContact.VAT_Number__c = (String)genData.get('vatNumber');
        }
        if(updateContact != null){
            update updateContact;
        }

        List<Order_Item__c> ordItems = new List<Order_Item__c>();

        for(Integer i = 0; i < participantsPrice.size(); i++) {
            ordItems.add( new Order_Item__c(
                Order_Custom__c = o.Id,
                Amount__c = (Decimal)participantsPrice[i].get('price'),
                Quantity__c = 1,
                Event_Participation__c = (Id)((Participant__c)participantsPrice[i].get('participant')).get('Id'),
                Discount__c = !tickets.isEmpty() ? tickets[0].discountId : null,
                Discount_Amount__c = !tickets.isEmpty() && tickets[0].discountAmount != null ? (-1) * tickets[0].discountAmount : 0
            ));
        }

        System.debug('ordItems: '+ordItems);

        if(sessionParticipantPrice != null && !sessionParticipantPrice.isEmpty()){

            for (String sessionPartId : sessionParticipantPrice.keySet()) {
                Map<String, Object> sessionPart = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(sessionParticipantPrice.get(sessionPartId))); 
                String sessionId = String.valueOf(sessionPart.get('id'));
                ordItems.add( new Order_Item__c(
                        Order_Custom__c = o.Id,
                        Amount__c = (Decimal)sessionPart.get('price'),
                        Quantity__c = 1,
                        Session_Participation__c = sessionPartId,
                        Discount__c = sessionMaps.containsKey(sessionId) ? sessionMaps.get(sessionId).discountId : null,
                        Discount_Amount__c = sessionMaps.containsKey(sessionId) && sessionMaps.get(sessionId).discountAmount != null ? (-1) * sessionMaps.get(sessionId).discountAmount : 0
                ));
            }

        }

        System.debug('createNewOrder ordItems ' + ordItems);

        insert ordItems;
        
        return new List<Order__c>{o};

    }

    public static void cancelledOrder(Map<Id, Id> ordToChanges) { System.debug('cancelledOrder method expired'); }

    @future(callout=true)
	public static void refundTransaction(String orderRefunedId, String orderCancelledId) {
        Map<String, String> resMap = PaymentHttpRequest.refundTransaction(orderRefunedId, orderCancelledId, 0);
    }

    @AuraEnabled
    public static Map<String, Object> getSoloParticipatCommunityButtonsInitData(Id participantId) {
        List<Participant__c> participants = [SELECT Id, Event_custom__c, (SELECT Id, Order_Custom__c, Order_Custom__r.Status__c FROM Order_Items__r) FROM Participant__c WHERE Id = :participantId];
		if (participants.size() > 0) {
            String status;
            Boolean displayDoPaymentButton = false;
            if (participants[0].Order_Items__r.size() > 0 && !String.isBlank(participants[0].Order_Items__r[0].Order_Custom__c)){
                status = participants[0].Order_Items__r[0].Order_Custom__r.Status__c;
                if (status != 'Paid') {
                    displayDoPaymentButton = true;
                }
				return new Map<String, Object> {
                    'id' => participants[0].Order_Items__r[0].Order_Custom__c,
                    'status' => status,
                    'eventId' => participants[0].Event_custom__c,
                    'displayCancelButton' => false,
                    'displayUpgradeButton' => true,
                    'displayDoPaymentButton' => displayDoPaymentButton
            	};                
            }
        }
        return new Map<String, Object> {
            'displayCancelButton' => false,
            'displayUpgradeButton' => false,
            'displayDoPaymentButton' => false
        };
    }

    @AuraEnabled
    public static List<Order__c> getOrderInfo(String Id) {
        return [
            SELECT Id, Status__c, Paid_Amount__c, Total_amount__c, Total_Amount_Net__c,
                (
                    SELECT Id, Name__c, Amount__c, Total_amount__c, Quantity__c, Paid__c, 
                        Discount_Amount__c, Discount__c, Refund_Amount__c,
                        Contact_Name__c
                    FROM Order_Items__r 
                ) 
            FROM Order__c 
            WHERE Id =:Id];
    }

    @AuraEnabled
    public static Map<String, Object> getCancellationSettings(String Id) {

        Map<String, Object> result = new Map<String, Object>{'orderList' => getOrderInfo(Id)};

        List<Change_Request__c> changeRequests = !String.isBlank(Id) ? [
            SELECT Id, Name FROM Change_Request__c WHERE Type__c = 'Individual Participant Group Registration Cancellation'
            AND (Status__c = 'Requested' OR Status__c = 'In Progress' OR Status__c = 'Approved') AND Order__c =:Id LIMIT 1
        ] : new List<Change_Request__c>();

        result.put('displayContactColumn', !changeRequests.isEmpty());
        return result;
    }

    @AuraEnabled
    public static Map<String,Object> cancelOrder(Map<String,Object> generalData){
        String orderId = String.valueOf(generalData.get('id'));
        Decimal refundAmount = (Decimal)generalData.get('refundAmount');
        List<Order_Item__c> oI = generalData.containsKey('oI') ?
            (List<Order_Item__c>)JSON.deserialize(JSON.serialize(generalData.get('oI')), List<Order_Item__c>.class) :
            new List<Order_Item__c>();
        System.debug('generalData.get(oIOrig) ' + generalData.get('oIOrig'));
        Map<String,Object> oIOrig = generalData.containsKey('oIOrig') ?
            (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(generalData.get('oIOrig'))) :
        new Map<String,Object>();   
        System.debug('generalData.get(oIOrig) oIOrig ' + oIOrig); 
        Map<String, String> resMap = PaymentHttpRequest.refundTransaction(orderId, orderId, refundAmount);

        if (resMap.get('status') == 'Success' && oI.size() > 0) {
            Savepoint sp = Database.setSavepoint(); 
            try {
                update oI;
                
                Set<String> oIs = new Set<String>();
                for (Order_Item__c o : oI) {
                    if (o.Refund_Amount__c > 0) {
                        oIs.add(o.Id);
                    }
                }

                List<Order_Item__c> orderItems = [
                    SELECT Id, Refund_Amount__c, Event_Participation__c, Session_Participation__c 
                    FROM Order_Item__c
                    WHERE Id IN: oIs
                ];

                List<Participant__c> part = new List<Participant__c>();
                List<Session_Participation__c> sPart = new List<Session_Participation__c>();

                for (Order_Item__c o : orderItems) {
                    if (o.Refund_Amount__c > 0) {
                        if (!String.isBlank(o.Event_Participation__c)) {
                            part.add( new Participant__c(Id = o.Event_Participation__c, Status__c = 'Canceled'));
                        }

                        if (!String.isBlank(o.Session_Participation__c)) {
                            sPart.add( new Session_Participation__c(Id = o.Session_Participation__c, Status__c = 'Canceled'));
                        }
                    }
                }

                update part;
                update sPart;

                List<Order__c> ord = [
                    SELECT Id, Contact__c, Contact__r.Email, Event_custom__c 
                    FROM Order__c 
                    WHERE Id =: orderId 
                    LIMIT 1
                ];

                if (ord.size() > 0) {
                    Email_Activity__c emailActivity = new Email_Activity__c(
                        Contact__c = ord[0].Contact__c,
                        Event_Custom__c = ord[0].Event_custom__c,
                        Order__c = ord[0].Id,
                        Send_To_Email__c = ord[0].Contact__r.Email,
                        Type__c = 'Refund Order',
                        JSON_body__c = JSON.serialize(oIOrig)
                    );
                    insert emailActivity;
                }
            }
            catch(Exception e) {
                Database.rollback(sp);
                return new Map<String,Object> {
                    'status' => 'Error',
                    'message' => e.getMessage()
                };
            }
        }
        return resMap;
    }
}