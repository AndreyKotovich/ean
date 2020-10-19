public with sharing class EAN_EmailBatch implements Database.Batchable<SObject> {
    public EAN_EmailBatch() {

    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String status = 'Registered';
        System.debug(Database.getQueryLocator('SELECT Id FROM Participant__c WHERE Status__c = :status AND Participant_Email__c = null'));
        return Database.getQueryLocator(
            'SELECT Id FROM Participant__c WHERE Status__c = :status AND Participant_Email__c = null'
            );
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {
        for(Participant__c participant : participants) {
            System.debug(participant);
        }
    }
    public void finish(Database.BatchableContext BC) {

    }
}