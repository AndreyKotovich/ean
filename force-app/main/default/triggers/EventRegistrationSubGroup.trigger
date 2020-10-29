trigger EventRegistrationSubGroup on Event_Registration_Sub_Group__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        EventRegistrationSubGroupTriggerHelper.sendEmailIfSubGroupIsLoked(Trigger.new, Trigger.oldMap);
    }
}