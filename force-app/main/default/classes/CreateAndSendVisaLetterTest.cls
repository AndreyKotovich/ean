@isTest
public class CreateAndSendVisaLetterTest {
    @isTest(SeeAllData = true)
    public static void AttachAndSendVisaLetterTest() {
        Test.startTest();
            Contact c = new Contact(LastName = 'test', Email = 'testEm@test.com', MailingStreet = 'TestStreet',
                    MailingCity = 'TestCity', MailingPostalCode = '11111',
                    MailingCountry = 'Germany');
            insert c;
    
            Id congressEventRT = Schema.SObjectType.Event__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
            Event__c event = new Event__c(Name = 'Event1', RecordTypeId = congressEventRT, 
                Start_Time__c = System.now().addDays(10), End_Time__c = System.now().addDays(20), Status__c = 'Scheduled');
            insert event;
            
            Id congressParticipantRT = Schema.SObjectType.Participant__c.getRecordTypeInfosByDeveloperName().get('Congress').getRecordTypeId();
            Participant__c p = new Participant__c(Contact__c = c.Id, Event_custom__c = event.Id, 
                RecordTypeId = congressParticipantRT, Status__c = 'Registered');
            insert p;
           
            Visa_Letter__c vL = new Visa_Letter__c(Event_Participation__c =p.Id);
            insert vL;
            CreateAndSendVisaLetter.AttachAndSendVisaLetter( new List<Id> { vL.Id } );
        Test.stopTest();
        
        List<Visa_Letter__c> vLs = [ SELECT Id, Name FROM Visa_Letter__c WHERE Id =:vL.Id];
        String expectedAtt1Name = 'VisaLetter_1_' + vLs[0].Name  + '.pdf';
        String expectedAtt2Name = 'VisaLetter_2_' + vLs[0].Name  + '.pdf';
        List<ContentVersion> attachments = [SELECT Title FROM ContentVersion WHERE Title =:expectedAtt1Name OR Title =:expectedAtt2Name];
        System.assertEquals(2, attachments.size());
    
    }
}