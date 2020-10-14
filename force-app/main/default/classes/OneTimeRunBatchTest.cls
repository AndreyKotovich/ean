@IsTest
public with sharing class OneTimeRunBatchTest {
    @IsTest public static void AssignMembershipsToSocietiesTest(){
        List<Membership__c> memberships = new List<Membership__c>{new Membership__c(Name = 'full_institutional_members', API__c = 'full_institutional_members'),
                new Membership__c(Name = 'corresponding_institutional_members', API__c = 'corresponding_institutional_members'),
                new Membership__c(Name = 'associate_corresponding_membership', API__c = 'associate_corresponding_membership'),
                new Membership__c(Name = 'associate_individual_membership', API__c = 'associate_individual_membership')};
        insert memberships;
        RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Society__c' AND DeveloperName='National_Neurological_Society'];
        Society__c corrSoc = new Society__c(Name = 'Test corr', tx_efnsusr_type_name__c = 'Corresponding Societies', RecordTypeId = rt.Id);
        insert corrSoc;
        Society__c socSoc = new Society__c(Name = 'Test corr', tx_efnsusr_type_name__c = 'Society', RecordTypeId = rt.Id);
        insert socSoc;
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i<15; i++){
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Test'+i));
        }
        insert contacts;

        RecordType rtSocMem = [SELECT Id FROM RecordType WHERE SobjectType = 'Society_Member__c' AND DeveloperName='National_Neurological_Society'];
        List<Society_Member__c> socMembers = new List<Society_Member__c>();
        for(Integer i = 0; i<contacts.size(); i++){
            if(Math.mod(i, 2) == 0){
                socMembers.add(new Society_Member__c(RecordTypeId = rtSocMem.Id, Contact__c = contacts[i].Id, Role__c='Member', Society__c = corrSoc.Id));
            }else{
                socMembers.add(new Society_Member__c(RecordTypeId = rtSocMem.Id, Contact__c = contacts[i].Id, Role__c='Member', Society__c = socSoc.Id));
            }
        }
        insert socMembers;

        Test.startTest();
        AssignMembershipsToSocieties job = new AssignMembershipsToSocieties();
        Database.executeBatch(job, 2);
        Test.stopTest();
    }
    @IsTest public static void UpdateDepartmentPositionsBatchTest(){
        Test.startTest();
        UpdateDepartmentPositionsBatch job = new UpdateDepartmentPositionsBatch();
        Database.executeBatch(job, 200);
        Test.stopTest();
    }

    //BEFORE RUN THIS BATCH DEACTIVATE Process Builder - "Set 'IsCommunityUser__c' on Contact"
    /*@IsTest public static void ContactsDMLTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<10; i++){
            contacts.add(new Contact(FirstName='Test', LastName='Contact'+i));
        }
        insert contacts;

        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = 'Non-Member Community User Profile' OR Name = 'Member Community User Profile'];

        List<User> users = new List<User>();
        for(Integer i=0; i<contacts.size(); i++){
            users.add(new User(
                    Alias = 'Alias'+i, Email = i+'test@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = contacts[i].LastName, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = Math.mod(i, 2) == 0?profiles[0].Id:profiles[1].Id, Country = 'United States', IsActive = false,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@email.com',
                    CommunityNickname = 'CommunityNickname'+i
            ));
        }
        insert users;

        Decimal permSetAssignmentsCount = [SELECT COUNT() FROM PermissionSetAssignment];

        Test.startTest();
        ContactsDML job = new ContactsDML();
        Database.executeBatch(job, 200);
        Test.stopTest();

        users = [SELECT Id, IsActive FROM User WHERE Id IN :users];

        for(User u: users){
            System.assert(u.IsActive);
        }
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, AssigneeId FROM PermissionSetAssignment];
        Map<Id, PermissionSetAssignment> mapa = new Map<Id, PermissionSetAssignment>();
        for(PermissionSetAssignment psa : permissionSetAssignments){
            mapa.put(psa.AssigneeId, psa);
        }
        for(User u: users){
            System.assert(mapa.containsKey(u.Id));
        }
    }*/
    /*@IsTest public static void GetUsersWithAvatarsBatchTest(){
        Test.startTest();
        GetUsersWithAvatarsBatch job = new GetUsersWithAvatarsBatch();
        Database.executeBatch(job, 200);
        Test.stopTest();
    }*/

    //COMMENTED DUE TO IN UpdateContactsAfterMigration WAS UPDATED FOR EM-350
    /*@IsTest public static void UpdateContactsAfterMigrationTest(){
        RecordType rtHospAcc = [SELECT Id FROM RecordType WHERE sobjecttype='Account' AND Name = 'Hospital'];
        Account hospital  = new Account(RecordTypeId = rtHospAcc.Id, Name='Hospital');
        insert hospital;
        RecordType rtDepAcc = [SELECT Id FROM RecordType WHERE sobjecttype='Account' AND Name = 'Department'];
        Account department = new Account(Name = 'Department', BillingCountry='Belarus', BillingPostalCode='123', BillingCity='Test', BillingStreet='Street', RecordTypeId = rtDepAcc.Id, ParentId = hospital.Id);
        insert department;
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i<15; i++){
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Test'+i));
        }
        insert contacts;
        insert new Contact(FirstName = 'Test', LastName='test', Work_Street__c = 'Street', Work_City__c = 'Test', Work_State_Province__c = 'State', Work_Zip_Postal_Code__c = '123', Mailing_address__c='Work Address', Work_Country__c = 'Belarus');
        List<Contact_Role__c> depPositions = new List<Contact_Role__c>();
        RecordType rtDepContRoles = [SELECT Id FROM RecordType WHERE sobjecttype='Contact_Role__c' AND Name = 'Department'];
        for(Contact c : contacts){
            depPositions.add(new Contact_Role__c(RecordTypeId = rtDepContRoles.Id, Account__c = department.Id, Hospital__c = hospital.Id, Contact__c = c.Id, Role__c='Member'));
        }
        insert depPositions;
        Test.startTest();
        UpdateContactsAfterMigration job = new UpdateContactsAfterMigration();
        Database.executeBatch(job, 200);
        Test.stopTest();
    }*/
    //BEFORE RUN THIS BATCH DEACTIVATE Process Builder - "Set 'IsCommunityUser__c' on Contact"
    /*@IsTest public static void updateUserProfileBatchTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        Account acc = new Account(Name='Account');
        insert acc;

        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<100; i++){
            contacts.add(new Contact(FirstName='Test', LastName='Contact'+i, AccountId=acc.Id));
        }
        insert contacts;

        Membership__c membership = new Membership__c(Name='Test', API__c='Test');
        insert membership;

        List<MembershipContactAssotiation__c> membershipStatuses = new List<MembershipContactAssotiation__c>();
        for(Contact c : contacts){
            membershipStatuses.add(new MembershipContactAssotiation__c(Contact__c=c.Id, Membership__c=membership.Id, Endless_Activation__c = true));
        }
        insert membershipStatuses;

        Id nonMemberProfileId = [SELECT Id FROM Profile WHERE Name = 'Non-Member Community User Profile'].Id;

        List<User> users = new List<User>();
        for(Integer i=0; i<contacts.size(); i++){
            users.add(new User(
                    Alias = 'Alias'+i, Email = i+'test@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = contacts[i].LastName, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = nonMemberProfileId, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test@email.com',
                    CommunityNickname = 'CommunityNickname'+i
            ));
        }
        insert users;

        Test.startTest();
        UpdateUserProfileBatch job = new UpdateUserProfileBatch();
        Database.executeBatch(job, 200);
        Test.stopTest();

        System.assertEquals('Completed', [SELECT Id, Status__c FROM Log__c LIMIT 1].Status__c);

        users = [SELECT Id, ProfileId FROM User WHERE Id IN :users];
        Id memberProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Member Community User Profile'].Id;

        for(User u: users){
            System.assertEquals(memberProfileId, u.ProfileId);
        }
    }*/
    @IsTest public static void UpdateTransactionRecordsBatchTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i<15; i++){
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Test'+i, Email=i+'test@test.com', MailingCountry='United States', MailingState='Alabama', OtherCountry='United States', OtherState='Alabama'));
        }

        insert contacts;

        List<Order__c> orders = new List<Order__c>();

        for(Contact contact : contacts){
            orders.add(new Order__c(Contact__c = contact.Id));
        }

        insert orders;

        List<Transaction__c> transactions = new List<Transaction__c>();

        for(Order__c order : orders){
            transactions.add(new Transaction__c(Order_Custom__c = order.Id));
            transactions.add(new Transaction__c(Order_Custom__c = order.Id, JSONResponse__c = 'None', Payment_Method__c='paypal'));
            transactions.add(new Transaction__c(Order_Custom__c = order.Id, JSONResponse__c = '{ "payment": { "transaction-id": "test-transaction-id" }}', Payment_Method__c='creditcard'));
        }

        insert transactions;

        Test.startTest();
        Database.executeBatch(new UpdateTransactionRecordsBatch(), 200);
        Test.stopTest();

        List<Transaction__c> updatedTransactions = [SELECT Id, Reference_Id__c FROM Transaction__c WHERE Id IN :transactions AND Payment_Method__c='Card'];

        for(Transaction__c transction : updatedTransactions){
            System.assertEquals('test-transaction-id', transction.Reference_Id__c);
        }
    }

    @IsTest public static void UpdateChatterGroupNotificationFreqBatchTest(){
        NewsletterSubscriptionController.isCreateSubscribersEnabled = false;

        Id MCUP = [SELECT Id FROM Profile WHERE Name = 'Member Community User Profile'].Id;

        Account account = new Account(Name = 'Individuals (Contacts)', RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individuals' AND SobjectType = 'Account' LIMIT 1].Id);
        insert account;

        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < 10; i++){
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Contact'+i, AccountId = account.Id));
        }

        insert contacts;

        List<User> users = new List<User>();

        for(Integer i = 0; i < contacts.size(); i++){
            users.add(new User(
                    Alias = 'test'+i, Email = i+'test_un@email.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Test_un'+i, LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = MCUP, Country = 'United States', IsActive = true,
                    ContactId = contacts[i].Id, TimeZoneSidKey = 'America/Los_Angeles', Username = i+'test_un@email.com'));
        }

        insert users;

        String communityId = [SELECT Id, Name FROM Network WHERE Name = 'ean' LIMIT 1].Id;
        CollaborationGroup cg = new CollaborationGroup(Name = 'Test Group Unique', NetworkId = communityId, CollaborationType = 'Public');
        insert cg;

        List<CollaborationGroupMember> collaborationGroupMembers = new List<CollaborationGroupMember>();

        for(User user : users){
            collaborationGroupMembers.add(new CollaborationGroupMember(MemberId = user.Id, CollaborationGroupId = cg.Id));
        }

        insert collaborationGroupMembers;

        Test.startTest();
        UpdateChatterGroupNotificationFreqBatch b = new UpdateChatterGroupNotificationFreqBatch();
        b.groupsIds = new List<Id>{cg.Id};
        b.notificationFrequency = 'N';
        Database.executeBatch(b, 200);
        Test.stopTest();

        List<CollaborationGroupMember> groupMembers = [SELECT Id, NotificationFrequency FROM CollaborationGroupMember WHERE Id = :cg.Id];

        for(CollaborationGroupMember cgm : groupMembers){
            System.assertEquals('N', cgm.NotificationFrequency);
        }

    }
}