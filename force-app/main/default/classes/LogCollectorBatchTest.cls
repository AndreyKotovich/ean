@IsTest
public class LogCollectorBatchTest {
    @IsTest public static void logCollectorTest(){
        List<Log__c> logs = new List<Log__c>();

        for(Integer i=0; i<10; i++){
            logs.add(new Log__c(Process_Name__c='Test'));
        }

        insert  logs;

        for(Integer i = 0; i<logs.size()/2; i++){
            Test.setCreatedDate(logs[i].Id, Datetime.now().addMonths(-2).addDays(-1));
        }

        Test.startTest();
        LogCollectorBatch job = new LogCollectorBatch();
        Database.executeBatch(job, 200);
        Test.stopTest();

        System.assertEquals(5, [SELECT Id FROM Log__c WHERE Process_Name__c='Test'].size());

        for(Log__c l : [SELECT Id, CreatedDate FROM Log__c]){
            Datetime now = Datetime.now();
            System.assertEquals(now.day(), l.CreatedDate.day());
            System.assertEquals(now.month(), l.CreatedDate.month());
            System.assertEquals(now.year(), l.CreatedDate.year());
        }
    }
}