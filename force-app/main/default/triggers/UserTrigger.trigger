trigger UserTrigger on User (after insert, before insert, before update, after update) {
    Set<String> ALLOWED_PROFILE_NAMES = new Set<String> {
        'Customer Community User',
        'Customer Community Login User',
        'Non-Member Community User Profile',
        'Member Community User Profile',
        'RRFS Reviewer',
        'Secretary General'
    };

    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> userId = new Set<Id>();
        Set<Id> profileId = new Set<Id>();
        for (User u : Trigger.New) {
            profileId.add(u.ProfileId);
        }
        Map<Id, Profile> profilesMap = new Map<Id, Profile> ([
            SELECT Name 
            FROM Profile 
            WHERE Id IN :profileId
        ]);
        //maks, creation of MC subscribers
        Set<Id> contactIds = new Set<Id>();

        for (User u : Trigger.New) {
            Profile currentProfile = profilesMap.get(u.ProfileId);

            if (ALLOWED_PROFILE_NAMES.contains(currentProfile.Name) && u.IsActive) {
                userId.add(u.Id);
                contactIds.add(u.ContactId);
            }
        }
        System.debug('TRIGGER');
        System.debug(contactIds);
        System.debug(NewsletterSubscriptionController.isCreateSubscribersEnabled);
        if (!contactIds.isEmpty() && NewsletterSubscriptionController.isCreateSubscribersEnabled) {
            NewsletterSubscriptionController.createMcSubscribers(contactIds);
        } 

        UserTriggerHelper.AssignPermissionSetToCommunityLoginUsers(userId);
    }
    if (Trigger.isBefore) {
        if(Trigger.isInsert){
            UserTriggerHelper.emailDuplicateValidationInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            UserTriggerHelper.emailDuplicateValidationUpdate(Trigger.new, Trigger.old);
        }
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        UpdateContactAndUserHelper.updateContact(Trigger.new, Trigger.old);
    }
}