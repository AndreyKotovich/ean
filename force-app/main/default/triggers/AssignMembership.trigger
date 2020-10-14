trigger AssignMembership on Application_form__c (before update, after update, before insert) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AssignMembershipHelper.assignMembership(Trigger.new);
        AssignMembershipHelper.documentsMissingEmailCheck(Trigger.old, Trigger.new);
        AssignMembershipHelper.rejectionLetterEmailCheck(Trigger.old, Trigger.new);
    }
}