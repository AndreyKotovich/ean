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
    public static void insertEventParticipants(
            List<Participant__c> participants
    ) {
        System.debug('participants:: ' + participants);

        Contact undefinedContact = getUndefinedParticipant();

        RecordType congressRT = [
                SELECT Id
                FROM RecordType
                WHERE SobjectType = 'Participant__c' AND DeveloperName = 'Congress'
        ];

        for (Participant__c participant : participants) {
            participant.RecordTypeId = congressRT.Id;
            //todo event record type
            if (participant.Contact__c == null) {
                participant.Contact__c = undefinedContact.Id;
            }
        }

        insert participants;
    }

    public static Contact getUndefinedParticipant() {
        Contact contact = [
                SELECT Id
                FROM Contact
                WHERE FirstName = 'Undefined' AND LastName = 'Participant'
        ];
        return contact;
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
}