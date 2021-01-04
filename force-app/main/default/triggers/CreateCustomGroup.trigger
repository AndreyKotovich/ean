trigger CreateCustomGroup on CollaborationGroup (before insert, after insert, after delete, after update, after undelete) {
    if(Trigger.isBefore && Trigger.isInsert){
        CreateCustomGroupHelper.disableAutoArchiving(Trigger.new);
    }

    if (Trigger.isUpdate) {
        CreateCustomGroupHelper.updateCustomGroup(Trigger.new, Trigger.old);
    }
}