public with sharing class QRcodeBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<String> participantIds;
    public QRcodeBatch(List<String> participantIds) {
        this.participantIds = participantIds;
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    public void execute(Database.BatchableContext BC, List<Participant__c> participants) {

    }
    public void finish(Database.BatchableContext BC) {

    }
}