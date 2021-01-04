@isTest
public with sharing class DownloadAbstractBookControllerTest {
    @isTest
    static void testPage() {
        List<Abstract__c> abs = new List<Abstract__c>();

        Test.startTest();
        Test.setCurrentPage(Page.DownloadAbstractBook);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(abs);
        DownloadAbstractBookController extension = new DownloadAbstractBookController(stdSetController);
        extension.doWord();
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooksWord?type=AbstractStaff',extension.redirectUrl );
        extension.doPDF();
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooks?type=AbstractStaff',extension.redirectUrl );
        extension.doHTML();
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm() + '/apex/AbstractBooksHtml?type=AbstractStaff',extension.redirectUrl );
        Test.stopTest();

    }
    
}