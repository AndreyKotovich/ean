@IsTest
public with sharing class MembershipChatterMembersSyncTest {
    @TestSetup public static void setup(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id MCUP = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id; //TODO PRofile non-member
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id);
        insert con;
        User user = new User(
                Alias = 'test', Email = 'test_un@email.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Test_un', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                ContactId = con.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'test_un@email.com');
        insert user;
    }

    @IsTest public static void insertUndeleteGroupMembersTest(){
        Contact con = [SELECT Id FROM Contact WHERE Name='Test Contact'];
        User u = [SELECT Id FROM User WHERE LastName = 'Test_un' LIMIT 1];
        Membership__c m = new Membership__c(Name='Membership_Test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert m;

        m = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Membership__c WHERE Id = :m.Id];
        MembershipContactAssotiation__c newMember = new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true);
        insert newMember;

        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 1);
        System.assertEquals(collMember[0].MemberId, u.Id);
        System.assertEquals(collMember[0].CollaborationGroupId, m.Chatter_Group_Id__c);

        delete collMember;
        delete newMember;

        undelete newMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 1);
        System.assertEquals(collMember[0].MemberId, u.Id);
        System.assertEquals(collMember[0].CollaborationGroupId, m.Chatter_Group_Id__c);
        delete collMember;
        delete newMember;

        m.Enable_synchronization__c = false;
        update m;
        newMember = new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true);
        insert newMember;
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(collMember.size(), 0);
        delete collMember;
        delete newMember;
        m.Enable_synchronization__c = true;
        update m;

        CollaborationGroupMember cgm = new CollaborationGroupMember(MemberId=u.Id, CollaborationGroupId= m.Chatter_Group_Id__c);
        insert cgm;
        newMember = new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true);
        insert newMember;
    }

    @IsTest public static void deleteFromChatterGroupTest(){
        Contact con = [SELECT Id FROM Contact WHERE Name='Test Contact'];
        User u = [SELECT Id FROM User WHERE LastName = 'Test_un' LIMIT 1];
        Membership__c m = new Membership__c(Name='Membership_Test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert m;

        m = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Membership__c WHERE Id = :m.Id];
        MembershipContactAssotiation__c newMember = new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true);
        insert newMember;

        m.Enable_synchronization__c = false;
        update m;

        delete newMember;

        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());
        System.assertEquals(u.Id, collMember[0].MemberId);
        System.assertEquals(m.Chatter_Group_Id__c, collMember[0].CollaborationGroupId);

        undelete newMember;
        m.Enable_synchronization__c = true;
        update m;

        delete newMember;

        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(0, collMember.size());

        List<MembershipContactAssotiation__c> newMembers = new List<MembershipContactAssotiation__c>{
                new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true),
                new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true)
        };
        insert newMembers;
        delete newMembers[0];
        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());
    }

    @IsTest public static void insertDeleteChatterGroupMemberTest(){

        Contact con = [SELECT Id FROM Contact WHERE Name='Test Contact'];
        User u = [SELECT Id FROM User WHERE LastName = 'Test_un' LIMIT 1];
        Membership__c m = new Membership__c(Name='Membership_Test', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert m;

        m = [SELECT Id, Name, Enable_synchronization__c, Chatter_Group_Id__c FROM Membership__c WHERE Id = :m.Id];
        MembershipContactAssotiation__c newMember = new MembershipContactAssotiation__c(Contact__c = con.Id, Membership__c= m.Id, Endless_Activation__c = true);
        insert newMember;

        newMember.Endless_Activation__c = false;
        update newMember;

        List<CollaborationGroupMember> collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(0, collMember.size());


        newMember.Endless_Activation__c = true;
        update newMember;

        collMember = [SELECT Id, MemberId, CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :u.Id];
        System.assertEquals(1, collMember.size());
    }
}