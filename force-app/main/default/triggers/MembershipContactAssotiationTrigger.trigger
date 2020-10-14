trigger MembershipContactAssotiationTrigger on MembershipContactAssotiation__c (after insert, after update, after undelete, before delete) {
    Set<Id> associationIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();
    // Collect all Membership Status records that are Active and has Application Form ===>
    if(Trigger.isAfter && Trigger.isInsert) {
        for (MembershipContactAssotiation__c m : Trigger.new) {
            if (m.IsActive__c) {
                contactIds.add(m.Contact__c);
                if (m.Application_form__c != null) {
                    associationIds.add(m.Id);
                }
            }
        }
    }
    //<===

    //Collect all Membership Status records that are Active after update. Only for associate memberships,
    //because their membership status records can be updated in logic.
    if(Trigger.isAfter && Trigger.isUpdate){
        for(Integer i=0; i<Trigger.new.size(); i++){
            if(!Trigger.old[i].IsActive__c && Trigger.new[i].IsActive__c){
                contactIds.add(Trigger.new[i].Contact__c);
            }
        }
    }

    if(!System.isBatch() && !System.isFuture()) {

        if (!associationIds.isEmpty()) {
            CertificatePDFGenerator.generateCertificatePDFs(associationIds);
        }
        if (!contactIds.isEmpty()) {
            CertificatePDFGenerator.setNewProfileForUser(contactIds);
        }

    }

    if(Trigger.isUndelete || (Trigger.isAfter && Trigger.isInsert)){
        MembershipChatterMembersSync.insertUndeleteMembershipMembers(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        MembershipChatterMembersSync.deleteFromChatterGroup(Trigger.old);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        MembershipChatterMembersSync.insertDeleteChatterGroupMember(Trigger.new, Trigger.old);
    }

}