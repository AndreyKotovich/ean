public with sharing class SyncMembershipToChatterMembersBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Log__c log = new Log__c();
    public List<Id> membershipsIds;
    public Map<Id, Set<Id>> chatterGroupListActiveContactsMap = new Map<Id, Set<Id>>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        log.Process_Name__c = 'Batch: SyncMembershipToChatterMembersBatch';
        log.Start_Time__c = Datetime.now();
        log.Status__c = 'In Progress';
        insert log;
        log.Status__c = 'Completed';
        log.Message__c = '';

        if(!membershipsIds.isEmpty() && membershipsIds != null){
            log.Message__c += 'Sync. memberships: ' + String.join(membershipsIds, ',') + '\n';
            return Database.getQueryLocator(
                    'SELECT Id, Contact__c, Membership__c, Membership__r.Chatter_Group_Id__c, IsActive__c FROM MembershipContactAssotiation__c WHERE Membership__c IN :membershipsIds AND Membership__r.Enable_synchronization__c = TRUE'
            );
        } else {
            sendErrorEmail('Synchronization error', new List<String>{'ilya.litovchik@succraft.com'}, 'Batch: SyncMembershipToChatterMembersBatch' + '\n' + 'Incoming params error');
            return null;
        }
    }

    public void execute(Database.BatchableContext bc, List<MembershipContactAssotiation__c> records) {
        try {
            Map<Id, Id> chatterGroupMembershipMap = new Map<Id, Id>();
            Set<Id> chatterGroupIds = new Set<Id>();
            Set<Id> contactMemberId = new Set<Id>();

            for ( MembershipContactAssotiation__c member : records){
                chatterGroupIds.add(member.Membership__r.Chatter_Group_Id__c);
                contactMemberId.add(member.Contact__c);
                chatterGroupMembershipMap.put(member.Membership__r.Chatter_Group_Id__c, member.Membership__c);
            }

            Map<Id, User> membersUsers = new Map<Id, User>([SELECT Id, ContactId FROM User WHERE ContactId IN : contactMemberId]);
            Map<Id, Id> contactUserMap = new Map<Id, Id>();

            for(Id contactId : contactMemberId){
                User foundUser;

                for(User user : membersUsers.values()){
                    if(user.ContactId == contactId){
                        foundUser = user;
                    }
                }

                contactUserMap.put(contactId, foundUser.Id);
            }

            List<CollaborationGroupMember> collaborationGroupMembers = [
                    SELECT CollaborationGroupId, MemberId
                    FROM CollaborationGroupMember
                    WHERE MemberId IN :membersUsers.keySet()
                    AND CollaborationGroupId IN :chatterGroupIds
            ];
            Set<CollaborationGroupMember> deleteChatterMemberList = new Set<CollaborationGroupMember>();
            Set<CollaborationGroupMember> insertChatterMemberList = new Set<CollaborationGroupMember>();

            //Collect all active members of chatter groups ===>
            for(MembershipContactAssotiation__c member : records){

                if(member.IsActive__c){
                    if(chatterGroupListActiveContactsMap.containsKey(member.Membership__r.Chatter_Group_Id__c)){
                        Set<Id> activeContacts = chatterGroupListActiveContactsMap.get(member.Membership__r.Chatter_Group_Id__c);
                        activeContacts.add(member.Contact__c);
                        chatterGroupListActiveContactsMap.put(member.Membership__r.Chatter_Group_Id__c, activeContacts);
                    } else {
                        chatterGroupListActiveContactsMap.put(member.Membership__r.Chatter_Group_Id__c, new Set<Id>{member.Contact__c});
                    }
                }

            }
            //<===


            for(MembershipContactAssotiation__c member : records){
                CollaborationGroupMember detectedChatterMember;
                if(contactUserMap.get(member.Contact__c) != null){

                    for(CollaborationGroupMember collaborationGroupMember : collaborationGroupMembers){
                        if(member.Membership__r.Chatter_Group_Id__c == collaborationGroupMember.CollaborationGroupId){
                            if(membersUsers.get(collaborationGroupMember.MemberId).ContactId == member.Contact__c){
                                detectedChatterMember = collaborationGroupMember;
                                break;
                            }
                        }
                    }

                    if(detectedChatterMember != null){
                        if(!member.IsActive__c){
                            Id memberContact = membersUsers.get(detectedChatterMember.MemberId).ContactId;
                            if(!chatterGroupListActiveContactsMap.get(detectedChatterMember.CollaborationGroupId).contains(memberContact)){
                                deleteChatterMemberList.add(detectedChatterMember);
                            }
                        }
                    } else {
                        if(member.IsActive__c){
                            insertChatterMemberList.add(new CollaborationGroupMember (CollaborationGroupId = member.Membership__r.Chatter_Group_Id__c, MemberId = contactUserMap.get(member.Contact__c)));
                        }
                    }
                }
            }


            Database.SaveResult[] srs = Database.insert(new List<CollaborationGroupMember>(insertChatterMemberList), false);

            for (Database.SaveResult sr : srs) {
                if(!sr.isSuccess()) {
                    log.Status__c = 'Error';
                    for(Database.Error err : sr.getErrors()) {
                        if(!log.Message__c.contains(err.getMessage())){
                            log.Message__c += err.getMessage() + '\n';
                        }
                    }
                }
            }


            Database.DeleteResult[] srs2 = Database.delete(new List<CollaborationGroupMember>(deleteChatterMemberList), false);
            List<Id> notDeletedIds = new List<Id>();

            for (Database.DeleteResult sr : srs2) {
                if(!sr.isSuccess()) {
                    log.Status__c = 'Error';
                    notDeletedIds.add(sr.getId());
                    for(Database.Error err : sr.getErrors()) {
                        if(!log.Message__c.contains(err.getMessage())){
                            log.Message__c += err.getMessage() + '\n';
                        }
                    }
                }
            }

            if(!notDeletedIds.isEmpty()){
                log.Message__c += '\n' + 'NOT DELETED IDs:' + String.join(notDeletedIds, ',') + '\n';
            }

        } catch (Exception e) {
            log.Message__c += e.getMessage() + '\n';
            log.Status__c = 'Error';
        }
    }

    public void finish(Database.BatchableContext bc) {
        log.End_Time__c = Datetime.now();
        update log;
        if(log.Status__c == 'Error'){
            sendErrorEmail('Synchronization error', new List<String>{'ilya.litovchik@succraft.com'}, 'Log: '+System.Url.getSalesforceBaseUrl().toExternalForm() +'/'+ log.Id);
        }
    }

    public static void sendErrorEmail (String subject, List<String> emails, String message) {
        Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
        errorEmail.setSubject(subject);
        errorEmail.setToAddresses(emails);
        errorEmail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{errorEmail});
    }
}