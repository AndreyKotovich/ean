public without sharing class EventRegistrationSubGroupTriggerHelper {
    public EventRegistrationSubGroupTriggerHelper() {

    }
    public static void sendEmailSubGroupMembers(List<Event_Registration_Sub_Group__c> subGroups, Map<Id, Event_Registration_Sub_Group__c> subGroupsOldMap) {
        List<String> lockedSubGroupIds = new List<String>();
        for (Event_Registration_Sub_Group__c subGroup : subGroups) {
            if (subGroup.Is_Locked__c && subGroup.Is_Locked__c != subGroupsOldMap.get(subGroup.Id).Is_Locked__c) {
                lockedSubGroupIds.add(subGroup.Id);
            }
        }
        if (lockedSubGroupIds.size() != 0) {
            List<Participant__c> partisipants = [
                SELECT Id, QR_Code_needed__c, Contact__c, Event_custom__c, Event_Registration_Sub_Group__c, Participant_Email__c, Contact__r.Email, Contact__r.Name FROM Participant__c WHERE Event_Registration_Sub_Group__c IN :lockedSubGroupIds
                ];
            List<Event_Badge__c> badges = new List<Event_Badge__c>();
            for (Participant__c partisipant : partisipants) {
                partisipant.QR_Code_needed__c = true;
                Event_Badge__c badge = new Event_Badge__c();
                badge.Event_Participation__c = partisipant.Id;
                badges.add(badge);
            }
            //Part for getting QR codes logic
            if (partisipants.size() > 0) {
                update partisipants;
            }
            
            List<Email_activity__c> emailActivities = new List<Email_activity__c>();
            for (Participant__c partisipant : partisipants) {
                Email_activity__c emailActivity = new Email_activity__c();
                emailActivity.Event_Participation__c = partisipant.Id;
                emailActivity.Contact__c = partisipant.Contact__c;
                emailActivity.Event_custom__c = partisipant.Event_custom__c;
                if (partisipant.Contact__r.Name == 'Undefined Participant') {
                    emailActivity.Send_to_email__c = partisipant.Participant_Email__c;
                } else {
                    emailActivity.Send_to_email__c = partisipant.Contact__r.Email;
                }
                emailActivity.Type__c = 'Sub group is submited';
                emailActivities.add(emailActivity);
            }
            insert emailActivities;
        }
    }
}