public without sharing class GTMGenerator {

    @AuraEnabled
    public static Boolean checkUserProfile() {
        Id profileId = UserInfo.getProfileId();
        
        String profileName = [SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        User user = [SELECT Id, Profile.Name, ContactId, Contact_Id__c, FirstName, LastName, Email FROM User WHERE Id = :UserInfo.getUserId()];
        if(profileName == 'Non-Member Community User Profile' ||
                user.Profile.Name == 'Customer Community Login User' ||
                user.Profile.Name == 'Executive Management' ||
                user.Profile.Name == 'Fundraising and Development' ||
                user.Profile.Name == 'Office Staff' ||
                user.Profile.Name == 'Program Staff' ||
                user.Profile.Name == 'Marketing User' ||
                user.Profile.Name == 'System Administrator' ||
                user.Profile.Name == 'Education Admin' ||
                user.Profile.Name == 'Member Community User Profile' ||
                user.Profile.Name == 'Membership Admin' ||
                user.Profile.Name == 'RRFS Reviewer' ||
                user.Profile.Name == 'Secretary General'
                ) {
            if (!String.isBlank(user.ContactId)) {
                return true;
            } else if (String.isBlank(user.Contact_Id__c)) {
                // Create duplicate contact
                Database.DMLOptions dml = new Database.DMLOptions(); 
                dml.DuplicateRuleHeader.allowSave = true;
                dml.DuplicateRuleHeader.runAsCurrentUser = true;
                Contact con = new Contact(FirstName = user.FirstName, LastName = user.LastName,
                        Email = user.Email, OwnerId = user.Id);
                Database.SaveResult sr = Database.insert(con, dml);
                if (sr.isSuccess()) {
                    System.debug('Duplicate contact has been inserted in Salesforce!');
                }

                Contact c = [SELECT Id FROM Contact WHERE Email =: user.Email LIMIT 1];
                user.Contact_Id__c = c.Id;
                update user;
                return true;
            } else {
                List <Contact> cont = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :user.Contact_Id__c];
                if (cont.isEmpty()) {
                    // Create duplicate contact
                    Database.DMLOptions dml = new Database.DMLOptions(); 
                    dml.DuplicateRuleHeader.allowSave = true;
                    dml.DuplicateRuleHeader.runAsCurrentUser = true;
                    Contact con = new Contact(FirstName = user.FirstName, LastName = user.LastName,
                            Email = user.Email, OwnerId = user.Id);
                    Database.SaveResult sr = Database.insert(con, dml);
                    if (sr.isSuccess()) {
                        System.debug('Duplicate contact has been inserted in Salesforce!');
                    }

                    Contact c = [SELECT Id FROM Contact WHERE Email =: user.Email LIMIT 1];
                    user.Contact_Id__c = c.Id;
                    update user;
                    return true;
                }
                return true;
            }
        } else {
            return false;
        }
    }

    /**
     * Get contacts Ids for default participants
     */
    @AuraEnabled
    public static String getContactsId(Map<String, String> data) {
        String conIdsStr = data.get('listIds');
        Set<Id> conIds = (Set<Id>) JSON.deserialize(conIdsStr, Set<Id>.class);
        List<Object> response = new List<Object>();

        List<User> userList = [SELECT Id, ContactId, Contact_Id__c, Name 
            FROM User
            WHERE Id IN : conIds
        ];

        for (User u : userList) {
            if(String.isNotBlank(u.ContactId)) {
                response.add(u.ContactId);
            } else if(String.isNotBlank(u.Contact_Id__c)) {
                response.add(u.Contact_Id__c);
            }
        }
        return JSON.serialize(response);
    }

    /**
     * Get contacts Id and Name for default participants
     */
    @AuraEnabled
    public static String getContactsData(Map<String, String> data) {
        String conIdsStr = data.get('ids');
        Set<Id> conIds = (Set<Id>) JSON.deserialize(conIdsStr, Set<Id>.class);
        List<Object> response = new List<Object>();

        List<Contact> contactList = [SELECT Id, Name 
            FROM Contact
            WHERE Id IN : conIds
        ];

        for (Contact c : contactList) {
            Map<String, String> m = new Map<String, String>();
            m.put('recId', c.Id);
            m.put('selectName', c.Name);
            response.add(m);
        }
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static String getAccessToken() {
        System.debug('getAccessToken');
        Map<String, String> responseMap = new Map<String, String>();
        G2M_Settings_Obj__c g2ms = [SELECT Id, Access_Token__c, Account_Key__c, Admin_Email__c,
        Admin_Password__c, Consumer_Key__c, Consumer_Secret__c, Access_Token_Received_At__c,
        Expires_in__c FROM G2M_Settings_Obj__c WHERE Name = 'Sandbox' LIMIT 1];

        String ACCESS_TOKEN;
        String ACCOUNT_KEY;
        String ADMIN_NAME;
        String ADMIN_PASSWORD;
        String CONSUMER_KEY;
        String CONSUMER_SECRET;
        Integer EXPIRES_IN;
        Datetime ACCESS_TOKEN_RECEIVED;
        Datetime ACCESS_TOKEN_EXPIRE;
        String AUTHORIZATION_CODE;

        if (g2ms != null) {
            ACCESS_TOKEN = g2ms.Access_Token__c;
            ACCOUNT_KEY = g2ms.Account_Key__c;
            ADMIN_NAME = g2ms.Admin_Email__c;
            ADMIN_PASSWORD = g2ms.Admin_Password__c;
            CONSUMER_KEY = g2ms.Consumer_Key__c;
            CONSUMER_SECRET = g2ms.Consumer_Secret__c;
            ACCESS_TOKEN_RECEIVED = g2ms.Access_Token_Received_At__c;
            EXPIRES_IN = g2ms.Expires_in__c != null ? Integer.valueOf(g2ms.Expires_in__c) : null;
            ACCESS_TOKEN_EXPIRE = EXPIRES_IN != null && ACCESS_TOKEN_RECEIVED != null ?
                    ACCESS_TOKEN_RECEIVED.addSeconds(EXPIRES_IN) : null;
            AUTHORIZATION_CODE = CONSUMER_KEY != null && CONSUMER_SECRET != null ?
                    EncodingUtil.base64Encode(Blob.valueOf(CONSUMER_KEY + ':' + CONSUMER_SECRET)) : null;

            System.debug('ADMIN AUTHORIZATION_CODE '+AUTHORIZATION_CODE);
            System.debug('ADMIN ADMIN_NAME '+ ADMIN_NAME);
            System.debug('ADMIN ADMIN_PASSWORD '+ADMIN_PASSWORD);

            if (ACCESS_TOKEN != null && EXPIRES_IN != null && ACCOUNT_KEY != null && ACCESS_TOKEN_EXPIRE != null &&
                    ACCESS_TOKEN_EXPIRE > System.now().addMinutes(10)) {
                responseMap.put('access_token', ACCESS_TOKEN);
                responseMap.put('account_key', ACCOUNT_KEY);

                return JSON.serialize(responseMap);
            } else {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://api.getgo.com/oauth/v2/token');
                // request.setEndpoint('https://api.getgo.com/admin/rest/v1/oauth/v2/token');

                request.setHeader('Authorization', 'Basic ' + AUTHORIZATION_CODE);
                request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request.setHeader('Accept', 'application/json');
                request.setBody('grant_type=password&username=' + ADMIN_NAME + '&password=' + ADMIN_PASSWORD);
                request.setMethod('POST');
                HttpResponse response = http.send(request);

                if(Test.isRunningTest()) {
                    return '{"access_token":"qwerty12345"}';
                } else
                if (response.getStatusCode() == 200) {
                    responseMap = (Map<String,String>)JSON.deserialize(response.getBody(), Map<String,String>.class);
                    g2ms.Access_Token_Received_At__c = System.now();
                    g2ms.Access_Token__c = responseMap.get('access_token');
                    g2ms.Account_Key__c = responseMap.get('account_key');
                    g2ms.Expires_in__c = Decimal.valueOf(responseMap.get('expires_in'));
                    update g2ms;

                    return response.getBody();
                } else {
                    return generateErrorDescription(response);
                }
            }
        }
        return  JSON.serialize(new Map<String, String>{ 'settings_error' => 'G2M custom setting doesn\'t ' +
                'contain required data' });
    }


    @AuraEnabled
    public static String getAccessTokenAnyUser(Map<String, String> data) {
        System.debug('getAccessTokenAnyUser');

        // G2M Settings Object
        G2M_Settings_Obj__c g2ms = [SELECT Id, Access_Token__c, Account_Key__c, Admin_Email__c,
                Admin_Password__c, Consumer_Key__c, Consumer_Secret__c, Access_Token_Received_At__c,
                Expires_in__c FROM G2M_Settings_Obj__c WHERE Name = 'Sandbox' LIMIT 1];

        System.debug('g2ms '+g2ms);

        String ACCESS_TOKEN;
        String ACCOUNT_KEY;
        String ADMIN_NAME;
        String ADMIN_PASSWORD;
        String CONSUMER_KEY;
        String CONSUMER_SECRET;
        Integer EXPIRES_IN;
        Datetime ACCESS_TOKEN_RECEIVED;
        Datetime ACCESS_TOKEN_EXPIRE;
        String AUTHORIZATION_CODE;

        if (g2ms != null) {
            ACCESS_TOKEN = g2ms.Access_Token__c;
            ACCOUNT_KEY = g2ms.Account_Key__c;
            ADMIN_NAME = data.get('userEmail');
            ADMIN_PASSWORD = data.get('userPass');
            CONSUMER_KEY = g2ms.Consumer_Key__c;
            CONSUMER_SECRET = g2ms.Consumer_Secret__c;
            ACCESS_TOKEN_RECEIVED = g2ms.Access_Token_Received_At__c;
            EXPIRES_IN = g2ms.Expires_in__c != null ? Integer.valueOf(g2ms.Expires_in__c) : null;
            ACCESS_TOKEN_EXPIRE = EXPIRES_IN != null && ACCESS_TOKEN_RECEIVED != null ?
                    ACCESS_TOKEN_RECEIVED.addSeconds(EXPIRES_IN) : null;
            AUTHORIZATION_CODE = CONSUMER_KEY != null && CONSUMER_SECRET != null ?
                    EncodingUtil.base64Encode(Blob.valueOf(CONSUMER_KEY + ':' + CONSUMER_SECRET)) : null;

            System.debug('AnyUser AUTHORIZATION_CODE '+AUTHORIZATION_CODE);
            System.debug('AnyUser ADMIN_NAME '+ ADMIN_NAME);
            System.debug('AnyUser ADMIN_PASSWORD '+ADMIN_PASSWORD);

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.getgo.com/oauth/v2/token');
            request.setHeader('Authorization', 'Basic ' + AUTHORIZATION_CODE);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('grant_type=password&username=' + ADMIN_NAME + '&password=' + ADMIN_PASSWORD);
            request.setMethod('POST');
            HttpResponse response = http.send(request);

            if(Test.isRunningTest()) {
                return '{"access_token":"qwerty12345"}';
            } else
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                return generateErrorDescription(response);
            }
        }
        return  JSON.serialize(new Map<String, String>{ 'settings_error' => 'G2M custom setting doesn\'t ' +
                'contain required data' });
    }


    /**
     * Update user LogMeIn data
     *
     * @param data
     */
    @AuraEnabled
    public static void updateUser(Map<String, String> data) {
        String userEmail = data.get('userEmail');
        String userLogMeInEmail = data.get('userLogMeInEmail');
        String userPass = data.get('userPass');

        List<Contact> contactList = [SELECT Id, Name, FirstName, LastName, Email, LogMeIn_Password__c, LogMeIn_Email__c
        FROM Contact
        WHERE Email =: userEmail];

        if (!contactList.isEmpty()) {
            for (Contact con : contactList) {
                con.LogMeIn_Password__c = userPass;
                con.LogMeIn_Email__c = userLogMeInEmail;
            }
            update contactList;
        } else {
            System.debug('Error updating contact information.');
        }
    }

    /**
     * get related meetings
     *
     * @return
     */
    @AuraEnabled
    public static String getMeetings() {
        System.debug('getMeetings');
        List<Event__c> meetings = new List<Event__c>();
        List<Participant__c> participants = new List<Participant__c>();
        Map<String, List<Object>> response = new Map<String, List<Object>>();
        List<Meeting> meetingsToReturn = new List<Meeting>();
        Set<Id> eventIds = new Set<Id>();
        Id contactId;
        String contactName;
        String contactFirstName;
        String contactLastName;
        String contactEmail;
        String contactPass;
        String contactLogMeInEmail;

        // get user Id
        List<User> users = [SELECT ContactId, Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
        if (!users.isEmpty()) {
            if (!String.isBlank(users[0].ContactId)) {
                contactId = users[0].ContactId;
            } else if (!String.isBlank(users[0].Contact_Id__c)) {
                contactId = users[0].Contact_Id__c;
            }
            // get contact info
            List<Contact> contactList = [SELECT Id, Name, FirstName, LastName, Email, LogMeIn_Password__c, LogMeIn_Email__c
                                        FROM Contact
                                        WHERE Id =:contactId];
            contactName = contactList[0].Name;
            contactFirstName = contactList[0].FirstName;
            contactLastName = contactList[0].LastName;
            contactEmail = contactList[0].Email;
            contactPass = contactList[0].LogMeIn_Password__c;
            contactLogMeInEmail = contactList[0].LogMeIn_Email__c;

            participants = [
                    SELECT Id, Event_custom__c
                    FROM Participant__c
                    WHERE Contact__c = :contactId AND Event_custom__c != NULL AND RecordType.Name = 'G2M'
            ];

            for (Participant__c p : participants) {
                eventIds.add(p.Event_custom__c);
            }

            if (!eventIds.isEmpty()) {
                meetings = [
                        SELECT Id, Name, Start_Time__c, Duration__c, CreatedBy.Contact.Name, Description__c,
                                Unique_Meeting_Id__c, Join_URL__c, Host_URL__c, External_Participants__c,
                        (SELECT Id, Status__c,Contact__c, Contact__r.Name FROM Participants__r)
                        FROM Event__c
                        WHERE RecordType.Name = 'G2M' AND Id IN :eventIds AND Start_Time__c != NULL AND Duration__c != NULL
                        ORDER BY Start_Time__c DESC
                ];
            }

            for (Event__c e : meetings) {
                meetingsToReturn.add(new Meeting(e));
            }
        }
        response.put('cId', new List<Id>{contactId});
        response.put('cName', new List<String>{contactName});
        response.put('contactFirstName', new List<String>{contactFirstName});
        response.put('contactLastName', new List<String>{contactLastName});
        response.put('contactEmail', new List<String>{contactEmail});
        response.put('contactPass', new List<String>{contactPass});
        response.put('contactLogMeInEmail', new List<String>{contactLogMeInEmail});
        response.put('meetings', meetingsToReturn);
        return JSON.serialize(response);
    }

    /**
     * Convert Integer to actual String for request
     *
     * @param i
     *
     * @return
     */
    public static String checkInteger(Integer i) {
        String result = '';
        if (i < 10) {
            result = '0' + String.valueOf(i);
        }else if (i == 0) {
            result = '00';
        } else {
            result = String.valueOf(i);
        }
        return result;
    }

    /**
     * Create Meeting on LogMeIn server
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String createMeetingLogMeIn(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String params = data.get('params');
        Map<String,Object> newMeetingParams = (Map<String, Object>)JSON.deserializeUntyped(params);

        String subject = newMeetingParams.get('subject') == null ?
                'New Meeting' : (String)newMeetingParams.get('subject');

        // Date and time
        List<String> startDateParams = ((String)newMeetingParams.get('startDate')).split('-');
        List<String> startTimeParams = ((String)newMeetingParams.get('startTime')).split(':');
        Integer yyyy = Integer.valueOf(startDateParams[0]);
        Integer dd = Integer.valueOf(startDateParams[2]);
        Integer mm = Integer.valueOf(startDateParams[1]);
        Integer hours = Integer.valueOf(startTimeParams[0]);
        Integer minutes = Integer.valueOf(startTimeParams[1]);

        // String meeting start time
        String st = checkInteger(yyyy) +'-'+ checkInteger(mm) +'-'+ checkInteger(dd) +'T'+ checkInteger(hours)+
                ':'+ checkInteger(minutes) +':00Z';

        Date myDate = Date.newInstance(yyyy, mm, dd);
        Time myTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime startTime = Datetime.newInstance(myDate, myTime);
        Datetime endTime = startTime.addMinutes((Integer)newMeetingParams.get('duration'));

        // End of meeting date and time
        Integer yyyyEnd = endTime.year();
        Integer ddEnd = endTime.day();
        Integer mmEnd = endTime.month();
        Integer hoursEnd = endTime.hour();
        Integer minutesEnd = endTime.minute();

        // String meeting end time
        String et = checkInteger(yyyyEnd) +'-'+ checkInteger(mmEnd) +'-'+ checkInteger(ddEnd) +'T'+
                checkInteger(hoursEnd) +':'+ checkInteger(minutesEnd) +':00Z';

        // Time zone
        String timezoneKey = 'Europe/Amsterdam';

        String requestBody = '{'+
                        '"subject": "'+subject+'",'+
                        '"starttime": "'+st+'",'+
                        '"endtime": "'+et+'",'+
                        '"passwordrequired": false,'+
                        '"conferencecallinfo": "hybrid",'+
                        '"timezonekey": "'+timezoneKey+'",'+
                        '"meetingtype": "scheduled"'+
        '}';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/G2M/rest/meetings');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);

        if(Test.isRunningTest()) {
            return '{"joinURL":"https://test/test"}';
        } else
        if (response.getStatusCode() == 201) {
            return response.getBody();
        } else {
            return generateErrorDescription(response);
        }
    }


    /**
     * create a meeting in Salesforce
     *
     * @param params
     *
     * @return
     */
    @AuraEnabled
    public static String createMeeting(Map<String, String> data) {
        System.debug('createMeeting');
        String params = data.get('params');
        String uniqueMeetingId = data.get('uniqueMeetingId');
        String joinURL = data.get('joinURL');
        String hostURL = data.get('hostURL');
        String ownerKey = data.get('ownerKey');

        Map<String,Object> newMeetingParams = (Map<String, Object>)JSON.deserializeUntyped(params);
        System.debug('newMeetingParams => '+ newMeetingParams);
        Id meetingRecordTypeId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('G2M').getRecordTypeId();
        System.debug('meetingRecordTypeId => '+ meetingRecordTypeId);
        Id participantRecordTypeId = Schema.SObjectType.Participant__c.getRecordTypeInfosByName().get('G2M').getRecordTypeId();
        System.debug('participantRecordTypeId => '+participantRecordTypeId);
        Event__c newMeeting = new Event__c();
        List<Participant__c> newParticipants = new List<Participant__c>();
        newMeeting.RecordTypeId = meetingRecordTypeId;
        newMeeting.Name = newMeetingParams.get('subject') == null ? 'New Meeting' : (String)newMeetingParams.get('subject');
        newMeeting.Description__c = (String)newMeetingParams.get('description');
        newMeeting.Duration__c = (Integer)newMeetingParams.get('duration');
        newMeeting.External_Participants__c = (String)newMeetingParams.get('externalParticipants');
        List<String> startDateParams = ((String)newMeetingParams.get('startDate')).split('-');
        List<String> startTimeParams = ((String)newMeetingParams.get('startTime')).split(':');
        Integer yyyy = Integer.valueOf(startDateParams[0]);
        Integer dd = Integer.valueOf(startDateParams[2]);
        Integer mm = Integer.valueOf(startDateParams[1]);
        Integer hours = Integer.valueOf(startTimeParams[0]);
        Integer minutes = Integer.valueOf(startTimeParams[1]);
        Date myDate = Date.newInstance(yyyy, mm, dd);
        Time myTime = Time.newInstance(hours, minutes, 0, 0);
        newMeeting.Start_Time__c = Datetime.newInstance(myDate, myTime);
        newMeeting.End_Time__c = newMeeting.Start_Time__c.addMinutes((Integer)newMeetingParams.get('duration'));
        if (uniqueMeetingId != null) {
            newMeeting.Unique_Meeting_Id__c = uniqueMeetingId;
        }
        if (joinURL != null) {
            newMeeting.Join_URL__c = joinURL;
        }
        if (hostURL != null) {
            newMeeting.Host_URL__c = hostURL;
        }
        if (ownerKey != null) {
            newMeeting.LogMeIn_Owner_Key__c = ownerKey;
        }

        List<Id> participantIds = new List<Id>();
        for (Object id : (List<Object>)newMeetingParams.get('participants')) {
            participantIds.add((Id)id);
            System.debug('participantIds => '+participantIds);
        }

        if ((String)newMeetingParams.get('index') != null) {
            newMeeting.Id = Id.valueOf((String)newMeetingParams.get('index'));
            System.debug('newMeeting.Id => '+ newMeeting.Id);
            System.debug(Id.valueOf((String)newMeetingParams.get('index')));
            List<Participant__c> participantsToDelete = [SELECT Id, Name FROM Participant__c WHERE Event_custom__c = :newMeeting.Id];
            System.debug('participantsToDelete => '+ participantsToDelete);
            delete participantsToDelete;
        }
        upsert newMeeting;

        for (Object id : (List<Object>)newMeetingParams.get('participants')) {
            if (String.isNotBlank((Id)id)) {
                Participant__c p = new Participant__c();
                p.RecordTypeId = participantRecordTypeId;
                p.Contact__c = (Id)id;
                p.Event_custom__c = newMeeting.Id;
                newParticipants.add(p);
            }
        }

        if (!newParticipants.isEmpty()) {
            insert newParticipants;
        }
        if (Test.isRunningTest()) {
            return 'done';
        } else {
            return GTMGenerator.getMeetings();
        }
    }


    /**
     * GET URL for start the meeting
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String startMeeting(Map<String, String> data) {
        String meetingId = data.get('meetingId');
        String accessToken = data.get('accessToken');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/G2M/rest/meetings/'+meetingId+'/start');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);

        HttpResponse response = http.send(request);

        return response.getBody();
    }


    /**
     * Delete meeting in Salesforce
     *
     * @param meetingId
     *
     * @return
     */
    @AuraEnabled
    public static String deleteMeeting(String meetingId) {
        System.debug('deleteMeeting');
        List<Event__c> meetingsToDelete = [
                SELECT Id,
                (SELECT Id FROM Participants__r)
                FROM Event__c
                WHERE Id = :meetingId
        ];

        if (!meetingsToDelete.isEmpty()) {
            delete meetingsToDelete[0].Participants__r;
            delete meetingsToDelete[0];
        }
        if (Test.isRunningTest()) {
            return 'done';
        }
        return GTMGenerator.getMeetings();
    }


    /**
     * Delete meeting on LogMeIn server
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String deleteMeetingLogMeIn(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String uniqueId = data.get('uniqueId');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/G2M/rest/meetings/'+ uniqueId);
        request.setMethod('DELETE');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);

        HttpResponse response = http.send(request);

        return response.getBody();
    }


    /**
     * Update Meeting
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String updateMeetingLogMeIn(Map<String, String> data){
        String accessToken = data.get('accessToken');
        String meetingUniqueId = data.get('meetingUniqueId');
        String params = data.get('params');
        Map<String,Object> newMeetingParams = (Map<String, Object>)JSON.deserializeUntyped(params);

        String subject = newMeetingParams.get('subject') == null ?
                'New Meeting' : (String)newMeetingParams.get('subject');

        // Date and time
        List<String> startDateParams = ((String)newMeetingParams.get('startDate')).split('-');
        List<String> startTimeParams = ((String)newMeetingParams.get('startTime')).split(':');
        Integer yyyy = Integer.valueOf(startDateParams[0]);
        Integer dd = Integer.valueOf(startDateParams[2]);
        Integer mm = Integer.valueOf(startDateParams[1]);
        Integer hours = Integer.valueOf(startTimeParams[0]);
        Integer minutes = Integer.valueOf(startTimeParams[1]);

        String st = checkInteger(yyyy) +'-'+ checkInteger(dd) +'-'+ checkInteger(mm) +'T'+ checkInteger(hours)+
                ':'+ checkInteger(minutes) +':00Z';

        Date myDate = Date.newInstance(yyyy, mm, dd);
        Time myTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime startTime = Datetime.newInstance(myDate, myTime);
        Datetime endTime = startTime.addMinutes((Integer)newMeetingParams.get('duration'));

        // End of meeting date and time
        Integer yyyyEnd = endTime.year();
        Integer ddEnd = endTime.day();
        Integer mmEnd = endTime.month();
        Integer hoursEnd = endTime.hour();
        Integer minutesEnd = endTime.minute();

        // String meeting end time
        String et = checkInteger(yyyyEnd) +'-'+ checkInteger(ddEnd) +'-'+ checkInteger(mmEnd) +'T'+
                checkInteger(hoursEnd) +':'+ checkInteger(minutesEnd) +':00Z';

        // Time zone
        String timezoneKey = 'Europe/Amsterdam';

        String requestBody = '{'+
                '"subject": "'+subject+'",'+
                '"starttime": "'+st+'",'+
                '"endtime": "'+et+'",'+
                '"passwordrequired": false,'+
                '"conferencecallinfo": "hybrid",'+
                '"timezonekey": "'+timezoneKey+'",'+
                '"meetingtype": "scheduled"'+
                '}';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/G2M/rest/meetings/'+ meetingUniqueId);
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);

        return response.getBody();
    }


    @AuraEnabled
    public static String getUpcomingMeetings(String accessToken){
        System.debug('getUpcomingMeetings');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/G2M/rest/upcomingMeetings');
        request.setMethod('GET');
        request.setHeader('Authorization', accessToken);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            return generateErrorDescription(response);
        }
    }

    /**
     * GET LogMeIn users
     *
     * @param data
     *
     * @return
     */
    // @AuraEnabled(Cacheable=true)
    @AuraEnabled(Cacheable=false)
    public static String getUsers(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String accountKey = data.get('accountKey');

        System.debug('getUsers accessToken: '+ accessToken);
        System.debug('getUsers accountKey: '+ accountKey);
        Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://api.getgo.com/admin/rest/v1/accounts/'+ accountKey +
                '/users?&ascending=lastName=true,firstName=true,email=true,admin=false');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);

        HttpResponse response = http.send(request);

        return response.getBody();
    }

    /**
     * GET Myself
     *
     * @param data
     */
    @AuraEnabled
    public static String getMyself(Map<String, String> data) {
        String accessToken = data.get('accessToken');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/admin/rest/v1/me');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);
        HttpResponse response = http.send(request);

        return response.getBody();
    }

    /**
     * GET SCIM Users
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String getUserSCIM(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String userName = data.get('userName');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/identity/v1/Users?filter=userName eq "'+userName+'"');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);

        HttpResponse response = http.send(request);

        return response.getBody();
    }

    /**
     * Create SCIM User
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String createUserSCIM(Map<String, String> data){
        String accessToken = data.get('accessToken');
        String displayName = data.get('userName');

        String userFirstName = data.get('userFirstName');
        String userLastName = data.get('userLastName');
        String userEmail = data.get('userEmail') + '@ean.org';
        String userPassword = data.get('userPass');

        String requestBody = '{"name": {"familyName": "'+userLastName+'", "givenName": "'+userFirstName+'"},'+
                +'"displayName": "'+displayName+'", "locale": "en_US", "timezone": "GMT",'+
                +'"userName": "'+userEmail+'", "password": "'+userPassword+'"}';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/identity/v1/Users');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);

        return response.getBody();
    }

    /**
     * Create user on LogMeIn server
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String createUser(Map<String, String> data){
        String accountKey = data.get('accountKey');
        String accessToken = data.get('accessToken');
        String userFirstName = data.get('userFirstName');
        String userLastName = data.get('userLastName');
        String userEmail = data.get('userEmail');
        Decimal licence = Decimal.valueOf(data.get('license'));

        String requestBody = '{ "users":[{ "email":"'+userEmail+'", "firstName":"'+userFirstName+'",'+
                +' "lastName":"'+userLastName+'", "locale":"en_US"}],'+
                +' "adminRoles":[], "managedGroupKeys":[],'+
                +' "licenseKeys":['+licence+'],'+
                +' "emailContent": { "subject":"Welcome to GoToMeeting",'+
                +' "text":"You have been added as a user to the GoToMeeting.'+
                +' Log in using your email as User ID at developer.logmein.com."}}';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/admin/rest/v1/accounts/'+ accountKey +'/users?allOrNothing=false');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            return response.getBody();
        } else {
            return response.getBody();
        }
    }


    /**
     * GET all account licenses
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static String getLicenses(Map<String, String> data){
        String accessToken = data.get('accessToken');
        String accountKey = data.get('accountKey');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/admin/rest/v1/accounts/'+ accountKey +'/licenses');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization','Bearer ' + accessToken);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            return generateErrorDescription(response);
        }
    }

    /**
     * SET license to user
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String setUserLicense(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String accountKey = data.get('accountKey');
        Decimal licence = Decimal.valueOf(data.get('licenceKey'));
        String userKey = data.get('userKey');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/admin/rest/v1/accounts/' + accountKey + '/licenses/' + licence +
                '/users/' + userKey + '?suppressEmail=TRUE');
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 204 || response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            return generateErrorDescription(response);
        }
     }

    /**
     * Delete user license
     *
     * @param data
     *
     * @return
     */
    @AuraEnabled
    public static String deleteUserLicense(Map<String, String> data) {
        String accessToken = data.get('accessToken');
        String accountKey = data.get('accountKey');
        String licence = data.get('licenceKey');
        String userKey = data.get('userKey');

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.getgo.com/admin/rest/v1/accounts/' + accountKey + '/licenses/' + licence +
                '/users/' + userKey + '?suppressEmail=TRUE');
        request.setMethod('DELETE');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        HttpResponse response = http.send(request);

        return response.getBody();
    }


    /**
     * Sens Email to participants
     *
     * @param data
     */
    @AuraEnabled
    public static List<String> sendEmailToParticipants(Map<String, String> data) {
        String participantsString = data.get('participantsString');
        String joinURL = data.get('joinURL');
        String ownerId = data.get('ownerId');
        String externalURL = data.get('externalURL');
        String meetingName = data.get('meetingName');
        String agenda = data.get('agenda');
        String meetingTime = data.get('meetingTime');
        String meetingDuration = data.get('meetingDuration');
        String startDate = data.get('startDate');
        String startDateTimeToInviteMethod = data.get('startDateTimeToInviteMethod');

        List<String> mailList = new List<String>();
        List<String> ownerList = new List<String>();
        List<String> listToReturn = new List<String>();
        String ownerLogin = null;
        String ownerPass = null;
        String ownerName = null;
        String siteUrl = null;
        // String mainUrl = Url.getSalesforceBaseUrl().toExternalForm();
        String mainUrl = 'https://eu30.lightning.force.com';

        // Get link to community
        Network myNetwork = [SELECT Id FROM Network WHERE Name ='ean'];

        if (Test.isRunningTest()) {
            siteUrl = 'https://dev1-ean.cs83.force.com/community/s/gotomeeting';
        } else {
            ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(myNetwork.Id);
            siteUrl = myCommunity.siteUrl + '/s/gotomeeting';
        }

        for(String eachStr : participantsString.split(',')) {
            // Owner data
            if (eachStr.equalsIgnoreCase(ownerId)) {
                Contact con = [SELECT Id, Name, Email, LogMeIn_Email__c, LogMeIn_Password__c
                                FROM Contact
                                WHERE Id =: ownerId];
                if (String.isNotBlank(con.Email)) {
                    ownerList.add(con.Email);
                }
                ownerLogin = con.LogMeIn_Email__c;
                ownerPass = con.LogMeIn_Password__c;
                ownerName = con.Name;
            } else {
                // Participants data
                Contact con = [SELECT Id, Email, LogMeIn_Email__c, LogMeIn_Password__c
                            FROM Contact
                            WHERE Id =: eachStr];
                if (String.isNotBlank(con.Email)) {
                    mailList.add(con.Email);
                }
            }
        }
        if (String.isNotBlank(externalURL)) {
            for (String str : externalURL.split(',')) {
                if (String.isNotBlank(str) && str.containsAny('@')) {
                    mailList.add(str);
                }
            }
        }

        // Get Email Wide Address from org
        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE 'noreply@ean.org' LIMIT 1];
        System.debug('Email send from address: '+address);

        if (!ownerList.isEmpty()) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] {};

            message.setToAddresses(ownerList);
            message.optOutPolicy = 'FILTER';
            message.subject = meetingName+' on '+startDate+' - GoToMeeting';
            message.htmlBody = '<div width="100%" style="background-color:#285ED1;padding:10px 0 10px 30px">' +
                '<span style="height:30px;color:white;"><b style="font-size:16px;">EAN</b></span></div>';
            message.htmlBody += '<h3>'+meetingName+'</h3><h4>Agenda</h4>';
            if(agenda != '') {
                message.htmlBody += '<h4>'+agenda+'</h4>';
            } else {
                message.htmlBody += '<h4>There was no agenda submitted for this meeting.</h4>';
            }
            // message.htmlBody += '<p>Organizer: <a href="https://ean--dev1.lightning.force.com/lightning/r/Contact/+ownerId+/view">'
            message.htmlBody += '<p>Organizer: <a href="'+mainUrl+'/lightning/r/Contact/'+ownerId+'/view">'
                +ownerName+'</a><br>Date: '+startDate+'<br>Duration: '+meetingDuration+' min</p>';
            message.htmlBody += '<div style="display:flex;flex-direction:row;padding:0 50px 0 50px;">'+
                '<a style="background-color:#285ED1;color:white;width:50%;height:30px;display:flex;flex-direction:row;padding:auto;" ' +
                'href="'+ siteUrl +'"><span style="margin:auto;">Open Meeting in MyEAN</span></a>'+
                '</div>';
            message.htmlBody += '<br><br><b>As organiser, you need to start the meeting using the following link:</b>' +
                '<br>'+ siteUrl;
            message.htmlBody += '<p><b>Your credentials to start the meeting.</b> <br>Login: '+ownerLogin+'<br>Password: '+ownerPass+'</p>';
            message.htmlBody += '<h4>Please note:</h4>';
            message.htmlBody += '<ul><li>It is not possible to start meeting on mobile devices!</li>'+
                '<li>By using the EAN Webconferencing tool, you agree with the <a href="https://www.ean.org/terms-privacy">EAN Terms</a> and '+
                '<a href="https://www.ean.org/terms-privacy">Privacy Policy</a>.</li><li>This link is valid 2 hours prior to the meeting</li></ul>';

            message.setReplyTo('noreply@ean.org');
            // message.setSenderDisplayName('noreply@ean.org');

            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.fileName = 'invite.ics';
            attach.contentType = 'text/calendar';
            attach.inline = true;
            attach.body = invite(startDateTimeToInviteMethod, meetingDuration);
            message.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});

            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            message.setOrgWideEmailAddressId(address.Id);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            if (results[0].success)
            {
                System.debug('The email to owner was sent successfully.');
            }
            listToReturn.addAll(message.toAddresses);
        }
        if (!mailList.isEmpty()) {
            Messaging.SingleEmailMessage mess = new Messaging.SingleEmailMessage();
            mess.toAddresses = new String[] {};

            mess.setToAddresses(mailList);
            mess.optOutPolicy = 'FILTER';
            mess.subject = meetingName+' on '+startDate+' - GoToMeeting';
            mess.htmlBody = '<div width="100%" style="background-color:#285ED1;padding:10px 0 10px 30px">' +
                    '<span style="height:30px;color:white;"><b style="font-size:16px;">EAN</b></span></div>';
            mess.htmlBody += '<h3>'+meetingName+'</h3><h4>Agenda</h4>';
            if(agenda != '') {
                mess.htmlBody += '<h4>'+agenda+'</h4>';
            } else {
                mess.htmlBody += '<h4>There was no agenda submitted for this meeting.</h4>';
            }
            mess.htmlBody += '<p>Organizer: <a href="'+mainUrl+'/lightning/r/Contact/'+ownerId+'/view">'
                +ownerName+'</a><br>Date: '+startDate+'<br>Duration: '+meetingDuration+' min'+'</p>';
            mess.htmlBody += '<div style="display:flex;flex-direction:row;padding:0 50px 0 50px;">'+
                '<a style="background-color:#285ED1;color:white;width:50%;height:30px;display:flex;flex-direction:row;padding:auto;" ' +
                'href="'+ siteUrl +'"><span style="margin:auto;">Open Meeting in MyEAN</span></a>'+
                '</div>';
            mess.htmlBody += '<br><br><b>You can join this meeting using the following link:</b><br>' + joinURL;
            mess.htmlBody += '<h4>Please note:</h4>';
            mess.htmlBody += '<ul><li>It is not possible to start meeting on mobile devices!</li>'+
                '<li>By using the EAN Webconferencing tool, you agree with the <a href="https://www.ean.org/terms-privacy">EAN Terms</a> and '+
                '<a href="https://www.ean.org/terms-privacy">Privacy Policy</a>.</li><li>This link is valid 2 hours prior to the meeting</li></ul>';

            mess.setReplyTo('noreply@ean.org');
            // mess.setSenderDisplayName('noreply@ean.org');

            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.fileName = 'invite.ics';
            attach.contentType = 'text/calendar';
            attach.inline = true;
            attach.body = invite(startDateTimeToInviteMethod, meetingDuration);
            mess.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});

            Messaging.SingleEmailMessage[] messagesPar =   new List<Messaging.SingleEmailMessage> {mess};
            mess.setOrgWideEmailAddressId(address.Id);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesPar);

            if (results[0].success)
            {
                System.debug('The email to participants was sent successfully.');
            }
            listToReturn.addAll(mess.toAddresses);
        }

        return listToReturn;
    }

    private static Blob invite(String startDateTimeToInviteMethod, String meetingDuration) {

        // Parse data string to List
        List<Integer> meetList = new List<Integer>();
        for (String val : startDateTimeToInviteMethod.split(',')) {
            meetList.add(Integer.valueOf(val));
        }

        Integer meetYear = meetList[0];
        Integer meetMonth = meetList[1];
        Integer meetDay = meetList[2];
        Integer meetHours = meetList[3];
        Integer meetMinutes = meetList[4];
        Integer meetSeconds = 0;

        Datetime dt = Datetime.newInstance(meetYear, meetMonth, meetDay, meetHours, meetMinutes, meetSeconds);
        String startDateTime = String.valueOf(dt.year()+'0'+dt.month()+''+dt.day()+'T'+dt.hour()+dt.minute()+'00Z');
        Datetime endDt = dt.addMinutes(Integer.valueOf(meetingDuration));
        String endDateTime = String.valueOf(endDt.year()+'0'+endDt.month()+''+endDt.day()+'T'+endDt.hour()+endDt.minute()+'00Z');

        String txtInvite = '';
        txtInvite += 'BEGIN:VCALENDAR\n';
        txtInvite += 'PRODID::-//hacksw/handcal//NONSGML v1.0//EN\n';
        txtInvite += 'VERSION:2.0\n';
        txtInvite += 'METHOD:PUBLISH\n';
        txtInvite += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
        txtInvite += 'BEGIN:VEVENT\n';
        txtInvite += 'CLASS:PUBLIC\n';
        txtInvite += 'CREATED:20200313T003709Z\n';
        txtInvite += 'DTEND;TZID=Europe/Amsterdam:'+ endDateTime +'\n';
        txtInvite += 'DTSTAMP:20300313T003709Z\n';
        txtInvite += 'DTSTART;TZID=Europe/Amsterdam:'+ startDateTime +'\n';
        txtInvite += 'LAST-MODIFIED:20200313T203709Z\n';
        txtInvite += 'LOCATION:GoToMeeting online\n';
        txtInvite += 'PRIORITY:5\n';
        txtInvite += 'SEQUENCE:0\n';
        // VALARM start
        txtInvite += 'BEGIN:VALARM\n';
        txtInvite += 'TRIGGER:-PT10M\n';
        txtInvite += 'DESCRIPTION:Meeting Reminder\n';
        txtInvite += 'ACTION:DISPLAY\n';
        txtInvite += 'END:VALARM\n';
        // VALARM end
        txtInvite += 'SUMMARY;';
        txtInvite += 'LANGUAGE=en-us:Meeting\n';
        txtInvite += 'TRANSP:OPAQUE\n';
        txtInvite += 'X-ALT-DESC;FMTTYPE=text/html:<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000"><TITLE></TITLE></HEAD><BODY><!-- Converted from text/plain format --></BODY></HTML>\n';
        txtInvite += 'X-MICROSOFT-CDO-BUSYSTATUS:BUSY\n';
        txtInvite += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
        txtInvite += 'END:VEVENT\n';
        txtInvite += 'END:VCALENDAR';
        return Blob.valueOf(txtInvite);
    }

    private static String generateErrorDescription (HttpResponse response) {
        System.debug('generateErrorDescription');
        System.debug(response);
        Map<String, String> errorMap = new Map<String, String>();

        switch on response.getStatusCode() {
            when 400 {
                errorMap.put('request_error','Bad Request');
            }
            when 401 {
                errorMap.put('request_error','Forbidden : ' + response.getBody());
            }
            when 403 {
                errorMap.put('request_error','Server Error');
            }
            when 404 {
                errorMap.put('request_error','Resource Not Found');
            }
            when 409 {
                errorMap.put('request_error','Conflict');
            }
            when 500 {
                errorMap.put('request_error','Internal Server Error');
            }
        }

        return JSON.serialize(errorMap);
    }

    private class Meeting {
        private String startDateTime;
        private String startTime;
        private Date startDate;
        private Date endDate;
        private String endTime;
        private String subject;
        private String organizerName;
        private String organizerId;
        private String status;
        private String description;
        private Integer participants;
        private List<Participant> participantList;
        private Boolean isFinished;
        private Boolean isNotEditable;
        private Id index;
        private Integer duration;
        private String uniqueMeetingId;
        private String JoinURL;
        private String hostURL;
        private String externalParticipants;
        private Id cId;

        private Meeting(Event__c e) {
            Datetime endDateTime = e.Start_Time__c.addMinutes(Integer.valueOf(e.Duration__c));
            subject = e.Name;
            organizerName = e.CreatedBy.Contact.Name != null ? e.CreatedBy.Contact.Name : 'Unknown';
            organizerId = 'testId';
            participants  = e.Participants__r.size();
            index = e.Id;
            isNotEditable = true;
            duration = (Integer)e.Duration__c;
            uniqueMeetingId = e.Unique_Meeting_Id__c;
            JoinURL = e.Join_URL__c;
            hostURL = e.Host_URL__c;
            externalParticipants = e.External_Participants__c;

            //Checking current Status of a meeting ===>
            startTime = e.Start_Time__c.hour() + ':' + e.Start_Time__c.format('mm');
            startDate = Date.newInstance(e.Start_Time__c.year(), e.Start_Time__c.month(), e.Start_Time__c.day());
            startDateTime = e.Start_Time__c.format('MMM') + ' ' + e.Start_Time__c.day() + ', ' +
                    + e.Start_Time__c.format('yy') + ' at ' +  e.Start_Time__c.hour() + ':' + e.Start_Time__c.format('mm');
            endTime = endDateTime.hour() + ':' + endDateTime.format('mm');
            endDate = Date.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day());
            Datetime currentDatetime = Datetime.now();
            if (endDateTime < currentDatetime) {
                status = 'FINISHED';
            } else if (e.Start_Time__c < currentDatetime && endDateTime > currentDatetime) {
                status = 'IN PROGRESS';
            } else {
                status = 'SCHEDULED';
                isNotEditable = false;
            }
            isFinished = status == 'FINISHED' ? true : false;
            //<===

            //Checking description of a meeting ===>
            if (e.Description__c != null && e.Description__c.contains('<img src="/community')) {
                String newPath =   Url.getOrgDomainUrl().toExternalForm().replace('.my.salesforce.com','--c.documentforce.com');
                description = e.Description__c.replaceAll('<img src="/community','<img src="' + newPath);
            } else {
                description = e.Description__c;
            }
            //<===

            //Checking is the current user the owner of this meeting ===>
            if (e.CreatedBy.Contact.Name != UserInfo.getName()) {
                isNotEditable = true;
            }
            //<===

            participantList = new List<Participant>();
            for (Participant__c p : e.Participants__r) {
                participantList.add(new Participant(p));
            }
        }
    }

    private class Participant {
        private String recId;
        private String selectName;

        private Participant(Participant__c p) {
            recId = (String)p.Contact__c;
            selectName = p.Contact__r.Name;
        }
    }
}