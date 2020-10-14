@isTest public class Test_DisableCommunityUserOnContact {
    @isTest public static void TESTUncheckCommunityUser(){
        Contact con = new Contact(LastName = 'testCon', IsCommunityUser__c = true);
        insert con;
        List<Id> contListIds = new List<Id>();
        contListIds.add(con.Id);
        Test.startTest();
        DisableCommunityUserOnContact.checkUncheckCommunityUser(contListIds);
        Test.stopTest();
        Contact cont = [SELECT Id, IsCommunityUser__c FROM Contact WHERE Id = :con.Id LIMIT 1];
        System.assertEquals(false, cont.IsCommunityUser__c);
    }
}