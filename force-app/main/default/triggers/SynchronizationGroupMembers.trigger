trigger SynchronizationGroupMembers on GroupChatterGroupAssotiation__c (after insert, before delete, after undelete, before insert, after update, after delete ) {
    if(Trigger.isBefore && Trigger.isInsert){
        SynchronizationGroupMembersHelper.checkGroupMemberDuplicateBeforeInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert){
        SynchronizationGroupMembersHelper.insertUndeleteGroupMembers(Trigger.new);
    }

    if(Trigger.isUndelete){
        SynchronizationGroupMembersHelper.checkGroupMemberDuplicateBeforeInsert(Trigger.new);
        SynchronizationGroupMembersHelper.insertUndeleteGroupMembers(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        SynchronizationGroupMembersHelper.checkGroupMemberDuplicateBeforeInsert(Trigger.new);
        SynchronizationGroupMembersHelper.updateGroupMembers(Trigger.new, Trigger.old);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        SynchronizationGroupMembersHelper.deleteFromChatterGroup(Trigger.old);
    }
}