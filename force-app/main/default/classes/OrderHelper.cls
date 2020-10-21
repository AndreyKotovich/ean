public without sharing class OrderHelper {

    public static List<Order__c> createNewOrder(Map<String,Object> generalData) {
        
        System.debug('createNewOrder');
        List<Participant__c> participants = generalData.containsKey('participants') ? 
            (List<Participant__c>)generalData.get('participants') : new List<Participant__c>();
        
        Map<String,Object> genData = generalData.containsKey('generalData') ? 
            (Map<String,Object>)generalData.get('generalData') : new Map<String,Object>();
        
        String contactId = (String)genData.get('contactId');
        String eventId = (String)genData.get('eventId');
        String groupId = (String)genData.get('groupId');
        System.debug('createNewOrder groupId ' + groupId);
        Decimal priceTicket = (Decimal)genData.get('priceTicket');
        List<Object> journals = (List<Object>)genData.get('journals');

        Order__c o = new Order__c(
            Contact__c = contactId,
            Status__c = 'Opened',
            Event_custom__c = eventId,
            Purchase_Type__c = 'New',
            Event_Registration_Sub_Group__c = groupId
        );
        System.debug('createNewOrder o ' + o);
        insert o;

        List<Order_Item__c> oi = new List<Order_Item__c>();

        for(Participant__c part : participants) {
            oi.add( new Order_Item__c(
                Order_Custom__c = o.Id,
                Amount__c = priceTicket,
                Quantity__c = 1,
                Event_Participation__c = part.Id
            ));
        }

        if(!journals.isEmpty()){
            for(Integer i = 0; i < journals.size(); i++){
                Map<Object, Object> obj = (Map<Object, Object>) journals[i];
                oi.add( new Order_Item__c(
                        Order_Custom__c = o.Id,
                        Amount__c = (Decimal)obj.get('price'),
                        Quantity__c = (Decimal)obj.get('quantity'),
                        Product__c = (String)obj.get('productId')
                ));
            }
        }

        System.debug('createNewOrder oi ' + oi);

        insert oi;
        
        return new List<Order__c>{o};

    }
}