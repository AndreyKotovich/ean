trigger CreateCustomGroup on CollaborationGroup (after insert, after delete, after update, after undelete) {
    if (Trigger.isUpdate) {
        CreateCustomGroupHelper.updateCustomGroup(Trigger.new, Trigger.old);
    }
}