global class SetMembershipsFlagsOnContactBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Log__c log = new Log__c();
    global List<Date> deadline1 = new List<Date>();
    global Set<String> unSuccessUpdate = new Set<String>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c='Batch: SetMembershipsFlagsOnContactBatch';
        log.Start_Time__c=Datetime.now();
        log.Status__c='In Progress';
        insert log;
        log.Status__c='Completed';
        log.Message__c='';

        //Determine borders of first deadline
        String label = Schema.getGlobalDescribe().get('Country_Price__c').getDescribe().fields.getMap().get('price_for_deadline_2__c').getDescribe().getLabel();
        List<String> dates = label.split('_');
        deadline1.add(Date.valueOf(dates[0]));
        deadline1.add(Date.valueOf(dates[dates.size() - 1]));
        return Database.getQueryLocator(
                'SELECT Id, Email, Flag_EAN_Full_Member__c, Flag_EAN_Corresponding_Member__c, Flag_EAN_Fellow_of_the_EAN__c, ' +
                        'Flag_EAN_Resident_Research_Member__c, Flag_EAN_Associate_Member__c, Flag_EAN_Student_Member__c, ' +
                        'Flag_EAN_New_Member__c, Flag_EAN_Associate_Corresponding_Member__c ' +
                        'FROM Contact'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> records) {
        try {
            List<MembershipContactAssotiation__c> contactsMemberships = [SELECT Id, IsActive__c, Membership__r.API__c, Contact__c, Assignment_date__c FROM MembershipContactAssotiation__c WHERE Contact__c IN:records];
            List<GroupChatterGroupAssotiation__c> contactsGroups = [SELECT Group__r.Type_of_Group__c, Type_of_Group__c FROM GroupChatterGroupAssotiation__c WHERE Contact__c IN :records];

            List<User> users = [SELECT Id, Email, ContactId FROM User WHERE ContactId IN :records];
            Map<String, String> contactIdEmailMap = new Map<String, String>();
            for(User u : users){
                contactIdEmailMap.put(u.ContactId, u.Email);
            }

            for (Contact contact : records) {
                contact.Flag_EAN_Full_Member__c = false;
                contact.Flag_EAN_Corresponding_Member__c = false;
                contact.Flag_EAN_Fellow_of_the_EAN__c = false;
                contact.Flag_EAN_Resident_Research_Member__c = false;
                contact.Flag_EAN_Associate_Member__c = false;
                contact.Flag_EAN_Student_Member__c = false;
                contact.Flag_EAN_New_Member__c = false;
                contact.Flag_EAN_Associate_Corresponding_Member__c = false;
                for (MembershipContactAssotiation__c membershipStatus : contactsMemberships) {
                    if (membershipStatus.Contact__c == contact.Id && membershipStatus.IsActive__c) {
                        if (membershipStatus.Membership__r.API__c == 'full_membership') {
                            contact.Flag_EAN_Full_Member__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'corresponding_membership') {
                            contact.Flag_EAN_Corresponding_Member__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'fellow_membership') {
                            contact.Flag_EAN_Fellow_of_the_EAN__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'resident_and_research_membership') {
                            contact.Flag_EAN_Resident_Research_Member__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'associate_individual_membership') {
                            contact.Flag_EAN_Associate_Member__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'student_membership') {
                            contact.Flag_EAN_Student_Member__c = true;
                        } else if (membershipStatus.Membership__r.API__c == 'associate_corresponding_membership') {
                            contact.Flag_EAN_Associate_Corresponding_Member__c = true;
                        }
                        if(membershipStatus.Assignment_date__c>= deadline1[0] && membershipStatus.Assignment_date__c<=deadline1[1]){
                            contact.Flag_EAN_New_Member__c = true;
                        }
                    }
                }
                if(contact.Email==null){
                    contact.Email = contactIdEmailMap.get(contact.Id);
                }
            }

            Database.SaveResult[] srLis = Database.update(records, false);
            for(Database.SaveResult sr : srLis){
                if(!sr.isSuccess()){
                    unSuccessUpdate.add(sr.getId());
                }
            }
            List<GroupChatterGroupAssotiation__c> groupRolesToUpdate = new List<GroupChatterGroupAssotiation__c>();
            for (GroupChatterGroupAssotiation__c groupRole : contactsGroups) {
                if (groupRole.Group__c != null && groupRole.Group__r.Type_of_Group__c != groupRole.Type_of_Group__c) {
                    groupRole.Type_of_Group__c = groupRole.Group__r.Type_of_Group__c;
                    groupRolesToUpdate.add(groupRole);
                }
            }
            if (!groupRolesToUpdate.isEmpty()) {
                update groupRolesToUpdate;
            }
        }catch (Exception e){
            log.Message__c+=e.getMessage()+'\n';
            log.Status__c='Error';
        }
    }
    global void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        log.Message__c+='NOT UPDATED CONTACTS: '+String.join(new List<String>(unSuccessUpdate),',');
        update log;
    }
}