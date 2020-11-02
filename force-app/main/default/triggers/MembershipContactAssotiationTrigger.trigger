trigger MembershipContactAssotiationTrigger on MembershipContactAssotiation__c (after insert, after update, after undelete, before delete) {

    //  'Membership Renewal' process    // collect to uncheck 'Do_Call_For_Renewal__c'  and generate 'Email_Activity__c' records
    Set<Id> mStatusIdSetToUpdate = new Set<Id>();

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

            //  'Membership Renewal' process    // collect to uncheck 'Do_Call_For_Renewal__c'  and generate 'Email_Activity__c' records
            if (Trigger.new[i].Do_Call_For_Renewal__c) {
                // mStatusesListToUpdate.add(new MembershipContactAssotiation__c(Id = Trigger.new[i].Id, Contact__c = Trigger.new[i].Contact__c, Do_Call_For_Renewal__c = false));
                mStatusIdSetToUpdate.add(Trigger.new[i].Id);
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


    //  'Membership Renewal' process:
    //  generate 'Email_Activity__c' records
    //  define 'Last Call For Renewal' field on 'MembershipContactAssotiation__c' records       //  field API Name: Email_Activity__c
    // if (!mStatusIdSetToUpdate.isEmpty()) {

    //     List<MembershipContactAssotiation__c> processedStatuses = [
    //         SELECT Id, Name, Do_Call_For_Renewal__c, Email_Activity__c, Contact__r.Email
    //         FROM MembershipContactAssotiation__c
    //         WHERE Id IN :mStatusIdSetToUpdate
    //         LIMIT :mStatusIdSetToUpdate.size()
    //     ];

    //     List<Email_Activity__c> newEmailActivityList = new List<Email_Activity__c>();
    //     for (MembershipContactAssotiation__c processedStatus : processedStatuses) {
    //         processedStatus.Do_Call_For_Renewal__c = false;
    //         newEmailActivityList.add(new Email_Activity__c(
    //             Contact__c = processedStatus.Contact__c,
    //             Membership_Status__c = processedStatus.Id,
    //             Send_To_Email__c = processedStatus.Contact__r.Email,
    //             Type__c = 'Call For Membership Renewal'
    //         ));
    //     }

    //     List<Database.SaveResult> sr = Database.insert(newEmailActivityList, false);

    //     for (Integer index = sr.size() - 1 ; index >= 0 ; index--) {
    //         if (sr[index].isSuccess()) {
    //             processedStatuses[index].Email_Activity__c = sr[index].getId();
    //         } else {
    //             Trigger.newMap.get(processedStatuses[index].Id).addError('Email was not sent');
    //             newEmailActivityList.remove(index);
    //         }
    //     }

    //     if (!processedStatuses.isEmpty()) update processedStatuses;
    // }
    

    // List<MembershipContactAssotiation__c> mStatusesListToUpdate = new List<MembershipContactAssotiation__c>();
    // mStatusesListToUpdate.add(
    //     new MembershipContactAssotiation__c(
    //         Id = mStatusId

    //     )
    // );
}