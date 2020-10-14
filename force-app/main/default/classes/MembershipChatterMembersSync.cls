public with sharing class MembershipChatterMembersSync {
    public static void insertUndeleteMembershipMembers(List<MembershipContactAssotiation__c> newMembers) {
        List<MembershipContactAssotiation__c> selectedNewMembers = [
                SELECT Id, Name, Contact__c, Membership__r.Enable_synchronization__c, Membership__r.Name, Membership__r.Chatter_Group_Id__c
                FROM MembershipContactAssotiation__c
                WHERE Id IN:newMembers AND IsActive__c = TRUE
        ];
        List<Id> contactIds = new List<Id>();
        List<Id> groupsIds = new List<Id>();

        for (MembershipContactAssotiation__c mca : selectedNewMembers) {
            contactIds.add(mca.Contact__c);
            groupsIds.add(mca.Membership__r.Chatter_Group_Id__c);
        }

        List<User> users = [
                SELECT Id, ContactId, IsActive
                FROM User
                WHERE ContactId IN :contactIds
        ];
        List<CollaborationGroup> collGroups = [
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :groupsIds
        ];
        List<CollaborationGroupMember> existedGroupMembers = [
                SELECT CollaborationGroupId, MemberId
                FROM CollaborationGroupMember
                WHERE MemberId IN :users
        ];
        Set<CollaborationGroupMember> cgm = new Set<CollaborationGroupMember>();

        for (MembershipContactAssotiation__c mca : selectedNewMembers) {
            if (mca.Membership__r.Enable_synchronization__c) {

                for (CollaborationGroup chatterGroup : collGroups) {
                    if (chatterGroup.Id == mca.Membership__r.Chatter_Group_Id__c) {

                        for (User u : users) {
                            if (u.ContactId == mca.Contact__c) {
                                if (!SynchronizationGroupMembersHelper.chatterDuplicateCheck(existedGroupMembers, u.Id, chatterGroup.Id)) {
                                    cgm.add(new CollaborationGroupMember (CollaborationGroupId = chatterGroup.Id, MemberId = u.Id));
                                }
                            }
                        }

                    }
                }

            }
        }

        insert new List<CollaborationGroupMember>(cgm);
    }

    public static void deleteFromChatterGroup(List<MembershipContactAssotiation__c> membersToDelete) {
        //check if group synchronization enabled
        List<MembershipContactAssotiation__c> membersWithEnabledSync = [
                SELECT Id, Contact__c, Membership__c, Membership__r.Enable_synchronization__c, Membership__r.Chatter_Group_Id__c
                FROM MembershipContactAssotiation__c
                WHERE Id IN:membersToDelete
                AND Membership__r.Enable_synchronization__c = TRUE
                AND Membership__r.Chatter_Group_Id__c != NULL
        ];

        List<Id> contactIds = new List<Id>();
        List<Id> groupsIds = new List<Id>();
        for (MembershipContactAssotiation__c gcg : membersWithEnabledSync) {
            contactIds.add(gcg.Contact__c);
            groupsIds.add(gcg.Membership__r.Chatter_Group_Id__c);
        }

        //check if groupsMembers have double membership in group

        List<MembershipContactAssotiation__c> allContactsMembershipsAssotiations = [
                SELECT Id, Contact__c, Membership__c, Role__c
                FROM MembershipContactAssotiation__c
                WHERE Contact__c IN :contactIds AND IsActive__c = TRUE
        ];

        List<MembershipContactAssotiation__c> noDuplicateMembersWithEnabledSync = new List<MembershipContactAssotiation__c>();

        for (MembershipContactAssotiation__c triggerMember : membersWithEnabledSync) {
            Boolean duplicateFound = false;
            for (MembershipContactAssotiation__c allGroupMember : allContactsMembershipsAssotiations) {
                if(allGroupMember.Id != triggerMember.Id){
                    if (triggerMember.Contact__c == allGroupMember.Contact__c && triggerMember.Membership__c == allGroupMember.Membership__c) {
                        duplicateFound = true;
                        break;
                    }
                }
            }
            if(!duplicateFound){
                noDuplicateMembersWithEnabledSync.add(triggerMember);
            }
        }

        //check if chatter group exists

        Map<Id, CollaborationGroup> membersGroups = new Map<Id, CollaborationGroup>([
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :groupsIds
        ]);

        List<MembershipContactAssotiation__c> membersWithExistedChatterGroups = new List<MembershipContactAssotiation__c>();

        for(MembershipContactAssotiation__c groupMember : noDuplicateMembersWithEnabledSync){
            if(membersGroups.containsKey(groupMember.Membership__r.Chatter_Group_Id__c)){
                membersWithExistedChatterGroups.add(groupMember);
            }
        }

        //check if the member is part of related chatter group
        List<User> membersUsers = [
                SELECT Id, ContactId
                FROM User
                WHERE ContactId IN :contactIds
        ];

        List<CollaborationGroupMember> chatterGroupMembers = [
                SELECT CollaborationGroupId, MemberId
                FROM CollaborationGroupMember
                WHERE MemberId IN :membersUsers
        ];

        List<CollaborationGroupMember> groupMembersToDelete = new List<CollaborationGroupMember>();

        for(MembershipContactAssotiation__c groupMember : membersWithExistedChatterGroups){
            for(User user : membersUsers){
                if(user.ContactId == groupMember.Contact__c){
                    for (CollaborationGroupMember c : chatterGroupMembers) {
                        if (c.CollaborationGroupId == groupMember.Membership__r.Chatter_Group_Id__c && c.MemberId == user.Id) {
                            groupMembersToDelete.add(c);
                        }
                    }
                }
            }
        }

        //remove chatter group membership
        if(!groupMembersToDelete.isEmpty()){
            delete groupMembersToDelete;
        }
    }

    public static void insertDeleteChatterGroupMember(List<MembershipContactAssotiation__c> newMembers, List<MembershipContactAssotiation__c> oldMembers){
        List<MembershipContactAssotiation__c> onInsert = new List<MembershipContactAssotiation__c>();
        List<MembershipContactAssotiation__c> onDelete = new List<MembershipContactAssotiation__c>();

        for(Integer i = 0; i < newMembers.size(); i++){
            if(!oldMembers[i].IsActive__c && newMembers[i].IsActive__c){
                onInsert.add(newMembers[i]);
            }

            if(oldMembers[i].IsActive__c && !newMembers[i].IsActive__c){
                onDelete.add(newMembers[i]);
            }
        }

        if(!onInsert.isEmpty()){
            insertUndeleteMembershipMembers(onInsert);
        }

        if(!onDelete.isEmpty()){
            deleteFromChatterGroup(onDelete);
        }
    }
}