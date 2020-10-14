public class CheckMeetingStartTimeQueueable implements Queueable, Database.AllowsCallouts{
    public void execute(QueueableContext context) {
        System.debug('CheckMeetingStartTime execute');
        Datetime nowDatetime = Datetime.now();
        Datetime checkedDatetime = nowDatetime.addMinutes(20);
        Datetime endDatTime = nowDatetime.addMinutes(-10);

        // Check if there are upcoming meetings
        List<Event__c> meetingsToStart = [
                SELECT Id, Start_Time__c, End_Time__c
                FROM Event__c
                WHERE Start_Time__c <=: checkedDatetime
                AND End_Time__c >=: nowDatetime
                AND LogMeIn_Owner_Key__c != null
        ];

        System.debug(meetingsToStart);

        //Check if there are finished meetings
        List<Event__c> meetingsToEnd = [
                SELECT Id
                FROM Event__c
                WHERE Start_Time__c < : nowDatetime
                AND End_Time__c <=: endDatTime
                AND End_Time__c >= : endDatTime.addMinutes(-10)
                AND LogMeIn_Owner_Key__c != null
        ];

        if (!meetingsToStart.isEmpty() || !meetingsToEnd.isEmpty()) {
            // Get admin token and account key
            String logData = GTMGenerator.getAccessToken();
            System.debug(logData);

            Map<String, String> responseTokenMap = new Map<String, String>();
            responseTokenMap = (Map<String,String>)JSON.deserialize(logData, Map<String,String>.class);
            System.debug(responseTokenMap);

            String accessToken = responseTokenMap.get('access_token');
            String accountKey =  responseTokenMap.get('account_key');

            if (!meetingsToStart.isEmpty()) {
                System.debug('!meetingsToStart.isEmpty()');
                getAndSetLicenses(accessToken, accountKey);
            }

            if (!meetingsToEnd.isEmpty()) {
                getAndDeleteLicenses(accessToken, accountKey);
            }
        }
    }

    @Future(callout=true)
    public static void getAndSetLicenses(String accessToken, String accountKey){
        System.debug('CheckMeetingStartTime getAndSetLicenses');

        // Get licenses
        String licenseData = GTMGenerator.getLicenses(new Map<String, String>{'accessToken' => accessToken, 'accountKey' => accountKey});
        System.debug(licenseData);
        Map<String, Object> responseLicenses =  (Map<String,Object>)JSON.deserializeUntyped(licenseData);
        System.debug(responseLicenses);

        String licenseKey = '0';
        if (responseLicenses.get('results') != null) {
            System.debug('responseLicenses != mull');
            for (Object instance : (List<Object>)responseLicenses.get('results')) {
                System.debug(instance);
                Map<String, Object> license = (Map<String, Object>)instance;
                if (String.valueOf(license.get('products')).contains('G2M') && Integer.valueOf(license.get('userCount')) < Integer.valueOf(license.get('seats'))) {
                    licenseKey =  String.valueOf(license.get('key'));
                    System.debug(licenseKey);
                    break;
                }
            }
        }


        // Set licenses
        if (licenseKey != '0' || Test.isRunningTest()) {
            System.debug('licenseKey != 0');
            Datetime nowDatetime = Datetime.now();
            Datetime checkedDatetime = nowDatetime.addMinutes(20);

            List<Event__c> meetings = [
                    SELECT Id, LogMeIn_Owner_Key__c, Start_Time__c, End_Time__c
                    FROM Event__c
                    WHERE Start_Time__c <=: checkedDatetime
                    AND End_Time__c >=: nowDatetime
                    AND LogMeIn_Owner_Key__c != null
            ];
            System.debug(meetings);

            for (Event__c meeting : meetings) {
                System.debug(meeting);
                System.debug(accessToken);
                System.debug(accountKey);
                System.debug(meeting.LogMeIn_Owner_Key__c);
                GTMGenerator.setUserLicense(new Map<String, String>{'accessToken' => accessToken, 'accountKey' => accountKey, 'licenceKey' => licenseKey, 'userKey' => meeting.LogMeIn_Owner_Key__c});
            }
        }
    }

    @Future(callout=true)
    public static void getAndDeleteLicenses(String accessToken, String accountKey){
        System.debug('CheckMeetingStartTime getAndDeleteLicenses');

        // Get licenses
        String licenseData = GTMGenerator.getLicenses(new Map<String, String>{'accessToken' => accessToken, 'accountKey' => accountKey});
        Map<String, Object> responseLicenses =  (Map<String,Object>)JSON.deserializeUntyped(licenseData);

        String licenseKey = '0';
        if (responseLicenses.get('results') != null) {
            for (Object instance : (List<Object>)responseLicenses.get('results')) {
                Map<String, Object> license = (Map<String, Object>)instance;
                if (String.valueOf(license.get('products')).contains('G2M')) {
                    licenseKey =  String.valueOf(license.get('key'));
                    break;
                }
            }
        }


        // Delete licenses
        if (licenseKey != '0' || Test.isRunningTest()) {
            Datetime nowDatetime = Datetime.now();
            Datetime endDatTime = nowDatetime.addMinutes(-10);
            List<Event__c> meetings = [
                    SELECT Id, LogMeIn_Owner_Key__c
                    FROM Event__c
                    WHERE Start_Time__c < : nowDatetime
                    AND End_Time__c <=: endDatTime
                    AND End_Time__c >= : endDatTime.addMinutes(-10)
                    AND LogMeIn_Owner_Key__c != null
            ];

            for (Event__c meeting : meetings) {
                GTMGenerator.deleteUserLicense(new Map<String, String>{'accessToken' => accessToken, 'accountKey' => accountKey, 'licenceKey' => licenseKey, 'userKey' => meeting.LogMeIn_Owner_Key__c});
            }
        }
    }
}