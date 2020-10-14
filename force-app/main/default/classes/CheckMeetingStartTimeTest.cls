@IsTest
public with sharing class CheckMeetingStartTimeTest {

    @TestSetup
    public static void setup() {
        Id meetingPTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('G2M').getRecordTypeId();
        Event__c meeting1 = new Event__c(Name = 'Test Start Meeting 1', RecordTypeId = meetingPTId, Start_Time__c = Datetime.now().addMinutes(-5),
                Duration__c = 150, LogMeIn_Owner_Key__c = '0123456789', End_Time__c = Datetime.now().addMinutes(30));
        insert meeting1;

        Event__c meeting2 = new Event__c(Name = 'Test Stop Meeting 1', RecordTypeId = meetingPTId, Start_Time__c = Datetime.now().addMinutes(-45),
                Duration__c = 150, LogMeIn_Owner_Key__c = '0123456789', End_Time__c = Datetime.now().addMinutes(-15));
        insert meeting2;

        G2M_Settings_Obj__c g2ms = new G2M_Settings_Obj__c(
                Name = 'Sandbox',
                Account_Key__c = '4845706458463628293',
                Admin_Email__c = 'test@test.com',
                Admin_Password__c = '1234567',
                Consumer_Key__c = 'RP3r0b7UsFMBO5MVARg',
                Consumer_Secret__c = 'jdkjughvqeNEnefe4A',
                Expires_in__c = 3600,
                Access_Token__c = '0b7UsFMBO5MVARughvqeNEnef');
        insert g2ms;
    }

    @IsTest
    public static void scheduleStartTest() {
        Test.startTest();
//        CheckMeetingStartTime cmst = new CheckMeetingStartTime();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        CheckMeetingStartTime cmst = new CheckMeetingStartTime();
        String sch = '0 0 * * * ?';
        System.schedule('Test Start', sch, cmst);
        Test.stopTest();
    }

    @IsTest
    public static void setLicenseTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        CheckMeetingStartTimeQueueable.getAndSetLicenses('12345678','12345678');
        Test.stopTest();
    }

    @IsTest
    public static void deleteLicenseTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetSomethingLogMeInMock());
        CheckMeetingStartTimeQueueable.getAndDeleteLicenses('12345678','12345678');
        Test.stopTest();
    }

}