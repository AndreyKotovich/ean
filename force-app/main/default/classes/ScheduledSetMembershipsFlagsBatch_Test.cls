@IsTest
public with sharing class ScheduledSetMembershipsFlagsBatch_Test {
    @IsTest public static void executeTest(){
        String sch = '0 0 1 * * ?';
        Test.startTest();
        System.schedule('ScheduledApexTest', sch, new ScheduledSetMembershipsFlagsBatch());
        Test.stopTest();
    }
}