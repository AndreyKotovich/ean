@IsTest
public with sharing class MembershipTriggerHelperTest {
    @IsTest public static void createChatterGroupHelperTest() {
        List<Membership__c> newMembership = new List<Membership__c>();
        newMembership.add(new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Private'));
        newMembership.add(new Membership__c(Name='Membership2', API__c = 'test_2', Enable_synchronization__c = false, Chatter_Group_Accessibility__c = 'Private'));
        insert newMembership;

        List<CollaborationGroup> allChatterGroups = [SELECT Id, Name, CollaborationType FROM CollaborationGroup];

        System.assertEquals(1, allChatterGroups.size());
        System.assertEquals('Membership1 Group', allChatterGroups[0].Name);
        System.assertEquals(newMembership[0].Chatter_Group_Accessibility__c, allChatterGroups[0].CollaborationType);
    }

    @IsTest public static void updateChatterGroupTest() {
        Membership__c g = new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert g;

        g  = [SELECT Id, Name, Chatter_Group_Id__c, Enable_synchronization__c FROM Membership__c WHERE Id =:g.Id];
        g.Enable_synchronization__c = false;
        g.Name = 'New Name';
        update g;

        System.assertNotEquals([SELECT Id, Name FROM CollaborationGroup WHERE Id = :g.Chatter_Group_Id__c].Name, g.Name + ' Group');

        g.Enable_synchronization__c = true;
        g.Chatter_Group_Accessibility__c = 'Private';
        update g;

        CollaborationGroup chatterGroup = [SELECT Id, Name, CollaborationType FROM CollaborationGroup WHERE Id = :g.Chatter_Group_Id__c];

        System.assertEquals(chatterGroup.Name, g.Name + ' Group');
        System.assertEquals(chatterGroup.CollaborationType, 'Private');
    }

    @IsTest public static void checkSyncStatusTest(){
        Membership__c g = new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = false, Chatter_Group_Accessibility__c = 'Public');
        insert g;

        g.Enable_synchronization__c = true;
        update g;

        List<CollaborationGroup> chatterGroups = [SELECT Id, Name FROM CollaborationGroup];

        System.assert(!chatterGroups.isEmpty());
        System.assertEquals('Membership1 Group', chatterGroups[0].Name);

        delete chatterGroups[0];

        System.assert([SELECT Id, Name FROM CollaborationGroup].isEmpty());

        g.API__c = 'test1';
        update g;

        chatterGroups = [SELECT Id, Name FROM CollaborationGroup];
        System.assert(!chatterGroups.isEmpty());
        System.assertEquals('Membership1 Group', chatterGroups[0].Name);
    }

    @IsTest public static void removeChatterGroupTest() {
        Membership__c membership = new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert membership;

        System.assert(![SELECT Id FROM CollaborationGroup].isEmpty());

        delete membership;

        System.assert([SELECT Id FROM CollaborationGroup].isEmpty());

        membership = new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert membership;

        membership.Enable_synchronization__c = false;
        update membership;

        delete membership;

        System.assert(![SELECT Id FROM CollaborationGroup].isEmpty());
    }
}