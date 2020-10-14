public with sharing class SynchronizationGroupMembersHelper {
    public static void insertUndeleteGroupMembers(List<GroupChatterGroupAssotiation__c> newMembers) {
        List<GroupChatterGroupAssotiation__c> selectedNewMembers = [
                SELECT Id, Name, Contact__c, Group__r.Enable_synchronization__c, Group__r.Name, Role__c,
                        Group__r.Chatter_Group_Id__c, Group__r.Management_Chatter_Group_Id__c, Group__r.Enable_management_group__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Id IN:newMembers
        ];

        List<Id> contactIds = new List<Id>();
        List<Id> groupsIds = new List<Id>();

        for (GroupChatterGroupAssotiation__c gcg : selectedNewMembers) {
            contactIds.add(gcg.Contact__c);
            groupsIds.add(gcg.Group__r.Chatter_Group_Id__c);
            groupsIds.add(gcg.Group__r.Management_Chatter_Group_Id__c);
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

        for (GroupChatterGroupAssotiation__c gcg : selectedNewMembers) {
            List<Id> potentialChatterGroups = new List<Id>();

            if(gcg.Group__r.Enable_synchronization__c){
                potentialChatterGroups.add(gcg.Group__r.Chatter_Group_Id__c);
            }

            if(gcg.Group__r.Enable_management_group__c && gcg.Role__c == 'Management Group Member'){
                potentialChatterGroups.add(gcg.Group__r.Management_Chatter_Group_Id__c);
            }

            Id workingGroupMemberUserId;

            for (User u : users) {
                if (u.ContactId == gcg.Contact__c) {
                    workingGroupMemberUserId = u.Id;
                }
            }

            if(workingGroupMemberUserId != null){

                for(Id potentialChatterGroupId : potentialChatterGroups){

                    for (CollaborationGroup chatterGroup : collGroups) {

                        if (potentialChatterGroupId == chatterGroup.Id) {
                            if (!chatterDuplicateCheck(existedGroupMembers, workingGroupMemberUserId, chatterGroup.Id)) {
                                cgm.add(new CollaborationGroupMember (CollaborationGroupId = chatterGroup.Id, MemberId = workingGroupMemberUserId));
                            }
                        }

                    }

                }

            }

        }

        insert new List<CollaborationGroupMember>(cgm);

    }

    public static Boolean chatterDuplicateCheck(List<CollaborationGroupMember> existedGroupMembers, Id userId, Id groupId) {
        Boolean isExist = false;
        for (CollaborationGroupMember c : existedGroupMembers) {
            if (c.CollaborationGroupId == groupId && c.MemberId == userId) {
                isExist = true;
            }
        }
        return isExist;
    }

    public static void checkGroupMemberDuplicateBeforeInsert(List<GroupChatterGroupAssotiation__c> newMembers) {
        List<Id> contactIds = new List<Id>();
        for (GroupChatterGroupAssotiation__c gcg : newMembers) {
            contactIds.add(gcg.Contact__c);
        }
        List<GroupChatterGroupAssotiation__c> existedGroupAssotiations = [
                SELECT Id, Contact__c, Group__c, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Contact__c IN :contactIds
        ];
        for (GroupChatterGroupAssotiation__c gcga : existedGroupAssotiations) {
            for (GroupChatterGroupAssotiation__c nm : newMembers) {
                if(gcga.Id != nm.Id){
                    if (nm.Contact__c == gcga.Contact__c && nm.Group__c == gcga.Group__c && nm.Role__c == gcga.Role__c) {
                        nm.addError('This contact already has this role in this group.');
                    }
                }

            }
        }
    }

    public static void deleteFromChatterGroup(List<GroupChatterGroupAssotiation__c> membersToDelete){
        //check if group synchronization enabled
        List<GroupChatterGroupAssotiation__c> membersWithEnabledSync = [
                SELECT Id, Contact__c, Group__c, Group__r.Enable_synchronization__c, Group__r.Chatter_Group_Id__c,
                        Group__r.Management_Chatter_Group_Id__c, Group__r.Enable_management_group__c, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Id IN:membersToDelete
        ];

        Set<Id> contactIds = new Set<Id>();
        List<Id> chatterGroupsIds = new List<Id>();

        for (GroupChatterGroupAssotiation__c gcg : membersWithEnabledSync) {

            if(gcg.Group__r.Chatter_Group_Id__c != null && gcg.Group__r.Enable_synchronization__c){
                chatterGroupsIds.add(gcg.Group__r.Chatter_Group_Id__c);
                contactIds.add(gcg.Contact__c);
            }

            if(gcg.Group__r.Management_Chatter_Group_Id__c != null && gcg.Group__r.Enable_management_group__c){
                chatterGroupsIds.add(gcg.Group__r.Management_Chatter_Group_Id__c);
                contactIds.add(gcg.Contact__c);
            }

        }

        //check if groupsMembers have double membership in group
        List<GroupChatterGroupAssotiation__c> allContactsWorkingGroupAssotiations = [
                SELECT Id, Contact__c, Group__c, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Contact__c IN :contactIds
        ];

        List<GroupChatterGroupAssotiation__c> updatedMembersWithEnabledSync = new List<GroupChatterGroupAssotiation__c>();

        List<GroupChatterGroupAssotiation__c> workingGroupManagementMembersToDel = new List<GroupChatterGroupAssotiation__c>();

        for (GroupChatterGroupAssotiation__c triggerGroupMember : membersWithEnabledSync) {

            if(triggerGroupMember.Group__r.Enable_management_group__c
                    && triggerGroupMember.Group__r.Management_Chatter_Group_Id__c != null
                    && triggerGroupMember.Role__c == 'Management Group Member'){
                workingGroupManagementMembersToDel.add(triggerGroupMember);
            }

            if(triggerGroupMember.Group__r.Enable_synchronization__c
                    && triggerGroupMember.Group__r.Chatter_Group_Id__c != null){
                Boolean duplicateFound = false;

                for (GroupChatterGroupAssotiation__c allGroupMember : allContactsWorkingGroupAssotiations) {
                    if(allGroupMember.Id != triggerGroupMember.Id){
                        if (triggerGroupMember.Contact__c == allGroupMember.Contact__c && triggerGroupMember.Group__c == allGroupMember.Group__c) {
                            duplicateFound = true;
                            break;
                        }
                    }
                }

                if(!duplicateFound){
                    updatedMembersWithEnabledSync.add(triggerGroupMember);
                }
            }

        }

        //check if chatter group exists
        Map<Id, CollaborationGroup> groupMembersGroups = new Map<Id, CollaborationGroup>([
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :chatterGroupsIds
        ]);

        List<GroupChatterGroupAssotiation__c> membersWithExistedChatterGroups = new List<GroupChatterGroupAssotiation__c>();

        for(GroupChatterGroupAssotiation__c groupMember : updatedMembersWithEnabledSync){
            if(groupMembersGroups.containsKey(groupMember.Group__r.Chatter_Group_Id__c)){
                membersWithExistedChatterGroups.add(groupMember);
            }
        }

        List<GroupChatterGroupAssotiation__c> managementMembersWithExistedChatterGroups = new List<GroupChatterGroupAssotiation__c>();

        for(GroupChatterGroupAssotiation__c groupMember : workingGroupManagementMembersToDel){
            if(groupMembersGroups.containsKey(groupMember.Group__r.Management_Chatter_Group_Id__c)){
                managementMembersWithExistedChatterGroups.add(groupMember);
            }
        }

        //check if the member is part of related chatter group
        List<User> groupMembersUsers = [
                SELECT Id, ContactId
                FROM User
                WHERE ContactId IN :contactIds
        ];

        List<CollaborationGroupMember> chatterGroupMembers = [
                SELECT CollaborationGroupId, MemberId
                FROM CollaborationGroupMember
                WHERE MemberId IN :groupMembersUsers
        ];

        Set<CollaborationGroupMember> groupMembersToDelete = new Set<CollaborationGroupMember>();

        for(GroupChatterGroupAssotiation__c groupMember : membersWithExistedChatterGroups){
            for(User user : groupMembersUsers){
                if(user.ContactId == groupMember.Contact__c){
                    for (CollaborationGroupMember c : chatterGroupMembers) {
                        if (c.CollaborationGroupId == groupMember.Group__r.Chatter_Group_Id__c && c.MemberId == user.Id) {
                            groupMembersToDelete.add(c);
                        }
                    }
                }
            }
        }

        for(GroupChatterGroupAssotiation__c groupMember : managementMembersWithExistedChatterGroups){
            for(User user : groupMembersUsers){
                if(user.ContactId == groupMember.Contact__c){
                    for (CollaborationGroupMember c : chatterGroupMembers) {
                        if (c.CollaborationGroupId == groupMember.Group__r.Management_Chatter_Group_Id__c && c.MemberId == user.Id) {
                            groupMembersToDelete.add(c);
                        }
                    }
                }
            }
        }

        //remove chatter group membership
        if(!groupMembersToDelete.isEmpty()){
            delete new List<CollaborationGroupMember>(groupMembersToDelete);
        }
    }

    public static void updateGroupMembers(List<GroupChatterGroupAssotiation__c> triggerNew, List<GroupChatterGroupAssotiation__c> triggerOld){
        List<GroupChatterGroupAssotiation__c> membersToInsert = new List<GroupChatterGroupAssotiation__c>();
        List<GroupChatterGroupAssotiation__c> membersToDelete = new List<GroupChatterGroupAssotiation__c>();

        for(Integer i = 0; i < triggerNew.size(); i++){
            if(triggerNew[i].Role__c == 'Management Group Member' && triggerOld[i].Role__c != 'Management Group Member'){
                membersToInsert.add(triggerNew[i]);
            }

            if(triggerNew[i].Role__c != 'Management Group Member' && triggerOld[i].Role__c == 'Management Group Member'){
                membersToDelete.add(triggerOld[i]);
            }
        }

        if(!membersToInsert.isEmpty()){
            insertUndeleteGroupMembers(membersToInsert);
        }

        if(!membersToDelete.isEmpty()){
            deleteFromChatterGroup_UPDATE(membersToDelete);
        }

    }

    public static void deleteFromChatterGroup_UPDATE(List<GroupChatterGroupAssotiation__c> membersToDelete){
        //check if group synchronization enabled
        List<GroupChatterGroupAssotiation__c> membersWithEnabledSync = [
                SELECT Id, Contact__c, Group__c, Group__r.Enable_synchronization__c, Group__r.Chatter_Group_Id__c,
                        Group__r.Management_Chatter_Group_Id__c, Group__r.Enable_management_group__c, Role__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Id IN:membersToDelete
        ];

        Set<Id> contactIds = new Set<Id>();
        List<Id> chatterGroupsIds = new List<Id>();

        for (GroupChatterGroupAssotiation__c gcg : membersWithEnabledSync) {

            if(gcg.Group__r.Management_Chatter_Group_Id__c != null && gcg.Group__r.Enable_management_group__c){
                chatterGroupsIds.add(gcg.Group__r.Management_Chatter_Group_Id__c);
                contactIds.add(gcg.Contact__c);
            }

        }

        List<GroupChatterGroupAssotiation__c> workingGroupManagementMembersToDel = new List<GroupChatterGroupAssotiation__c>();

        for (GroupChatterGroupAssotiation__c triggerGroupMember : membersWithEnabledSync) {

            if(triggerGroupMember.Group__r.Enable_management_group__c
                    && triggerGroupMember.Group__r.Management_Chatter_Group_Id__c != null){
                workingGroupManagementMembersToDel.add(triggerGroupMember);
            }

        }

        //check if chatter group exists
        Map<Id, CollaborationGroup> groupMembersGroups = new Map<Id, CollaborationGroup>([
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :chatterGroupsIds
        ]);

        List<GroupChatterGroupAssotiation__c> managementMembersWithExistedChatterGroups = new List<GroupChatterGroupAssotiation__c>();

        for(GroupChatterGroupAssotiation__c groupMember : workingGroupManagementMembersToDel){
            if(groupMembersGroups.containsKey(groupMember.Group__r.Management_Chatter_Group_Id__c)){
                managementMembersWithExistedChatterGroups.add(groupMember);
            }
        }

        //check if the member is part of related chatter group
        List<User> groupMembersUsers = [
                SELECT Id, ContactId
                FROM User
                WHERE ContactId IN :contactIds
        ];

        List<CollaborationGroupMember> chatterGroupMembers = [
                SELECT CollaborationGroupId, MemberId
                FROM CollaborationGroupMember
                WHERE MemberId IN :groupMembersUsers
        ];

        Set<CollaborationGroupMember> groupMembersToDelete = new Set<CollaborationGroupMember>();


        for(GroupChatterGroupAssotiation__c groupMember : managementMembersWithExistedChatterGroups){
            for(User user : groupMembersUsers){
                if(user.ContactId == groupMember.Contact__c){
                    for (CollaborationGroupMember c : chatterGroupMembers) {
                        if (c.CollaborationGroupId == groupMember.Group__r.Management_Chatter_Group_Id__c && c.MemberId == user.Id) {
                            groupMembersToDelete.add(c);
                        }
                    }
                }
            }
        }

        //remove chatter group membership
        if(!groupMembersToDelete.isEmpty()){
            delete new List<CollaborationGroupMember>(groupMembersToDelete);
        }
    }
}