public without sharing class EventRegistrationController {
    @AuraEnabled
    public static Event__c getEvent(String eventId) {
        Event__c event = [
                SELECT Id, Name, Early_Bird_Deadline__c, Registration_Deadline__c
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
    public static Map<String, Object> insertEventParticipants( List<Participant__c> participants, Map<String,Object> generalData ) {
        Savepoint sp = Database.setSavepoint();
        try{
            System.debug('participants:: ' + participants);

            Contact undefinedContact = getUndefinedParticipant();
            Id congressRTId = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();

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

            insert participants;

            //Create order
            List<Order__c> order = OrderHelper.createNewOrder( new Map<String,Object> {
				'generalData' => generalData,
                'participants' => participants
            });

            return new Map<String, Object>{
                'status' => 'Success',
                'message' => 'Success',
                'result' => order
            };
        }
        catch (Exception e) {
            Database.rollback(sp);
            return new Map<String, Object>{
                'status' => 'Error',
                'message' => e.getMessage()
            };
        }
    }

    public static Contact getUndefinedParticipant() {
        return [ SELECT Id FROM Contact WHERE FirstName = 'Undefined' AND LastName = 'Participant' LIMIT 1 ];
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

    @AuraEnabled public static String insertRegistrationGroup(String groupName, String groupLeaderId) {
      Event_Registration_Group__c ERGroup = new Event_Registration_Group__c();
      List<Event_Registration_Group__c> groups = [SELECT Id FROM Event_Registration_Group__c WHERE Name = :groupName AND Contact__c = :groupLeaderId LIMIT 1];

      if(groups.isEmpty()){
        ERGroup = new Event_Registration_Group__c(Name = groupName, Contact__c = groupLeaderId);
        insert ERGroup;
      } else {
        ERGroup = groups[0];
      }

      Event_Registration_Sub_Group__c subGroup = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = ERGroup.Id);
      insert subGroup;
      return subGroup.Id;
    }

    @AuraEnabled
    public static List<Session__c> getExtraSessions(String eventId) {
        return [
                SELECT Id, Session_Start__c, Session_End__c, Registrations__c, Max_Participants__c,
                (
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