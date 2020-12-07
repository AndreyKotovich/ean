public without sharing class EventRegistrationController {
    @AuraEnabled
    public static Event__c getEvent(String eventId) {
        Event__c event = [
                SELECT Id, Name, Early_Bird_Deadline__c, Registration_Deadline__c, RecordType.DeveloperName,
                        Start_Time__c, End_Time__c, Max_Participants__c, Registrations__c, Country__c
                FROM Event__c
                WHERE Id = :eventId
        ];
        return event;
    }

    @AuraEnabled
    public static Map<String, Object> getContactInfo(String contactId) {
        Map<String, Object> result = new Map<String, Object>();
        User user = new User();

        if(contactId == null){
            user = [SELECT Contact.Id FROM User WHERE Id = :UserInfo.getUserId()];
            contactId = user.Contact.Id;
        }

        Contact contact = [
                SELECT Id, Residency__c, Newsletter__c
                FROM Contact
                WHERE Id = :contactId
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
                ),
                (
                        SELECT Id
                        FROM Event_Registration_Groups__r
                )
                FROM Event_Exhibitor__c
                WHERE Contact__c = :contactId
                AND Event_custom__c = :eventId
                LIMIT 1
        ];
    }

    @AuraEnabled
    public static Map<String, Object> insertEventParticipants(List<Map<String, Object>> participantPriceMap, Map<String, Object> generalData, List<Object> selectedSession) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Participant__c> participants = new List<Participant__c>();
            Set<Id> eventIds = new Set<Id>();

            for(Integer i = 0; i<participantPriceMap.size(); i++){
                Participant__c p = (Participant__c)JSON.deserialize(JSON.serialize(participantPriceMap[i].get('participant')), Participant__c.class);
                participantPriceMap[i].put('participant', p);
                participants.add((Participant__c)participantPriceMap[i].get('participant'));
                eventIds.add(((Participant__c)participantPriceMap[i].get('participant')).Event_custom__c);
            }

            Contact undefinedContact = getUndefinedParticipant();
            Map<Id, Event__c> eventMap = new Map<Id, Event__c>([SELECT Id, RecordType.DeveloperName FROM Event__c WHERE Id IN :eventIds]);

            List<RecordType> participantRTs = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Participant__c'];
            Map<String, Id> devNameIdParticipantRTsMap = new Map<String, Id>();
            for(RecordType rt : participantRTs){
                devNameIdParticipantRTsMap.put(rt.DeveloperName, rt.Id);
            }

            System.debug('undefinedContact ' + undefinedContact);

            if (undefinedContact == null) {
                return new Map<String, Object>{
                        'status' => 'Error',
                        'message' => 'Contact record Undefined Participant not found'
                };
            }

            for (Participant__c participant : participants) {
                Event__c event = eventMap.get(participant.Event_custom__c);
                String participantRecordTypeId = devNameIdParticipantRTsMap.containsKey(event.RecordType.DeveloperName) ? devNameIdParticipantRTsMap.get(event.RecordType.DeveloperName) : '';
                participant.RecordTypeId = participantRecordTypeId;

                if (participant.Contact__c == null) {
                    participant.Contact__c = undefinedContact.Id;
                }
            }

            System.debug('insert participants:: ' + participants);
            insert participants;
            System.debug('participantPriceMap:: ' + participantPriceMap);


            if (generalData.containsKey('selectedDates')) {
                List<Date> selectedDates = (List<Date>) JSON.deserialize( JSON.serialize(generalData.get('selectedDates')), List<Date>.class);
                List<Event_participation_configuration__c> epc = new List<Event_participation_configuration__c>();
                for (Date d: selectedDates) {
                    epc.add(new Event_participation_configuration__c(Event_Participation__c = participants[0].Id, Date_of_visit__c = d));
                }
                insert epc;
            }

            Map<String, Object> sessionParticipationPriceMap = new Map<String, Object>();
            System.debug('participants.size(): ' + participants.size());
            if (participants.size() == 1) {
                sessionParticipationPriceMap = insertSessionParticipants(selectedSession, participants[0].Id);
            }
            System.debug('sessionParticipation: ' + sessionParticipationPriceMap);


            //Create order
            List<Order__c> order = OrderHelper.createNewOrder(new Map<String, Object>{
                    'generalData' => generalData,
                    'participantsPrice' => participantPriceMap,
                    'sessionParticipantPrice' => sessionParticipationPriceMap
            });

            List<String> orderIds = new List<String>();

            for(Order__c o : order){
                orderIds.add(o.Id);
            }

            if(!orderIds.isEmpty()){
                sendInvoiceToGroupLeader(orderIds);
            }

            return new Map<String, Object>{
                    'status' => 'Success',
                    'message' => 'Success',
                    'result' => order
            };
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('ERROR: '+e);
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
                SELECT Id, Price__c, Early_bird_price__c, Event_custom__c, Ticket__c, Ticket__r.Name,
                        Ticket__r.Available_for_Memberships__c, Ticket__r.Available_for_Countries__c,
                        Ticket__r.Available_for_Personas__c, Ticket__r.Is_Group_only__c, 
                        Ticket__r.Is_IPR_only__c, Participation__c, Ticket__r.Event_Country_Ticket__c
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
        if (eventGroupInformation.Id == null) {
            eventGroupInformation.Contact__c = groupLeaderId;
            insert eventGroupInformation;
        }

        if(eventGroupInformation.Event_Exhibitor__c != null){
            createIPRBadge(eventGroupInformation);
        }

        Event_Registration_Sub_Group__c subGroup = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = eventGroupInformation.Id);
        insert subGroup;
        return subGroup.Id;
    }

    public static void createIPRBadge(Event_Registration_Group__c eventGroup){
        List<Event_Exhibitor__c> exhibitor = [SELECT Id, Event_custom__c FROM Event_Exhibitor__c WHERE Id =: eventGroup.Event_Exhibitor__c];
        List<RecordType> exhibitorRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Event_Badge__c' AND DeveloperName = 'Exhibitor_Badge'];
        if(!exhibitor.isEmpty()){
            Event_Badge__c badge = new Event_Badge__c(
                    Event_Registration_Group__c = eventGroup.Id,
                    Event_custom__c = exhibitor[0].Event_custom__c,
                    Company__c = eventGroup.Name,
                    Footer_Definitions__c = 'Non-Member',
                    RecordTypeId = exhibitorRT[0].Id
            );
            insert badge;
            List<NamedCredential> namedCredentials = [SELECT DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = 'QR_Code_Generator_Link'];
            badge.QR_code__c = namedCredentials[0].Endpoint + '/chart?chs=200x200&cht=qr&chl=' + Url.getOrgDomainUrl().toExternalForm() + '/' + badge.Id;
            update badge;
        }
    }

    @AuraEnabled
    public static List<Session__c> getExtraSessions(String eventId) {
        return [
                SELECT Id, Session_Start__c, Session_End__c, Registrations__c, Max_Participants__c, (
                        SELECT Id, Price__c, Early_bird_price__c, Event_custom__c, Ticket__c, Ticket__r.Name,
                                Ticket__r.Available_for_Memberships__c, Ticket__r.Available_for_Countries__c,
                                Session__c, Session__r.Name, Session__r.Description__c, Session__r.Mutual_Exclusion__c,
                                Session__r.Max_Participants__c, Session__r.Registrations__c, Participation__c
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

    public static Map<String, Object> insertSessionParticipants(List<Object> selectedSessions, String participantId) {
        Map<String, Object> sessionParticipantPriceMap = new Map<String, Object>();
        Map<String, Decimal> selectedSessionsMap = new Map<String, Decimal>();

        for (Integer i = 0; i < selectedSessions.size(); i++) {
            Map<Object, Object> obj = (Map<Object, Object>) selectedSessions[i];
            selectedSessionsMap.put((String) obj.get('id'), (Decimal) obj.get('price'));
        }

        List<Event_Ticket__c> extraSessions = [SELECT Id, Session__c, Session__r.Event_custom__c FROM Event_Ticket__c WHERE Id IN :selectedSessionsMap.keySet()];
        List<Session_Participation__c> sessionParticipants = new List<Session_Participation__c>();

        Map<String, Object> contactInfo = getContactInfo(null);
        Contact contact = (Contact) contactInfo.get('contact');

        for (Event_Ticket__c et : extraSessions) {
            Session_Participation__c sessionParticipation = new Session_Participation__c(
                    Session__c = et.Session__c, Contact__c = contact.Id, Event__c = et.Session__r.Event_custom__c,
                    Event_Participation__c = participantId, Event_Ticket__c = et.Id, Status__c = 'Pending');

            sessionParticipants.add(sessionParticipation);
        }

        insert sessionParticipants;

        for (Session_Participation__c sp : sessionParticipants) {
            sessionParticipantPriceMap.put(sp.Id, new  Map<String, Object> {
                'price' => selectedSessionsMap.get(sp.Event_Ticket__c),
                'id' => sp.Session__c
            });
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

    @AuraEnabled
    public static Map<String, Object> updateContacts(List<Contact> contacts){
        try{
            System.debug('contacts: '+contacts);
            update contacts;
            return new Map<String, Object>{
                    'status' => 'Success',
                    'message' => 'Success'
            };
        } catch(Exception e){
            return new Map<String, Object>{
                    'status' => 'Error',
                    'message' => 'You haven\'t been subscribed to the EAN newsletter. Please contact you system administrator.'
            };
        }
    }

    @AuraEnabled
    public static Map<String, Object> getParticipation(String participantId){
        Map<String, Object> participantsMap = new Map<String, Object>();
        List<Participant__c> eventParticipants = [
                SELECT Id, Visa_Letter__c, Event_custom__c, Contact__c, Badge_Retrieval__c,
                    (SELECT Id FROM Event_participation_configurations__r)
                FROM Participant__c
                WHERE Id = :participantId
                AND Status__c != 'Canceled'
        ];

        if(!eventParticipants.isEmpty()){
            participantsMap.put('eventParticipant', eventParticipants[0]);
            participantsMap.put('eventParticipantConf', eventParticipants[0].Event_participation_configurations__r.size());

            List<Session_Participation__c> sessionParticipation = [
                    SELECT Id, Session__c, (SELECT Id, Amount__c FROM Order_Items__r LIMIT 1)
                    FROM Session_Participation__c
                    WHERE Contact__c = :eventParticipants[0].Contact__c
                    AND Event__c = :eventParticipants[0].Event_custom__c
                    AND Status__c != 'Canceled'
            ];

            if(!sessionParticipation.isEmpty()){
                participantsMap.put('sessionParticipation', sessionParticipation);
            }
        }
        return participantsMap;
    }

    @AuraEnabled public static void updateParticipant(Participant__c participant){
        update participant;
    }

    @AuraEnabled public static Map<String, Object> insertUpgradeData(Map<String, Object> data){
        Savepoint sp = Database.setSavepoint();
        try{
            List<Object> selectedSession = data.containsKey('selectedSessions') ? (List<Object>)data.get('selectedSessions') : new List<Object>();
            System.debug('data.get(\'participant\'): '+data.get('participant'));
            String participantId = data.containsKey('participant') ? (String)data.get('participant') : '';
            Map<Object,Object> generalDataObj = data.containsKey('generalData') ? (Map<Object,Object>)data.get('generalData') : new Map<Object,Object>();
            Map<String, Object> m = new Map<String, Object>();
            for(Object obj : generalDataObj.keySet()){
                m.put((String)obj, generalDataObj.get(obj));
            }

            Map<String, Object> sessionParticipationPriceMap = new Map<String, Object>();
            if (participantId != '') {
                sessionParticipationPriceMap = insertSessionParticipants(selectedSession, participantId);

                if (generalDataObj.containsKey('selectedDates')) {
                    List<Date> selectedDates = (List<Date>) JSON.deserialize( JSON.serialize(generalDataObj.get('selectedDates')), List<Date>.class);
                    List<Event_participation_configuration__c> epc = new List<Event_participation_configuration__c>();
                    for (Date d: selectedDates) {
                        epc.add(new Event_participation_configuration__c(Event_Participation__c = participantId, Date_of_visit__c = d));
                    }
                    insert epc;
                }

            }

            system.debug('m' + m) ;
            List<Order__c> order = OrderHelper.createNewOrder(new Map<String, Object>{
                    'generalData' => m,
                    'sessionParticipantPrice' => sessionParticipationPriceMap
            });

            return new Map<String, Object>{
                    'status' => 'Success',
                    'message' => 'Success',
                    'result' => order
            };
        } catch(Exception e){
            System.debug(e);
            Database.rollback(sp);
            return new Map<String, Object>{
                    'status' => 'Error',
                    'message' => e.getMessage()
            };
        }

    }

    @AuraEnabled public static Boolean validateGroupName(String eventId, String groupName){
        List<Participant__c> participants = [
                SELECT Id
                FROM Participant__c
                WHERE Event_custom__c = :eventId
                AND Event_Registration_Sub_Group__r.Event_Registration_Group__r.Name = :groupName
        ];

        return participants.isEmpty();
    }

    @AuraEnabled public static Map<String, Object> getEventPersonaInfo(String eventId, String contactId){
        Map<String, Object> roleEventPersonaMap = new Map<String, Object>();
        List<Event_Persona__c> eventPersonas = [SELECT Id, RecordType.Name, RecordType.DeveloperName FROM Event_Persona__c WHERE Event_custom__c = :eventId AND Contact__c = :contactId];

        for(Event_Persona__c ep : eventPersonas){
            roleEventPersonaMap.put(ep.RecordType.DeveloperName, ep);
        }

        List<Speaker__c> speaker = [
                SELECT Id
                FROM Speaker__c
                WHERE Contact__c = :contactId
                AND Lecture__r.Session__r.Event_custom__c = :eventId
                AND Eligible_for_Speaker_Ticket__c = TRUE
        ];

        System.debug('speaker: '+speaker);
        if(!speaker.isEmpty()){
            roleEventPersonaMap.put('Speaker', speaker[0]);
        }

        return roleEventPersonaMap;
    }

    @AuraEnabled public static List<String> getNotAvailableEventRegistrationEmails(List<String> eventsIds){
        return getNotAvailableEventRegistrationEmails(eventsIds, new List<String>());
    }

    @AuraEnabled public static List<String> getNotAvailableEventRegistrationEmails(List<String> eventsIds, List<String> skippedSubGroupsIds){
        List<Participant__c> registeredParticipants = skippedSubGroupsIds.isEmpty()
            ? [
                SELECT Id, Participant_Email__c, Contact__r.Email
                FROM Participant__c
                WHERE Event_custom__c IN :eventsIds
                AND Status__c != 'Canceled'
            ]
            : [
                SELECT Id, Participant_Email__c, Contact__r.Email
                FROM Participant__c
                WHERE Event_custom__c IN :eventsIds
                AND Status__c != 'Canceled'
                AND Event_Registration_Sub_Group__c NOT IN :skippedSubGroupsIds
            ];

        Set<String> emails = new Set<String>();

        for(Participant__c p : registeredParticipants){
            emails.add(p.Contact__r.Email);
            emails.add(p.Participant_Email__c);
        }

        List<Change_Request__c> activeChangeRequests = [
                SELECT Id, Type__c, TransferToContact__r.Email, TransferToEmail__c
                FROM Change_Request__c
                WHERE Status__c IN ('Requested', 'In Progress')
                AND Type__c IN ('Solo Registration Transfer', 'Group Registration Transfer')
        ];

        for(Change_Request__c cr : activeChangeRequests){
            emails.add(cr.TransferToEmail__c);
            emails.add(cr.TransferToContact__r.Email);
        }

        List<String> emailsList = new List<String>(emails);

        Integer nullIndex = emailsList.indexOf(null);

        if(nullIndex >= 0){
            emailsList.remove(nullIndex);
        }

        return emailsList;
    }

    @AuraEnabled public static void sendInvoiceToGroupLeader(List<String> orderIds) {
        List<Order__c> orders = [
            SELECT Id, Contact__r.Email, Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id, Event_custom__c,
            (SELECT Id, Total_amount__c, Name__c, Event_Participation__r.Contact__r.Name FROM Order_Items__r)
            FROM Order__c
            WHERE Id IN :orderIds
        ];
        Map<String, List<Order__c>> ordersToGroupIdsMap = new Map<String, List<Order__c>>();
        for (Order__c order : orders) {
            if (String.isNotBlank(order.Event_Registration_Sub_Group__c)) {
                if (!ordersToGroupIdsMap.containsKey(order.Event_Registration_Sub_Group__r.Event_Registration_Group__c)){
                    ordersToGroupIdsMap.put(order.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id, new List<Order__c>());
                }
                ordersToGroupIdsMap.get(order.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id).add(order);
            }
        }
        Map<Id, Event_Registration_Group__c> eventGroupsMap = new Map<Id, Event_Registration_Group__c>([
            SELECT Id, (SELECT Id FROM Event_Registration_Sub_Groups__r)
            FROM Event_Registration_Group__c
            WHERE Id IN :ordersToGroupIdsMap.keySet()
        ]);
        List<Order__c> groupCreatedOrders = new List<Order__c>();
        List<Order__c> groupAddedParticipantsOrders = new List<Order__c>();
        for (Order__c order : orders) {
            if (String.isNotBlank(order.Event_Registration_Sub_Group__c)) {
                if (eventGroupsMap.get(order.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id).Event_Registration_Sub_Groups__r.size() == 1) {
                    groupCreatedOrders.add(order);
                } else if (eventGroupsMap.get(order.Event_Registration_Sub_Group__r.Event_Registration_Group__r.Id).Event_Registration_Sub_Groups__r.size() > 1) {
                    groupAddedParticipantsOrders.add(order);
                }
            }
        }
        List<Email_Activity__c> emailActivities = new List<Email_Activity__c>();
        for (Order__c order : groupCreatedOrders) {
            Boolean isAllOrderItemsSame = checkOrderItemsEquality(order);
            if (isAllOrderItemsSame) {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group registration success with same orderItems'
                );
                emailActivities.add(emailActivity);
            } else {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group registration success'
                );
                emailActivities.add(emailActivity);
            }
        }
        for (Order__c order : groupAddedParticipantsOrders) {
            Boolean isAllOrderItemsSame = checkOrderItemsEquality(order);
            if (isAllOrderItemsSame) {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group participants added with same orderItems'
                );
                emailActivities.add(emailActivity);
            } else {
                Email_Activity__c emailActivity = new Email_Activity__c(
                    Contact__c = order.Contact__c,
                    Event_Custom__c = order.Event_custom__c,
                    Order__c = order.Id,
                    Send_To_Email__c = order.Contact__r.Email,
                    Type__c = 'Group participants added'
                );
                emailActivities.add(emailActivity);
            }
        }
        if (emailActivities.size() > 0) {
            insert emailActivities;
        }
    }

    private static Boolean checkOrderItemsEquality(Order__c order) {
        Boolean isAllOrderItemsSame = true;
        Decimal orderItemAmount;
        String orderItemName;
        String orderItemContact;
        for (Order_Item__c orderItem : order.Order_Items__r) {
            if (orderItemAmount == null) {
                orderItemAmount = orderItem.Total_amount__c;
            } else if (orderItemAmount != orderItem.Total_amount__c) {
                isAllOrderItemsSame = false;
            }
            if (orderItemName == null) {
                orderItemName = orderItem.Name__c;
            } else if (orderItemName != orderItem.Name__c) {
                isAllOrderItemsSame = false;
            }
            if (String.isNotBlank(orderItem.Event_Participation__c)) {
                if (orderItemContact == null) {
                    orderItemContact = orderItem.Event_Participation__r.Contact__c;
                } else if (orderItemContact != orderItem.Event_Participation__r.Contact__c) {
                    isAllOrderItemsSame = false;
                }
            }
        }
        return isAllOrderItemsSame;
    }

    //Same as Utils.getContactMemberships but without sharing
    @AuraEnabled
    public static List<MembershipContactAssotiation__c> getContactMemberships(String contactId){
        List<MembershipContactAssotiation__c> contactsMemberships = [
                SELECT Id, Membership__r.Name, Membership__r.API__c, CreatedDate
                FROM MembershipContactAssotiation__c
                WHERE Contact__c = :contactId
                AND IsActive__c = TRUE
                ORDER BY CreatedDate DESC
        ];

        return contactsMemberships;
    }

    @AuraEnabled
    public static Boolean displayEventRegisterButton(Id recordId){
        return recordId.getSobjectType().getDescribe().getName() == 'Event__c';
    }
}