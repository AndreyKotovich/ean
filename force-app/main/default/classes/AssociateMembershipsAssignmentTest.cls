@IsTest
public with sharing class AssociateMembershipsAssignmentTest {
    @IsTest public static void assignAssociateMembership(){
        RecordType socRTNatNeurSoc = [SELECT Id FROM RecordType WHERE SobjectType = 'Society__c' AND DeveloperName = 'National_Neurological_Society'];
        RecordType socRTPartnerSoc = [SELECT Id FROM RecordType WHERE SobjectType = 'Society__c' AND DeveloperName = 'Partner_Society'];
        RecordType socMemRTNatNeurSoc = [SELECT Id FROM RecordType WHERE SobjectType = 'Society_Member__c' AND DeveloperName = 'National_Neurological_Society'];
        RecordType socMemRTPartnerSoc = [SELECT Id FROM RecordType WHERE SobjectType = 'Society_Member__c' AND DeveloperName = 'Partner_Societies'];
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        List<Membership__c> newMemberships = new List<Membership__c>();
        newMemberships.add(new Membership__c(Name = 'Associate Membership', API__c = 'associate_individual_membership'));
        newMemberships.add(new Membership__c(Name = 'Associate Corresponding Membership', API__c = 'associate_corresponding_membership'));
        newMemberships.add(new Membership__c(Name = 'Full Institutional Members', API__c = 'full_institutional_members'));
        newMemberships.add(new Membership__c(Name = 'Corresponding Institutional Members', API__c = 'corresponding_institutional_members'));
        insert newMemberships;
        List<Society__c> societies = new List<Society__c>();
        societies.add(new Society__c(Name='TestSociety1', RecordTypeId=socRTNatNeurSoc.Id, Membership__c = newMemberships[2].Id));
        societies.add(new Society__c(Name='TestSociety2', RecordTypeId=socRTPartnerSoc.Id, Membership__c = newMemberships[3].Id));
        insert societies;

        //test start
        insert new Society_Member__c(Contact__c = contact.Id, Society__c = societies[1].Id, Is_Active__c = true, RecordTypeId=socMemRTPartnerSoc.Id, Role__c='President');
        System.assertEquals(0, [SELECT Id FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id].size());
        Society_Member__c societyMemberWorking = new Society_Member__c(Contact__c = contact.Id, Society__c = societies[0].Id, Is_Active__c = true, RecordTypeId=socMemRTNatNeurSoc.Id, Role__c='Member');
        insert societyMemberWorking;
        System.assertEquals('associate_individual_membership', [SELECT Id, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id AND IsActive__c = TRUE].Membership__r.API__c);
        societyMemberWorking.Is_Active__c = false;
        update societyMemberWorking;
        System.assertEquals(0, [SELECT Id, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id AND IsActive__c = TRUE].size());
        societies[0].Membership__c = newMemberships[3].Id;
        update societies;
        societyMemberWorking.Is_Active__c = true;
        update societyMemberWorking;
        System.assertEquals('associate_corresponding_membership', [SELECT Id, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id AND IsActive__c = TRUE].Membership__r.API__c);
        //check on duplicate membership status creation
        Society_Member__c societyMemberWorkingDuplicate = new Society_Member__c(Contact__c = contact.Id, Society__c = societies[0].Id, Is_Active__c = true, RecordTypeId=socMemRTNatNeurSoc.Id, Role__c='Member');
        insert societyMemberWorkingDuplicate;
        System.assertEquals(1, [SELECT Id, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id AND IsActive__c = TRUE].size());
        //del duplicate soc_member record, membership status should still active
        delete societyMemberWorkingDuplicate;
        List<MembershipContactAssotiation__c> mca = [SELECT Id, Membership__r.API__c FROM MembershipContactAssotiation__c WHERE Contact__c =:contact.Id AND IsActive__c = TRUE];
        System.assertEquals(1, mca.size());
        //check if endless activation is not setup. membership status should be yesterday.
        mca[0].Endless_Activation__c = false;
        mca[0].Expiration_date__c = Date.today().addDays(1);
        update mca;
        delete societyMemberWorking;
        mca = [SELECT Id, IsActive__c, Expiration_date__c FROM MembershipContactAssotiation__c WHERE Id = :mca[0].Id];
        System.assert(!mca[0].IsActive__c);
        System.assertEquals(Date.today().addDays(-1), mca[0].Expiration_date__c);
        //check on activating old Membership Status, without creating new
        undelete societyMemberWorking;
        System.assert([SELECT Id, IsActive__c, Expiration_date__c FROM MembershipContactAssotiation__c WHERE Id = :mca[0].Id].IsActive__c);
    }

}