public with sharing class InviteAllController {
    @AuraEnabled public static List<User> getGroupMembers(Id groupId){
        List<CollaborationGroupMember> groupMembers = [SELECT Id, MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :groupId LIMIT 25000];
        if(groupMembers.isEmpty()){
            AuraHandledException e = new AuraHandledException('No members found');
            e.setMessage('No members found');
            throw e;
        } else {
            List<Id> userIds = new List<Id>();

            for(CollaborationGroupMember collMember : groupMembers){
                userIds.add(collMember.MemberId);
            }

            List<User> groupMembersUsers = [SELECT Id, Name, Email, SmallPhotoUrl FROM User WHERE Id IN :userIds LIMIT 25000];
            Integer removeIndex;

            for(Integer i=0; i<groupMembersUsers.size(); i++){
                if(groupMembersUsers[i].Id == UserInfo.getUserId()){
                    removeIndex = i;
                }
            }

            if(removeIndex != null){
                groupMembersUsers.remove(removeIndex);
            }

            if(!groupMembersUsers.isEmpty()){
                return groupMembersUsers;
            } else {
                AuraHandledException e = new AuraHandledException('No members found');
                e.setMessage('No members found');
                throw e;
            }
        }

    }
}