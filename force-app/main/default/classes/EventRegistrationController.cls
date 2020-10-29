public without sharing class EventRegistrationController {
    @AuraEnabled
    public static Event__c getEvent(String eventId) {
        Event__c event = [
                SELECT Id, Name, Early_Bird_Deadline__c, Registration_Deadline__c, RecordType.DeveloperName,
                        Start_Time__c, End_Time__c, Max_Participants__c, Registrations__c
                FROM Event__c
                WHERE Id = :eventId
        ];
        return event;
    }

    @AuraEnabled
    public static Map<String, Object> getContactInfo() {
        Map<String, Object> result = new Map<String, Object>();
        User user = [SELECT Contact.Id FROM User WHERE Id = :UserInfo.getUserId()];
        Contact contact = [
                SELECT Id, Residency__c
                FROM Contact
                WHERE Id = :user.Contact.Id
        ];
        result.put('contact', contact);
        return result;
    }

    @AuraEnabled
    public static List<Event_Exhibitor__c> getContactIpr(String contactId, String eventId){
        return [
                SELECT Id, Number_of_free_tickets__c, Account__r.Name,
                (
                        SELECT Id
                        FROM Event_Participations__r
                        WHERE Status__c != 'Canceled'
                )
                FROM Event_Exhibitor__c
                WHERE Contact__c = :contactId
                AND Event_custom__c = :eventId
                LIMIT 1
        ];
    }

    @AuraEnabled
    public static Map<String, Object> insertEventParticipants(List<Participant__c> participants, Map<String, Object> generalData, List<Object> selectedSession) {
        Savepoint sp = Database.setSavepoint();
        try {
            System.debug('participants:: ' + participants);

            Contact undefinedContact = getUndefinedParticipant();
            Id congressRTId = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
            System.debug('congressRTId ' + congressRTId);
            System.debug('undefinedContact ' + undefinedContact);

            if (undefinedContact == null) {
                return new Map<String, Object>{
                        'status' => 'Error',
                        'message' => 'Contact record Undefined Participant not found'
                };
            }

            for (Participant__c participant : participants) {
                participant.RecordTypeId = congressRTId;
                //todo event record type
                if (participant.Contact__c == null) {
                    participant.Contact__c = undefinedContact.Id;
                }
            }

            System.debug('insert participants:: ' + participants);
            insert participants;

            Map<String, Decimal> sessionParticipationPriceMap = new Map<String, Decimal>();
            System.debug('participants.size(): ' + participants.size());
            if (participants.size() == 1) {
                sessionParticipationPriceMap = insertSessionParticipants(selectedSession, participants[0].Id);
            }
            System.debug('sessionParticipation: ' + sessionParticipationPriceMap);


            //Create order
            List<Order__c> order = OrderHelper.createNewOrder(new Map<String, Object>{
                    'generalData' => generalData,
                    'participants' => participants,
                    'sessionParticipantPrice' => sessionParticipationPriceMap
            });

            return new Map<String, Object>{
                    'status' => 'Success',
                    'message' => 'Success',
                    'result' => order
            };
        } catch (Exception e) {
            Database.rollback(sp);
            return new Map<String, Object>{
                    'status' => 'Error',
                    'message' => e.getMessage()
            };
        }
    }

    public static Contact getUndefinedParticipant() {
        return [SELECT Id FROM Contact WHERE FirstName = 'Undefined' AND LastName = 'Participant' LIMIT 1];
    }

    @AuraEnabled
    public static List<Event_Ticket__c> getEventTickets(String eventId) {
        List<Event_Ticket__c> tickets = [
                SELECT Id,
                        Price__c,
                        Early_bird_price__c,
                        Event_custom__c,
                        Ticket__c,
                        Ticket__r.Name,
                        Ticket__r.Available_for_Memberships__c,
                        Ticket__r.Available_for_Countries__c,
                        Ticket__r.Available_for_Personas__c,
                        Ticket__r.Is_Group_only__c,
                        Ticket__r.Is_IPR_only__c
                FROM Event_Ticket__c
                WHERE
                Event_custom__c = :eventId
                AND Ticket__c != NULL
                AND (Price__c != NULL
                OR Early_bird_price__c != NULL)
        ];

        return tickets;
    }

    @AuraEnabled public static String insertRegistrationGroup(Event_Registration_Group__c eventGroupInformation, String groupLeaderId) {
//        Event_Registration_Group__c ERGroup = new Event_Registration_Group__c();
//        List<Event_Registration_Group__c> groups = [SELECT Id FROM Event_Registration_Group__c WHERE Name = :groupName AND Contact__c = :groupLeaderId LIMIT 1];

        if (eventGroupInformation.Id == null) {
//            ERGroup = new Event_Registration_Group__c(Name = group.Name, Contact__c = groupLeaderId);
//            insert ERGroup;
            eventGroupInformation.Contact__c = groupLeaderId;
            insert eventGroupInformation;
        }

        Event_Registration_Sub_Group__c subGroup = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = eventGroupInformation.Id);
        insert subGroup;
        return subGroup.Id;
    }

    @AuraEnabled
    public static List<Session__c> getExtraSessions(String eventId) {
        return [
                SELECT Id, Session_Start__c, Session_End__c, Registrations__c, Max_Participants__c, (
                        SELECT Id, Price__c, Early_bird_price__c, Event_custom__c, Ticket__c, Ticket__r.Name,
                                Ticket__r.Available_for_Memberships__c, Ticket__r.Available_for_Countries__c,
                                Session__r.Name, Session__r.Description__c, Session__r.Mutual_Exclusion__c,
                                Session__r.Max_Participants__c, Session__r.Registrations__c
                        FROM Event_Tickets__r
                        WHERE Ticket__c != NULL
                        AND (Price__c != NULL OR Early_bird_price__c != NULL)
                )
                FROM Session__c
                WHERE Event_custom__c = :eventId
                AND Type__c = 'Payable'
                AND Session_Start__c != NULL
                AND Session_End__c != NULL
                ORDER BY Session_Start__c ASC NULLS FIRST
        ];
    }

    public static Map<String, Decimal> insertSessionParticipants(List<Object> selectedSessions, String participantId) {
        Map<String, Decimal> sessionParticipantPriceMap = new Map<String, Decimal>();
        Map<String, Decimal> selectedSessionsMap = new Map<String, Decimal>();

        for (Integer i = 0; i < selectedSessions.size(); i++) {
            Map<Object, Object> obj = (Map<Object, Object>) selectedSessions[i];
            selectedSessionsMap.put((String) obj.get('id'), (Decimal) obj.get('price'));
        }

        List<Event_Ticket__c> extraSessions = [SELECT Id, Session__c, Session__r.Event_custom__c FROM Event_Ticket__c WHERE Id IN :selectedSessionsMap.keySet()];
        List<Session_Participation__c> sessionParticipants = new List<Session_Participation__c>();

        Map<String, Object> contactInfo = getContactInfo();
        Contact contact = (Contact) contactInfo.get('contact');

        for (Event_Ticket__c et : extraSessions) {
            Session_Participation__c sessionParticipation = new Session_Participation__c(
                    Session__c = et.Session__c, Contact__c = contact.Id, Event__c = et.Session__r.Event_custom__c,
                    Event_Participation__c = participantId, Event_Ticket__c = et.Id);

            sessionParticipants.add(sessionParticipation);
        }

        insert sessionParticipants;

        for (Session_Participation__c sp : sessionParticipants) {
            sessionParticipantPriceMap.put(sp.Id, selectedSessionsMap.get(sp.Event_Ticket__c));
        }

        return sessionParticipantPriceMap;
    }

    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName){
        return Utils.picklistValues(objectName, fieldName);
    }

    @AuraEnabled
    public static Map<String, String> getEventTicketsLabels(List<String> eventTicketsIds){
        Map<String, String> result = new Map<String, String>();
        List<Event_Ticket__c> eventTicket = [
                SELECT Id, Session__c, Session__r.Name, Ticket__c, Ticket__r.Name, Event_custom__c
                FROM Event_Ticket__c
                WHERE Id IN :eventTicketsIds
                AND (Ticket__c != NULL OR Session__c != NULL OR Event_custom__c != NULL)
        ];

        for(Event_Ticket__c et : eventTicket){
            if(et.Session__c != null){
                result.put(et.Id, et.Session__r.Name);
            }
            if(et.Event_custom__c != null){
                result.put(et.Id, et.Ticket__r.Name);
            }
        }

        return result;
    }

    @AuraEnabled
    public static List<Participant__c> existedParticipationCheck(String contactId, String eventId){
        return [
                SELECT Id
                FROM Participant__c
                WHERE Contact__c = :contactId
                AND Event_custom__c = :eventId
                AND Status__c != 'Canceled'
                LIMIT 1
        ];
    }

    @AuraEnabled
    public static List<Event_Registration_Group__c> getRegistrationGroupById(String groupId){
        return  [
                SELECT Id, Name, Event_Exhibitor__c
                FROM Event_Registration_Group__c
                WHERE Id = :groupId
        ];
    }

//    @AuraEnabled
//    public static List<Event_Ticket__c> getSessionsTickets(String eventId) {
//        List<Session__c> sessions = [
//                SELECT Id, Name, Session_Start__c, Session_End__c
//                FROM Session__c
//                WHERE Event_custom__c = :eventId
//                AND Session_Start__c != NULL
//                AND Session_End__c != NULL
//        ];
//
//        List<Event_Ticket__c> tickets = [
//                SELECT Id, Price__c, Early_bird_price__c, Event_custom__c, Ticket__c, Ticket__r.Name,
//                        Ticket__r.Available_for_Memberships__c, Ticket__r.Available_for_Countries__c
//                FROM Event_Ticket__c
//                WHERE Session__c IN :sessions
//                AND Ticket__c != NULL
//                AND (Price__c != NULL OR Early_bird_price__c != NULL)
//        ];
//
//        return tickets;
//    }
}