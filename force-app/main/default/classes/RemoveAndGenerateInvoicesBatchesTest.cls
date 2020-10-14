@IsTest
public with sharing class RemoveAndGenerateInvoicesBatchesTest {
    @TestSetup public static void setup(){
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i<10; i++){
            contacts.add(new Contact(LastName = 'Test', Email = 'test@test.com'));
        }

        insert contacts;

        List<Order__c> orders = new List<Order__c>();

        for (Integer i = 0; i<contacts.size(); i++){
            orders.add(new Order__c(Contact__c=contacts[i].Id, Status__c = 'Paid', Invoice_Number__c = 'TEST-'+i));
        }

        insert  orders;
    }

    @IsTest public static void generateInvoicesTest(){
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch(), 200);
        Test.stopTest();

        List<Order__c> orders = [SELECT Id, Status__c, Invoice_Number__c FROM Order__c WHERE Status__c = 'Paid'];
        Set<Id> orderIds = new Set<Id>();

        for (Order__c order : orders){
            orderIds.add(order.Id);
            System.assert(order.Invoice_Number__c.contains('EIMF'));
        }

        List<ContentDocumentLink> invoicesLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :orderIds AND LinkedEntity.Type='Order__c' AND ContentDocument.Title LIKE '%Invoice%'];
        System.assertEquals(10, invoicesLinks.size());
    }

    @IsTest public static void removeInvoicesTest(){
        List<Order__c> orders = [SELECT Id, Status__c, Invoice_Number__c FROM Order__c WHERE Status__c = 'Paid'];
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'test@test.com'];
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for(Integer i = 0; i<contacts.size(); i++){
            contentVersions.add( new ContentVersion(
                    Title = 'Invoice'+1,
                    PathOnClient = 'Invoice'+i+'.jpg',
                    VersionData = Blob.valueOf('Test Content Data'),
                    IsMajorVersion = true
            ));
        }

        insert contentVersions;
        contentVersions = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions];

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();

        for (Integer i = 0; i<orders.size(); i++){
            newLinks.add( new ContentDocumentLink(LinkedEntityId = orders[i].Id, ShareType = 'V', Visibility = 'AllUsers', ContentDocumentId = contentVersions[i].ContentDocumentId));
        }

        insert newLinks;

        Set<Id> orderIds = new Set<Id>();

        for (Order__c order : orders){
            orderIds.add(order.Id);
        }

        List<ContentDocumentLink> invoicesLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :orderIds AND LinkedEntity.Type='Order__c' AND ContentDocument.Title LIKE '%Invoice%'];
        System.assertEquals(10, invoicesLinks.size());

        Test.startTest();
        Database.executeBatch(new RemoveInvoicesAndInvoiceNumbersBatch(), 200);
        Test.stopTest();

        invoicesLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :orderIds AND LinkedEntity.Type='Order__c' AND ContentDocument.Title LIKE '%Invoice%'];
        System.assertEquals(0, invoicesLinks.size());
    }
}