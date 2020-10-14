@IsTest
public with sharing class GTMGeneratorTest {

    @TestSetup
    public static void setup() {
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        TestService.insertMcCustomSettings();

        Id comUserId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'].Id;
        Id individualsRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individuals').getRecordTypeId();
        Id meetingPTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('G2M').getRecordTypeId();
        Id participantRTId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('G2M').getRecordTypeId();
        G2M_Settings_Obj__c g2ms = new G2M_Settings_Obj__c(Name = 'Sandbox', Account_Key__c = '4845706458463628293',
                Admin_Email__c = 'test@test.com', Admin_Password__c = '1234567', Consumer_Key__c = 'RP3r0b7UsFMBO5MVARg',
                Consumer_Secret__c = 'jdkjughvqeNEnefe4A', Expires_in__c = 3600);
        insert g2ms;
        Account acc = new Account(Name = 'Ind Account', RecordTypeId = individualsRTId);
        insert acc;
        Contact con = new Contact(LastName = 'testComCon', Email = 'test@test.com', AccountId = acc.Id);
        insert con;
        Contact con2 = new Contact(LastName = 'testComCon2', Email = 'test2@test.com', AccountId = acc.Id);
        insert con2;

        Event__c meeting = new Event__c(Name = 'Test Meeting 1', RecordTypeId = meetingPTId, Start_Time__c = Datetime.now(),
                Duration__c = 150, Unique_Meeting_Id__c = '1234567');
        insert  meeting;
        Participant__c pt1 = new Participant__c(Event_custom__c = meeting.Id, RecordTypeId = participantRTId, Contact__c = con.Id);
        insert pt1;
        Participant__c pt2 = new Participant__c(Event_custom__c = meeting.Id, RecordTypeId = participantRTId, Contact__c = con2.Id);
        insert pt2;
        User user = new User(
                Alias = 'cUser911', Email = 'test911@testemail.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'Community', LastName = 'User', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = comUserId, Country = 'Germany', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'Europe/Berlin', Username = 'comuser@testemail.com');
        insert user;
        NewsletterSubscriptionController.isCreateSubscribersEnabled = true;
    }

    @IsTest
    public static void getAccessTokenTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getAccessToken();
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('access_token'), 'qwerty12345');
    }

    @IsTest
    public static void getAccessTokenAnyUserTest() {
        User comUser = [SELECT Id, ContactId, Email FROM User WHERE Email = 'test911@testemail.com' AND Username = 'comuser@testemail.com' LIMIT 1];
        Map<String, String> data = new Map<String, String>();
        data.put('userEmail', comUser.Email);
        data.put('userPass', '12345');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getAccessTokenAnyUser(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('access_token'), 'qwerty12345');
    }

    @IsTest
    public static void updateUserTest() {
        User comUser = [SELECT Id, ContactId FROM User WHERE Email = 'test911@testemail.com' AND Username = 'comuser@testemail.com' LIMIT 1];
        Map<String, String> data = new Map<String, String>();
        data.put('userEmail', 'test@test.com');
        data.put('userLogMeInEmail', 'test.test.com@ean.org');
        data.put('userPass', '987654');

        System.runAs(comUser) {
            GTMGenerator.updateUser(data);
            Contact con = [SELECT LogMeIn_Password__c, LogMeIn_Email__c FROM Contact WHERE Email = 'test@test.com'];

            System.assertEquals(con.LogMeIn_Email__c, 'test.test.com@ean.org');
            System.assertEquals(con.LogMeIn_Password__c, '987654');
        }
    }

    @IsTest
    public static void getMeetingsTest() {
        User comUser = [SELECT Id, ContactId FROM User WHERE Email = 'test911@testemail.com' AND Username = 'comuser@testemail.com' LIMIT 1];
        System.runAs(comUser) {
            String response = GTMGenerator.getMeetings();
            System.assert(!String.isBlank(response));
        }
    }

    @IsTest
    public static void createMeetingLogMeInTest() {
        Contact comContact = [SELECT Id FROM Contact WHERE LastName = 'testComCon' LIMIT 1];
        Event__c meeting = [SELECT Id FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];
        String params = '{"subject":"test","startDate":"2020-11-29","startTime":"12:37","duration":30,' +
                '"todaysDate":"2019-11-29","description":"","participants":["'+ comContact.Id +'"],"index":"' + meeting.Id + '"}';
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('params', params);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CreateMeetingLogMeInMock());
        String response = GTMGenerator.createMeetingLogMeIn(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('joinURL'), 'https://test/test');
    }

    @IsTest
    public static void checkIntegerTest() {
        Integer small = 5;
        Integer zero = 0;
        Integer big = 11;

        Test.startTest();
        String response1 = GTMGenerator.checkInteger(small);
        String response2 = GTMGenerator.checkInteger(zero);
        String response3 = GTMGenerator.checkInteger(big);
        Test.stopTest();
        System.assertEquals(response1, '05');
        System.assertEquals(response2, '00');
        System.assertEquals(response3, '11');
    }

    @IsTest
    public static void createMeetingTest() {
        Contact comContact = [SELECT Id FROM Contact WHERE LastName = 'testComCon' LIMIT 1];
        Event__c meeting = [SELECT Id FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];
        String params = '{"subject":"test","startDate":"2020-11-29","startTime":"12:37","duration":30,' +
                '"todaysDate":"2019-11-29","description":"","participants":["'+ comContact.Id +'"],"index":"' + meeting.Id + '"}';
        Map<String, String> data = new Map<String, String>();
        data.put('uniqueMeetingId', '12563987654');
        data.put('params', params);
        data.put('joinURL', 'https://test/test');
        data.put('hostURL', 'https://test/test/test');
        data.put('ownerKey', '123456');

        Test.startTest();
        String response = GTMGenerator.createMeeting(data);
        Test.stopTest();

        Event__c newMeeting = [SELECT Id, Name, Join_URL__c, Host_URL__c, LogMeIn_Owner_Key__c, Unique_Meeting_Id__c
                            FROM Event__c WHERE Unique_Meeting_Id__c = '12563987654'];
        System.assertEquals(newMeeting.Name, 'test');
        System.assertEquals(newMeeting.Host_URL__c, 'https://test/test/test');
    }

    @IsTest
    public static void startMeetingTest() {
        Event__c meeting = [SELECT Id, Unique_Meeting_Id__c FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('meetingId', meeting.Unique_Meeting_Id__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new startMeetingMock());
        String response = GTMGenerator.startMeeting(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('hostURL'), 'https://test/test/test');
    }

    @IsTest
    public static void deleteMeetingTest() {
        Event__c meeting = [SELECT Id FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];

        Test.startTest();
        String response = GTMGenerator.deleteMeeting(meeting.Id);
        Test.stopTest();

        Event__c newMeeting = [SELECT Id, Name
                                FROM Event__c
                                WHERE Name = 'Test Meeting 1'
                                AND IsDeleted = TRUE ALL ROWS];
        System.assertEquals(newMeeting.Name, 'Test Meeting 1');
    }

    @IsTest
    public static void deleteMeetingLogMeInTest() {
        Event__c meeting = [SELECT Id, Unique_Meeting_Id__c FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('uniqueId', meeting.Unique_Meeting_Id__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new deleteMeetingLogMeInMock());
        String response = GTMGenerator.deleteMeetingLogMeIn(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'meeting was deleted');
    }

    @IsTest
    public static void updateMeetingLogMeInTest() {
        Contact comContact = [SELECT Id FROM Contact WHERE LastName = 'testComCon' LIMIT 1];
        Event__c meeting = [SELECT Id, Unique_Meeting_Id__c FROM Event__c WHERE Name = 'Test Meeting 1' LIMIT 1];
        String params = '{"subject":"test","startDate":"2020-11-29","startTime":"12:37","duration":30,' +
                '"todaysDate":"2019-11-29","description":"","participants":["'+ comContact.Id +'"],"index":"' + meeting.Id + '"}';
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('meetingUniqueId', meeting.Unique_Meeting_Id__c);
        data.put('params', params);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new updateMeetingLogMeInMock());
        String response = GTMGenerator.updateMeetingLogMeIn(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'meeting updated successfully');
    }

    @IsTest
    public static void getUpcomingMeetingsTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getUpcomingMeetings('access987654');
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void getUsersTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('accountKey', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getUsers(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void getMyselfTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getMyself(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void getUserSCIMTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('userName', 'test@test.com');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getUserSCIM(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void getLicensesTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('accountKey', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.getLicenses(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void createUserSCIMTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accessToken', 'access987654');
        data.put('userName', 'Test Tester');
        data.put('userFirstName', 'Test');
        data.put('userLastName', 'Tester');
        data.put('userEmail', 'test@test.com');
        data.put('userPass', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.createUserSCIM(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void createUserTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accountKey', '123456789');
        data.put('accessToken', 'access987654');
        data.put('userFirstName', 'Test');
        data.put('userLastName', 'Tester');
        data.put('userEmail', 'test@test.com');
        data.put('license', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.createUser(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void setUserLicenseTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accountKey', '123456789');
        data.put('accessToken', 'access987654');
        data.put('userKey', '985612725456');
        data.put('licenceKey', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.setUserLicense(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void deleteUserLicenseTest() {
        Map<String, String> data = new Map<String, String>();
        data.put('accountKey', '123456789');
        data.put('accessToken', 'access987654');
        data.put('userKey', '985612725456');
        data.put('licenceKey', '1234567');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        String response = GTMGenerator.deleteUserLicense(data);
        Test.stopTest();
        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(res.get('response'), 'success');
    }

    @IsTest
    public static void sendEmailToParticipantsTest() {
        Contact con1 = [SELECT Id, Email FROM Contact WHERE LastName = 'testComCon'];
        Contact con2 = [SELECT Id, Email FROM Contact WHERE LastName = 'testComCon2'];

        Map<String, String> data = new Map<String, String>();
        data.put('participantsString', con1.Id+','+con2.Id);
        data.put('joinURL', 'https://test/test');
        data.put('ownerId', con2.Id);
        data.put('externalURL', 'https://test/test/test');
        data.put('meetingName', 'Test');
        data.put('meetingTime', '10:00');
        data.put('startDate', 'Jan 01, 2020');
        data.put('startDateTimeToInviteMethod', '2020,01,15,11,20,00');
        data.put('meetingDuration', '30');

        Test.startTest();
        List<String> response = GTMGenerator.sendEmailToParticipants(data);
        Test.stopTest();
        System.debug(response);

//        Map<String, String> res = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        System.assertEquals(response[0], 'test2@test.com');
        System.assertEquals(response[1], 'test@test.com');
    }

    @IsTest
    public static void checkUserProfileTest() {
        Test.startTest();
        Boolean response = GTMGenerator.checkUserProfile();
        Test.stopTest();
        System.assertEquals(response, true);
    }

    @IsTest
    public static void testGetContactsData() {
        Contact con1 = [SELECT Id, Email FROM Contact WHERE LastName = 'testComCon'];
        Contact con2 = [SELECT Id, Email FROM Contact WHERE LastName = 'testComCon2'];
        Set<Id> conIds = new Set<Id>();
        conIds.add(con1.Id);
        conIds.add(con2.Id);
        Map<String, String> data = new Map<String, String>();
        data.put('ids', JSON.serialize(conIds));
        Test.startTest();
        String response = GTMGenerator.getContactsData(data);
        System.assert(!String.isBlank(response));
        Test.stopTest();
    }

    @IsTest
    public static void testGetContactsId() {
        // Contact con1 = [SELECT Id, Email FROM Contact WHERE LastName = 'testComCon'];
        User comUser = [SELECT Id, ContactId, Email FROM User WHERE Email = 'test911@testemail.com' LIMIT 1];
        Set<Id> userIds = new Set<Id>();
        userIds.add(comUser.Id);
        Map<String, String> data = new Map<String, String>();
        data.put('listIds', JSON.serialize(userIds));
        Test.startTest();
        String response = GTMGenerator.getContactsId(data);
        System.assert(!String.isBlank(response));
        Test.stopTest();
    }
}