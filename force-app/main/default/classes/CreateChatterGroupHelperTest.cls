@IsTest public with sharing class CreateChatterGroupHelperTest {

    @IsTest public static void newWorkingGroupTest() {
        List<Group__c> newCustomGroups = new List<Group__c>();
        newCustomGroups.add(new Group__c(Name='Group_un1', Enable_synchronization__c = true, Enable_management_group__c = false, Chatter_Group_Accessibility__c = 'Public'));
        newCustomGroups.add(new Group__c(Name='Group_un2', Enable_synchronization__c = false, Enable_management_group__c = true));

        insert newCustomGroups;

        List<CollaborationGroup> allChatterGroups = [SELECT Id, Name, CollaborationType FROM CollaborationGroup];

        System.assertEquals(2, allChatterGroups.size());

        for(CollaborationGroup chatterGroup : allChatterGroups){

            if(chatterGroup.Name == 'MG Group_un2'){
                System.assertEquals('Private', chatterGroup.CollaborationType);
            } else {
                System.assertEquals(newCustomGroups[0].Chatter_Group_Accessibility__c, chatterGroup.CollaborationType);
            }

        }

    }

    @IsTest public static void updateWorkingGroupTest() {
        Group__c g = new Group__c(Name='Group_un1', Enable_synchronization__c = true, Enable_management_group__c = true, Chatter_Group_Accessibility__c = 'Public');
        insert g;
        g  = [SELECT Id, Name, Chatter_Group_Id__c, Management_Chatter_Group_Id__c, Enable_synchronization__c, Enable_management_group__c FROM Group__c WHERE Id =:g.Id];
        g.Enable_synchronization__c = true;
        g.Enable_management_group__c = false;
        g.Name = 'Group_un2';
        update g;
        List<Id> chatterGroupIds = new List<Id>{g.Chatter_Group_Id__c, g.Management_Chatter_Group_Id__c};
        List<CollaborationGroup> chatterGroups = [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupIds];

        for(CollaborationGroup chatterGroup : chatterGroups){

            if(chatterGroup.Id == g.Management_Chatter_Group_Id__c){
                System.assertEquals('MG Group_un1', chatterGroup.Name);
            }

            if(chatterGroup.Id == g.Chatter_Group_Id__c){
                System.assertEquals(g.Name, chatterGroup.Name);
            }

        }

        CollaborationGroup managementGroup = [SELECT Id FROM CollaborationGroup WHERE Name = 'MG Group_un1'];
        delete managementGroup;

        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;
        Id MCUP = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;
        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;

        List<Contact> contacts = new List<Contact>();

        contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact1', AccountId = account.Id));
        contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact2', AccountId = account.Id));
        contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact3', AccountId = account.Id));

        insert contacts;

        List<User> user = new List<User>();

        user.add(
                new User(
                        Alias = 'test0', Email = '0test_un@email.com',
                        EmailEncodingKey = 'UTF-8', LastName = 'Test_un', LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                        ContactId = contacts[0].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = '0test_un@email.com'
                )
        );
        user.add(
                new User(
                        Alias = 'test1', Email = '1test_un@email.com',
                        EmailEncodingKey = 'UTF-8', LastName = contacts[1].LastName, LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                        ContactId = contacts[1].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = '1test_un@email.com'
                )
        );

        insert user;

        RecordType groupMemberRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'GroupChatterGroupAssotiation__c' AND DeveloperName = 'Level_3_Working_Group'];
        List<GroupChatterGroupAssotiation__c> workingGroupMembers = new List<GroupChatterGroupAssotiation__c>();

        workingGroupMembers.add(new GroupChatterGroupAssotiation__c(Group__c = g.Id, Contact__c = contacts[0].Id, Role__c = 'Management Group Member', RecordTypeId = groupMemberRecordType.Id));
        workingGroupMembers.add(new GroupChatterGroupAssotiation__c(Group__c = g.Id, Contact__c = contacts[1].Id));
        workingGroupMembers.add(new GroupChatterGroupAssotiation__c(Group__c = g.Id, Contact__c = contacts[2].Id));

        insert workingGroupMembers;

        g.Enable_management_group__c = true;
        update g;

        g  = [SELECT Id, Name, Chatter_Group_Id__c, Management_Chatter_Group_Id__c, Enable_synchronization__c, Enable_management_group__c FROM Group__c WHERE Id =:g.Id];

        List<CollaborationGroupMember> managedChatterGroupMembers = [
                SELECT Id, MemberId
                FROM CollaborationGroupMember
                WHERE CollaborationGroupId = :g.Management_Chatter_Group_Id__c
                AND CollaborationRole != 'Admin'
        ];

        System.assertEquals(1, managedChatterGroupMembers.size());

        g.Enable_management_group__c = false;
        update g;

        g.Enable_management_group__c = true;
        g.Name = 'Group_un3';
        update g;

        managementGroup = [SELECT Id, Name FROM CollaborationGroup WHERE Id  = :g.Management_Chatter_Group_Id__c];

        System.assertEquals('MG Group_un3', managementGroup.Name);
    }

    @IsTest public static void getChatterGroupNameTest(){
        String str = '';

        for(Integer i =0; i < 41; i++){
            str += 'a';
        }

        String str2 = '';

        for(Integer i =0; i < 37; i++){
            str2 += 'a';
        }

        str2+='...';

        System.assertEquals(str2, CreateChatterGroupHelper.getChatterGroupName(str));
    }

}