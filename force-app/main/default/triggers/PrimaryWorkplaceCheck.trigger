trigger PrimaryWorkplaceCheck on Contact_Role__c (before insert, after insert, before update, after update, after undelete, after delete) {
    //Check Contact_Role__c on unique is_primary_workplace__c for current contact
    if((Trigger.isBefore&&Trigger.isInsert) || (Trigger.isBefore&&Trigger.isUpdate)){
        PrimaryWorkplaceCheckHelper.PWUniqueCheck(Trigger.New);
    }
    //Clean Mailing address on Contact if it's = "Work Address"
    if(Trigger.isDelete){
        PrimaryWorkplaceCheckHelper.PWDeleted(Trigger.Old);
    }
    if(Trigger.isUpdate){
        PrimaryWorkplaceCheckHelper.uncheckedPW(Trigger.New, Trigger.Old);
    }
    //Set Mailing Address on Contact to "Work Address" if Previous Address = "Work Address"
    if(Trigger.isAfter&&Trigger.isUpdate){
        PrimaryWorkplaceCheckHelper.checkedPW(Trigger.New, Trigger.Old);
    }
    if(Trigger.isAfter&&Trigger.isInsert){
        PrimaryWorkplaceCheckHelper.checkedPWInInsert(Trigger.New);
    }
    //Check Contact_Role__c on unique is_primary_workplace__c for current contact
    //Set Mailing Address on Contact to "Work Address" if Previous Address = "Work Address"
    if(Trigger.isUndelete){
        PrimaryWorkplaceCheckHelper.PWUniqueCheck(Trigger.New);
        PrimaryWorkplaceCheckHelper.checkedPWInInsert(Trigger.New);
    }
}