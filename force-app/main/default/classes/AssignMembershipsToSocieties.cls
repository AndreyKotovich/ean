global class AssignMembershipsToSocieties implements Database.Batchable<sObject>, Database.Stateful {
    global Log__c log = new Log__c();
    global List<Membership__c> memberships = new List<Membership__c>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: AssignMembershipsToSocieties';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';
        memberships = [SELECT Id, API__c FROM Membership__c WHERE API__c = 'full_institutional_members' OR API__c='corresponding_institutional_members'];
        return Database.getQueryLocator(
                'SELECT Id, tx_efnsusr_type_name__c, Membership__c, RecordType.DeveloperName FROM Society__c WHERE tx_efnsusr_type_name__c = \'Society\' OR tx_efnsusr_type_name__c = \'Corresponding Societies\''
        );
    }
    global List<MembershipContactAssotiation__c> getUpsertMembershipStatuses(Set<Id> contacIds, Membership__c criteriaMembership){
        List<MembershipContactAssotiation__c> resultList = new List<MembershipContactAssotiation__c>();
        List<Contact> contactsWithSocietyType = [SELECT Id, (SELECT Id, Endless_Activation__c, Membership__c FROM MembershipContactAssotiations__r) FROM Contact WHERE Id IN :contacIds];
        for (Contact c : contactsWithSocietyType){
            Boolean isFoundAssociateMembership = false;
            for (MembershipContactAssotiation__c memAss : c.MembershipContactAssotiations__r){
                if(memAss.Membership__c == criteriaMembership.Id){
                    isFoundAssociateMembership = true;
                    if(!memAss.Endless_Activation__c){
                        memAss.Endless_Activation__c = true;
                        resultList.add(memAss);
                    }
                }
            }
            if(!isFoundAssociateMembership){
                resultList.add(new MembershipContactAssotiation__c(Contact__c = c.Id, Membership__c = criteriaMembership.Id, Endless_Activation__c = true, Assignment_date__c = Date.today()));
            }
        }
        return resultList;
    }
    global void execute(Database.BatchableContext bc, List<Society__c> records) {
        try {
            for(Society__c s : records){
                for (Membership__c m : memberships){
                    if(s.tx_efnsusr_type_name__c == 'Society' && m.API__c == 'full_institutional_members'){
                        s.Membership__c = m.Id;
                    }else if(s.tx_efnsusr_type_name__c == 'Corresponding Societies' && m.API__c == 'corresponding_institutional_members'){
                        s.Membership__c = m.Id;
                    }
                }
            }
            update records;

            List<Society__c> societiesToAssignMembershipForContacts = new List<Society__c>();
            for(Society__c s : records){
                if(s.RecordType.DeveloperName == 'National_Neurological_Society'){
                    societiesToAssignMembershipForContacts.add(s);
                }
            }

            List<Society_Member__c> societyMembers = [SELECT Id, Society__r.tx_efnsusr_type_name__c, Contact__c FROM Society_Member__c WHERE Society__c IN :societiesToAssignMembershipForContacts AND Role__c = 'Member'];
            Set<Id> contactsIdsForAssMembership = new Set<Id>();
            Set<Id> contactsIdsForAssCorrMembership = new Set<Id>();
            for (Society_Member__c sm : societyMembers){
                if(sm.Society__r.tx_efnsusr_type_name__c == 'Society'){
                    contactsIdsForAssMembership.add(sm.Contact__c);
                } else if(sm.Society__r.tx_efnsusr_type_name__c == 'Corresponding Societies') {
                    contactsIdsForAssCorrMembership.add(sm.Contact__c);
                }
            }
            Membership__c associateMembership = [SELECT Id FROM Membership__c WHERE API__c = 'associate_individual_membership' LIMIT 1];
            Membership__c associateCorrespondingMembership = [SELECT Id FROM Membership__c WHERE API__c = 'associate_corresponding_membership' LIMIT 1];
            List<MembershipContactAssotiation__c> upsetMembershipContactAssotiations = new List<MembershipContactAssotiation__c>();
//            List<Contact> contactsWithSocietyType = [SELECT Id, (SELECT Id, Endless_Activation__c, Membership__c FROM MembershipContactAssotiations__r) FROM Contact WHERE Id IN :contactsWithSocietyTypeIds];
//            for (Contact c : contactsWithSocietyType){
//                Boolean isFoundAssociateMembership = false;
//                for (MembershipContactAssotiation__c memAss : c.MembershipContactAssotiations__r){
//                    if(memAss.Membership__c == associateMembership.Id){
//                        isFoundAssociateMembership = true;
//                        if(!memAss.Endless_Activation__c){
//                            memAss.Endless_Activation__c = true;
//                            upsetMembershipContactAssotiations.add(memAss);
//                        }
//                    }
//                }
//                if(!isFoundAssociateMembership){
//                    upsetMembershipContactAssotiations.add(new MembershipContactAssotiation__c(Contact__c = c.Id, Membership__c = associateMembership.Id));
//                }
//            }
            upsetMembershipContactAssotiations = getUpsertMembershipStatuses(contactsIdsForAssMembership, associateMembership);
            upsetMembershipContactAssotiations.addAll(getUpsertMembershipStatuses(contactsIdsForAssCorrMembership, associateCorrespondingMembership));
            upsert upsetMembershipContactAssotiations;
        }catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }
    global void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
    }

}