trigger ChangeRequest on Change_Request__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter) {
        ChangeRequestHelper.createChangeRequestOrder(Trigger.new, Trigger.oldMap);
        ChangeRequestHelper.sendEmailIfStatusChanged(Trigger.new, Trigger.oldMap);
    }
}