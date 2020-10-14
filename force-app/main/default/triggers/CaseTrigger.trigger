trigger CaseTrigger on Case (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){
        CaseTriggerHelper.postRecordsTo45kBrains(Trigger.new, Trigger.old);
    }

}