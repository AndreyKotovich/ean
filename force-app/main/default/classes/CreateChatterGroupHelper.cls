public with sharing class CreateChatterGroupHelper {
    public static String communityId = [SELECT Id, Name FROM Network WHERE Name = 'ean' LIMIT 1].Id;

    public static void createChatterGroup(List<Group__c> newGroup) {
        List<Group__c> workingGroupWithoutChatterGroup = new List<Group__c>();
        List<Group__c> managementWorkingGroupWithoutChatterGroup = new List<Group__c>();
        List<Id> checkExistenceChatterGroups = new List<Id>();

        for(Integer i=0; i < newGroup.size(); i++){

            if(newGroup[i].Enable_synchronization__c){

                if(newGroup[i].Chatter_Group_Id__c == null){
                    workingGroupWithoutChatterGroup.add(newGroup[i]);
                } else {
                    checkExistenceChatterGroups.add(newGroup[i].Chatter_Group_Id__c);
                }

            }

            if(newGroup[i].Enable_management_group__c){

                if(newGroup[i].Management_Chatter_Group_Id__c == null){
                    managementWorkingGroupWithoutChatterGroup.add(newGroup[i]);
                } else {
                    checkExistenceChatterGroups.add(newGroup[i].Management_Chatter_Group_Id__c);
                }

            }

        }

//        find un existed chatter groups
        Map<Id, CollaborationGroup> chatterGroups = new Map<Id, CollaborationGroup>([SELECT Id FROM CollaborationGroup WHERE Id IN :checkExistenceChatterGroups]);
        List<Id> unExistedChatterGroups = new List<Id>();

        for (Id id : checkExistenceChatterGroups) {
            if(!chatterGroups.containsKey(id)){
                unExistedChatterGroups.add(id);
            }
        }

//        find membership with un existed chatter groups and add on create
        if(!unExistedChatterGroups.isEmpty()){

            for ( Group__c workingGroup : newGroup ) {

                for(Id chatterGroupId : unExistedChatterGroups){

                    if(workingGroup.Chatter_Group_Id__c == chatterGroupId){
                        workingGroupWithoutChatterGroup.add(workingGroup);
                    }

                    if(workingGroup.Management_Chatter_Group_Id__c == chatterGroupId){
                        managementWorkingGroupWithoutChatterGroup.add(workingGroup);
                    }

                }

            }

        }

        List<CollaborationGroup> newChatterGroups = new List<CollaborationGroup>();

        for (Group__c g : workingGroupWithoutChatterGroup) {
            String name = getChatterGroupName(g.Name);
            newChatterGroups.add(new CollaborationGroup(Name = name, NetworkId = communityId, CollaborationType = g.Chatter_Group_Accessibility__c, Description = name.contains('...')?'Chatter Group Full Name:\n"' + g.Name + '"':''));
        }

        for(Group__c g : managementWorkingGroupWithoutChatterGroup){
            String name = getChatterGroupName('MG ' + g.Name);
            newChatterGroups.add(new CollaborationGroup(Name = name, NetworkId = communityId, CollaborationType = 'Private', Description = name.contains('...')?'Chatter Group Full Name:\n"' + 'MG ' + g.Name + '"':''));
        }

        insert newChatterGroups;

        for(Group__c g : workingGroupWithoutChatterGroup){

            for(CollaborationGroup cg : newChatterGroups){

                if(getChatterGroupName(g.Name) == cg.Name){
                    g.Chatter_Group_Id__c = cg.Id;
                }

            }
        }

        List<Id> newManagementChatterGroupIds = new List<Id>();

        for(Group__c g : managementWorkingGroupWithoutChatterGroup){

            for(CollaborationGroup cg : newChatterGroups){

                if(getChatterGroupName('MG ' + g.Name) == cg.Name){
                    g.Management_Chatter_Group_Id__c = cg.Id;
                    newManagementChatterGroupIds.add(cg.Id);
                }

            }

        }

    }

    public static void updateChatterGroup(List<Group__c> newGroup, List<Group__c> oldGroup){
        List<Id> chatterGroupsIds = new List<Id>();
        for(Group__c g : newGroup){
            if(g.Enable_synchronization__c){
                chatterGroupsIds.add(g.Chatter_Group_Id__c);
            }

            if(g.Enable_management_group__c) {
                chatterGroupsIds.add(g.Management_Chatter_Group_Id__c);
            }
        }
        List<CollaborationGroup> chatterGroups = [
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :chatterGroupsIds
        ];
        Set<CollaborationGroup> chatterGroupsToUpdate = new Set<CollaborationGroup>();

        List<Group__c> changedSyncManagementWorkingGroups = new List<Group__c>();
        List<Id> changedSyncManagementChatterGroupIds = new List<Id>();

        for(Integer i = 0; i<newGroup.size(); i++){

            if(newGroup[i].Id == oldGroup[i].Id && newGroup[i].Name != oldGroup[i].Name){

                for(CollaborationGroup cg : chatterGroups){

                    if(newGroup[i].Chatter_Group_Id__c == cg.Id && newGroup[i].Enable_synchronization__c){
                        cg.Name = newGroup[i].Name;
                        chatterGroupsToUpdate.add(cg);
                    }

                    if(newGroup[i].Management_Chatter_Group_Id__c == cg.Id && newGroup[i].Enable_management_group__c){
                        cg.Name = getChatterGroupName('MG ' + newGroup[i].Name);
                        chatterGroupsToUpdate.add(cg);
                    }

                }

            }

            if(newGroup[i].Id == oldGroup[i].Id  && newGroup[i].Enable_management_group__c && !oldGroup[i].Enable_management_group__c){
                if(newGroup[i].Management_Chatter_Group_Id__c != null){
                    changedSyncManagementWorkingGroups.add(newGroup[i]);
                    changedSyncManagementChatterGroupIds.add(newGroup[i].Management_Chatter_Group_Id__c);
                }
            }

        }

        update new List<CollaborationGroup>(chatterGroupsToUpdate);

        synchronizeManagementMembers(changedSyncManagementWorkingGroups, changedSyncManagementChatterGroupIds);
    }

    public static void synchronizeManagementMembers(List<Group__c> changedSyncManagementWorkingGroups, List<Id> changedSyncManagementChatterGroupIds){
        //Synchronize their management group members usual number of is about 3
        List<GroupChatterGroupAssotiation__c> workingGroupManagementMembers = [
                SELECT Id, Contact__c, Group__c
                FROM GroupChatterGroupAssotiation__c
                WHERE Group__c IN :changedSyncManagementWorkingGroups
                AND Role__c = 'Management Group Member'
        ];

        List<Id> contactIds = new List<Id>();

        for(GroupChatterGroupAssotiation__c groupMember : workingGroupManagementMembers){
            contactIds.add(groupMember.Contact__c);
        }

        List<User> workingGroupManagementUsers = [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds];

        Map<Id, Id> contactUserIdsMap = new Map<Id, Id>();

        for(User user : workingGroupManagementUsers){
            contactUserIdsMap.put(user.ContactId, user.Id);
        }


        List<CollaborationGroupMember> existedManagementChatterGroupMembers = [
                SELECT Id, MemberId, CollaborationGroupId
                FROM CollaborationGroupMember
                WHERE MemberId IN :workingGroupManagementUsers
                AND CollaborationGroupId IN :changedSyncManagementChatterGroupIds
        ];


        List<CollaborationGroupMember> newManagementChatterGroupMembers = new List<CollaborationGroupMember>();

        for(Group__c managementWorkingGroupId : changedSyncManagementWorkingGroups){

            for(GroupChatterGroupAssotiation__c managementWorkingGroupMember : workingGroupManagementMembers){

                if(contactUserIdsMap.containsKey(managementWorkingGroupMember.Contact__c)){

                    Boolean isFoundExistedChatterMember = false;

                    for(CollaborationGroupMember existedChatterMember : existedManagementChatterGroupMembers){

                        if(existedChatterMember.MemberId == contactUserIdsMap.get(managementWorkingGroupMember.Contact__c) && existedChatterMember.CollaborationGroupId == managementWorkingGroupId.Management_Chatter_Group_Id__c){
                            isFoundExistedChatterMember = true;
                        }

                    }

                    if(!isFoundExistedChatterMember){
                        newManagementChatterGroupMembers.add(
                                new CollaborationGroupMember(
                                        CollaborationGroupId = managementWorkingGroupId.Management_Chatter_Group_Id__c,
                                        MemberId = contactUserIdsMap.get(managementWorkingGroupMember.Contact__c))
                        );
                    }

                }

            }

        }

        insert newManagementChatterGroupMembers;
    }

    public static String getChatterGroupName(String name){
        if(name.length() > 40){
            String s = name.substring(0, 37);
            name = s + '...';
        }
        return name;
    }

}