/*
Unit Tests are located in the RemoveAndGenerateInvoicesBatchesTest class
* */
public class GenerateInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c = 'Batch: GenerateInvoicesBatch';
        log.Start_Time__c = Datetime.now();
        log.Status__c = 'In Progress';
        insert log;
        log.Status__c = 'Completed';
        log.Message__c = '';

        return Database.getQueryLocator(
                'SELECT Id, Name, Invoice_Number__c, Purchase_Type__c, Type__c FROM Order__c WHERE Status__c = \'Paid\' ORDER BY CreatedDate ASC'
        );
    }
    public void execute(Database.BatchableContext bc, List<Order__c> orders) {
        try {
            List<ContentVersion> attachments = new List<ContentVersion>();
            List<ContentVersion> newAttachments = new List<ContentVersion>();
            Map<String, ContentVersion> attachmentMap = new Map<String, ContentVersion>();
            Map<String, String> fileOrderMap = new Map<String, String>();
            Set<String> attachmentNames = new Set<String>();

            // Generate new Invoice Numbers
            Boolean generated = InvoicePDFGenerator.generateInvoiceNumber(orders);

            List<Network> community = [SELECT Id FROM Network WHERE Name = 'ean'];

            if (generated) {

                // Collect all Attachment Names
                for (Order__c o : orders) {
                    attachmentNames.add('Invoice_' + o.Name + '.pdf');
                }

                // Collect all related Attachments
                attachments = [SELECT Title, VersionData FROM ContentVersion WHERE Title IN :attachmentNames];

                for (ContentVersion at : attachments) {
                    attachmentMap.put(at.Title, at);
                }

                for (Order__c o : orders) {
                    ContentVersion att;

                    // if PDF doesn't exist
                    if (!attachmentMap.keySet().contains('Invoice_' + o.Name + '.pdf')) {
                        PageReference defaultPage = new PageReference('/apex/InvoicePage');
                        defaultPage.getParameters().put('co', o.Id);
                        defaultPage.getParameters().put('in', o.Invoice_Number__c);
                        Blob pageData;

                        if (Test.isRunningTest()) {
                            pageData = Blob.valueOf('Unit.Test');
                        } else {
                            pageData = defaultPage.getContent();
                        }
                        att = new ContentVersion(
                                VersionData = pageData,
                                Title = 'Invoice_' + o.Name + '.pdf',
                                PathOnClient = 'Invoice_' + o.Name + '.pdf',
                                IsMajorVersion = true,
                                ContentLocation = 'S',
                                NetworkId = community[0].Id
                        );
                        newAttachments.add(att);
                        fileOrderMap.put(att.Title, o.Id);
                        // else if PDF exists
                    } else {
                        att = attachmentMap.get('Invoice_' + o.Name + '.pdf');
                    }
                }

                // Insert new PDF Invoices as Attachments
                if (!newAttachments.isEmpty()) {
                    insert newAttachments;

                    List<ContentVersion> cds = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :newAttachments];
                    List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
                    for (ContentVersion cd : cds) {
                        Id orderId = fileOrderMap.get(cd.Title);
                        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = orderId,
                                ShareType = 'V', ContentDocumentId = cd.ContentDocumentId, Visibility = 'AllUsers');
                        cdLinks.add(link);
                    }

                    if (!cdLinks.isEmpty()) {
                        insert cdLinks;
                    }
                }
            }

        } catch (Exception e) {
            log.Message__c += e.getMessage() + '\n';
            log.Status__c = 'Error';
        }
    }
    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }
}