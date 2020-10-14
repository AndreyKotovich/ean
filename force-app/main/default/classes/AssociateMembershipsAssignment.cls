public with sharing class AssociateMembershipsAssignment {
    public static void associateMembershipsUpdateHandler(List<Society_Member__c> newSocietyMembers) {
        List<Society_Member__c> societyMembershipsActivate = new List<Society_Member__c>();
        List<Society_Member__c> societyMembershipsDeactivate = new List<Society_Member__c>();
        for (Society_Member__c sc : newSocietyMembers) {
            if(sc.Is_Active__c){
                societyMembershipsActivate.add(sc);
            }
            if(!sc.Is_Active__c || sc.Role__c != 'Member'){
                societyMembershipsDeactivate.add(sc);
            }
        }
        if(!societyMembershipsActivate.isEmpty()){
            assignAssociateMembership(societyMembershipsActivate);
        }
        if(!societyMembershipsDeactivate.isEmpty()){
            //deactivate
            deactivateAssociateMembership(societyMembershipsDeactivate);
        }
    }
    public static void assignAssociateMembership(List<Society_Member__c> societyMembers){
        Set<Id> contactsIds = new Set<Id>();
        Set<Id> societiesIds = new Set<Id>();
        for (Society_Member__c sm : societyMembers){
            contactsIds.add(sm.Contact__c);
            societiesIds.add(sm.Society__c);
        }
        List<Society__c> societies = [SELECT Id, Membership__r.API__c FROM Society__c WHERE Id IN :societiesIds];
        RecordType nationalNeurologySocietyRT = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'National_Neurological_Society' AND SobjectType = 'Society_Member__c'];
        Set<Id> potentialToAssociateMembership = new Set<Id>();
        Set<Id> potentialToAssociateCorrespondingMembership = new Set<Id>();
        List<MembershipContactAssotiation__c> upsetMembershipContactAssotiations = new List<MembershipContactAssotiation__c>();
        for(Society_Member__c sm : societyMembers){
            if(sm.RecordTypeId == nationalNeurologySocietyRT.Id && sm.Role__c == 'Member'){
                for(Society__c society : societies){
                    if(society.Id == sm.Society__c && society.Membership__r.API__c == 'full_institutional_members'){
                        potentialToAssociateMembership.add(sm.Contact__c);
                    }
                    if(society.Id == sm.Society__c && society.Membership__r.API__c == 'corresponding_institutional_members'){
                        potentialToAssociateCorrespondingMembership.add(sm.Contact__c);
                    }
                }
            }
        }
        upsetMembershipContactAssotiations = getUpsertMembershipStatuses(potentialToAssociateMembership, 'associate_individual_membership');
        upsetMembershipContactAssotiations.addAll(getUpsertMembershipStatuses(potentialToAssociateCorrespondingMembership, 'associate_corresponding_membership'));
        if(!upsetMembershipContactAssotiations.isEmpty()){
            upsert upsetMembershipContactAssotiations;
        }
    }
    public static List<MembershipContactAssotiation__c> getUpsertMembershipStatuses(Set<Id> contactsIds, String criteriaMembershipApi){
        List<MembershipContactAssotiation__c> resultList = new List<MembershipContactAssotiation__c>();
        List<Contact> contacts = [SELECT Id, (SELECT Id, Endless_Activation__c, Membership__c FROM MembershipContactAssotiations__r) FROM Contact WHERE Id IN :contactsIds];
        Membership__c criteriaMembership = [SELECT Id FROM Membership__c WHERE API__c = :criteriaMembershipApi LIMIT 1];
        for (Contact c : contacts){
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
    public static void deactivateAssociateMembership(List<Society_Member__c> societyMembers){
        RecordType nationalNeurologySocietyRT = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'National_Neurological_Society' AND SobjectType = 'Society_Member__c'];
        Set<Id> contactsIds = new Set<Id>();
        Set<Id> societiesIds = new Set<Id>();
        for(Society_Member__c sm : societyMembers){
            //check if society memberships have National_Neurological_Society record type
            if(sm.RecordTypeId == nationalNeurologySocietyRT.Id){
                contactsIds.add(sm.Contact__c);
                societiesIds.add(sm.Society__c);
            }
        }
        //check if contacts have required membership to deactivate
        List<MembershipContactAssotiation__c> contactsStatuses = [
                SELECT Id, Membership__c, Contact__c, Membership__r.API__c, Endless_Activation__c, Expiration_date__c
                FROM MembershipContactAssotiation__c
                WHERE Contact__c IN:contactsIds
                AND IsActive__c = TRUE
                AND (Membership__r.API__c = 'associate_individual_membership'
                OR Membership__r.API__c = 'associate_corresponding_membership')
        ];
        Set<Id> contactsWithAssMembership = new Set<Id>();
        for(MembershipContactAssotiation__c ms: contactsStatuses){
            for(Id contactId : contactsIds){
                if(ms.Contact__c == contactId){
                    contactsWithAssMembership.add(contactId);
                }
            }
        }
        //check if societies have required membership to deactivate contact's one
        Set<Society__c> societiesWithReqMembership = new Set<Society__c>();
        List<Society__c> societies = [SELECT Id, Membership__c, Membership__r.API__c FROM Society__c WHERE Id IN :societiesIds];
        for(Society__c society : societies){
            if(society.Membership__r.API__c == 'full_institutional_members' || society.Membership__r.API__c == 'corresponding_institutional_members'){
                societiesWithReqMembership.add(society);
            }
        }
        //select other contact's Society Membership which can activate associate memberships
        List<Society_Member__c> restSocietiesMemberships = [
                SELECT Id, Society__r.Membership__r.API__c, Contact__c
                FROM Society_Member__c
                WHERE Contact__c IN :contactsWithAssMembership
                AND (Society__r.Membership__r.API__c = 'full_institutional_members'
                OR Society__r.Membership__r.API__c = 'corresponding_institutional_members')
                AND Role__c = 'Member'
                AND RecordTypeId = :nationalNeurologySocietyRT.Id
                AND Is_Active__c = TRUE
        ];
        //Parse initial Societies Memberships, to have only those which can deactivate associate membership.
        List<Society_Member__c> parsedSocietyMemberships = new List<Society_Member__c>();
        for(Society_Member__c sm : societyMembers){
            for(Society__c soc : societiesWithReqMembership){
                if(sm.Society__c == soc.Id){
                    for (Id contId : contactsWithAssMembership){
                        if(sm.Contact__c == contId){
                            parsedSocietyMemberships.add(sm);
                        }
                    }
                }
            }
        }
        List<MembershipContactAssotiation__c> membershipStatusesToDeactivate = new List<MembershipContactAssotiation__c>();
        for(Society_Member__c sm : parsedSocietyMemberships){
            Society__c currentSociety = new Society__c();
            for(Society__c soc : societiesWithReqMembership){
                if(sm.Society__c == soc.Id){
                    currentSociety = soc;
                }
            }
            Boolean isFound = false;
            for(Society_Member__c otherSM : restSocietiesMemberships){
                if(sm.Contact__c == otherSM.Contact__c){
                    if(currentSociety.Membership__r.API__c == otherSM.Society__r.Membership__r.API__c){
                        isFound = true;
                        break;
                    }
                }
            }
            if(!isFound){
                String membershipToDeactivate = currentSociety.Membership__r.API__c == 'full_institutional_members'?'associate_individual_membership':'associate_corresponding_membership';
                for(MembershipContactAssotiation__c mca : contactsStatuses){
                    if(sm.Contact__c == mca.Contact__c && mca.Membership__r.API__c == membershipToDeactivate){
                        if(mca.Endless_Activation__c){
                            mca.Endless_Activation__c = false;
                        }
                        if(mca.Expiration_date__c>Date.today()){
                            mca.Expiration_date__c = Date.today().addDays(-1);
                        }
                        membershipStatusesToDeactivate.add(mca);
                    }
                }
            }
        }
        if(!membershipStatusesToDeactivate.isEmpty()){
            update membershipStatusesToDeactivate;
        }
    }
}