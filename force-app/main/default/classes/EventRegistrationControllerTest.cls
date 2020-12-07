@IsTest
public with sharing class EventRegistrationControllerTest {

    @TestSetup
    public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Developer' LIMIT 1];

        User sysAdminUser = new User(
                Alias = 'test', Email = 'ean_sysadmin@test.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'FirstName', LastName = 'LastName', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfileId, Country = 'Germany', IsActive = true,
                TimeZoneSidKey = 'Europe/Berlin', Username = 'ean_sysadmin@test.com', UserRoleId = userRole.Id
        );
        insert sysAdminUser;

        System.runAs(sysAdminUser){
            List<Event__c> events = new List<Event__c>();

            for(Integer i = 0; i < 3; i++){
                events.add(new Event__c(Name = 'Event '+i));
            }

            insert events;

            List<Session__c> extraSessions = new List<Session__c>();

            for(Event__c event : events){
                extraSessions.add(new Session__c(Name = 'Session Extra 1', Type__c = 'Payable', Session_Type__c = 'Special Session',
                        Max_Participants__c = 50, Event_custom__c = event.Id, Session_Start__c = Datetime.now(),
                        Session_End__c = Datetime.now().addDays(1)));
            }

            insert extraSessions;

            List<Ticket__c> tickets = new List<Ticket__c>();
            tickets.add(new Ticket__c(Name = 'Non-Member Ticket', Available_for_Countries__c = 'A;B;C;F'));
            tickets.add(new Ticket__c(Name = 'Any Member Ticket', Available_for_Countries__c = 'A;B;C;F', Available_for_Memberships__c = 'associate_corresponding_membership;' +
                    'associate_individual_membership;' +
                    'corresponding_institutional_members;' +
                    'corresponding_membership;' +
                    'fellow_membership;' +
                    'full_institutional_members;' +
                    'full_membership;' +
                    '55;' +
                    'resident_and_research_membership;' +
                    'student_membership'));
            tickets.add(new Ticket__c(Name = 'Any Persona Ticket', Available_for_Personas__c = 'Press;' +
                    'Grant_Winner;' +
                    'Invited_Person;' +
                    'Speaker'));
            tickets.add(new Ticket__c(Name = 'Group Ticket', Is_Group_only__c = true));
            tickets.add(new Ticket__c(Name = 'IPR Ticket', Is_IPR_only__c = true));
            insert tickets;

            List<Event_Ticket__c> eventTickets = new List<Event_Ticket__c>();

            for(Event__c event : events){
                for(Ticket__c ticket : tickets){
                    eventTickets.add(new Event_Ticket__c(Event_custom__c = event.Id, Ticket__c = ticket.Id, Early_bird_price__c = (Math.random() * (100)).intValue(), Price__c = (Math.random() * (100)).intValue()));
                }
            }

            for(Session__c extraSession : extraSessions){
                eventTickets.add(new Event_Ticket__c(Session__c = extraSession.Id, Ticket__c = tickets[0].Id, Early_bird_price__c = (Math.random() * (100)).intValue(), Price__c = (Math.random() * (100)).intValue()));
            }

            insert eventTickets;

            RecordType iprRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Industry_Partner'];
            Account acc = new Account(Name = 'Test', RecordTypeId = iprRT.Id);
            insert acc;

            Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'info@test.com', AccountId = acc.Id);
            insert contact;

            Contact undefinedContact = new Contact(FirstName = 'Undefined', LastName = 'Participant');
            insert undefinedContact;

            Id memberProfileId = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;

            User communityUser = new User(
                    Alias = 'test', Email = 'info@test.com',
                    EmailEncodingKey = 'UTF-8', FirstName = 'FirstName', LastName = 'LastName', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = memberProfileId, Country = 'Germany', IsActive = true,
                    ContactId = contact.Id, TimeZoneSidKey = 'Europe/Berlin', Username = 'info@test.com'
            );
            insert communityUser;
        }


    }

    @IsTest
    public static void getEvent(){
        List<Event__c> event = [SELECT Id FROM Event__c LIMIT 1];
        Event__c retrievedEvent = EventRegistrationController.getEvent(event[0].Id);
        System.assertEquals(event[0].Id, retrievedEvent.Id);
    }

    @IsTest
    public static void getContactInfoTest(){
        User user = [SELECT Id, ContactId FROM User WHERE Email = 'info@test.com'];
        System.runAs(user){
            Map<String, Object> result = EventRegistrationController.getContactInfo(null);
            System.assertEquals(user.ContactId, ((Contact)result.get('contact')).get('Id'));

            result = EventRegistrationController.getContactInfo(user.ContactId);
            System.assertEquals(user.ContactId, ((Contact)result.get('contact')).get('Id'));

        }
    }

    @IsTest
    public static void getContactIprTest(){
        Account acc = [
                SELECT Id,
                (
                        SELECT Id
                        FROM Contacts
                        WHERE Email = 'info@test.com'
                        LIMIT 1
                )
                FROM Account
                WHERE Name = 'Test'
                LIMIT 1
        ];

        Event__c event = [SELECT Id FROM Event__c LIMIT 1];

        Event_Exhibitor__c exhibitor  = new Event_Exhibitor__c(Event_custom__c = event.Id, Account__c = acc.Id, Contact__c = acc.Contacts[0].Id, Number_of_free_tickets__c = 5);
        insert exhibitor;

        List<Event_Exhibitor__c> exhibitors = EventRegistrationController.getContactIpr(acc.Contacts[0].Id, event.Id);

        System.assertEquals(exhibitor.Id, exhibitors[0].Id);
    }

    @IsTest
    public static void getUndefinedParticipantTest(){
        Contact undefinedContact = EventRegistrationController.getUndefinedParticipant();
        System.assertNotEquals(null, undefinedContact.Id);
    }

    @IsTest
    public static void getEventTicketsTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        List<Event_Ticket__c> selectedTickets = EventRegistrationController.getEventTickets(event.Id);
        System.assert(!selectedTickets.isEmpty());
    }

    @IsTest
    public static void insertRegistrationGroupTest(){
        Event_Registration_Group__c event_group = new Event_Registration_Group__c(Name = 'Test Group');
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        String subGroupId = EventRegistrationController.insertRegistrationGroup(event_group, contact.Id);
        System.assertEquals([SELECT Id FROM Event_Registration_Sub_Group__c ORDER BY CreatedDate DESC].Id, subGroupId);
    }

    @IsTest
    public static void getExtraSessionsTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        List<Session__c> sessions = EventRegistrationController.getExtraSessions(event.Id);
        System.assertEquals(1, sessions.size());
    }

    @IsTest
    public static void getPicklistValuesTest(){
        List<Map<String, String>> picklistValuesListMap = EventRegistrationController.getPicklistValues('Contact', 'Salutation');
        System.assertNotEquals(null, picklistValuesListMap.size());
    }

    @IsTest
    public static void getEventTicketsLabelsTest(){
        List<Session__c> sessions = [SELECT Id FROM Session__c];
        List<Event__c> events = [SELECT Id FROM Event__c];

        Map<Id, Event_Ticket__c> eventTickets = new Map<Id, Event_Ticket__c>([SELECT Id, Session__c, Event_custom__c FROM Event_Ticket__c WHERE Session__c IN :sessions OR Event_custom__c IN :events]);

        List<String> eventTicketsIds = new List<String>();

        for(Event_Ticket__c et : eventTickets.values()){
            eventTicketsIds.add(et.Id);
        }

        Map<String, String> idNameMap = EventRegistrationController.getEventTicketsLabels(eventTicketsIds);

        for(Event_Ticket__c et : eventTickets.values()){
            System.assert(String.isNotBlank(idNameMap.get(et.Id)));
        }
    }

    @IsTest
    public static void existedParticipationCheckTest(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        System.assert(EventRegistrationController.existedParticipationCheck(contact.Id, event.Id).isEmpty());
    }

    @IsTest
    public static void getRegistrationGroupByIdTest(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event_Registration_Group__c event_group = new Event_Registration_Group__c(Name = 'Test', Contact__c = contact.Id);
        insert event_group;
        System.assert(!EventRegistrationController.getRegistrationGroupById(event_group.Id).isEmpty());
    }

    @IsTest
    public static void updateContactsTest(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        contact.Salutation = 'Mr.';
        Map<String, Object> result = EventRegistrationController.updateContacts(new List<Contact>{contact});
        System.assertEquals('Success', result.get('status'));
    }

    @IsTest
    public static void getParticipationTest(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        Participant__c participant = new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id);
        insert participant;

        Map<String, Object> resultMap = EventRegistrationController.getParticipation(participant.Id);
        System.assertEquals(participant.Id, ((Participant__c)resultMap.get('eventParticipant')).Id);
    }

    @IsTest
    public static void updateParticipant(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        Participant__c participant = new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id);
        insert participant;

        participant.Visa_Letter__c = true;
        EventRegistrationController.updateParticipant(participant);
        System.assert([SELECT Id, Visa_Letter__c FROM Participant__c WHERE Id = :participant.Id].Visa_Letter__c);
    }

    @IsTest
    public static void validateGroupNameTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        System.assert(EventRegistrationController.validateGroupName(event.Id, 'Test_unq'));
    }

    @IsTest
    public static void getEventPersonaInfoTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        List<Event_Persona__c> eventPersonas = new List<Event_Persona__c>();

        List<RecordType> eventPersonaRTs = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Event_Persona__c'];

        for(RecordType rt : eventPersonaRTs){
            eventPersonas.add(new Event_Persona__c(Event_custom__c = event.Id, Contact__c = contact.Id, RecordTypeId = rt.Id));
        }

        insert eventPersonas;

        System.assertEquals(eventPersonaRTs.size(), EventRegistrationController.getEventPersonaInfo(event.Id, contact.Id).size());
    }

    @IsTest
    public static void getNotAvailableEventRegistrationEmailsTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        insert new Participant__c(Event_custom__c = event.Id, Participant_Email__c = 'participant@email.com', Contact__c = EventRegistrationController.getUndefinedParticipant().Id);
        insert new Change_Request__c(Type__c = 'Group Registration Transfer', Status__c = 'In Progress', TransferToEmail__c = 'change@request.com');

        List<String> emails = EventRegistrationController.getNotAvailableEventRegistrationEmails(new List<String>{event.Id});
        System.assert(emails.contains('participant@email.com'));
        System.assert(emails.contains('change@request.com'));
    }

    @IsTest
    public static void insertEventParticipantsSoloTest(){
        User user = [SELECT Id, ContactId FROM User WHERE Email = 'info@test.com'];
        Event__c event = [SELECT Id, (SELECT Id FROM Event_Tickets__r LIMIT 1) FROM Event__c LIMIT 1];
        List<Event_Ticket__c> sessionEventTicket = [SELECT Id, Session__c FROM Event_Ticket__c WHERE Session__c != NULL AND Ticket__c != NULL AND Session__r.Event_custom__c = :event.Id];
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];

        Participant__c participant = new Participant__c(
                Contact__c = contact.Id,
                Event_Ticket__c = event.Event_Tickets__r[0].Id,
                Event_custom__c = event.Id,
                Badge_Retrieval__c = 'onsite',
                Visa_Letter__c = false,
                Status__c = 'Pending',
                Role__c = 'Individual_Participant'
        );

        List<Map<String, Object>> participantPriceMap = new List<Map<String, Object>>();
        participantPriceMap.add(new Map<String, Object>{'participant' => participant, 'price' => 55});

        Map<String, Object> generalData = new Map<String, Object>();
        generalData.put('eventId', event.Id);
        generalData.put('contactId', contact.Id);
        List<Object> selectedSession = new List<Object>();

        if(!sessionEventTicket.isEmpty()){
            selectedSession.add(new Map<Object, Object>{'id' => sessionEventTicket[0].Id, 'price' => 35});
        }

        System.runAs(user){
            Map<String, Object> result = EventRegistrationController.insertEventParticipants(participantPriceMap, generalData, selectedSession);
            System.assertEquals('Success', (String)result.get('message'));
            List<Participant__c> participants = [SELECT Id, (SELECT Id FROM Session_Participations__r) FROM Participant__c WHERE Contact__c = :contact.Id AND Event_custom__c = :event.Id];
            System.assert(!participants.isEmpty());
            System.assert(!participants[0].Session_Participations__r.isEmpty());
        }
    }

    @IsTest
    public static void insertEventParticipantsGroupTest(){
        User user = [SELECT Id, ContactId FROM User WHERE Email = 'info@test.com'];
        Event__c event = [SELECT Id, (SELECT Id FROM Event_Tickets__r WHERE Ticket__r.Is_Group_only__c = TRUE LIMIT 1) FROM Event__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];

        Event_Registration_Group__c event_group = new Event_Registration_Group__c(Name = 'Test Group', Contact__c = contact.Id);
        insert event_group;
        Event_Registration_Sub_Group__c eventRegistrationSubGroup = new Event_Registration_Sub_Group__c(Event_Registration_Group__c = event_group.Id);
        insert eventRegistrationSubGroup;

        Participant__c participant = new Participant__c(
                Event_Ticket__c = event.Event_Tickets__r[0].Id,
                Event_custom__c = event.Id,
                Badge_Retrieval__c = 'onsite',
                Visa_Letter__c = false,
                Status__c = 'Pending',
                Role__c = 'Group_Participant',
                Event_Registration_Sub_Group__c = eventRegistrationSubGroup.Id
        );

        List<Map<String, Object>> participantPriceMap = new List<Map<String, Object>>();
        participantPriceMap.add(new Map<String, Object>{'participant' => participant, 'price' => 55});

        Map<String, Object> generalData = new Map<String, Object>();
        generalData.put('eventId', event.Id);
        generalData.put('contactId', contact.Id);
        generalData.put('groupId', eventRegistrationSubGroup.Id);
        List<Object> selectedSession = new List<Object>();

        Map<String, Object> result = new Map<String, Object>();
        System.runAs(user){
            result = EventRegistrationController.insertEventParticipants(participantPriceMap, generalData, selectedSession);
        }

        List<Participant__c> participants = [SELECT Id FROM Participant__c WHERE Contact__r.Name = 'Undefined Participant' AND Event_custom__c = :event.Id];
        System.assert(!participants.isEmpty());

        System.assert(![SELECT Id FROM Email_Activity__c].isEmpty());
    }

    @IsTest
    public static void insertUpgradeDataTest(){
        User user = [SELECT Id, ContactId FROM User WHERE Email = 'info@test.com'];
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        Participant__c participant = new Participant__c(Contact__c = contact.Id, Event_custom__c = event.Id);
        insert participant;

        Map<String, Object> data = new Map<String, Object>();
        data.put('participant', participant.Id);

        Map<Object, Object> generalData = new Map<Object, Object>();
        generalData.put('eventId', event.Id);
        generalData.put('contactId', contact.Id);
        data.put('generalData', generalData);

        List<Event_Ticket__c> sessionEventTicket = [
                SELECT Id, Session__c
                FROM Event_Ticket__c
                WHERE Session__c != NULL
                AND Ticket__c != NULL
                AND Session__r.Event_custom__c = :event.Id
        ];
        List<Object> selectedSession = new List<Object>();
        if(!sessionEventTicket.isEmpty()){
            selectedSession.add(new Map<Object, Object>{'id' => sessionEventTicket[0].Id, 'price' => 35});
        }
        data.put('selectedSessions', selectedSession);

        Map<String, Object> result = new Map<String, Object>();

        System.runAs(user){
            result = EventRegistrationController.insertUpgradeData(data);
        }
        List<Participant__c> participants = [SELECT Id, (SELECT Id FROM Session_Participations__r) FROM Participant__c WHERE Id  = :participant.Id];
        System.assertEquals('Success', (String)result.get('message'));
        System.assert(!participants[0].Session_Participations__r.isEmpty());
    }

    @IsTest
    public static void getContactMemberships(){
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'info@test.com' LIMIT 1];
        Membership__c membership = new Membership__c(Name = 'Test Membership', API__c = 'test');
        insert membership;
        MembershipContactAssotiation__c membershipStatus = new MembershipContactAssotiation__c(Contact__c = contact.Id, Membership__c = membership.Id, Endless_Activation__c = true);
        insert membershipStatus;

        List<MembershipContactAssotiation__c> contactsMemebrships = EventRegistrationController.getContactMemberships(contact.Id);
        System.assertEquals(membership.Id, contactsMemebrships[0].Membership__c);
    }

    @IsTest
    public static void displayEventRegisterButtonTest(){
        List<Event__c> event = [SELECT Id FROM Event__c LIMIT 1];
        System.assert(EventRegistrationController.displayEventRegisterButton(event[0].Id));
    }
}