public with sharing class CreateCustomGroupHelper {
    public static void updateCustomGroup(List<CollaborationGroup> newChatterGroups, List<CollaborationGroup> oldChatterGroups) {
        List<String> chatterGroupsIds = new List<Id>();
        for(CollaborationGroup cg: newChatterGroups){
            chatterGroupsIds.add(cg.Id);
        }
        List<Group__c> allCustomGroups = [SELECT Id, Name, Chatter_Group_Id__c, Enable_synchronization__c FROM Group__c WHERE Chatter_Group_Id__c IN :chatterGroupsIds];
        System.debug('allCustomGroups:: '+allCustomGroups);
        List<Group__c> groupsToUpdate = new List<Group__c>();
        for (Integer i = 0; i < newChatterGroups.size(); i++) {
            if (oldChatterGroups[i].Name != newChatterGroups[i].Name) {
                for (Group__c g : allCustomGroups) {
                    if (g.Chatter_Group_Id__c == oldChatterGroups[i].Id && g.Enable_synchronization__c) {
                        g.Name = newChatterGroups[i].Name;
                        groupsToUpdate.add(g);
                    }
                }
            }
        }
        update groupsToUpdate;
    }

    public static void disableAutoArchiving(List<CollaborationGroup> newChatterGroups){

        for(CollaborationGroup collGroup : newChatterGroups){
            collGroup.IsAutoArchiveDisabled = true;
        }

    }

}