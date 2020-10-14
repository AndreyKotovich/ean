trigger FellowshipApplicationsFormTrigger on Fellowship_Applications_Form__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        FellowshipApplicationsFormTriggerHelper.unlockRecords(Trigger.old, Trigger.new);
    }
}