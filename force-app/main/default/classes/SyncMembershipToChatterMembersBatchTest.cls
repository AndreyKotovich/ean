@IsTest
public with sharing class SyncMembershipToChatterMembersBatchTest {
    @IsTest public static void batchTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        List<Membership__c> memberships = new List<Membership__c>();
        memberships.add(new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Private'));
        memberships.add(new Membership__c(Name='Membership2', API__c = 'test_2', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Private'));
        insert memberships;

        memberships[0].Enable_synchronization__c = false;
        memberships[1].Enable_synchronization__c = false;
        update memberships;

        Account acc = new Account(Name = 'Individual');
        insert acc;

        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < 6; i++){
            contacts.add(new Contact(LastName = 'test', AccountId = acc.Id));
        }

        insert contacts;

        Id MCUP = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        List<User> users = new List<User>();

        for(Integer i = 0; i < contacts.size(); i++){
            users.add(new User(
                    Alias = 'test'+i, Email = i+'test@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Test'+i, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@email.com',
                    CommunityNickname = 'commNick'+i));
        }

        insert users;

        List<MembershipContactAssotiation__c> membershipContactAssotiations = new List<MembershipContactAssotiation__c>();

        for(Integer i = 0; i < contacts.size(); i++) {
            if(Math.mod(i, 2) == 0){
                membershipContactAssotiations.add(new MembershipContactAssotiation__c(Membership__c = memberships[0].Id, Contact__c = contacts[i].Id, Endless_Activation__c = true));
            } else {
                membershipContactAssotiations.add(new MembershipContactAssotiation__c(Membership__c = memberships[1].Id, Contact__c = contacts[i].Id, Endless_Activation__c = true));
            }
        }

        insert membershipContactAssotiations;

        /**
        * To check remove chatter group participant by batch insert new group member
        * and deactivate his MembershipContactAssotiation__c
         */
        //=====>
        List<CollaborationGroup> chatterGroups = [SELECT Id FROM CollaborationGroup WHERE Name = :memberships[0].Name + ' Group'];
        insert new CollaborationGroupMember(MemberId = users[0].Id, CollaborationGroupId = chatterGroups[0].Id);

        membershipContactAssotiations[0].Endless_Activation__c = false;
        update membershipContactAssotiations;
        //<=====

        memberships[0].Enable_synchronization__c = true;
        memberships[1].Enable_synchronization__c = true;
        Test.startTest();
        update memberships;
        Test.stopTest();

        System.assertEquals(users.size() + memberships.size() - 1, [SELECT Id FROM CollaborationGroupMember].size());
        /**
        * users.size() - amount of group members.
        * memberships.size() - for each group +1 members, admin, which created a group.
        * "- 1" - one, deactivated before, MembershipContactAssotiation__c record
         */
    }

    @IsTest public static void sendErrorEmailTest(){
        Test.startTest();
        SyncMembershipToChatterMembersBatch.sendErrorEmail('Test', new List<String>{'ilya.litovchik@succraft.com'}, 'Test');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, invocations);
    }

    @IsTest public static void ScheduledSyncMembershipChatterBatchTest(){
        insert new Membership__c(Name='Membership1', API__c = 'test_1', Enable_synchronization__c = true, Chatter_Group_Accessibility__c = 'Private');

        String sch = '0 0 1 * * ?';

        Test.startTest();
        System.schedule('ScheduledApexTest', sch, new ScheduledSyncMembershipChatterBatch());
        Test.stopTest();
    }
}