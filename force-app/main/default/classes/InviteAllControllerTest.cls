@IsTest
public with sharing class InviteAllControllerTest {
    @IsTest public static void getGroupMembersTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        List<Network> community = [SELECT Id FROM Network WHERE Name = 'ean' LIMIT 1];

        Account account = new Account(Name = 'Individuals (Contacts)');
        insert account;

        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(LastName = 'Contact'+i, AccountId = account.Id));
        }

        insert contacts;
        Id memberProfile = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        List<User> users = new List<User>();

        for(Integer i =0; i<contacts.size(); i++){
            users.add(new User(
                    Alias = 'Alias'+i, Email = i+'test@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = contacts[i].LastName, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = memberProfile, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@email.com',
                    CommunityNickname = 'CommunityNickname'+i
            ));
        }

        insert users;

        CollaborationGroup chatterGroup = new CollaborationGroup(Name = 'Test Group Invite All1', NetworkId = community[0].Id, CollaborationType='Public');
        insert chatterGroup;

        List<CollaborationGroupMember> groupMembers = new List<CollaborationGroupMember>();

        for (User u : users){
            groupMembers.add(new CollaborationGroupMember(MemberId = u.Id, CollaborationGroupId = chatterGroup.Id));
        }

        insert groupMembers;

        System.runAs(users[0]){
            List<User> members = InviteAllController.getGroupMembers(chatterGroup.Id);
            System.assertEquals(groupMembers.size(), members.size());

            CollaborationGroup emptyGroup = new CollaborationGroup(Name = 'Test Group Invite All2', NetworkId = community[0].Id, CollaborationType='Public');
            insert emptyGroup;

            try{
                InviteAllController.getGroupMembers(emptyGroup.Id);
            } catch (Exception e){
                System.assertEquals('No members found', e.getMessage());
            }

            try{
                InviteAllController.getGroupMembers('0F90000000000FFFFF');
            } catch (Exception e){
                System.assertEquals('No members found', e.getMessage());
            }
        }

    }
}