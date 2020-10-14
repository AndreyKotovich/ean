trigger CollaborationGroupMemberTrigger on CollaborationGroupMember (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        CollaborationGroupMemberHelper.setNotificationFrequency(Trigger.new);
    }
}