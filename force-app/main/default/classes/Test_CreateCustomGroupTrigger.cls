@isTest public with sharing class Test_CreateCustomGroupTrigger {
    @isTest public static void updateCustomGroupTest(){
        Group__c g = new Group__c(Name='TestWithSynch', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert g;
        CollaborationGroup cg = [SELECT Id FROM CollaborationGroup WHERE Name = 'TestWithSynch'];
        cg.Name = 'Change Name';
        update cg;
        System.assertEquals([SELECT Name FROM Group__c WHERE Name='Change Name'].size(),1);

        g.Enable_synchronization__c = false;
        update g;
        cg.Name = 'Change Name2';
        update cg;
        System.assertEquals([SELECT Name FROM Group__c WHERE Name='Change Name2'].size(),0);
    }
}