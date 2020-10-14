trigger SocietyMemberTrigger on Society_Member__c (after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter){
        if (Trigger.isUpdate || Trigger.isInsert || Trigger.isUndelete) {
            AssociateMembershipsAssignment.associateMembershipsUpdateHandler(Trigger.new);
        }
//        if (Trigger.isInsert || Trigger.isUndelete){
//            AssociateMembershipsAssignment.associateMembershipsNewRecordHandler(Trigger.new);
//        }
        if(Trigger.isDelete){
            AssociateMembershipsAssignment.deactivateAssociateMembership(Trigger.old);

//            System.debug(Trigger.old);
        }
    }

}