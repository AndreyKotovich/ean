trigger MembershipTrigger on Membership__c (before insert, before update, after update, after delete) {

    if(Trigger.isBefore && Trigger.isInsert){
        MembershipTriggerHelper.createChatterGroup(Trigger.new);
    }

    if(Trigger.isUpdate && Trigger.isAfter){
        MembershipTriggerHelper.updateChatterGroup(Trigger.new, Trigger.old);
    }

    if(Trigger.isUpdate && Trigger.isBefore){
        MembershipTriggerHelper.checkSyncStatus(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        MembershipTriggerHelper.removeChatterGroup(Trigger.old);
    }

}