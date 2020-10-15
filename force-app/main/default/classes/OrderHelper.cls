public with sharing class OrderHelper {

    public static List<Order__c> createNewOrder(Map<String,Object> generalData) {
        
        List<Participant__c> participants = generalData.containsKey('participants') ? 
            (List<Participant__c>)generalData.get('participants') : new List<Participant__c>();
        
        Map<String,Object> genData = generalData.containsKey('generalData') ? 
            (Map<String,Object>)generalData.get('generalData') : new Map<String,Object>();
            System.debug('OrderHelper participants ' + participants);
            System.debug('OrderHelper generalData ' + generalData);
            System.debug('OrderHelper participants ' + (String)((Map<String,Object>)genData.get('contact')).get('Id'));

        // String contactId = (String)((Map<String,Object>)genData.get('contact')).get('Id');
        // String eventId = (String)genData.get('event');
        // Decimal priceTicket = (Decimal)genData.get('priceTicket');

        

        // Order__c o = new Order__c(
        //     Contact__c = contactId,
        //     Status__c = 'Opened',
        //     Event_custom__c = eventId,
        //     Purchase_Type__c = 'New'
        // );

        // insert o;
        return new List<Order__c>();
        // List<Order_Item__c> oi = new List<Order_Item__c>();

        // for(Participant__c part : participants) {
        //     oi.add( new Order_Item__c(
        //         Order_Custom__c = o.Id,
        //         Amount__c = priceTicket,
        //         Quantity__c = 1,
        //         Event_Participation__c = part.Id
        //     ));
        // }

        // insert oi;
        
        // return new List<Order__c>{o};

    }
}