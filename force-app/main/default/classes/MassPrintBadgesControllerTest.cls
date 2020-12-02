@IsTest
public with sharing class MassPrintBadgesControllerTest {
    @IsTest
    public static void MassPrintBadgesControllerTest(){
        List<Event_Badge__c> badges = new List<Event_Badge__c>();
        badges.add(new Event_Badge__c(FirstName__c = 'Test', LastName__c = 'Test', Footer_Definitions__c = 'None'));
        insert badges;

        Test.startTest();
        Test.setCurrentPage(Page.massPrintBadges);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(badges);
        stdSetController.setSelected(badges);
        MassPrintBadgesController extension = new MassPrintBadgesController(stdSetController);
        System.assert(extension.redirectUrl.contains(badges[0].Id));
        Test.stopTest();
    }
}