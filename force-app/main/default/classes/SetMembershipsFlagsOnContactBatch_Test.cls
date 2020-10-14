@IsTest
public with sharing class SetMembershipsFlagsOnContactBatch_Test {
    @testSetup static void setup() {
        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<10; i++){
            contacts.add(new Contact(LastName='Test'+i));
        }
        insert contacts;
        List<Membership__c> memberships = new List<Membership__c>();
        memberships.add(new Membership__c(Name='Test1', API__c='full_membership'));
        memberships.add(new Membership__c(Name='Test2', API__c='corresponding_membership'));
        memberships.add(new Membership__c(Name='Test3', API__c='fellow_membership'));
        memberships.add(new Membership__c(Name='Test4', API__c='resident_and_research_membership'));
        memberships.add(new Membership__c(Name='Test5', API__c='associate_individual_membership'));
        memberships.add(new Membership__c(Name='Test6', API__c='student_membership'));
        insert memberships;
        List<MembershipContactAssotiation__c> membershipStatuses = new List<MembershipContactAssotiation__c>();
        for(Contact c : contacts){
            membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = c.Id, Membership__c = memberships[0].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        }
        membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = memberships[1].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = memberships[2].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = memberships[3].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = memberships[4].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c = contacts[0].Id, Membership__c = memberships[5].Id, Expiration_date__c = Datetime.now().addYears(1), Assignment_date__c = Date.newInstance(Date.today().year(), 01, 28)));
        insert membershipStatuses;

        Id groupRTId = Schema.SObjectType.Group__c.getRecordTypeInfosByName().get('Level 3 Working Group').getRecordTypeId();
        Group__c testGroup = new Group__c(Name = 'Test_Group_1', Type_of_Group__c = 'Other', RecordTypeId = groupRTId);
        insert testGroup;

        Id groupRoleRTId = Schema.SObjectType.GroupChatterGroupAssotiation__c.getRecordTypeInfosByName().get('Level 3 Working Group').getRecordTypeId();
        List<GroupChatterGroupAssotiation__c> groupRoles = new List<GroupChatterGroupAssotiation__c>();
        for (Contact c : contacts) {
            groupRoles.add(new GroupChatterGroupAssotiation__c(Contact__c = c.Id, Group__c = testGroup.Id, RecordTypeId = groupRoleRTId));
        }
        insert  groupRoles;
    }
    @IsTest public static void setMembershipsFlagsOnContactBatchTest(){
        Test.startTest();
        SetMembershipsFlagsOnContactBatch job = new SetMembershipsFlagsOnContactBatch();
        Database.executeBatch(job, 200);
        Test.stopTest();
        List<Contact> contacts = [SELECT Id, Flag_EAN_Full_Member__c FROM Contact];
        for (Contact c : contacts){
            System.assertEquals(true, c.Flag_EAN_Full_Member__c);
        }

        List<GroupChatterGroupAssotiation__c> groupRoles = [SELECT Group__r.Type_of_Group__c, Type_of_Group__c FROM GroupChatterGroupAssotiation__c];
        for (GroupChatterGroupAssotiation__c groupRole : groupRoles) {
            System.debug(groupRole.Type_of_Group__c);
            System.debug(groupRole.Group__r.Type_of_Group__c);
            System.assertEquals(groupRole.Type_of_Group__c, groupRole.Group__r.Type_of_Group__c);
        }
        System.assertEquals(1, [SELECT Id FROM Log__c].size());
    }
}