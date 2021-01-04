@IsTest
public with sharing class CaseTriggerHelperTest {
    @IsTest public static void postRecordsTo45kBrainsTest(){
        List<Network> community = [SELECT Id FROM Network WHERE Name = 'ean' LIMIT 1];

        CollaborationGroup fortyFiveKBrains = new CollaborationGroup(Name = '45,000 Brains - Neurology Case Forum_1', NetworkId = community[0].Id, CollaborationType='Public');
        insert fortyFiveKBrains;

        String richText = '<p><img src="test.test" alt="test.png"></img></p>';
        richText += '<p><img src="test.test" alt="test.png"></img></p>';

        Case c = new Case(
                Subject = 'Test', patient_disclaimer__c = true, Clinical_History__c = 'Clinical History',
                Scans_or_other_images__c = richText, Examination_Investigation_Findings__c = 'Examination_Investigation_Findings__c',
                Differential_Diagnosis__c = 'Differential_Diagnosis__c', Challenge_Question__c = 'Challenge_Question__c');
        insert c;

        c.Status = 'Accepted';

        Test.startTest();
        update c;
        Test.stopTest();

        c = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Posted', c.Status);
    }

}