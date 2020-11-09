trigger Participant on Participant__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        List<String> soloParticipantIds = new List<String>();
        List<String> groupParticipantIds = new List<String>();
        for (Participant__c participant : Trigger.new) {
            if (String.isBlank(participant.Event_Registration_Sub_Group__c) && participant.Status__c == 'Pending') {
                soloParticipantIds.add(participant.Id);
            } else if (String.isNotBlank(participant.Event_Registration_Sub_Group__c) && participant.Status__c == 'Pending'){
                groupParticipantIds.add(participant.Id);
            }
        }
        if(soloParticipantIds.size() > 0) {
            ParticipantTriggerHelper.soloParticipantRegistration(soloParticipantIds);
        }
        if (groupParticipantIds.size() > 0) {
            ParticipantTriggerHelper.groupParticipantRegistration(groupParticipantIds);
        }
    }

}