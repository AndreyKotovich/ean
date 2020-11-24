trigger ContactToUser on Contact (after insert, after update) { 
    if (Trigger.isUpdate && Trigger.isAfter) {
        UpdateContactAndUserHelper.updateUser(Trigger.New, Trigger.Old);
        ParticipantTriggerHelper.updateParticipant(Trigger.New, Trigger.oldMap);
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        ParticipantTriggerHelper.updateParticipant(Trigger.new);
    }
    //calling a method to add/remove subscriptions for contacts, mks lvk
    NewsletterSubscriptionController.subscriptionManagement(Trigger.New, Trigger.oldMap, Trigger.isInsert);
}