public with sharing class CollaborationGroupMemberHelper {
    public static void setNotificationFrequency(List<CollaborationGroupMember> members){
        List<Chatter_Group_Settings__mdt> groupSettings = [
                SELECT Chatter_Group_Id__c, NotificationFrequency__c
                FROM Chatter_Group_Settings__mdt
        ];

        Map<Id, Chatter_Group_Settings__mdt> groupIdSettingsMap = new Map<Id, Chatter_Group_Settings__mdt>();

        if(!groupSettings.isEmpty()){

            for(Chatter_Group_Settings__mdt setting : groupSettings){
                groupIdSettingsMap.put(setting.Chatter_Group_Id__c, setting);
            }

            for(CollaborationGroupMember member : members){
                if (groupIdSettingsMap.containsKey(member.CollaborationGroupId)){
                    member.NotificationFrequency = groupIdSettingsMap.get(member.CollaborationGroupId).NotificationFrequency__c;
                }
            }

        }

    }
}