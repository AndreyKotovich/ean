/*
Unit Tests are located in the RemoveAndGenerateInvoicesBatchesTest class
* */
public with sharing class RemoveInvoicesAndInvoiceNumbersBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: RemoveInvoicesAndInvoiceNumbersBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        return Database.getQueryLocator(
                'SELECT Id, Status__c, Invoice_Number__c FROM Order__c WHERE Status__c = \'Paid\''
        );
    }
    public void execute(Database.BatchableContext bc, List<Order__c> records) {
        try {
            Set<Id> orderIds = new Set<Id>();

            for (Order__c order : records){
                orderIds.add(order.Id);
                if (order.Invoice_Number__c != null){
                    order.Invoice_Number__c = null;
                }
            }

            update records;

            List<ContentDocumentLink> invoicesLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :orderIds AND LinkedEntity.Type='Order__c' AND ContentDocument.Title LIKE '%Invoice%'];
            List<ContentDocument> contentDocuments = new List<ContentDocument>();

            for (ContentDocumentLink link : invoicesLinks){
                contentDocuments.add(new ContentDocument(Id = link.ContentDocumentId));
            }

            if (!contentDocuments.isEmpty()){
                delete contentDocuments;
            }
        }catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }
    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}