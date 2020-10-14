trigger CreateChatterGroup on Group__c (before insert, after update, before update) {
    if(Trigger.isBefore && Trigger.isInsert){
        CreateChatterGroupHelper.createChatterGroup(Trigger.new);
    }

    if(Trigger.isUpdate && Trigger.isAfter){
        CreateChatterGroupHelper.updateChatterGroup(Trigger.new, Trigger.old);
    }

    if(Trigger.isUpdate && Trigger.isBefore){
        CreateChatterGroupHelper.createChatterGroup(Trigger.new);
    }
}