public without sharing class OrderHelper {

    public static List<Order__c> createNewOrder(Map<String,Object> generalData) {
        
        System.debug('createNewOrder');
        List<Participant__c> participants = generalData.containsKey('participants') ? 
            (List<Participant__c>)generalData.get('participants') : new List<Participant__c>();
        
        Map<String,Object> genData = generalData.containsKey('generalData') ? 
            (Map<String,Object>)generalData.get('generalData') : new Map<String,Object>();

        Map<String, Decimal> sessionParticipantPrice = generalData.containsKey('sessionParticipantPrice') ?
                (Map<String, Decimal>)generalData.get('sessionParticipantPrice') : new Map<String, Decimal>();
        
        String contactId = (String)genData.get('contactId');
        String eventId = (String)genData.get('eventId');
        String groupId = (String)genData.get('groupId');
        System.debug('createNewOrder groupId ' + groupId);
        Decimal priceTicket = (Decimal)genData.get('priceTicket');
        List<Object> journals = (List<Object>)genData.get('journals');
//        List<Object> selectedSessions = (List<Object>)genData.get('selectedSessions');
//        List<Event_Ticket__c> sessionParticipants = (List<Event_Ticket__c>)genData.get('sessionParticipants');
//        System.debug('sessionParticipants: '+sessionParticipants);


        Order__c o = new Order__c(
            Contact__c = contactId,
            Status__c = 'Opened',
            Event_custom__c = eventId,
            Purchase_Type__c = 'New',
            Event_Registration_Sub_Group__c = groupId
        );
        System.debug('createNewOrder o ' + o);
        insert o;

        List<Order_Item__c> ordItems = new List<Order_Item__c>();

        for(Participant__c part : participants) {
            ordItems.add( new Order_Item__c(
                Order_Custom__c = o.Id,
                Amount__c = priceTicket,
                Quantity__c = 1,
                Event_Participation__c = part.Id
            ));
        }

        System.debug('journals: '+journals);
        if(!journals.isEmpty()){

            for(Integer i = 0; i < journals.size(); i++){
                Map<Object, Object> obj = (Map<Object, Object>) journals[i];
                ordItems.add( new Order_Item__c(
                        Order_Custom__c = o.Id,
                        Amount__c = (Decimal)obj.get('price'),
                        Quantity__c = (Decimal)obj.get('quantity'),
                        Product__c = (String)obj.get('productId')
                ));
            }

        }

        if(!sessionParticipantPrice.isEmpty()){

            for(String sessionPartId : sessionParticipantPrice.keySet()){
                ordItems.add( new Order_Item__c(
                        Order_Custom__c = o.Id,
                        Amount__c = sessionParticipantPrice.get(sessionPartId),
                        Quantity__c = 1,
                        Session_Participation__c = sessionPartId
                ));
            }

        }

        System.debug('createNewOrder ordItems ' + ordItems);

        insert ordItems;
        
        return new List<Order__c>{o};

    }

    public static void cancelledOrder(Map<Id, Id> ordToChanges) {
        try {
            List<Order__c> ords = new List<Order__c>();
            Map<Id, Decimal> ordPrice = new Map<Id, Decimal>();
            List<Order__c> orders = [ 
                SELECT Id, Contact__c,Payment_Invoice__c, Event_custom__c, Purchase_Type__c, Event_Registration_Sub_Group__c, Total_amount__c
                FROM Order__c
                WHERE Id IN :ordToChanges.keySet()
            ];

            for (Order__c o: orders) {
                ordPrice.put(o.Id, o.Total_amount__c);

                o.Change_Request__c = ordToChanges.get(o.Id);
                o.Purchase_Type__c = 'Update';
                
                ords.add(o);
                ords.add(
                    new Order__c(
                        Payment_Invoice__c = o.Id,
                        Contact__c = o.Contact__c,
                        Status__c = 'Cancelled',
                        Event_custom__c = o.Event_custom__c,
                        Purchase_Type__c = 'New',
                        Event_Registration_Sub_Group__c = o.Event_Registration_Sub_Group__c,
                        Change_Request__c = o.Change_Request__c
                    )
                );
            }

            upsert ords;

            List<Order_Item__c> ordItems = new List<Order_Item__c>();
            String orderRefunedId, orderCancelledId;
            for (Order__c o : ords) {
                if (!String.isBlank(o.Payment_Invoice__c)) {
                    orderCancelledId = o.Id;
                    orderRefunedId = o.Payment_Invoice__c;
                    ordItems.add( 
                        new Order_Item__c(
                            Order_Custom__c = o.Id,
                            Amount__c =  ordPrice.get(o.Payment_Invoice__c),
                            Quantity__c = 1
                        )
                    );  
                }
            }
            insert ordItems;

            refundTransaction(orderRefunedId, orderCancelledId);

        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    @future(callout=true)
	public static void refundTransaction(String orderRefunedId, String orderCancelledId) {
        PaymentHttpRequest.refundTransaction(orderRefunedId, orderCancelledId);
    }
    
    @AuraEnabled
    public static Map<String, String> getOrderIdFromParticipant(Id participantId) {
        List<Participant__c> participants = [SELECT Id, (SELECT Id, Order_Custom__c, Order_Custom__r.Status__c FROM Order_Items__r) FROM Participant__c WHERE Id = :participantId];
        if (participants.size() > 0 && participants[0].Order_Items__r.size() > 0 && !String.isBlank(participants[0].Order_Items__r[0].Order_Custom__c)) {
            return new Map<String, String> {
                'id' => participants[0].Order_Items__r[0].Order_Custom__c,
                'status' => participants[0].Order_Items__r[0].Order_Custom__r.Status__c
            };
        }
        return new Map<String, String>();
    }
}