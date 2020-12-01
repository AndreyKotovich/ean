@IsTest public with sharing class SynchronizationGroupMembersHelperTest {
    @TestSetup public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id cclu = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        Contact con = new Contact(LastName = 'testCon', AccountId = account.Id);
        insert con;
        User user = new User(
                Alias = 'test123', Email = 'test123@noemail.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing_un', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = cclu, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'tester@noemail.com');
        insert user;
    }

    @IsTest public static void insertUndeleteGroupMembersTest(){
        Contact con = [SELECT Id FROM Contact WHERE Name='testCon'];
        User u = [SELECT Id FROM User WHERE LastName = 'Testing_un' LIMIT 1];

        Group__c g = new Group__c(Name = 'TestGroup_test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public', Enable_management_group__c = true);
        insert g;
        g = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Group__c WHERE Id = :g.Id];
        g.Enable_synchronization__c = false;
        g.Enable_management_group__c = false;
        update g;

        RecordType groupMemberRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'GroupChatterGroupAssotiation__c' AND DeveloperName = 'Level_3_Working_Group'];
        GroupChatterGroupAssotiation__c newManagementMember = new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id, RecordTypeId = groupMemberRecordType.Id, Role__c = 'Management Group Member');
        insert newManagementMember;
        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 0);

        delete newManagementMember;

        g.Enable_synchronization__c = true;
        update g;
        undelete newManagementMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 1);
        System.assertEquals(collMember[0].CollaborationGroupId, g.Chatter_Group_Id__c);

        delete newManagementMember;

        g.Enable_synchronization__c = true;
        g.Enable_management_group__c = true;
        update g;

        undelete newManagementMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 2);

        //Make sure that no exceptions occurs
        GroupChatterGroupAssotiation__c newMember = new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id);
        insert newMember;

    }

    @IsTest public static void checkGroupMemberDuplicateBeforeInsertTest(){
        try {
            Contact con = [SELECT Id FROM Contact WHERE Name='testCon'];
            Group__c g = new Group__c(Name='TestGroup_test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
            insert g;
            insert new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id);
            insert new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id);
        }catch (Exception e){
            System.assert(e.getMessage().contains('This contact already has this role in this group.'));
        }
    }

    @IsTest public static void deleteFromChatterGroupTest(){
        Contact con = [SELECT Id FROM Contact WHERE Name='testCon'];
        User u = [SELECT Id FROM User WHERE LastName = 'Testing_un' LIMIT 1];
        Group__c g = new Group__c(Name='TestGroup_test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public', Enable_management_group__c = true);
        insert g;

        g = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Group__c WHERE Id = :g.Id];
        RecordType groupMemberRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'GroupChatterGroupAssotiation__c' AND DeveloperName = 'Level_3_Working_Group'];
        GroupChatterGroupAssotiation__c newManagementMember = new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id, RecordTypeId = groupMemberRecordType.Id, Role__c = 'Management Group Member');
        insert newManagementMember;

        g.Enable_synchronization__c = false;
        g.Enable_management_group__c = false;
        update g;

        delete newManagementMember;
        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(2, collMember.size());

        undelete newManagementMember;

        test.startTest();
        g.Enable_synchronization__c = true;
        g.Enable_management_group__c = true;
        update g;
        delete newManagementMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(0, collMember.size());

        undelete newManagementMember;

        g.Enable_synchronization__c = false;
        update g;
        delete newManagementMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());
        System.assertEquals(g.Chatter_Group_Id__c, collMember[0].CollaborationGroupId);

        g.Enable_synchronization__c = true;
        update g;

        //test groupsMembers have double membership in group
        List<GroupChatterGroupAssotiation__c> newMembers = new List<GroupChatterGroupAssotiation__c>{
                new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id),
                new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id, RecordTypeId = groupMemberRecordType.Id, Role__c = 'Management Group Member')
        };
        insert newMembers;
        delete newMembers[1];
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());
        test.stopTest();
    }

    @IsTest public static void updateGroupMembersTest(){
        Contact con = [SELECT Id FROM Contact WHERE Name='testCon'];
        User u = [SELECT Id FROM User WHERE LastName = 'Testing_un' LIMIT 1];
        Group__c g = new Group__c(Name='TestGroup_test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public', Enable_management_group__c = true);
        insert g;

        g = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Group__c WHERE Id = :g.Id];
        RecordType groupMemberRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'GroupChatterGroupAssotiation__c' AND DeveloperName = 'Level_3_Working_Group'];
        GroupChatterGroupAssotiation__c newManagementMember = new GroupChatterGroupAssotiation__c(Contact__c = con.Id, Group__c= g.Id, RecordTypeId = groupMemberRecordType.Id, Role__c = 'Management Group Member');
        insert newManagementMember;

        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(2, collMember.size());

        newManagementMember.Role__c = 'Chair';
        update newManagementMember;

        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());

        newManagementMember.Role__c = 'Management Group Member';
        update newManagementMember;

        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(2, collMember.size());

        g.Enable_management_group__c = false;
        update g;

        newManagementMember.Role__c = 'Chair';
        update newManagementMember;

        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(2, collMember.size());

    }
}