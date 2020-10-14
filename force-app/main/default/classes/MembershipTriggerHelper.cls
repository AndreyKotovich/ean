public with sharing class MembershipTriggerHelper {
    public static String communityId = [SELECT Id, Name FROM Network WHERE Name = 'ean' LIMIT 1].Id;

    public static void createChatterGroup(List<Membership__c> memberships) {
        List<String> names = new List<String>();

        for (Membership__c m : memberships) {
            names.add(m.Name);
        }

        List<CollaborationGroup> newChatterGroups = new List<CollaborationGroup>();

        for (Membership__c m : memberships) {
            if (m.Enable_synchronization__c) {
                newChatterGroups.add(new CollaborationGroup(Name = m.Name + ' Group', NetworkId = communityId, CollaborationType = m.Chatter_Group_Accessibility__c));
            }
        }

        insert newChatterGroups;

        for(Membership__c m : memberships){

            for(CollaborationGroup cg : newChatterGroups){
                if(m.Name + ' Group' == cg.Name){
                    m.Chatter_Group_Id__c = cg.Id;
                }
            }

        }

    }

    public static void updateChatterGroup(List<Membership__c> newMemberships, List<Membership__c> oldMemberships){
        List<Id> chatterGroupsIds = new List<Id>();
        List<Id> changedSyncStatusMemberships = new List<Id>();

        for(Integer i=0; i < newMemberships.size(); i++){

            if(newMemberships[i].Enable_synchronization__c){

                chatterGroupsIds.add(newMemberships[i].Chatter_Group_Id__c);

                if(!oldMemberships[i].Enable_synchronization__c){
                    changedSyncStatusMemberships.add(newMemberships[i].Id);
                }

            }

        }

        List<CollaborationGroup> chatterGroups = [
                SELECT Id, Name
                FROM CollaborationGroup
                WHERE Id IN :chatterGroupsIds
        ];

        List<CollaborationGroup> chatterGroupsToUpdate = new List<CollaborationGroup>();

        for(Integer i=0; i< newMemberships.size(); i++){

            if(newMemberships[i].Id == oldMemberships[i].Id &&
                    (newMemberships[i].Name != oldMemberships[i].Name ||
                            newMemberships[i].Chatter_Group_Accessibility__c != oldMemberships[i].Chatter_Group_Accessibility__c)){

                for(CollaborationGroup cg : chatterGroups){

                    if(newMemberships[i].Chatter_Group_Id__c == cg.Id){
                        cg.Name = newMemberships[i].Name + ' Group';
                        cg.CollaborationType = newMemberships[i].Chatter_Group_Accessibility__c;
                        chatterGroupsToUpdate.add(cg);
                    }

                }

            }

        }

        update chatterGroupsToUpdate;

        if(!changedSyncStatusMemberships.isEmpty()){
            SyncMembershipToChatterMembersBatch b = new SyncMembershipToChatterMembersBatch();
            b.membershipsIds = changedSyncStatusMemberships;
            Database.executeBatch(b, 200);
        }
    }

    public static void checkSyncStatus(List<Membership__c> newMemberships){
        List<Membership__c> membershipsWithoutChatterGroup = new List<Membership__c>();
        List<Id> checkExistenceChatterGroups = new List<Id>();

        for(Integer i=0; i < newMemberships.size(); i++){

            if(newMemberships[i].Enable_synchronization__c){

                if(newMemberships[i].Chatter_Group_Id__c == null){
                    membershipsWithoutChatterGroup.add(newMemberships[i]);
                } else {
                    checkExistenceChatterGroups.add(newMemberships[i].Chatter_Group_Id__c);
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

            for ( Membership__c membership : newMemberships ) {

                for(Id chatterGroupId : unExistedChatterGroups){

                    if(membership.Chatter_Group_Id__c == chatterGroupId){
                        membershipsWithoutChatterGroup.add(membership);
                    }

                }
            }

        }

        if(!membershipsWithoutChatterGroup.isEmpty()){
            createChatterGroup(membershipsWithoutChatterGroup);
        }
    }

    public static void removeChatterGroup(List<Membership__c> memberships){
        List<Id> relatedChatterGroupsIds = new List<Id>();

        for (Membership__c m : memberships){
            if(m.Enable_synchronization__c && m.Chatter_Group_Id__c != null){
                relatedChatterGroupsIds.add(m.Chatter_Group_Id__c);
            }
        }

        List<CollaborationGroup> chatterGroups = [SELECT Id FROM CollaborationGroup WHERE Id IN :relatedChatterGroupsIds];

        if(!chatterGroups.isEmpty()){
            delete chatterGroups;
        }
    }

}